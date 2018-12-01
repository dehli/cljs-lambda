#!/usr/bin/env bash

# TODO: Move these into args
STACK_NAME=cp-test
export AWS_PROFILE=personal

# Install node_modules
[[ -d runtime/node_modules ]] || npm --prefix runtime ci

deploy_bucket=$(aws cloudformation \
                    describe-stack-resource \
                    --logical-resource-id DeployBucket \
                    --query "StackResourceDetail.PhysicalResourceId" \
                    --output text \
                    --stack-name $STACK_NAME)

# Package and deploy CloudFormation resources
sam package \
    --template-file cloudformation.yml \
    --output-template-file out.yml \
    --s3-bucket $deploy_bucket

sam deploy \
    --template-file out.yml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM
