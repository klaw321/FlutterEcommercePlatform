pipeline {
    agent any
    environment {
        FLUTTER_VERSION = '3.24.3' // Update as needed
        ANDROID_HOME = "${WORKSPACE}/Android/Sdk"
        ANDROID_SDK_ROOT = "${WORKSPACE}/Android/Sdk"
        FLUTTER_HOME = "${WORKSPACE}/flutter"
        PATH = "${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${env.PATH}"
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
                    retry(3) { // Retry up to 3 times
                        try {
                            sh '''
                                #!/bin/bash
                                # Wait for any existing apt processes to finish
                                while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
                                    echo "Waiting for other apt-get processes to finish..."
                                    sleep 5
                                done
                                sudo apt-get update
                                sudo apt-get install -y curl unzip wget git xz-utils clang cmake ninja-build pkg-config libgtk-3-dev
                            '''
                        } catch (Exception e) {
                            echo "Failed to install dependencies. Retrying..."
                            sleep 10
                            throw e // Trigger retry
                        }
                    }
                }
            }
        }
        stage('Install Git Safe Directory') {
            steps {
                script {
                    sh "git config --global --add safe.directory ${WORKSPACE}/flutter"
                }
            }
        }
        stage('Install Android SDK') {
            steps {
                script {
                    echo 'Installing Android SDK Command Line Tools...'
                    sh '''
                        mkdir -p "${ANDROID_HOME}/cmdline-tools/temp"
                        wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip
                        unzip -o cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools/temp"
                        mkdir -p "${ANDROID_HOME}/cmdline-tools/latest"
                        mv "${ANDROID_HOME}/cmdline-tools/temp/cmdline-tools/"* "${ANDROID_HOME}/cmdline-tools/latest/"
                        rm -rf "${ANDROID_HOME}/cmdline-tools/temp"
                        rm cmdline-tools.zip
                    '''
                }
            }
        }
        stage('Install Android SDK Components') {
            steps {
                script {
                    sh '''
                        export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:$PATH
                        sdkmanager --update
                        yes | sdkmanager --licenses
                        sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0" "platforms;android-33" "system-images;android-33;google_apis;x86_64"
                    '''
                }
            }
        }
        stage('Verify Android SDK Installation') {
            steps {
                script {
                    sh '''
                        ls -la ${ANDROID_HOME}/cmdline-tools/latest/bin
                        ls -la ${ANDROID_HOME}/platform-tools
                        ls -la ${ANDROID_HOME}/build-tools/33.0.0
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
                        rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
                    '''
                }
            }
        }
        stage('Cache Flutter') { // Optional caching stage
            steps {
                cache(path: "${FLUTTER_HOME}", key: "flutter-${FLUTTER_VERSION}") {
                    // Flutter installation steps are already done in the previous stage
                    echo "Flutter cached."
                }
            }
        }
        stage('Setup Flutter') {
            steps {
                script {
                    echo "Setting up Flutter..."
                    sh '''
                        flutter config --android-sdk $ANDROID_HOME
                        flutter config --enable-web
                        flutter doctor -v
                    '''
                }
            }
        }
        stage('Install Flutter Dependencies') {
            steps {
                script {
                    sh '''
                        flutter pub get
                    '''
                }
            }
        }
        stage('Check Flutter Doctor') {
            steps {
                script {
                    sh '''
                        flutter doctor -v
                    '''
                }
            }
        }
        stage('Build APK') {
            steps {
                script {
                    echo 'Building APK...'
                    sh '''
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
