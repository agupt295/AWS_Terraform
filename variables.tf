# This is where to create variables

# define number of Availability Zones
variable "az_num" {
  type    = number
  default = 2
}

# define namespace
variable "namespace" {
  type    = string
  default = "terraform-workshop"
}

# define VPC CIDR block to be used for deployment
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}