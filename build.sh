#!/bin/bash
echo "Deploying networking..."
aws cloudformation deploy --stack-name AssetApp-Main-VPC-Stack -template-file ./src/vpc/AssetApp-Main-VPC.yml --capabilities CAPABILITY_NAMED_IAM

echo "Deploying security groups..."
aws cloudformation deploy --stack-name AssetApp-Frontend-SG-Stack -template-file ./src/security_groups/AssetApp-Frontend-SG.yml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --stack-name AssetApp-API-SG-Stack -template-file ./src/security_groups/AssetApp-API-SG.yml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --stack-name AssetApp-DB-SG-Stack -template-file ./src/security_groups/AssetApp-DB-SG.yml --capabilities CAPABILITY_NAMED_IAM

echo "Deploying EC2 instances..."
aws cloudformation deploy --stack-name AssetApp-Frontend-Instance-Stack -template-file ./src/ec2/AssetApp-Frontend-Instance.yml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --stack-name AssetApp-API-Instance-Stack -template-file ./src/ec2/AssetApp-API-Instance.yml --capabilities CAPABILITY_NAMED_IAM

echo "Deploying RDS..."
aws cloudformation deploy --stack-name AssetApp-DB-RDS-Stack -template-file ./src/rds/AssetApp-DB-RDS.yml --capabilities CAPABILITY_NAMED_IAM