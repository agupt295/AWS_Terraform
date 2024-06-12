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

# Create resources for IAM- allow our EC2 instances to read from an S3 bucket, as well get full access permissions to the RDS resources
resource "aws_iam_role" "app" {
  name               = "app"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    data.aws_iam_policy.ssm_managed.arn,
    data.aws_iam_policy.database.arn
  ]
}

resource "aws_iam_role" "web_hosting" {
  name               = "web_hosting"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    data.aws_iam_policy.ssm_managed.arn,
    data.aws_iam_policy.s3_ReadOnly.arn
  ]
}

resource "aws_iam_instance_profile" "app" {
  name = "app-profile"
  role = aws_iam_role.app.name
}

resource "aws_iam_instance_profile" "web_hosting" {
  name = "web-hosting-profile"
  role = aws_iam_role.web_hosting.name
}

# creating VPC network components such as the subnets, internet gateway, route tables, and NAT gateway.
resource "aws_vpc" "default" {
  cidr_block           = local.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.namespace}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  vpc_id                  = aws_vpc.default.id
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 0)))
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.namespace}-subnet-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 1)))
  availability_zone = each.value

  tags = {
    Name = "${var.namespace}-subnet-private-${each.key}"
  }
}

resource "aws_subnet" "private_ingress" {
  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 2)))
  availability_zone = each.value

  tags = {
    Name = "${var.namespace}-subnet-private_ingress-${each.key}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.namespace}-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.namespace}-route-table-public"
  }
}

resource "aws_route_table" "private_ingress" {
  count = length(aws_subnet.private_ingress)

  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default[count.index].id
  }

  tags = {
    Name = "${var.namespace}-route-table-private-ingress-${count.index}"
  }
}

resource "aws_main_route_table_association" "default" {
  vpc_id         = aws_vpc.default.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_ingress" {
  count = length(aws_subnet.private_ingress)

  subnet_id      = aws_subnet.private_ingress[count.index].id
  route_table_id = aws_route_table.private_ingress[count.index].id
}

resource "aws_eip" "nat_gateway" {
  count = length(aws_subnet.public)

  tags = {
    Name = "${var.namespace}-private_ingress-nat-gateway-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "default" {
  count = length(aws_subnet.public)

  connectivity_type = "public"
  subnet_id         = aws_subnet.public[count.index].id
  allocation_id     = aws_eip.nat_gateway[count.index].id
  depends_on        = [aws_internet_gateway.default]

  tags = {
    Name = "${var.namespace}-private_ingress-nat-gateway-${count.index}"
  }
}
