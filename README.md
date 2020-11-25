## EMR Studio Samples

This repository contains a script and AWS CloudFormation template samples for Amazon EMR Studio preview. For more
information about using EMR Studio, see [Use EMR Studio](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio.html) in the *Amazon EMR Management Guide*.

You can submit feedback and requests for changes by opening an issue in this repo or by making proposed changes and submitting a pull request.

## Creating an EMR Studio using create_studio.sh


1. Set up the EMR Studio prerequisites described in the [Set Up an EMR Studio](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-set-up.html) section of the *Amazon EMR Management Guide*.
2. Make sure you have [jq](https://stedolan.github.io/jq/) installed. The script uses jq to parse and display AWS CLI output.
3. Make sure you have your AWS credentials configured. For more information, see [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).
4. Make sure your AWS CLI version is equal or later than [awscli-1.18.184](https://github.com/aws/aws-cli/releases/tag/1.18.184)
5. Clone this repository, or download [create.sh](https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/create_studio.sh) using one of the following commands:
   * Clone: ```git clone https://github.com/aws-samples/emr-studio-samples.git```
   * Download: ```curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/create_studio.sh --output create_studio.sh```
6. In the terminal, navigate to the directory where you saved `create_studio.sh`. 
7. Run: ```bash create_studio.sh```

## Bring your own S3 bucket, VPC and cluster templates
If you prefer to use existing S3 Bucket, VPC, Private Subnets(with NAT) and Service catalog products, use the ``min_studio_dependencies.yml`` to create the resource stack for your Studio. The created stack contains only service role, user role, three session policies and two securigy groups. 


1. If you did not clone the repository, download ``min_studio_dependencies.yml`` on your local machine using the following command: ```curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/min_studio_dependencies.yml -o min_studio_dependencies.yml```.
2. Create a new Cloudformation stack with ```min_studio_dependencies.yml``` via AWS Management console or AWS CLI. (fill your VPC Id for the stack parameter ```VPC```)
3. Remove the egress rule of ```EngineSecurityGroup```
4. Note down the Cloudformation stack outputs: ``EMRStudioServiceRoleArn, EMRStudioUserRoleArn, EngineSecurityGroup and WorkspaceSecurityGroup``
4. Run
```
aws emr create-studio --region $region \
--name $studio_name \
--auth-mode SSO \
--vpc-id $vpc \
--subnet-ids $private_subnet_with_NAT_1 $private_subnet_with_NAT_2 \
--service-role $service_role_from_cloudformation \
--user-role $user_role_from_cloudformation \
--workspace-security-group-id $workspace_sg_from_cloudformation \
--engine-security-group-id $engine_sg_from_cloudformation \
--default-s3-location s3://$storage_bucket
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Copyright and License
All content in this repository, unless otherwise stated, is Copyright © Amazon Web Services, Inc. or its affiliates. All rights reserved.

The sample code within this repository is made available under the MIT-0 License. See the LICENSE file.
