#!/usr/bin/env bash

# TODO: Move these into args
STACK_NAME=cp-test
export AWS_PROFILE=personal

# Install node_modules
[[ -d runtime/cljs-runtime/node_modules ]] || npm --prefix runtime/cljs-runtime ci

# CloudFormation parameters
parameter_overrides=""

add_parameter() {
  if [ -n "$2" ]; then
    parameter_overrides="$parameter_overrides $1=$2"
  fi
}

# Get S3 bucket to package resources into
deploy_bucket=$(aws cloudformation \
                    describe-stack-resource \
                    --logical-resource-id DeployBucket \
                    --query "StackResourceDetail.PhysicalResourceId" \
                    --output text \
                    --stack-name $STACK_NAME)

# Package and deploy CloudFormation resources
aws cloudformation package \
    --template-file cloudformation.yml \
    --output-template-file out.yml \
    --s3-bucket $deploy_bucket

add_parameter DeployStack true

aws cloudformation deploy \
    --template-file out.yml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides $parameter_overrides
