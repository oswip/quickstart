# AWS infrastructure resources

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "quickstart_key_pair" {
  key_name_prefix = "${var.prefix}-rancher-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

# 2021-07-16 os - disabled this security group creation and instead used existing security group named "osdev-rancher-sg" 
## Security group to allow all traffic
#resource "aws_security_group" "rancher_sg_allowall" {
#  name        = "${var.prefix}-rancher-allowall"
#  description = "Rancher quickstart - allow all traffic"
#
#  ingress {
#    from_port   = "0"
#    to_port     = "0"
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  egress {
#    from_port   = "0"
#    to_port     = "0"
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Creator = "rancher-quickstart"
#  }
#}

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name        = aws_key_pair.quickstart_key_pair.key_name
  vpc_security_group_ids = [data.aws_security_groups.osdev-rancher-sg.ids[0]]

  # specify the subnet_id here
  #subnet_id              = data.aws_subnet.cagen1-dev-vpc-PublicSubnetA.id
  subnet_id              = data.aws_subnet.vum-dev-vpc-PublicSubnetA.id

  user_data = templatefile(
    join("/", [path.module, "../cloud-common/files/userdata_rancher_server.template"]),
    {
      docker_version = var.docker_version
      username       = local.node_username
    }
  )

  root_block_device {
    volume_size = 16
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      agent       = true
      host        = self.private_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "${var.prefix}-rancher-server"
    Creator = "rancher-quickstart"
  }
}

# Rancher resources
module "rancher_common" {
  source = "../rancher-common"

  node_public_ip         = aws_instance.rancher_server.private_ip
  node_internal_ip       = aws_instance.rancher_server.private_ip
  node_username          = local.node_username
  ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
  rke_kubernetes_version = var.rke_kubernetes_version

  cert_manager_version = var.cert_manager_version
  rancher_version      = var.rancher_version

  rancher_server_dns = join(".", ["rancher", aws_instance.rancher_server.private_ip, "nip.io"])

  admin_password = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "quickstart-aws-custom"
}

# 2021-08-17 os - quickstart node wasn't starting, so commented this out, can do deployments to rancher-server instead (see above)
## AWS EC2 instance for creating a single node workload cluster
#resource "aws_instance" "quickstart_node" {
#  ami           = data.aws_ami.ubuntu.id
#  instance_type = var.instance_type
#
#  key_name        = aws_key_pair.quickstart_key_pair.key_name
#  vpc_security_group_ids = [data.aws_security_groups.osdev-rancher-sg.ids[0]]
#
#  # specify the subnet_id here
#  subnet_id              = data.aws_subnet.cagen1-dev-vpc-PublicSubnetA.id
#
#  user_data = templatefile(
#    join("/", [path.module, "files/userdata_quickstart_node.template"]),
#    {
#      docker_version   = var.docker_version
#      username         = local.node_username
#      register_command = module.rancher_common.custom_cluster_command
#    }
#  )
#
#  provisioner "remote-exec" {
#    inline = [
#      "echo 'Waiting for cloud-init to complete...'",
#      "cloud-init status --wait > /dev/null",
#      "echo 'Completed cloud-init!'",
#    ]
#
#    connection {
#      type        = "ssh"
#      host        = self.private_ip
#      user        = local.node_username
#      private_key = tls_private_key.global_key.private_key_pem
#    }
#  }
#
#  tags = {
#    Name    = "${var.prefix}-quickstart-node"
#    Creator = "rancher-quickstart"
#  }
#}
