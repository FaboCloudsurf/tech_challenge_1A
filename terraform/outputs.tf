# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main_vpc.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnet[*].id
}

# ECR Outputs
output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend_repo.repository_url
}

output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend_repo.repository_url
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main_alb.name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main_alb.zone_id
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main_ecs_cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main_ecs_cluster.arn
}

# Jenkins Outputs
output "jenkins_master_public_ip" {
  description = "Public IP address of the Jenkins master instance"
  value       = aws_eip.jenkins_master.public_ip
}

output "jenkins_master_instance_id" {
  description = "Instance ID of the Jenkins master"
  value       = aws_instance.jenkins_master.id
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_eip.jenkins_master.public_ip}:8080"
}

# Security Group Outputs
output "jenkins_security_group_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.jenkins_sg.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.main_alb_sg.id
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
} 