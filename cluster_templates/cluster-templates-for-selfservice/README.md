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
| 1. | emr-transform-lambda.yaml | AWS Cloudformation template to deploy an AWS Lambda Function that will be reference by your Macro|
| 2. | emr-transform-macro.yaml | AWS Cloudformation template to deploy the Transform macro |
| 3. | sample-cluster-template-for-service-catalog.yaml | Sample cluster template to deploy via EMR Studio|
| 4. | emr-studio-service-catalog-setup.yaml | Template to deploy template in service catalog |

## Deployment Instructions

### 1. Deploying the AWS Cloudformation Macro in your AWS Account

Follow these instructions to deploy the sample macro in your AWS cloudformation environment. 

1. Deploy your AWS Lambda function using the sample emr-transform-lambda.yaml:

```
aws cloudformation create-stack \
--stack-name "emr-transform-lambda" \
--template-body file://emr-transform-lambda.yaml \
--parameters ParameterKey=EnvName,ParameterValue=emr-transform-lambda \
--capabilities CAPABILITY_NAMED_IAM \
--region us-west-2

```

2. Deploy your AWS Cloudformation macro:

```
aws cloudformation create-stack \
--stack-name "emrstudio-emr-size-macro" \
--template-body file://emr-transform-macro.yaml \
--region us-west-2
```

### 2. Deploy your sample template in AWS Service Catalog

1. Upload the emr cluster template into your Amazon S3 bucket
2. Create a portfolio and product referencing your template.

### 3. Cleanup

Delete cloudformation stacks:
1. Remove service catalog stacks
2. Remove macro stack
3. Remove lambda stack
4. Delete Amazon S3 buckets


```
aws s3 cp ./sample-cluster-template-for-service-catalog.yaml s3://emrstudio.sample.templates/
aws s3 cp ./emr-studio-network-setup.yaml s3://emrstudio.sample.templates/
aws s3 cp ./emr-studio-iam-setup.yaml s3://emrstudio.sample.templates/
aws s3 cp ./emr-studio-service-catalog-setup.yaml s3://emrstudio.sample.templates/
aws s3 cp ./sample-cluster-template-for-service-catalog.yaml s3://emrstudio.sample.templates/


https://s3.us-west-2.amazonaws.com/emrstudio.sample.templates/sample-cluster-template-for-service-catalog.yaml
```
 