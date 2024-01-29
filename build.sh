#!/bin/bash

REGION="ap-southeast-2"

echo "Deploying pipeline(s)..."
aws cloudformation deploy --stack-name AssetApp-CodePipeline-Infra-Stack --template-file ./src/cicd/AssetApp-CodePipeline-Infra.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides CodePipelineName='AssetApp-Infra-Pipeline' BucketName='assetapp-artifact-bucket-20014321525' GitHubRepo='https://github.com/da2667/asset-app-infra.git' CodeBuildImage='aws/codebuild/amazonlinux2-x86_64-standard:5.0'

# Add frontend app pipeline here
# Add backend app pipeline here

echo "Deploying networking..."
aws cloudformation deploy --stack-name AssetApp-Main-VPC-Stack --template-file ./src/vpc/vpc.yml --capabilities CAPABILITY_NAMED_IAM  --parameter-overrides VpcName=''
VPCID=$(aws cloudformation --region $REGION describe-stacks --stack-name AssetApp-Main-VPC-Stack --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
FrontendSubnet=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPCID --query 'Subnets[?CidrBlock=='10.0.0.0/24'].SubnetId')
APISubnet=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPCID --query 'Subnets[?CidrBlock=='10.0.1.0/24'].SubnetId')

echo "Deploying security groups..."
aws cloudformation deploy --stack-name AssetApp-Frontend-SG-Stack --template-file ./src/security_groups/sg-cidr.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides SGName='AssetApp-Frontend-SG' SGDescription='Frontend of Asset App security group - allows web traffic' VpcId=$VPCID
FrontendSG=$(aws ec2 describe-security-groups --region $REGION --group-names AssetApp-Frontend-SG --query 'SecurityGroups[0].GroupId' --output text)

aws cloudformation deploy --stack-name AssetApp-API-SG-Stack --template-file ./src/security_groups/sg.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides SGName='AssetApp-API-SG' SGDescription='API Security Group - allowing access from the frontend instance only' VpcId=$VPCID SourceSG=$FrontendSG Port=3001
APISG=$(aws ec2 describe-security-groups --region $REGION --group-names AssetApp-API-SG --query 'SecurityGroups[0].GroupId' --output text)

aws cloudformation deploy --stack-name AssetApp-DB-SG-Stack --template-file ./src/security_groups/sg.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides SGName='AssetApp-DB-SG' SGDescription='DB Security group - only allows port 3306 access from the API instance security group' VpcId=$VPCID SourceSG=$APISG Port=3306

echo "Deploying EC2 instances..."
aws cloudformation deploy --stack-name AssetApp-Frontend-Instance-Stack --template-file ./src/ec2/instance.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ImageId='ami-0611295b922472c22' InstanceType='t2.micro' InstanceName='AssetApp-Frontend-Instance' KeyPairName='AssetApp-Frontend-KeyPair' SecurityGroup=$FrontendSG SubnetId=$FrontendSubnet
aws cloudformation deploy --stack-name AssetApp-API-Instance-Stack --template-file ./src/ec2/instance.yml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ImageId='ami-0611295b922472c22' InstanceType='t2.micro' InstanceName='AssetApp-API-Instance' KeyPairName='AssetApp-API-KeyPair' SecurityGroup=$APISG SubnetId=$APISubnet

#echo "Deploying RDS..."
# aws cloudformation deploy --stack-name AssetApp-DB-RDS-Stack --template-file ./src/rds/rds.yml --capabilities CAPABILITY_NAMED_IAM

# echo "Deploying CloudWatch Monitoring stack..."
# aws cloudformation deploy --stack-name AssetApp-CW-Monitoring-Stack --template-file ./src/monitoring/monitoring.yml --capabilities CAPABILITY_NAMED_IAM