pipeline {
    agent any

    environment {
        // Define where Flutter will be installed
        FLUTTER_HOME = '/var/jenkins_home/flutter'
        // Update PATH to include Flutter's bin directory
        PATH = "${env.PATH}:${env.FLUTTER_HOME}/bin"
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the repository
                checkout scm
            }
        }

        stage('Increment Build Number') {
            steps {
                script {
                    // Extract current version and build number from pubspec.yaml
                    def currentVersion = sh(
                        script: "grep 'version:' pubspec.yaml | cut -d ' ' -f2 | cut -d '+' -f1",
                        returnStdout: true
                    ).trim()
                    def currentBuild = sh(
                        script: "grep 'version:' pubspec.yaml | cut -d '+' -f2",
                        returnStdout: true
                    ).trim()
                    def newBuild = currentBuild.toInteger() + 1

                    // Update pubspec.yaml with the new build number
                    sh "sed -i 's/version: .*/version: ${currentVersion}+${newBuild}/' pubspec.yaml"
                    echo "Updated version to ${currentVersion}+${newBuild}"
                }
            }
        }

        stage('Install Flutter') {
            steps {
                script {
                    // Check if Flutter is already installed
                    if (!fileExists(env.FLUTTER_HOME)) {
                        echo "Flutter is not installed. Installing Flutter..."
                        sh "git clone https://github.com/flutter/flutter.git -b stable ${env.FLUTTER_HOME}"
                        echo "Flutter installed."
                    } else {
                        echo "Flutter is already installed."
                    }

                    // Initialize Flutter and download dependencies
                    sh "${env.FLUTTER_HOME}/bin/flutter doctor -v"
                }
            }
        }

        stage('Verify Flutter Installation') {
            steps {
                script {
                    // Verify that the flutter command is accessible
                    sh "flutter --version"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                // Get Flutter dependencies
                sh "flutter pub get"
            }
        }

        stage('Build APK') {
            steps {
                // Build the APK in release mode
                sh "flutter build apk --release"
            }
        }

        stage('Archive APK') {
            steps {
                // Archive the generated APK
                archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
            }
        }

        stage('Deploy to Firebase') {
            steps {
                script {
                    // Retrieve SERVICE_CREDENTIALS from Jenkins credentials
                    withCredentials([file(credentialsId: 'SERVICE_CREDENTIALS_ID', variable: 'SERVICE_CREDENTIALS_FILE')]) {
                        // Save service credentials to a file
                        sh "cp ${SERVICE_CREDENTIALS_FILE} service_credentials.json"
                    }

                    // Install Firebase CLI if not already installed
                    sh """
                    if ! command -v firebase &> /dev/null; then
                        echo "Firebase CLI not found. Installing Firebase CLI..."
                        curl -sL https://firebase.tools | bash
                        echo "Firebase CLI installed."
                    else
                        echo "Firebase CLI is already installed."
                    fi
                    """

                    // Authenticate with Firebase using the service account
                    withEnv(["GOOGLE_APPLICATION_CREDENTIALS=service_credentials.json"]) {
                        // Deploy the APK to Firebase App Distribution
                        sh """
                        firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
                            --app YOUR_FIREBASE_APP_ID \
                            --groups "kushalpokharel234@gmail.com" \
                            --token ${env.FIREBASE_TOKEN}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            // Optional: Add cleanup steps if necessary
            sh 'rm -f service_credentials.json'
        }
    }
}
