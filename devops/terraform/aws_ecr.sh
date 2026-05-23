#!/bin/bash

AWS_ACCOUNT_ID="866849310135"
AWS_REGION="us-east-1"
ECR=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Create ECR repositories for each microservice

for service in ui catalog orders checkout cart; do
    echo "==== Pushing retail-${service}:1.0.0 to ECR ===="
    docker tag retail-${service}:1.0.0 ${ECR}/retail-store-${service}:1.0.0
    docker push ${ECR}/retail-store-${service}:1.0.0
done
