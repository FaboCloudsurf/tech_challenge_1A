#logical grouping/namespace that all your services and tasks run inside.
resource "aws_ecs_cluster" "main_ecs_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights" #enables extra CloudWatch metrics (CPU/memory graphs) for monitoring the cluster.
    value = "enabled"
  }


  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

#fargate has no server you can ssh into to check whats wrong,no docker logs.Cloudwatch is how we see whats going on in inside the containers
resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/${var.project_name}-backend"
  retention_in_days = 7 #auto-deletes old logs after 7 days so they don't pile up/cost money forever.


  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/${var.project_name}-frontend"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-frontend-logs"
  }
}

#the blueprint for a container - WHAT/WHICH image to run, CPU/memory size, and required IAM roles.
resource "aws_ecs_task_definition" "frontend_ecs_task" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn #permissions to pull the image + write logs; task_role_arn = permissions the app code itself needs.
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  #sets the actual container: image, port, env vars, and where its logs go.
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image = var.frontend_image != "" ? var.frontend_image : "${aws_ecr_repository.frontend_repo.repository_url}:latest"
      #an if/else that fits on one line.someone pass in a frontend_image? If yes, use it. If no, fall back to my ECR repo's :latest tag."if/else 
      #condition ? use_this_if_true : use_this_if_false
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "REACT_APP_BACKEND_URL", value = "http://${aws_lb.main_alb.dns_name}" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
          
      #logDriver = "awslogs", which tells ECS "send this container's stdout/stderr output to CloudWatch 
      #Logs." But that log driver needs somewhere to actually write to — the specific log group named in 
      #awslogs-group. By default, AWS does not auto-create that log group for you;
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-frontend-task"
    Environment = var.environment

  }
}


#The blueprint (WHAT/WHICH image to run, how much CPU/memory, what port) — it doesn't run anything by itself.
resource "aws_ecs_task_definition" "backend_ecs_task" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image != "" ? var.backend_image : "${aws_ecr_repository.backend_repo.repository_url}:latest"

      essential = true
      portMappings = [
        {
          containerPort = var.backend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "CORS_ORIGIN", value = "http://${aws_lb.main_alb.dns_name}" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
          
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-backend-task"
    Environment = var.environment

  }
}


# The instruction that actually keeps frontend tasks alive and running.
resource "aws_ecs_service" "frontend_ecs_service" {
  name            = "${var.project_name}-frontend_service"
  cluster         = aws_ecs_cluster.main_ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_ecs_task.arn
  desired_count   = var.desired_tasks
  launch_type     = "FARGATE" 

  network_configuration {
    security_groups  = [aws_security_group.frontend_sg.id]
    subnets          = aws_subnet.private_subnet[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }

  depends_on = [ aws_lb_listener.frontend_listener]

  tags = {
    Name        = "${var.project_name}-frontend-service"
    Environment = var.environment
    
  }
}

#The instruction that says "keep desired_count copies of that blueprint running at all times." 
#Each individual running copy — the actual live container instance, with its own IP address inside your private subnet — is called a task.
resource "aws_ecs_service" "backend_ecs_service" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main_ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend_ecs_task.arn
  desired_count   = var.desired_tasks
  launch_type     = "FARGATE" 

  network_configuration {
    security_groups  = [aws_security_group.backend_sg.id]
    subnets          = aws_subnet.private_subnet[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = var.backend_port
  }

  tags = {
    Name            = "${var.project_name}-backend-service"
    Environment     = var.environment
    
  }
}

# Overview & Explanations

# Task Definition = The recipe , What the container should look like
# It describes exactly how to make one dish (one container): which ingredients (image), how much of each (CPU/memory), what temperature (ports), 
# special instructions (environment variables), etc.

# Service = The kitchen manager, How many of them should be running and keeping them alive
# It makes sure the right number of those dishes are always being prepared and served. If one burns or runs out, it starts a new one using the recipe.