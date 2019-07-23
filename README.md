# Terraform Aqua Security Build

- [Goals](#goals)
- [Prerequisites](#prerequisites)
    - [AWS Preparation](#aws-preparation)
    - [Variable Preparation](#variable-preparation)
- [Terraform Version](#terraform-version)
- [Running the Template](#running-the-template)


# Goals

The main goal of this project is templatize a Production ready Aqua Security build on AWS using Terraform using AWS ECS. For some of you, this Terraform template will be the equivalant of dog poop. For others, it might be "Holy crap that is a lot of stuff!". Whichever camp you fit in, the end goal of this template is to standardize a production level deployment for folks that just don't have the bandwidth to start from scratch when Terraform is required.

Currently, this template is using AWS ECS. Perhaps it should be on Fargate...as of today, I don't know. Hopefully, some of you season experts will be willing to help me improve this template.

Finally, since multi-AWS accounts are being used more and more (hint: they should be), this template should also support multi-AWS accounts. For example, instead of using AWS access keys to setup AWS ECR for container image scans, cross account IAM roles are the way to go.

# Prerequisites

Before you can use this template, you'll need to prepare a some things as well as make some decisions.

## AWS Preparation

First, you need to have a domain name registered and configured in AWS Route 53. Of course you don't _have_ to have a domain name registered but remember, the goal of this project is a ***PRODUCTION*** worthy build.

<p align="center">
<img src="https://github.com/jeremyjturner/terraform-aqua-csp/blob/master/images/01-route53-domain-name-example.jpg" alt="Example of having a Route 53 domain name configured." height="75%" width="75%">
</p>

 Next, you need to have various secrets stored in AWS Secrets Manager. Some of these secrets will need to be provided to your by Aqua Security so if you don't have them, make sure to contact your account manager. This template will use the default AWS managed `aws/ssm` KMS key and should be sufficient for most environments. The secrets that you need to prepare are:

- Username and Password for your Aqua Security account
- A password for the Aqua CSP web console
- Your Aqua License Token
- A password for your Aqua RDS database

Here are some AWS CLI commands to help you set up these secrets–if this is the first time for you to setup anything in Secrets Manager, use the names that I have configured:

```
aws secretsmanager create-secret --region ap-northeast-1 --name aqua/container_repository \
--description "Username and Password for the Aqua Container Repository" \
--secret-string "{\"username\":\"<<YOUR_AQUA_USERNAME>>\",\"password\":\"<<YOUR_AQUA_PASSWORD>>\"}"
 
aws secretsmanager tag-resource --region ap-northeast-1 --secret-id aqua/container_repository \
    --tags "[{\"Key\": \"Owner\", \"Value\": \"<<YOUR_NAME>>\"}]"
  
aws secretsmanager create-secret --region ap-northeast-1 --name "aqua/admin_password" \
    --description "Aqua CSP Console Administrator Password" \
    --secret-string "<<ADMIN_PASSWORD>>"
 
aws secretsmanager tag-resource --region ap-northeast-1 --secret-id aqua/admin_password \
    --tags "[{\"Key\": \"Owner\", \"Value\": \"<<YOUR_NAME>>\"}]"
 
aws secretsmanager create-secret --region ap-northeast-1 --name "aqua/license_token" \
    --description "Aqua Security License" \
    --secret-string "<<LICENSE_TOKEN>>"
 
aws secretsmanager tag-resource --region ap-northeast-1 --secret-id aqua/license_token \
    --tags "[{\"Key\": \"Owner\", \"Value\": \"<<YOUR_NAME>>\"}]"
  
aws secretsmanager create-secret --region ap-northeast-1 --name "aqua/db_password" \
    --description "Aqua CSP Database Password" \
    --secret-string "<<YOUR_DB_PASSWORD>>"
 
aws secretsmanager tag-resource --region ap-northeast-1 --secret-id aqua/db_password \
    --tags "[{\"Key\": \"Owner\", \"Value\": \"<<YOUR_NAME>>\"}]"
```

Make sure to clear the commands that contain secrets out of your bash history with the following command:

`history -d <line number to zap>`

Whatever method you use to setup your secrets, you should have something similar to the screenshot below:

<p align="center">
<img src="https://github.com/jeremyjturner/terraform-aqua-csp/blob/master/images/02-aws-secrets-manager-prepared-example.jpg" alt="Example of having secrets stored in AWS SSM." height="75%" width="75%">
</p>

You will also need to have an EC2 Key Pair configured so that you can use ECS. Don't forget to set the permission on the private key with `chmod 400 <private key file name>`. This will be configured in the `variables.tf` file in the line that has:

```
variable "ssh-key_name" {
  default = "your-ssh-key-goes-here"
}
```
And finally, you'll need to have an ACM certificate setup to attach to an Application Load Balancer. Of course this could or perhaps _should_ be automated with the template but for now, I have it as a manual step as DNS or Email validation can sometimes be a complete pain in the arse.

<p align="center">
<img src="https://github.com/jeremyjturner/terraform-aqua-csp/blob/master/images/03-aws-acm-prepared-example.jpg" alt="Example of having an AWS ACM certificate prepared." height="75%" width="75%">
</p>



## Variable and File Preparation

Our Terraform variables are located in the file `variables.tf` and you'll need to provide inputs.

As mentioned previously, you'll need to have prepared an AWS ACM certificate and the ARN will go here:

```
variable "ssl_certificate_id" {
  default = "arn:aws:acm:<region>:<aws account id:certificate/<certificate id>"
}
```

Your Route 53 DNS name and hosted zone goes in the following variables:

```
variable "dns_domain" {
  default = ""
}

variable "aqua_zone_id" {
  default = ""
}
```

If you want to change the region (currently using Tokyo), you'll need to make those adjustments as well. Note that AWS Availability Zones like the Tokyo region below do not have consecutive identifiers:

```
variable "region" {
  default = "ap-northeast-1"
}
```

```
variable "vpc_azs" {
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}
```

Finally, in file `aquacsp-infrastructure.config` you need to configure a key and S3 bucket for your Terraform state file. You can keep what I have for the `key=` value but you'll need to select your own `bucket` and `region`: 

```
key="AQUACSP/aquacsp-infrastructure.tfstate"
bucket="insert-your-s3-state-bucket-name-here"
region="ap-northeast-1"
```

# Terraform Version

This template was run using Terraform `v0.11.13`.

# Running the Template

No magic here but this is what you _should_ get when you run this template:

