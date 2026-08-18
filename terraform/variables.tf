variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-challenge"
}

variable "frontend_cpu" {
  description = "CPU units for frontend task"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Memory for frontend task (MB)"
  type        = number
  default     = 1024
}

variable "backend_memory" {
  description = "Memory for backend task (MB)"
  type        = number
  default     = 1024
}

variable "min_tasks" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "desired_tasks" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for auto scaling"
  type        = number
  default     = 50
} 

variable "frontend_image" {
  description = "ECR image URI for frontend"
  type        = string
  default     = ""
}

variable "backend_image" {
  description = "ECR image URI for backend"
  type        = string
  default     = ""
}

variable "frontend_port" {
  description = "Port for frontend service"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 8080
}