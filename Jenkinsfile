pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Increment Build Number') {
            steps {
                script {
                    // Incrementing build number in pubspec.yaml
                    def currentVersion = sh(script: "grep 'version:' pubspec.yaml | cut -d ' ' -f2 | cut -d '+' -f1", returnStdout: true).trim()
                    def currentBuild = sh(script: "grep 'version:' pubspec.yaml | cut -d '+' -f2", returnStdout: true).trim()
                    def newBuild = currentBuild.toInteger() + 1

                    sh "sed -i 's/version: .*/version: ${currentVersion}+${newBuild}/' pubspec.yaml"
                    echo "Updated version to ${currentVersion}+${newBuild}"
                }
            }
        }

        stage('Install Flutter') {
            steps {
                script {
                    // Ensure Flutter is installed
                    sh "flutter pub get"
                }
            }
        }

        stage('Build APK') {
            steps {
                script {
                    // Build the APK
                    sh "flutter build apk --release"
                }
            }
        }

        stage('Archive APK') {
            steps {
                // Ensure artifacts are archived within a node block
                script {
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
                }
            }
        }

        stage('Deploy to Firebase') {
            steps {
                script {
                    // Ensure SERVICE_CREDENTIALS is set correctly
                    def serviceCredentials = "${env.SERVICE_CREDENTIALS}"
                    if (!serviceCredentials) {
                        error "SERVICE_CREDENTIALS is not set"
                    }

                    // Upload APK to Firebase
                    sh """
                    curl -X POST -H "Authorization: Bearer \${{ secrets.FIREBASE_APP_ID }}" \
                        -F "file=@build/app/outputs/flutter-apk/app-release.apk" \
                        -F "testers=kushalpokharel234@gmail.com" \
                        https://firebaseappdistribution.googleapis.com/v1/projects/YOUR_PROJECT_ID/apps/YOUR_APP_ID/releases:upload
                    """
                }
            }
        }
    }

    post {
        always {
            // Optional: Clean up actions, notifications, etc.
            echo 'Cleaning up...'
        }
    }
}

