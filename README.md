# Terraform Aqua Security Build

- [Goals](#goals)
- [Prerequisites](#prerequisites)
    - [AWS Preparation](#aws-preparation)
    - [Variable Preparation](#variable-preparation)
- [Terraform Version](#terraform-version)
- [Running the Template](#running-the-template)
- [Cleaning Up](#cleaning-up)


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

You will also need to have an EC2 Key Pair configured so that you can use ECS. Don't forget to set the permission on the private key with `chmod 400 <private key file name>` and don't include the file extension `.pem`. Otherwise, you'll get the error:

`ValidationError: The key pair 'your-key-name.pem' does not exist`

This will be configured in the `variables.tf` file in the line that has:

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
You might also want to add your name since all resources should have a named owner.

```
variable "resource_owner" {
  default = "Your Name"
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

No magic here but this is what you _should_ get when you run this template. Note that I am using a tool called [saml2aws](https://github.com/Versent/saml2aws) since I have multiple AWS accounts configured with LDAP.

First run `init` using the `aquacsp-infrastructure.config` file:

```
jeremyturner: saml2aws exec -a test-account "terraform init -backend-config="aquacsp-infrastructure.config""
Initializing modules...
- module.asg
- module.db
- module.vpc
- module.db.db_subnet_group
- module.db.db_parameter_group
- module.db.db_option_group
- module.db.db_instance

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "template" (2.1.2)...
- Downloading plugin for provider "aws" (2.20.0)...
- Downloading plugin for provider "null" (2.1.2)...
- Downloading plugin for provider "random" (2.1.2)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.20"
* provider.null: version = "~> 2.1"
* provider.random: version = "~> 2.1"
* provider.template: version = "~> 2.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Now you run `plan`. Note that I have snipped out much of the output:

```
jeremyturner: saml2aws exec -a test-account "terraform plan"
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.template_file.userdata: Refreshing state...
data.aws_secretsmanager_secret.admin_password: Refreshing state...
data.aws_secretsmanager_secret.db_password: Refreshing state...
<snip>
<snip>
<snip>
Plan: 60 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```
Now run `apply`. Note that I have snipped out much of the output:

```
jeremyturner: saml2aws exec -a test-account "terraform apply"
data.template_file.userdata: Refreshing state...
data.aws_secretsmanager_secret.admin_password: Refreshing state...
data.aws_secretsmanager_secret.db_password: Refreshing state...
data.aws_ami.ecs-optimized: Refreshing state...
<snip>
<snip>
<snip>
Plan: 60 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
<snip>
<snip>
<snip>
aws_ecs_service.console-service: Creation complete after 1s (ID: arn:aws:ecs:ap-northeast-1:242279356189...quacsp-cluster/aquacsp-console-service)

Apply complete! Resources: 60 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = aquacsp-alb-162839334.ap-northeast-1.elb.amazonaws.com
elb_dns_name = internal-aquacsp-aqua-gw-elb-504453041.ap-northeast-1.elb.amazonaws.com
hostnames = [
    aqua.yourowndomain.com
]
```
# Cleaning Up

Once you've tested everything, make sure to clean-up the resources your made. Otherwise, you'll be footing the bill for some beefy instances.

Run `destroy` to delete all of the resources:

```
jeremyturner: saml2aws exec -a test-account "terraform destroy"
data.template_file.userdata: Refreshing state...
aws_iam_role.aquacsp-vpc: Refreshing state... (ID: aquacsp-VPC-Flow-Logs)
aws_iam_role.enhanced_monitoring: Refreshing state... (ID: aquacsp_monitoring_role)
<snip>
<snip>
<snip>
  - module.db.module.db_subnet_group.aws_db_subnet_group.this


Plan: 0 to add, 0 to change, 60 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
<snip>
<snip>
<snip>
module.vpc.aws_vpc.this: Destroying... (ID: vpc-067fe813a20de9644)
module.vpc.aws_vpc.this: Destruction complete after 1s

Destroy complete! Resources: 60 destroyed.
```
Also, for some reason the VPC log group `/vpc/aquacsp` doesn't get destroyed sometimes so you'll need to manually delete it. 