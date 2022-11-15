# Sample cluster template for self-service

The templates in this repo provides a sample EMR Cluster template that can be deployed via Service Catalog so 
AWS EMR Studio users can self provision an EMR Cluster.  The template abstracts the configuration of the cluster into 
three simple questions for ease of use by Data Scientist and Data Engineering teams: 

1. **User Concurrency** - *What is the expected user concurrency in the environment?* 
This will help determine the target capacity
2. **Memory Profile** - *What are the memory expectations of the workload (Small, Medium, Large)*?. 
This will help determine the instance type and subsequently the CPU and Memory provisioned to each Spark Executor.
3. **Optimization** - *Does the workload has specific SLAs to meet? then optimize for reliability, ot is flexiblr? optimize for Cost*.
This will help determine if the task nodes can leverage AWS Spot instances or only On-Demand.

In order to resolve the size configurations from these abstract input values the template is using AWS CloudFormation 
functionality including Mappings, Conditions and Transforms. All other configurations like network and  security are pre-defined 
in the template and hidden from end users for ease of use. It is expected that Cloud Operations teams will define the configuration 
following best practices and remove complexities from analytics teams. For additional help with EMR best practices see

## Licensing Info
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

## Contents
The following table list and describes the files in this repo:

| # | File Name | Description  |
| :-: |:---:   | :-: |
| 1. | emr-transform-lambda.yaml | AWS Cloudformation template to deploy a Transform and an AWS Lambda Function macro.|
| 2. | sample-cluster-template-for-service-catalog.yaml | Sample cluster template to deploy via EMR Studio|
| 3. | emr-studio-service-catalog-setup.yaml | Template to deploy the sample cluster template as a service catalog product|

## Deployment Instructions

### 1. Deploying the AWS Cloudformation Macro in your AWS Account

Follow these instructions to deploy the sample macro in your AWS cloudformation environment. 

Deploy the "emr-transform-lambda.yaml" template in  AWS CloudFormation. The stack will deploy an IAM Role, an AWS Lambda 
function and initializes the "emr-capacity-macro" in your AWS Cloudformation environment.

```
aws cloudformation create-stack \
--stack-name "emr-transform-lambda" \
--template-body file://emr-transform-lambda.yaml \
--parameters ParameterKey=EnvName,ParameterValue=emr-transform-lambda \
--capabilities CAPABILITY_NAMED_IAM \
--region us-west-2
```

### 2. Deploy the custom EMR template as a product in AWS Service Catalog

1. Create an S3 bucket.
2. Upload the sample emr cluster template into your Amazon S3 bucket
3. Create a portfolio and product referencing your template using the "emr-studio-service-catalog-setup.yaml" template

```
aws cloudformation create-stack \
--stack-name "emr-service-catalog-product" \
--template-body file://emr-studio-service-catalog-setup.yaml \
--parameters ParameterKey=DeploymentName,ParameterValue=EMRStudioSampleProduct \
ParameterKey=EMRStudioAdminRole,ParameterValue=<your-emr-studio-admin-role> \
ParameterKey=TemplateS3Bucket,ParameterValue=<your-bucket-name> \
--capabilities CAPABILITY_NAMED_IAM \
--region us-west-2
```

### 3. Cleanup

To clean-up remove the two AWS Cloudformation stacks deployed and delete the Amazon S3 bucket just created.

