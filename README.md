## EMR Studio Samples

This repository contains a script and AWS CloudFormation template samples for Amazon EMR Studio preview. You can create EMR Studios in AWS Organization [Member accounts](https://aws.amazon.com/organizations/faqs/) by using these samples. For more
information about using EMR Studio, see [Use EMR Studio](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio.html) in the *Amazon EMR Management Guide*.

You can submit feedback and requests for changes by opening an issue in this repo or by making proposed changes and submitting a pull request.

## Creating an EMR Studio using demo script



| :warning: WARNING          |
|:---------------------------|
| Charges accrue for the AWS resources that the demo script provisions, such as the Amazon VPC, subnets, and the AWS Service Catalog portfolio in the AWS CloudFormation stack.      |



1. Make sure you have your AWS credentials configured. For more information, see [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html). The IAM principal should contain at least [Minimum Studio Admin permissions](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-admin-role.html) and [AdditionalPermissionForDemoScript.json](https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/AdditionalPermissionForDemoScript.json) in this repo
2. Make sure your AWS CLI version is equal or later than [awscli-1.18.184](https://github.com/aws/aws-cli/releases/tag/1.18.184) or [awscli-2.1.4](https://github.com/aws/aws-cli/releases/tag/2.1.4)
3. The cluster creations inside EMR Studio use the default EMR resources, such as EMR_EC2_DefaultRole, EMR_DefaultRole and S3 bucket for logging EMR steps (e.g. s3://aws-logs123456789012-us-east-1/elasticmapreduce/). So make sure they are present. If your account has never created any EMR cluster before, these default resources will be missing. The easiest way to bootstrap them is to create an EMR cluster using console.
4. Clone this repository, or download [create.sh](https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/create_demo_studio_with_dependencies.sh) using one of the following commands:
   * Clone: ```git clone https://github.com/aws-samples/emr-studio-samples.git```
   * Download: ```curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/create_demo_studio_with_dependencies.sh --output create_demo_studio_with_dependencies.sh```
5. In the terminal, navigate to the directory where you saved `create_demo_studio_with_dependencies.sh`
6. Run: ```bash create_demo_studio_with_dependencies.sh```

## Creating an EMR Studio using your own S3 bucket, VPC and cluster templates

| :warning: WARNING          |
|:---------------------------|
|Make sure your  VPC and Subnets have the required tag: key = "for-use-with-amazon-emr-managed-policies", value = "true". Update S3 resource in service role policy to your S3 bucket


If you prefer to use existing S3 Bucket, VPC, Private Subnets(with NAT) and Service catalog products, use ``min_studio_dependencies.yml`` to create a minimum resource stack for your Studio. This stack contains only one service role, one user role, three example session policies and two securigy groups, which are needed to create an EMR Studio. 


1. If you did not clone the repository, download ``min_studio_dependencies.yml`` on your local machine using the following command: ```curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/min_studio_dependencies.yml -o min_studio_dependencies.yml```.
2. Create a new Cloudformation stack with ```min_studio_dependencies.yml``` via AWS Management console or AWS CLI. (Provide VPC Id for the stack parameter ```VPC```)
3. Remove the egress rule of ```EngineSecurityGroup``` (Unfortunately Cloudformation does not support creating 0-egress security group).
4. Note down the Cloudformation stack outputs: ``EMRStudioServiceRoleArn, EMRStudioUserRoleArn, EngineSecurityGroup and WorkspaceSecurityGroup``
4. Run
```
aws emr create-studio --region $region \
--name $studio_name \
--auth-mode SSO \
--vpc-id $your_vpc \
--subnet-ids $your_subnet_1 $your_subnet_2 \
--service-role $service_role \
--user-role $user_role \
--workspace-security-group-id $workspace_sg \
--engine-security-group-id $engine_sg \
--default-s3-location s3://$your_s3_bucket
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Copyright and License
All content in this repository, unless otherwise stated, is Copyright © Amazon Web Services, Inc. or its affiliates. All rights reserved.

The sample code within this repository is made available under the MIT-0 License. See the LICENSE file.
