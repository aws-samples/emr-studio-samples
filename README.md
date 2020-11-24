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

## Modifying the EMR Studio dependency stack created by create_studio.sh
Charges accrue for the AWS resources (VPC, subnets, AWS Service Catalog portfolio of templates) that ```create_studio.sh``` provisions. Use the following instructions to customize the resource stack for your Studio. For example, you might want to use ``create_studio.sh`` to provision the default IAM roles and security groups for EMR Studio, but use your own VPC, subnets, and cluster templates. You can remove the network and AWS Service Catalog resources from ```full_studio_dependencies.yml```, and update ```create-studio.sh``` accordingly.
1. If you did not clone the repository, download ```full_studio_dependencies.yml``` to the same location on your local machine using the following command: ```curl https://rawgithubusercontent.com/aws-samples/emr-studio-samples/main/full_studio_dependencies.yml```.
2. Open ```full_studio_dependencies.yml``` in your editor of choice.
3. Modify resource definitions or remove unwanted resources from the template. For example, you might remove all of the network resources if you want to supply your own VPC and subnets.
5. Open ```create_studio.sh``` in your editor of choice. 
6. Comment out line 43 ```curl https://raw.githubusercontent.com/aws-samples/emr-studio-samples/main/full_studio_dependencies.yml --output full_studio_dependencies.yml``` since ```create-studio.sh``` will use your local, modified version of ```full_studio_dependencies.yml```.
7. Replace the variable values in lines 97-105 to specify your custom values to the ```create-studio``` CLI command. For example, replace ```--vpc-id $vpc``` with ```--vpc-id <your-vpc-id>``` to supply the ID of the VPC you want to associate with the Studio. For more information about ```create-studio``` requirements, see [create-studio](https://docs.aws.amazon.com/cli/latest/reference/emr/create-studio.html) in the *AWS CLI Command Reference*.
6. Save your changes and run create-studio using ```base create_studio.sh```.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Copyright and License
All content in this repository, unless otherwise stated, is Copyright © Amazon Web Services, Inc. or its affiliates. All rights reserved.

The sample code within this repository is made available under the MIT-0 License. See the LICENSE file.
