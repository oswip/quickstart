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

data "aws_security_groups" "osdev-rancher-sg" {
  tags = {
    Name = "osdev-rancher-sg"
  }
}

data "aws_subnet" "vum-dev-vpc-PublicSubnetA" {
  tags = {
    Name = "vum-dev-vpc-PublicSubnetA"
  }
}


