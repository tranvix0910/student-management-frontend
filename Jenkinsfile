pipeline {
    agent {
        label 'Development Server'
    }
    environment {
        CI_COMMIT_SHORT_SHA = ""
        CI_COMMIT_TAG = ""
        CI_PROJECT_NAME = ""
        IMAGE_VERSION = ""

        AWS_DEFAULT_REGION = "ap-southeast-1"
        ECR_URL = "022499043310.dkr.ecr.ap-southeast-1.amazonaws.com"
        ECR_REPO = "student-management/frontend"
        
        TASK_FAMILY = "frontend-task-definition"
        CLUSTER_NAME = "student-management-cluster"
        SERVICE_NAME = "student-management-frontend"
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout From Git'){
            steps{
                git branch: 'main', 
                url: 'https://github.com/tranvix0910/student-management-frontend.git'
            }
        }
        stage('Get Infomation Project') {
            steps {
                script {
                    CI_PROJECT_NAME = sh(
                        script: "git remote show origin -n | grep Fetch | cut -d'/' -f5 | cut -d'.' -f1",
                        returnStdout: true
                    ).trim()

                    def CI_COMMIT_HASH = sh(
                        script: "git rev-parse HEAD",
                        returnStdout: true
                    ).trim()
                    
                    CI_COMMIT_SHORT_SHA = CI_COMMIT_HASH.take(8)

                    // CI_COMMIT_TAG = sh(
                    //     script: "git describe --tags --exact-match ${CI_COMMIT_HASH}",
                    //     returnStdout: true
                    // ).trim()

                    // IMAGE_VERSION = "${CI_PROJECT_NAME}:${CI_COMMIT_SHORT_SHA}_${CI_COMMIT_TAG}"
                    IMAGE_VERSION = "${CI_PROJECT_NAME}:${CI_COMMIT_SHORT_SHA}"
                    // TRIVY_IMAGE_REPORT = "SCAN_IMAGE_REPORT_${CI_PROJECT_NAME}_${CI_COMMIT_TAG}_${CI_COMMIT_SHORT_SHA}"
                    // CODECLIMATE_REPORT = "TEST_SOURCE_CODE_REPORT_${CI_PROJECT_NAME}_${CI_COMMIT_TAG}_${CI_COMMIT_SHORT_SHA}"
                    TRIVY_IMAGE_REPORT = "SCAN_IMAGE_REPORT_${CI_PROJECT_NAME}_${CI_COMMIT_SHORT_SHA}"
                    CODECLIMATE_REPORT = "TEST_SOURCE_CODE_REPORT_${CI_PROJECT_NAME}_${CI_COMMIT_SHORT_SHA}"
                }
            }
        }
        // stage('Test Source Code') {
        //     steps {
        //         sh(
        //             script: "docker run --tty --rm \
        //                 --env CODECLIMATE_CODE=\"$PWD\" \
        //                 --volume $PWD:/code \
        //                 --volume /var/run/docker.sock:/var/run/docker.sock \
        //                 --volume /tmp/cc:/tmp/cc codeclimate/codeclimate analyze \
        //                 -f html > ${CODECLIMATE_REPORT}.html",
        //             label: "Test Source Code"
        //         )
        //     }
        // }
        stage('Build Docker Image') {
            steps {
                sh(
                    script: "docker build -t ${IMAGE_VERSION} .",
                    label: "Build Docker Image"
                )
            }
        }
        stage('Trivy Scan Image') {
            steps {
                sh(
                    script: "docker run --rm \
                        --volume $PWD:/${CI_PROJECT_NAME} \
                        --volume /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy clean --all",
                    label: "Clean Trivy"
                )
                sh(
                    script: "docker run --rm \
                        --volume $PWD:/${CI_PROJECT_NAME} \
                        --volume /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy fs /${CI_PROJECT_NAME} --severity HIGH,CRITICAL \
                        --format template --template \"@contrib/html.tpl\" \
                        --output /${CI_PROJECT_NAME}/${TRIVY_IMAGE_REPORT}.html",
                    label: "Trivy Scan Image"
                )
                sh(
                    script: "cp \"/$PWD/${TRIVY_IMAGE_REPORT}.html\" \"${WORKSPACE}/${TRIVY_IMAGE_REPORT}.html\" || true",
                    label: "Copy Trivy Report to Workspace"
                )
                archiveArtifacts(
                    artifacts: "${TRIVY_IMAGE_REPORT}.html",
                    allowEmptyArchive: true,
                    fingerprint: true
                )
            }
        }
        stage('Push Image to ECR') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'tranvix0910-tranvix-accessKeys', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh(
                        script: "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_URL}",
                        label: "Login to ECR"
                    )
                    sh(
                        script: "docker tag ${IMAGE_VERSION} ${ECR_URL}/${ECR_REPO}:${CI_COMMIT_SHORT_SHA}",
                        label: "Tag Image"
                    )
                    sh(
                        script: "docker push ${ECR_URL}/${ECR_REPO}:${CI_COMMIT_SHORT_SHA}",
                        label: "Push Image to ECR"
                    )
                    sh(
                        script: "docker logout",
                        label: "Logout from ECR"
                    )
                }   
            }
        }
        stage('Update Task Definition') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'tranvix0910-tranvix-accessKeys', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh(
                        script: "TASK_DEFINITION=\$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --region ${AWS_DEFAULT_REGION})",
                        label: "Get Task Definition"
                    )
                    sh(
                        script: """
                            NEW_TASK_DEFINITION=\$(echo \$TASK_DEFINITION | jq --arg IMAGE "\${IMAGE_VERSION}" '.taskDefinition |
                            .containerDefinitions[0].image = \$IMAGE |
                            del(.taskDefinitionArn) |
                            del(.revision) |
                            del(.status) |
                            del(.requiresAttributes) |
                            del(.compatibilities) |
                            del(.registeredAt) |
                            del(.registeredBy)')
                        """,
                        label: "Update Task Definition"
                    )
                    sh(
                        script: "NEW_TASK_INFO=$(aws ecs register-task-definition --region ${AWS_DEFAULT_REGION} --cli-input-json \"\$NEW_TASK_DEFINITION\")",
                        label: "Register Task Definition"
                    )
                    sh(
                        script: "NEW_REVISION=$(echo \$NEW_TASK_INFO | jq '.taskDefinition.revision')",
                        label: "Get New Revision"
                    )
                    sh(
                        script: "aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${NEW_REVISION} --force-new-deployment",
                        label: "Update Service"
                    )
                }
            }
        }
    }
}