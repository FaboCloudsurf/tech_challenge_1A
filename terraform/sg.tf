#ALB this is the PUBLIC entry point, so its rules are deliberately open:
resource "aws_security_group" "main_alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "SG for ALB"
  vpc_id      = aws_vpc.main_vpc.id

  
  #HTTP port 80 (HyperText Transfer Protocol) is the basic "language" browsers and servers use to talk to each other.
   ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  #HTTPS port 443 (HyperText Transfer Protocol) is the basic "language" browsers and servers use to talk to each other with ENCRYPTION
   ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp" #all protocols
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
    Name = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
 
}

#Frontend Security Group — the ECS tasks running your React app:
resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.frontend_port #the port your container listens on
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.main_alb_sg.id]
    
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }

  tags = {
    name      = "${var.project_name}-frontend-sg"
    Environment = var.environment
  }
}

#backend
resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Security group for backend ECS tasks"
  vpc_id      = aws_vpc.main_vpc.id

ingress {
    description     = "HTTP from frontend"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id] #allows the frontend's tasks to call the backend directly, container-to-container
  }                                                    #server-side rendering, or if the frontend makes internal API calls

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.main_alb_sg.id]     #When a user visits a URL that starts with /api/..., the ALB receives the request and then 
  }                                                   #needs to pass it to one of the healthy backend tasks.
    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-backend-sg"
    Environment = var.environment
  }

}



#jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main_vpc.id
  
  #optional
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #optional
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Ability to remote in the instance to install software,troubleshoot,config server
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #this is Jenkins' own built-in web dashboard, where you'll actually log in, configure pipelines, view build logs, and trigger deployments 
  #through your browser. This is the main way you use Jenkins day-to-day, separate from SSH
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
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
    Name        = "${var.project_name}-jenkins-sg"
    Environment = var.environment
  }
}


#overview and Exlanation

# Reasons frontend port needs direct access to backend port

# 1. Server-Side Rendering (SSR) / Next.js / Nuxt style
# When the frontend is rendered on the server (inside the container), it often needs to fetch data before sending the HTML to the browser.

# // Inside the frontend container (Node.js / Next.js)
# const res = await fetch("http://backend:3000/api/products");  // direct internal call
# const products = await res.json();

# This call never goes through the ALB. It goes straight from the frontend container → backend container.

# 2. Frontend making internal API calls during build or startup
# Sometimes the frontend container needs to call the backend when it starts (for configuration, feature flags, etc.).
# JavaScript// frontend startup code
# const config = await fetch("http://backend.local:8080/api/config");

# 3. Backend-for-Frontend (BFF) pattern
# The frontend talks to its own backend, and that backend then calls other internal services. In simpler setups, the frontend container itself acts a bit like a BFF and calls the real backend directly.

# 4. Health checks or readiness from frontend to backend (less common)
# Some advanced setups have the frontend check if the backend is ready before considering itself healthy.