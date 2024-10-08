pipeline {
    agent any 

    environment {
        FLUTTER_VERSION = '3.24.3'
        JAVA_VERSION = '17' // Specify the required Java version
        FIREBASE_APP_ID = credentials('FIREBASE_APP_ID') // Jenkins credential for Firebase App ID
        SERVICE_CREDENTIALS = credentials('SERVICE_CREDENTIALS') // Jenkins credential for Firebase service account
        TESTERS = 'kushalpokharel234@gmail.com' // Adjust as needed
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/klaw321/FlutterEcommercePlatform.git', branch: 'main'
            }
        }

        stage('Set up JDK') {
            steps {
                script {
                    sh "sudo apt-get update"
                    sh "sudo apt-get install openjdk-${JAVA_VERSION}-jdk -y"
                    sh "java -version"
                }
            }
        }

        stage('Increment Build Number') {
            steps {
                script {
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
                sh "wget https://storage.googleapis.com/download/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
                sh "tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
                sh "export PATH=\$PATH:\$PWD/flutter/bin"
                sh "flutter doctor"
            }
        }

        stage('Install Dependencies') {
            steps {
                sh "flutter pub get"
            }
        }

        stage('Build APK') {
            steps {
                sh "flutter build apk --release"
            }
        }

        stage('Upload APK to Firebase Distribution') {
            steps {
                script {
                    // Creating the temporary service account file
                    def serviceAccountFile = "${WORKSPACE}/service_account.json"
                    writeFile file: serviceAccountFile, text: "${SERVICE_CREDENTIALS}"

                    sh """
                    curl -X POST -H "Authorization: Bearer \$(gcloud auth print-access-token)" \
                    -F "file=@build/app/outputs/flutter-apk/app-release.apk" \
                    -F "appId=${FIREBASE_APP_ID}" \
                    -F "testers=${TESTERS}" \
                    "https://firebaseappdistribution.googleapis.com/v1alpha/apps/${FIREBASE_APP_ID}/releases"
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', allowEmptyArchive: true
        }
        success {
            echo 'Successfully built and uploaded the APK to Firebase Distribution.'
        }
        failure {
            echo 'There was an error in the pipeline.'
        }
    }
}
