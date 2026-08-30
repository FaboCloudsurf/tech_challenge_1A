pipeline {
    agent any

    environment {
        // ====> Replace with your AWS region, e.g., 'us-east-1'
        AWS_REGION                  = 'us-east-1'
        AWS_ACCOUNT_ID              = '730335577638'


        // ====> Replace with your own ECR repository URIs
        ECR_FRONTEND               = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-challenge-frontend"
        ECR_BACKEND                = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-challenge-backend"
        CLUSTER_NAME                = 'devops-challenge-cluster'
        FRONTEND_TASK_FAMILY        = 'devops-challenge-frontend'
        BACKEND_TASK_FAMILY         = 'devops-challenge-backend'
        FRONTEND_SERVICE            = 'devops-challenge-frontend-service'
        BACKEND_SERVICE             = 'devops-challenge-backend-service'
        // Uses this build's unique number as the image tag, so every build is traceable to a specific image
        IMAGE_TAG                   = "${env.BUILD_NUMBER}"
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

        // Stage 3 — Push images to ECR Authenticates Docker against ECR, then uploads both newly built images
        stage('Push images to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                    sh "docker push ${ECR_FRONTEND}:${IMAGE_TAG}"
                    sh "docker push ${ECR_BACKEND}:${IMAGE_TAG}"
                }
            }
        }

                // Stage 4 — Register new ECS task definitions Creates a brand new task definition revision for each app, pointing at the freshly pushed image
        stage('Register new ECS task definitions') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    script {
                        // --- Frontend: pull the current task def, swap in the new image, register it as a new revision ---
                        sh """
                            aws ecs describe-task-definition --task-definition ${FRONTEND_TASK_FAMILY} --region ${AWS_REGION} \
                              --query 'taskDefinition' > frontend-task-def.json

                            jq --arg IMAGE "${ECR_FRONTEND}:${IMAGE_TAG}" \
                              '.containerDefinitions[0].image = \$IMAGE |
                               del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
                              frontend-task-def.json > frontend-task-def-new.json

                            aws ecs register-task-definition --region ${AWS_REGION} \
                              --cli-input-json file://frontend-task-def-new.json
                        """

                        // --- Backend: identical process, separate task definition ---
                        sh """
                            aws ecs describe-task-definition --task-definition ${BACKEND_TASK_FAMILY} --region ${AWS_REGION} \
                              --query 'taskDefinition' > backend-task-def.json

                            jq --arg IMAGE "${ECR_BACKEND}:${IMAGE_TAG}" \
                              '.containerDefinitions[0].image = \$IMAGE |
                               del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
                              backend-task-def.json > backend-task-def-new.json

                            aws ecs register-task-definition --region ${AWS_REGION} \
                              --cli-input-json file://backend-task-def-new.json
                        """
                    }
                }
            }
        }

        // Stage 5 — Update ECS services Tells each ECS service to switch to the newest task definition revision (deploys the new image)
        stage('Update ECS services') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    // Passing just the family name (no revision number) makes AWS automatically use the LATEST revision
                    sh """
                        aws ecs update-service --cluster ${CLUSTER_NAME} --service ${FRONTEND_SERVICE} \
                          --task-definition ${FRONTEND_TASK_FAMILY} --region ${AWS_REGION}
                    """
                    sh """
                        aws ecs update-service --cluster ${CLUSTER_NAME} --service ${BACKEND_SERVICE} \
                          --task-definition ${BACKEND_TASK_FAMILY} --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        always {
            // Wipes the Jenkins workspace after every run so temp files (task def JSONs, etc.) don't pile up
            cleanWs()
        }
    }
}



  
