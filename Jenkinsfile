pipeline {
    agent any
    tools{
        maven 'maven3'
    }
    
    environment{
        SCANNER_HOME=tool 'sonar-scanner'
        DOCKER_SERVER = '44.204.161.43'  // Replace with the IP of your remote server
        DOCKER_USER = 'ubuntu'        // Replace with the user of your remote server
        IMAGE_NAME = 'full-fledge-pipeline'     // Replace with your image name
        DOCKER_REPO = 'saurabhchavan216'   // Replace with your Docker repository
        DOCKERFILE_PATH = '/var/lib/jenkins/workspace/full-fledge-pipeline/docker/Dockerfile'
        WAR_FILE_PATH = '/var/lib/jenkins/workspace/full-fledge-pipeline/target/petclinic.war'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()  // This will clean the workspace
            }
        }
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/chavansaurabh216/Petclinic.git'
            }
        }
        stage('Compile') {
            steps {
                sh 'mvn clean compile -DskipTests=true'
            }
        }
        stage('Test-Cases') {
            steps {
                sh 'mvn test'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Petclinic \
                    -Dsonar.java.binaries=. \
                    -Dsonar.projectKey=Petclinic '''
                }
            }
        }
        stage('Build Package') {
            steps {
                sh 'mvn package -DskipTests=true'
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan target/ --format ALL', odcInstallation: 'owasp'
            }
        }
        stage('OWASP Dependency Check Report') {
            steps {
                // Verify that the HTML report is accessible
                sh 'ls -l target'
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'target',
                    reportFiles: 'dependency-check-report.html',
                    reportName: 'OWASP Dependency Check Report'
                ])
            }
        }
        stage('Push Artifact to Nexus') {
            steps {
                configFileProvider([configFile(fileId: '34219ca2-bbc0-4c1b-bce7-7631b53c923a', variable: 'MAVEN_SETTINGS')]) {
                sh '''
                echo Using Maven settings file: ${MAVEN_SETTINGS}
                mvn -s ${MAVEN_SETTINGS} deploy
                '''
                }
            }
        }
        stage('Copy Dockerfile to Remote Server') {
            steps {
                sshagent(['remote-docker-server']) {  // Use your SSH credentials ID
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@44.204.161.43 'mkdir -p /tmp/docker-build'
                    scp -o StrictHostKeyChecking=no ${DOCKERFILE_PATH} ubuntu@44.204.161.43:/tmp/docker-build/
                    scp -o StrictHostKeyChecking=no ${WAR_FILE_PATH} ubuntu@44.204.161.43:/tmp/docker-build/
                    """
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sshagent(credentials: ['remote-docker-server']) { // Replace with your credentials ID
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@44.204.161.43 \\
                        'cd /tmp/docker-build/ && docker build -t $DOCKER_REPO/$IMAGE_NAME:${BUILD_ID} -f /tmp/docker-build/Dockerfile .'
                    """
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                sshagent(credentials: ['remote-docker-server']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@44.204.161.43 \\
                        'docker push $DOCKER_REPO/$IMAGE_NAME:${BUILD_ID}'
                    """
                }
            }
        }
        stage('Deploy the application as Docker Container') {
            steps {
                sshagent(credentials: ['remote-docker-server']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@44.204.161.43 \\
                        'docker run -d --name PetClinic -p 8082:8082 $DOCKER_REPO/$IMAGE_NAME:${BUILD_ID}'
                    """
                }
            }
        }
    }
}