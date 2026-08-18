# the public entry point users hit. Lives in public subnets so,it's reachable from the internet.
# the single public entry point for your whole app.
resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-alb"
  internal           = false                      #internet-facing (reachable from outside AWS) rather than only reachable from inside your own VPC.
  load_balancer_type = "application"              #specifically understand HTTP/HTTPS and can make routing decisions based on the URL path. (api split)
  security_groups    = [aws_security_group.main_alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id

  enable_deletion_protection = false              #Terraform is allowed to delete this resource without an extra manual safety step

  

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Desination of current IP addresses of every healthy frontend task (servers)right now.
# Defines the pool of frontend tasks the ALB can route to, and how to health-check them.
# A list of frontend servers/containers that the load balancer can send website traffic to. Also checks if they are healthy.
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"    #HTTP (HyperText Transfer Protocol) is the basic "language" browsers and servers use to talk to each other.
  target_type = "ip"      #tells AWS "targets will be identified by IP address" rather than by an EC2 instance ID.Required for Fargate (serverless)
  vpc_id      = aws_vpc.main_vpc.id

 health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
 }

 tags = {
   Name = "${var.project_name}-frontend-tg"
   Environment = var.environment
 }
}

# Same structure and purpose as the frontend one, just for backend tasks on port 8080.the health check path is /health
# Same idea as the frontend target group, but for your API servers. Health check looks at /health instead of the root page.
resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"            ##HTTP (HyperText Transfer Protocol) is the basic "language" browsers and servers use to talk to each other.
  target_type = "ip"              #tells AWS "targets will be identified by IP address" rather than by an EC2 instance ID.Required for Fargate (serverless)
  vpc_id      = aws_vpc.main_vpc.id

 health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
 }

 tags = {
   Name = "${var.project_name}-backend-tg"
   Environment = var.environment
 }
}

# This is the part that actually listens for incoming web traffic on port 80. By default it sends everything to the frontend.
# Opens an actual listening port on the ALB.
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"            # means it listens for plain HTTP traffic on port 80 — this is the "unlocked door" that lets any request in at all.
 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}


# ALB Listener Rule for Backend API
# An extra rule on top of the same listener: "if the request path starts with /api/, send it to the backend instead of the frontend (the default)." 
# This is how one ALB serves both the website and the API.
resource "aws_lb_listener_rule" "backend_listener" {
  listener_arn = aws_lb_listener.frontend_listener.arn
  priority     = 100              # Rules are checked in order (lower number = higher priority)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {                # is the actual matching logic: "only apply this override if the request's URL path starts with /api/."
      values = ["/api/*"]         # Match any path that begins with /api/
    }
  }
} 


#overview
#So in a typical frontend/backend challenge you'd have two target groups:

# frontend-tg — the frontend tasks are registered here; a listener rule for /* forwards to it
# backend-tg — the backend tasks are registered here; a rule for /api/* forwards to it

# Resource	Job
# aws_lb	              The entry point — DNS name, subnets, security groups
# aws_lb_listener	      What port to listen on + the fallback destination
# aws_lb_listener_rule	The decision — which request goes to which pool
# aws_lb_target_group	  The pool + how to health-check its members