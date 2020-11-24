#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Please make sure jq is installed before runing this script

# Read inputs
echo "Please enter the region where the studio will be created. (e.g. us-east-1)"
read region

# Sanity check if customer has enabled AWS SSO is in this region
aws sso-admin list-instances --region $region > /dev/null
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "SSO is not enabled in region: $region. Please enable SSO in $region and try again."
    exit $retVal
fi


echo "Please enter the name for the studio. (e.g. my-awesome-studio)"
read studio_name

curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/full_studio_dependencies.yml --output full_studio_dependencies.yml

stack_name=emr-studio-dependencies
echo "Creating a cloudformation stack: $stack_name to provision dependencies for the studio. This can take a few minutes..."
aws cloudformation --region $region \
create-stack --stack-name $stack_name \
--template-body 'file://full_studio_dependencies.yml' \
--capabilities CAPABILITY_NAMED_IAM



# wait till dependencies are provisioned
status=""
while [ "$status" != "CREATE_COMPLETE" ]
do
  status=$(aws cloudformation --region $region describe-stacks --stack-name $stack_name --query "Stacks[0].StackStatus" --output text)
  if [[ "$status" == "CREATE_COMPLETE" ]]
  then
    break
  elif [[ "$status" != "CREATE_IN_PROGRESS" ]]
  then
    echo "Cloudformation stack failed. Please fix the cause, delete the failed stack and try again."
    exit 1
  else
    echo "Wait for cloudformation to finish. Current status: $status"
    echo "Sleep for 10 seconds..."
    sleep 10
  fi
done

outputs=$(aws cloudformation --region $region describe-stacks --stack-name $stack_name --query "Stacks[0].Outputs" --output json)

# update engine security group as Cloudformation does not support zero-egress SGs
engine_sg=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EngineSecurityGroup") | .OutputValue')
aws ec2 --region $region revoke-security-group-egress --group-id "$engine_sg" --protocol all --port all --cidr 0.0.0.0/0


echo "Creating studio with these dependencies:"
echo "------------------------------------------------------------"
echo $outputs | jq -r '.[] | "\(.OutputKey)\t\(.OutputValue)"'
echo "------------------------------------------------------------"

vpc=$(echo $outputs | jq -r '.[] | select(.OutputKey=="VPC") | .OutputValue')
private_subnet_1=$(echo $outputs | jq -r '.[] | select(.OutputKey=="PrivateSubnet1") | .OutputValue')
private_subnet_2=$(echo $outputs | jq -r '.[] | select(.OutputKey=="PrivateSubnet2") | .OutputValue')
service_role=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EMRStudioServiceRoleArn") | .OutputValue')
user_role=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EMRStudioUserRoleArn") | .OutputValue')
workspace_sg=$(echo $outputs | jq -r '.[] | select(.OutputKey=="WorkspaceSecurityGroup") | .OutputValue')
storage_bucket=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EmrStudioStorageBucket") | .OutputValue')

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
--default-s3-location s3://$storage_bucket --output json)


studio_id=$(echo $studio_outputs | jq -r '.["StudioId"]')
studio_url=$(echo $studio_outputs | jq -r '.["Url"]')

echo "Successfully created a studio: $studio_id"
echo "End users can log into the studio via: $studio_url"
printf "\n"

echo "To fetch more detail of the studio, run:"
printf "aws emr describe-studio --region $region --studio-id $studio_id"
printf "\n"

echo "To list all the studios in the current region, run:"
printf "aws emr list-studios --region $region"

printf "\n"
echo "To delete a studio, run:"
echo "aws emr delete-studio --region $region --studio-id $studio_id"
printf "\n"

echo "In order for an end user to login to the studio, the administrator must assign a policy to him/her. Available policies are: "
basic_policy=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EMRStudioBasicUserPolicyArn") | .OutputValue')
intermediate_policy=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EMRStudioIntermediateUserPolicyArn") | .OutputValue')
advanced_policy=$(echo $outputs | jq -r '.[] | select(.OutputKey=="EMRStudioAdvancedUserPolicyArn") | .OutputValue')
echo "------------------------------------------------------------"
echo $basic_policy
echo $intermediate_policy
echo $advanced_policy ;
echo "------------------------------------------------------------"

printf "\n"
echo "Try assigning a policy to a user so he/she can login to the studio."
echo "For example, to assign a policy to user hello@world, run:"
echo "aws emr create-studio-session-mapping --region $region --studio-id $studio_id --identity-name hello@world --identity-type USER --session-policy-arn $advanced_policy"

printf "\n"
echo "Try assigning a policy to a group so that all the users in that group can login to the studio."
echo "For example, to assign a policy to group data-org, run:"
echo "aws emr create-studio-session-mapping --region $region --studio-id $studio_id --identity-name data-org --identity-type GROUP --session-policy-arn $advanced_policy"

