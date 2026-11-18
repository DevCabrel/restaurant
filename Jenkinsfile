pipeline {
    agent any

    parameters {
        string(name: 'DOCKERHUB_ID', defaultValue: 'cabrelo', description: 'Identifiant Docker Hub')
        string(name: 'IMAGE_NAME', defaultValue: 'restaurant', description: 'Nom de l image Docker')
        string(name: 'IMAGE_TAG', defaultValue: '1.0', description: 'Version de base de l image')
    }

    environment {
        DOCKERHUB_CREDS = credentials('dockerhub')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    def shortCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    def fullCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.VERSIONED_IMAGE = "${params.DOCKERHUB_ID}/${params.IMAGE_NAME}:${params.IMAGE_TAG}.${env.BUILD_NUMBER}-${shortCommit}"
                    env.LATEST_IMAGE = "${params.DOCKERHUB_ID}/${params.IMAGE_NAME}:latest"

                    sh """
                        docker build --label org.opencontainers.image.revision=${fullCommit} -t ${env.VERSIONED_IMAGE} -t ${env.LATEST_IMAGE} -t ${params.IMAGE_NAME}:${params.IMAGE_TAG} .
                    """

                    def networkName = sh(script: "docker inspect jenkins-server -f '{{range \$k, \$v := .NetworkSettings.Networks}}{{\$k}}{{end}}'", returnStdout: true).trim()
                    def containerName = "${params.IMAGE_NAME}-test"

                    sh """
                        docker rm -f ${containerName} || true
                        docker run -d --name ${containerName} --network ${networkName} ${env.VERSIONED_IMAGE}
                        for i in \$(seq 1 10); do
                            if curl -sf http://${containerName}/ > /dev/null; then break; fi
                            sleep 1
                        done
                        curl -sf http://${containerName}/ | grep -qi "<title>Restaurant" && echo "✅ titre OK"
                        curl -sf -o /dev/null -w "%{http_code} %{content_type}\\n" http://${containerName}/1.jpg
                        test "\$(curl -s -o /dev/null -w "%{http_code}" http://${containerName}/nexiste-pas)" = "404" && echo "✅ 404 OK"
                    """
                }
            }
        }

        stage('Publish') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDS_PSW" | docker login -u "$DOCKERHUB_CREDS_USR" --password-stdin
                    docker push "$VERSIONED_IMAGE"
                    docker push "$LATEST_IMAGE"
                '''
            }
        }
    }

    post {
        always {
            sh "docker rm -f ${params.IMAGE_NAME}-test || true"
        }
        success {
            echo "Pipeline réussi ! Image publiée : ${env.VERSIONED_IMAGE}"
        }
        failure {
            echo "Le pipeline a échoué. Aucune image validée n'a été publiée."
        }
    }
}