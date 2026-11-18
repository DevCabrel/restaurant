pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_NAME', defaultValue: 'restaurant', description: 'Nom de l image Docker')
        string(name: 'IMAGE_TAG', defaultValue: '1.0', description: 'Version de base')
        string(name: 'DOCKERHUB_ID', defaultValue: 'votre_pseudo_dockerhub', description: 'Votre ID Docker Hub')
    }

    environment {
        // Récupération sécurisée du token Docker Hub stocké dans les credentials Jenkins (ID: dockerhub)
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
                    def testName = "${env.IMAGE_NAME}-test"
                    def image = "${env.DOCKERHUB_ID}/${env.IMAGE_NAME}"
                    // Génération d'un tag unique traçable (version + build + commit short sha)
                    env.UNIQUE_TAG = "${env.IMAGE_TAG}.${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"

                    // 1. Création du Dockerfile à la volée
                    writeFile file: 'Dockerfile', text: '''FROM nginx:1.27-alpine
COPY . /usr/share/nginx/html/
EXPOSE 80'''
                    writeFile file: '.dockerignore', text: '.git\nDockerfile\n'

                    // 2. Build de l'image
                    sh "docker build --label org.opencontainers.image.revision=${env.GIT_COMMIT} -t ${image}:${env.UNIQUE_TAG} -t ${env.IMAGE_NAME}:${env.IMAGE_TAG} ."

                    // 3. Lancement du conteneur de test sur le réseau de Jenkins
                    def jenkinsNet = sh(script: "docker inspect jenkins-server -f '{{range \$k, \$v := .NetworkSettings.Networks}}{{\$k}}{{end}}'", returnStdout: true).trim()
                    sh "docker rm -f ${testName} 2>/dev/null || true"
                    sh "docker run -d --name ${testName} --network ${jenkinsNet} ${image}:${env.UNIQUE_TAG}"

                    // 4. Attente de la disponibilité de nginx (10s max)
                    sh "for i in \$(seq 1 10); do curl -sf http://${testName}/ >/dev/null && break; sleep 1; done"

                    // 5. Tests d'acceptance et vérifications statiques
                    sh """
                    curl -sf http://${testName}/ | grep -qi "<title>Restaurant" && echo "✅ titre OK"
                    curl -sf -o /dev/null -w "%{http_code} %{content_type}\\n" http://${testName}/1.jpg
                    test "\$(curl -s -o /dev/null -w '%{http_code}' http://${testName}/nexiste-pas)" = "404" && echo "✅ 404 OK"
                    """
                }
            }
        }

        stage('Publish') {
            steps {
                script {
                    def image = "${env.DOCKERHUB_ID}/${env.IMAGE_NAME}"

                    // Connexion sécurisée à Docker Hub via les credentials injectés
                    sh "echo '${DOCKERHUB_CREDS_PSW}' | docker login -u '${DOCKERHUB_CREDS_USR}' --password-stdin"

                    // Push de l'image unique
                    sh "docker push ${image}:${env.UNIQUE_TAG}"

                    // Tag et push de la version latest si les tests sont passés
                    sh "docker tag ${image}:${env.UNIQUE_TAG} ${image}:latest"
                    sh "docker push ${image}:latest"

                    sh "docker logout"
                }
            }
        }
    }

    post {
        always {
            // Nettoyage garanti du conteneur de test, qu'il y ait succès ou échec
            script {
                sh "docker rm -f ${env.IMAGE_NAME}-test 2>/dev/null || true"
            }
        }
        success {
            echo "Pipeline exécuté avec succès ! Image publiée : ${env.DOCKERHUB_ID}/${env.IMAGE_NAME}:${env.UNIQUE_TAG}"
        }
        failure {
            echo "Le pipeline a échoué. Aucune image validée n'a été publiée."
        }
    }
}