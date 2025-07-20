provider "aws" {
    region = "ap-southeast-1"
}

data "aws_vpc" "default" {
    default = true

}

data "aws_caller_identity" "current" {}


data  "aws_subnets" default {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

output "subnet_ids" {
    value = data.aws_subnets.default.ids
}