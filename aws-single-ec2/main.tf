terraform {
  required_version = "~> 1.1.0"
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      product = "digdag"
    }
  }
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs 
  public_subnets  = var.public_subnets
  database_subnets = var.private_subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = true
}


#EC2 SG
module "http80_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "http-sg"
  description = "HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "https443_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"

  name        = "https-sg"
  description = "HTTPS"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "ssh22_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = "ssh-sg"
  description = "ssh"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# module "digdag6543_sg" {
#   source = "terraform-aws-modules/security-group/aws"

#   name        = "digdag-sg"
#   description = "digdag"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks      = ["0.0.0.0/0"]
#   ingress_rules            = ["https-443-tcp"]
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 6543
#       to_port     = 6543
#       protocol    = "tcp"
#       description = "digdag"
#       cidr_blocks = "0.0.0.0/0"
#     }
#   ]
# }

#RDS SG
module "postgresql_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/postgresql"

  name        = "postgresql-sg"
  description = "postgresql"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.cidr]
}

#EC2 Instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "digdag-instance"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.incetance_type
  monitoring             = true
  vpc_security_group_ids = [module.http80_sg.security_group_id, module.https443_sg.security_group_id, module.ssh22_sg.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)

  user_data_base64 = base64encode(file("./cloud-init.tpl"))
}

resource "aws_eip" "eip" {
    instance = module.ec2_instance.id
}


