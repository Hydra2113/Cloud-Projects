variable "region" {
    type = string
    description = "aws region where infrastructure is hosted"
    default = "us-east-1"
}

variable "vpc1_cidr" {
    type = string
    description = "CIDR address for the first vpc"
    default = "10.0.0.0/16"
}

variable "vpc2_cidr" {
    type = string
    description = "CIDR address for the second vpc"
    default = "10.1.0.0/16"
}

variable "subnet1_cidr" {
    type = string
    description = "CIDR address for the second vpc"
    default = "10.0.0.0/24"
}

variable "subnet2_cidr" {
    type = string
    description = "CIDR address for the second vpc"
    default = "10.1.0.0/24"
}

variable "instance_type" {
    type = string
    description "EC2 instances to be deployed in both subnets"
    default = "t3.micro"
}