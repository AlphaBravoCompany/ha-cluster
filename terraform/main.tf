provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "baremetal_instance" {
  ami           = var.ami
  instance_type = var.node_type
  key_name      = var.ssh_key
  count         = var.quantity_of_nodes

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  placement {
    availability_zone = var.zone
  }

  tags = {
    Name = "baremetal_instance"
  }
}