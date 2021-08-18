# Data for AWS module

# AWS data
# ----------------------------------------------------------

# Use latest Ubuntu 18.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_security_groups" "rancher-nodes" {
  tags = {
    Name = "rancher-nodes"
  }
}

data "aws_subnet" "cagen1-dev-vpc-PublicSubnetA" {
  tags = {
    Name = "cagen1-dev-vpc-PublicSubnetA"
  }
}


