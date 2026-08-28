pipeline {
    agent any

    environment {
        // ====> Replace with your AWS region, e.g., 'us-east-1'
        AWS_REGION                  = 'us-east-1'
        AWS_ACCOUNT_ID              = '730335577638'


        // ====> Replace with your own ECR repository URIs
        FRONTEND_REPO               = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-challenge-frontend"
        BACKEND_REPO                = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-challenge-backend"
        CLUSTER_NAME                = 'devops-challenge-cluster'
        FRONTEND_TASK_FAMILY        = 'devops-challenge-frontend'
        BACKEND_TASK_FAMILY         = 'devops-challenge-backend'
        FRONTEND_SERVICE            = 'devops-challenge-frontend-service'
        BACKEND_SERVICE             = 'devops-challenge-backend-service'
        // Uses this build's unique number as the image tag, so every build is traceable to a specific image
        IMAGE_TAG                   = "${env.BUILD_NUMBER}
    }   

     stages {

        // Pulls down the latest code from whichever branch/repo this pipeline is watching
        stage('Checkout code') {
            steps {
                checkout scm
            }
        }

        // Builds a fresh Docker image for each app, using each folder's own Dockerfile
        stage('Build Docker images') {
            steps {
                sh "docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} ./frontend"
                sh "docker build -t ${ECR_BACKEND}:${IMAGE_TAG} ./backend"
            }
        }

        // Authenticates Docker against ECR, then uploads both newly built images
        stage('Push images to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                    sh "docker push ${ECR_FRONTEND}:${IMAGE_TAG}"
                    sh "docker push ${ECR_BACKEND}:${IMAGE_TAG}"
                }
            }
        }



  
