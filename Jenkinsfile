pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('dockerhub')
        // Génère un tag propre selon la branche (ex: 1.0.5 sur main, ou feature-couleur-1 sur une branche)
        VERSION = "${env.BRANCH_NAME == 'main' ? '1.0.' + env.BUILD_NUMBER : env.BRANCH_NAME.replaceAll('[^a-zA-Z0-9.-]', '-') + '-' + env.BUILD_NUMBER}"
        IMAGE_NAME = "restaurant"
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
                    env.FULL_IMAGE = "cabrelo/${env.IMAGE_NAME}:${env.VERSION}"
                    env.LATEST_IMAGE = "cabrelo/${env.IMAGE_NAME}:latest"

                    sh "docker build -t ${env.FULL_IMAGE} -t ${env.LATEST_IMAGE} ."

                    // Tests automatisés (identiques au TP précédent)
                    def networkName = sh(script: "docker inspect jenkins-server -f '{{range \$k, \$v := .NetworkSettings.Networks}}{{\$k}}{{end}}'", returnStdout: true).trim()
                    def containerName = "${env.IMAGE_NAME}-test"

                    sh """
                        docker rm -f ${containerName} || true
                        docker run -d --name ${containerName} --network ${networkName} ${env.FULL_IMAGE}
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
            when { 
                branch 'main' // Publication uniquement sur la branche main !
            }
            steps {
                script {
                    sh '''
                        echo "$DOCKERHUB_CREDS_PSW" | docker login -u cabrelo --password-stdin
                        docker push "$FULL_IMAGE"
                        docker push "$LATEST_IMAGE"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f restaurant-test || true"
        }
        success {
            echo "Pipeline réussi sur la branche ${env.BRANCH_NAME} !"
        }
        failure {
            echo "Le pipeline a échoué sur ${env.BRANCH_NAME}."
        }
    }
}