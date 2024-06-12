# This is the main file to add resources

locals {
  vpc = {
    azs        = slice(data.aws_availability_zones.available.names, 0, var.az_num)
    cidr_block = var.vpc_cidr_block
  }

  rds = {
    engine         = "mysql"
    engine_version = "8.0.35"
    instance_class = "db.t3.micro"
    db_name        = "mydb"
    username       = "dbuser123"
  }

  vm = {
    instance_type = "m5.large"

    instance_requirements = {
      memory_mib = {
        min = 8192
      }
      vcpu_count = {
        min = 2
      }
      instance_generations = ["current"]
    }
  }

  demo = {
    admin = {
      username = "wpadmin"
      password = "wppassword"
      email    = "admin@demo.com"
    }
  }
}

# Basic Lookups 
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "linux" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^al2023-ami-2023\\..*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# IAM
data "aws_iam_policy" "administrator" {
  name = "AdministratorAccess"
}

data "aws_iam_policy" "ssm_managed" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "database" {
  name = "AmazonRDSDataFullAccess"
}

data "aws_iam_policy" "s3_ReadOnly" {
  name = "AmazonS3ReadOnlyAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
