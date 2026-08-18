# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Jenkins Master EC2 Instance
resource "aws_instance" "jenkins_master" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"
  key_name      = "1_percent_keypair517"

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_subnet[0].id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "Jenkins Master"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP for Jenkins Master
resource "aws_eip" "jenkins_master" {
  instance = aws_instance.jenkins_master.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-jenkins-master-eip"
    Environment = var.environment
  }
} 