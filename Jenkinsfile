pipeline {
    agent any

    environment {
        FLUTTER_VERSION = '3.24.3'  // Set your Flutter version
        ANDROID_HOME = "${WORKSPACE}/Android/Sdk"  // Define Android SDK home directory
        ANDROID_SDK_ROOT = "${WORKSPACE}/Android/Sdk" // Ensure ANDROID_SDK_ROOT is set
        FLUTTER_HOME = "${WORKSPACE}/flutter"  // Define Flutter home directory
        PATH = "${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${env.PATH}"  // Add Android SDK and Flutter to PATH
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Increment Build Number') {
            steps {
                script {
                    def versionLine = sh(script: "grep ^version: pubspec.yaml", returnStdout: true).trim()
                    echo "Extracted version line: ${versionLine}"
                    def newVersion = versionLine.replace('+1', '+2')
                    sh "sed -i 's/${versionLine}/${newVersion}/' pubspec.yaml"
                    echo "Updated version to ${newVersion}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        sudo apt-get update
                        sudo apt-get install -y curl unzip wget git xz-utils clang cmake ninja-build pkg-config
                    '''
                }
            }
        }

        stage('Install Git Safe Directory') {
            steps {
                script {
                    sh "git config --global --add safe.directory ${WORKSPACE}/flutter"  // Mark the flutter directory as safe
                }
            }
        }

        stage('Install Android SDK') {
            steps {
                script {
                    echo 'Installing Android SDK Command Line Tools...'
                    sh '''
                        mkdir -p "${ANDROID_HOME}/cmdline-tools/latest"
                        wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip
                        unzip -o cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools/temp"
                        mv "${ANDROID_HOME}/cmdline-tools/temp/cmdline-tools/"* "${ANDROID_HOME}/cmdline-tools/latest/"
                        rm -rf "${ANDROID_HOME}/cmdline-tools/temp"
                        rm cmdline-tools.zip
                    '''
                }
            }
        }

        stage('Install Flutter') {
            steps {
                script {
                    echo "Installing Flutter ${FLUTTER_VERSION}..."
                    sh '''
                        wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
                        tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C ${WORKSPACE}
                    '''
                }
            }
        }

        stage('Setup Flutter') {
            steps {
                script {
                    echo "Setting up Flutter..."
                    sh '''
                        flutter config --android-sdk ${ANDROID_HOME}
                        flutter config --enable-web
                    '''
                }
            }
        }

        stage('Install Flutter Dependencies') {
            steps {
                script {
                    sh 'flutter pub get'
                }
            }
        }

        stage('Build APK') {
            steps {
                script {
                    echo 'Building APK...'
                    sh 'flutter build apk --release'
                }
            }
        }

        stage('Upload APK to Firebase') {
            steps {
                script {
                    echo 'Uploading APK to Firebase...'
                    withCredentials([file(credentialsId: 'firebase-service-credentials', variable: 'FIREBASE_CREDENTIALS')]) {
                        sh '''
                            export FIREBASE_TOKEN=$(cat ${FIREBASE_CREDENTIALS})
                            firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
                                --app $FIREBASE_APP_ID \
                                --token $FIREBASE_TOKEN \
                                --groups testers
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'rm -f service_credentials.json'
            script {
                if (currentBuild.currentResult == 'FAILURE') {
                    echo 'Build failed.'
                }
            }
        }
    }
}
