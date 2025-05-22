pipeline {
    agent {
        label 'Development Server'
    }
    environment {
        CI_COMMIT_SHORT_SHA = ""
        CI_COMMIT_TAG = ""
        CI_PROJECT_NAME = ""
        IMAGE_VERSION = ""
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
                archiveArtifacts(
                    artifacts: "${TRIVY_IMAGE_REPORT}.html",
                    allowEmptyArchive: true,
                    fingerprint: true
                )
            }
        }
    }
}