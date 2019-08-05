variable "region" {
  default = "us-east-1"
}

variable "resource_owner" {
  default = "Reshef Sharvit"
}

variable "project" {
  default = "aquaresheftest"
}

#################################################
# ACM Configuration - INPUT REQUIRED
#################################################
variable "ssl_certificate_id" {
  default = "arn:aws:acm:<region>:<aws account id:certificate/<certificate id>"
}

#################################################
# DNS Configuration - INPUT REQUIRED
#################################################
variable "dns_domain" {
  default = ""
}

variable "aqua_zone_id" {}

#################################################
# VPC Configuration
#################################################
variable "vpc_cidr" {
  default = "10.111.0.0/16"
}

variable "vpc_public_subnets" {
  default = ["10.111.1.0/24", "10.111.2.0/24"]
}

variable "vpc_private_subnets" {
  default = ["10.111.3.0/24", "10.111.4.0/24"]
}

variable "vpc_azs" {
  default = ["us-east-1a", "us-east-1b"]
}

#################################################
# Secrets Manager Configuration
#################################################
variable "secretsmanager_container_repository" {
  default = "aqua/container_repository"
}

variable "secretsmanager_admin_password" {
  default = "aqua/admin_password"
}

variable "secretsmanager_license_token" {
  default = "aqua/license_token"
}

variable "secretsmanager_db_password" {
  default = "aqua/db_password"
}

#################################################
# EC2 Configuration - INPUT REQUIRED
#################################################
variable "ssh-key_name" {
}

variable "instance_type" {
  default = "m5.large"
}

#################################################
# RDS Configuration
#################################################
variable "db_instance_type" {
  default = "db.t2.large"
}

variable "postgres_username" {
  default = "postgres"
}

variable "postgres_port" {
  default = "5432"
}

#################################################
# AQUA Ports
#################################################
variable "aqua_server_port_01" {
  default = "8080"
}

variable "aqua_server_port_02" {
  default = "8443"
}

variable "aqua_gateway_port" {
  default = "3622"
}

# Note that port 80 is redirected to 443
variable "lb_port" {
  default = "80"
}
