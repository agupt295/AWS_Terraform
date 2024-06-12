# This is where to create variables

variable "az_num" {
  type    = number
  default = 2
}

variable "namespace" {
  type    = string
  default = "terraform-workshop"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}