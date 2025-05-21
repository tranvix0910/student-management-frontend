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

                    CI_COMMIT_TAG = sh(
                        script: "git describe --tags --exact-match ${CI_COMMIT_HASH}",
                        returnStdout: true
                    ).trim()

                    IMAGE_VERSION = "${CI_PROJECT_NAME}:${CI_COMMIT_SHORT_SHA}_${CI_COMMIT_TAG}"
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh(
                    script: "pwd"
                )
                sh(
                    script: "docker build -t ${IMAGE_VERSION} -f Dockerfile .",
                    label: "Build Docker Image"
                )
            }
        }
    }
}