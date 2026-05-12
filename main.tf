terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # If you configured a named profile above, add: profile = "cs312"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "cs312" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "cs312-vpc"
  }
}

resource "aws_subnet" "cs312_public" {
  vpc_id                  = aws_vpc.cs312.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cs312-public-subnet"
  }
}

resource "aws_internet_gateway" "cs312_igw" {
  vpc_id = aws_vpc.cs312.id

  tags = {
    Name = "cs312-igw"
  }
}

resource "aws_route_table" "cs312_public_rt" {
  vpc_id = aws_vpc.cs312.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cs312_igw.id
  }

  tags = {
    Name = "cs312-public-rt"
  }
}

resource "aws_route_table_association" "cs312_public_rta" {
  subnet_id      = aws_subnet.cs312_public.id
  route_table_id = aws_route_table.cs312_public_rt.id
}

resource "aws_security_group" "minecraft" {
  name        = "cs312-tf-minecraft-sg"
  description = "Minecraft node: SSH and Minecraft only"
  vpc_id      = aws_vpc.cs312.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Minecraft"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cs312-tf-minecraft-sg"
  }
}

# Minecraft node: you SSH into this instance from your laptop
resource "aws_instance" "minecraft" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  iam_instance_profile   = "LabInstanceProfile"
  subnet_id = aws_subnet.cs312_public.id

  root_block_device {
    volume_size = 20    # GB — enough for Minecraft world data
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "cs312-tf-minecraft"
  }
}

# Have to add key_path variable to variables.tf and set it to the path of your SSH private key 
resource "null_resource" "ansible" {
  depends_on = [aws_instance.minecraft]

  provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = <<EOT
      ansible-playbook \
        -i '${aws_instance.minecraft.public_ip},' \
        -u ubuntu \
        --private-key '${var.key_path}' \
        -e 'aws_account_id=${data.aws_caller_identity.current.account_id}' \
        -e 'aws_region=us-east-1' \
        -e 'minecraft_image_tag=${var.minecraft_image_tag}' \
        playbook.yml
    EOT
  }
}

# ECR repository for the CI/CD pipeline in Lab 6
resource "aws_ecr_repository" "minecraft-storage" {
  name                 = "cs312-minecraft-terraform"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# 
resource "aws_s3_bucket" "minecraft_backup" {
  bucket = "cs312-minecraft-backup-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "cs312-minecraft-backup"
  }
}