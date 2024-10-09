pipeline {
    agent any

    environment {
        ANDROID_SDK_ROOT = "${WORKSPACE}/Android/Sdk"
        FLUTTER_VERSION = '3.24.3'  // Set your Flutter version
        PATH = "${WORKSPACE}/flutter/bin:${env.PATH}"  // Add Flutter to PATH for all stages
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
                        sudo apt-get install -y curl unzip wget git xz-utils  # Add xz-utils here
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
                        # Create the cmdline-tools directory and the latest folder
                        mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools/latest"

                        # Download the Command Line Tools
                        wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip

                        # Unzip the Command Line Tools into a temporary directory
                        unzip -o cmdline-tools.zip -d "${ANDROID_SDK_ROOT}/cmdline-tools/temp"

                        # Move the extracted content to the latest directory
                        mv "${ANDROID_SDK_ROOT}/cmdline-tools/temp/cmdline-tools/"* "${ANDROID_SDK_ROOT}/cmdline-tools/latest/"

                        # Clean up temporary files
                        rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/temp"
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
                        tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
                    '''
                }
            }
        }
   stage('Setup Flutter') {
            steps {
                script {
                    echo 'Setting up Flutter...'
                    sh '''
                        # Ensure Flutter is in PATH
                        export PATH="${WORKSPACE}/flutter/bin:${PATH}"

                        # Run flutter doctor to perform initial setup
                        flutter doctor

                        # Configure Flutter to use the Android SDK
                        flutter config --android-sdk ${ANDROID_SDK_ROOT}

                        # Optionally, enable web support if needed
                        flutter config --enable-web
                    '''
                }
            }
        }

        stage('Install Flutter Dependencies') {
            steps {
                script {
                    echo 'Installing Flutter dependencies...'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Build APK') {
            steps {
                script {
                    echo 'Building APK...'
                    sh '''
                        # Ensure Flutter and Android SDK tools are in PATH
                        export PATH="${WORKSPACE}/flutter/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

                        # Build the APK in release mode
                        flutter build apk --release
                    '''
                }
            }
        }

        stage('Upload APK to Firebase') {
            steps {
                script {
                    echo 'Uploading APK to Firebase...'
                    withCredentials([file(credentialsId: 'firebase-service-credentials', variable: 'FIREBASE_CREDENTIALS')]) {
                        sh '''
                            # Export Firebase token from the credentials file
                            export FIREBASE_TOKEN=$(cat ${FIREBASE_CREDENTIALS})

                            # Upload the APK to Firebase App Distribution
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
