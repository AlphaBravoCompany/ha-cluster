provider "aws" {
  access_key              = var.aws_access_key
  secret_key              = var.aws_secret_key
  region                  = var.region
}

resource "aws_security_group" "ssh_access" {
  name                    = "baremetal_ssh_access"
  description             = "Allow SSH inbound traffic for Baremetal server nodes"

  ingress {
    from_port             = 22
    to_port               = 22
    protocol              = "tcp"
    cidr_blocks           = ["0.0.0.0/0"]
  }

  egress {
    from_port             = 0
    to_port               = 0
    protocol              = "-1"
    cidr_blocks           = ["0.0.0.0/0"]
  }

  tags = {
    Name                  = "Baremetal Instance"
  }
}

resource "aws_instance" "baremetal_instance" {
  ami                     = var.ami_id
  instance_type           = var.instance_type
  key_name                = var.ssh_key
  count                   = var.instance_count
  availability_zone       = var.zone

  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  root_block_device {
    volume_size           = "250"
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name                  = "Baremetal Instance"
  }
}

resource "local_file" "inventory" {
  content                 = join("\n", aws_instance.baremetal_instance.*.public_ip)
  filename                = "../ansible/inventory.txt"
  depends_on              = [aws_instance.baremetal_instance]
}