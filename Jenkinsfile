pipeline {
    agent {
        label 'Development Server'
    }
    stages {
        stage('Info') {
            steps {
                sh(
                    script: """
                        whoami;
                        pwd;
                        ls -la;
                    """,
                    label: "First Stage"    
                )
            }
        }
    }
}