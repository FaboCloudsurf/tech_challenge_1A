# Registers the ECS service as a resource AWS Autoscaling is allowed to scale
# scales all kinds of managed resources that aren't raw EC2 instances
# ECS service task counts, DynamoDB read/write capacity, Aurora replicas, and a handful of others.(Fargate/serverless)It doesn't manage servers at all
resource "aws_appautoscaling_target" "asg_ecs_frontend" {
  max_capacity       = var.max_tasks
  min_capacity       = var.min_tasks
  resource_id        = "service/${aws_ecs_cluster.main_ecs_cluster.name}/${aws_ecs_service.frontend_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount" #specifies exactly what's being scaled (the number of running tasks, not CPU/memory directly
  service_namespace  = "ecs"

  
}

#this is the actual scaling behavior, attached to the target above.
resource "aws_appautoscaling_policy" "ecs_policy_frontend" {
  name               = "${var.project_name}-frontend-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_ecs_frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_ecs_frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_ecs_frontend.service_namespace

    target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization" #tells it to track average CPU across the service's tasks
    }

    target_value = var.cpu_threshold
  }
}


resource "aws_appautoscaling_target" "asg_ecs_backend" {
  max_capacity       = var.max_tasks
  min_capacity       = var.min_tasks
  resource_id        = "service/${aws_ecs_cluster.main_ecs_cluster.name}/${aws_ecs_service.backend_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  
}

resource "aws_appautoscaling_policy" "ecs_policy_backend" {
  name               = "${var.project_name}-backend-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_ecs_backend.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_ecs_backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_ecs_backend.service_namespace

    target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.cpu_threshold
  }
}
