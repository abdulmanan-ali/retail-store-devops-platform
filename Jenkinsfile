pipeline {
    agent any

    environment {
        AWS_REGION    = 'us-east-1'
        ECR_REGISTRY  = '866849310135.dkr.ecr.us-east-1.amazonaws.com'
        AWS_CREDS     = credentials('aws-creds')  
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Build, Scan and Push') {
            matrix {
                axes {
                    axis {
                        name 'SERVICE'
                        values 'catalog', 'orders', 'checkout', 'cart', 'ui'
                    }
                }
                stages {
                    stage('Checkout') {
                        steps {
                            checkout scm
                        }
                    }

                    stage('Login to ECR') {
                        steps {
                            withCredentials([
                                usernamePassword(
                                    credentialsId: 'aws-creds',
                                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                                )
                            ]) {
                                sh '''
                                    aws ecr get-login-password --region ${AWS_REGION} \
                                      | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                                '''
                            }
                        }
                    }

                    stage('Build Docker image') {
                        steps {
                            sh '''
                                docker build \
                                  -f devops/docker/${SERVICE}/Dockerfile \
                                  -t ${ECR_REGISTRY}/retail-store-${SERVICE}:${GIT_COMMIT} \
                                  .
                            '''
                        }
                    }

                    stage('Scan image with Trivy') {
                        steps {
                            sh '''
                                trivy image \
                                  --format table \
                                  --exit-code 1 \
                                  --severity CRITICAL \
                                  ${ECR_REGISTRY}/retail-store-${SERVICE}:${GIT_COMMIT}
                            '''
                        }
                    }

                    stage('Push to ECR') {
                        when {
                            allOf {
                                branch 'main'
                                not { changeRequest() }   // equivalent to event_name == 'push'
                            }
                        }
                        steps {
                            sh '''
                                docker push ${ECR_REGISTRY}/retail-store-${SERVICE}:${GIT_COMMIT}
                            '''
                        }
                    }
                }
            }
        }

        stage('Update Helm Image Tags') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                checkout scm

                sh '''
                    for service in catalog orders checkout cart ui; do
                      sed -i "/^  ${service}:$/,/tag:/ s|image: .*|image: ${ECR_REGISTRY}/retail-store-${service}|" devops/kubernetes/helm/retail-store/values.yaml

                      sed -i "/^  ${service}:$/,/tag:/ s|tag: \\".*\\"|tag: \\"${GIT_COMMIT}\\"|" devops/kubernetes/helm/retail-store/values.yaml
                    done
                '''

                withCredentials([usernamePassword(
                    credentialsId: 'github-pat',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        git config --global user.name "jenkins-ci"
                        git config --global user.email "ci@jenkins.local"
                        git add devops/kubernetes/helm/retail-store/values.yaml
                        git diff --staged --quiet || git commit -m "ci: update all image tags to ${GIT_COMMIT}"
                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/abdulmanan-ali/retail-store-devops-platform.git HEAD:main
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout ${ECR_REGISTRY} || true'
        }
    }
}