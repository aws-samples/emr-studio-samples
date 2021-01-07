#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# About create_studio.sh
# Creates a new Amazon EMR Studio and its associated AWS resource stack
# through the following actions:
#    - Prompts for AWS Region.
#    - Prompts for the new EMR Studio name.
#    - Provisions a Studio resource stack called emr-studio-dependencies
#      using the full_studio_dependencies.yml AWS CloudFormation template 
#      located in the same repository.
#    - Creates an EMR Studio using the provisioned resources.
#    - Returns the details about the new Studio.
#    
# Prerequisites
#    - The default Amazon EMR IAM roles, security groups,
#      and Amazon S3 logging bucket must already exist in the AWS Region 
#      where you want to create the Studio.


# Read AWS Region
echo "Enter the code for the AWS Region in which you want to create the Studio. For example, us-east-1."
read region

# Read Studio name
echo "Enter a descriptive name for the Studio. For example, my-first-emr-studio."
read studio_name

# Retrieve full_studio_dependencies.yml
curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/full_studio_dependencies.yml --output full_studio_dependencies.yml

# Provision the Studio resource stack using AWS CloudFormation
stack_name=emr-studio-dependencies

aws cloudformation --region $region describe-stacks --stack-name $stack_name > /dev/null 2>&1
retVal=$?

if [ $retVal -ne 0 ]; then
  echo "Creating the following CloudFormation stack to provision dependencies for the Studio: $stack_name. This takes a few minutes..."
  aws cloudformation --region $region \
  create-stack --stack-name $stack_name \
  --template-body 'file://full_studio_dependencies.yml' \
  --capabilities CAPABILITY_NAMED_IAM
else
  echo "There is an existing dependency Cloudformation stack: $stack_name. Resuming with that stack."
fi

# Check whether the resource stack has been created
status=""
while [ "$status" != "CREATE_COMPLETE" ]
do
  status=$(aws cloudformation --region $region describe-stacks --stack-name $stack_name --query "Stacks[0].StackStatus" --output text)
  if [[ "$status" == "CREATE_COMPLETE" ]]
  then
    echo "Dependency Cloudfomaton stack has completed."
    break
  elif [[ "$status" != "CREATE_IN_PROGRESS" ]]
  then
    echo "Failed to create the Cloudformation stack. Fix the cause, delete the failed stack ($stack_name), and try again."
    exit 1
  else
    echo "Waiting for CloudFormation to finish. Current status: $status"
    echo "Checking the status again in 10 seconds..."
    sleep 10
  fi
done

# Return the resource stack details
outputs=$(aws cloudformation --region $region describe-stacks --stack-name $stack_name --query "Stacks[0].Outputs" --output text)

# Remove the default allow-all egress rule of engine security group
engine_sg=$(echo $outputs | tr " " "\n" | grep -A 1 'EngineSecurityGroup' | tail -n1)
aws ec2 --region $region revoke-security-group-egress --group-id $engine_sg --protocol all --port all --cidr 0.0.0.0/0  > /dev/null 2>&1

# Create the Studio
vpc=$(echo $outputs | tr " " "\n" | grep -A 1 'VPC' | tail -n1)
private_subnet_1=$(echo $outputs | tr " " "\n" | grep -A 1 'PrivateSubnet1' | tail -n1) 
private_subnet_2=$(echo $outputs | tr " " "\n" | grep -A 1 'PrivateSubnet2' | tail -n1) 
service_role=$(echo $outputs | tr " " "\n" | grep -A 1 'EMRStudioServiceRoleArn' | tail -n1)
user_role=$(echo $outputs | tr " " "\n" | grep -A 1 'EMRStudioUserRoleArn' | tail -n1)
workspace_sg=$(echo $outputs | tr " " "\n" | grep -A 1 'WorkspaceSecurityGroup' | tail -n1)
engine_sg=$(echo $outputs | tr " " "\n" | grep -A 1 'EngineSecurityGroup' | tail -n1)
storage_bucket=$(echo $outputs | tr " " "\n" | grep -A 1 'EmrStudioStorageBucket' | tail -n1)

echo "Creating a studio with $vpc, $private_subnet_1, $private_subnet_2, $service_role, $user_role, $workspace_sg, $engine_sg"
echo "......"

studio_outputs=$(aws emr create-studio --region $region \
--name $studio_name \
--auth-mode SSO \
--vpc-id $vpc \
--subnet-ids $private_subnet_1 $private_subnet_2 \
--service-role $service_role \
--user-role $user_role \
--workspace-security-group-id $workspace_sg \
--engine-security-group-id $engine_sg \
--default-s3-location s3://$storage_bucket \
--output text)

studio_id=$(echo $studio_outputs | tr " " "\n" | head -n1)
studio_url=$(echo $studio_outputs | tr " " "\n"  | tail -n1)


# Return additional information about managing the Studio
echo "Successfully created an EMR Studio with this ID: $studio_id"
echo "Users can log in to the Studio with this access URL: $studio_url"

echo "To fetch details about the Studio, use:"
printf "aws emr describe-studio --region $region --studio-id $studio_id"
printf "\n"

echo "To list all of the Studios in the specified Region, use:"
printf "aws emr list-studios --region $region"

printf "\n"
echo "To delete the Studio, use:"
echo "aws emr delete-studio --region $region --studio-id $studio_id"
printf "\n"

echo "Specify one of the following session policies when you assign a user or group to the Studio: "
basic_policy=$(echo $outputs | tr " " "\n" | grep -A 1 'EMRStudioBasicUserPolicyArn' | tail -n1)
intermediate_policy=$(echo $outputs | tr " " "\n" | grep -A 1 'EMRStudioIntermediateUserPolicyArn' | tail -n1)
advanced_policy=$(echo $outputs | tr " " "\n" | grep -A 1 'EMRStudioAdvancedUserPolicyArn' | tail -n1)

echo "------------------------------------------------------------"
echo $basic_policy
echo $intermediate_policy
echo $advanced_policy ;
echo "------------------------------------------------------------"

printf "\n"
echo "To assign a user to the Studio and attach a session policy, use:"
echo "aws emr create-studio-session-mapping --region $region --studio-id $studio_id --identity-name johndoe@enterprise.com --identity-type USER --session-policy-arn $advanced_policy"

printf "\n"
echo "To assign a group (for example, data-org) to the Studio and attach a session policy, use:"
echo "aws emr create-studio-session-mapping --region $region --studio-id $studio_id --identity-name data-org --identity-type GROUP --session-policy-arn $advanced_policy"
