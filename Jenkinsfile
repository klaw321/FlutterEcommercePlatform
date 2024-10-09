pipeline {
    agent any

    environment {
       ANDROID_HOME = "${env.WORKSPACE}/android-sdk"
        PATH = "$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
        ANDROID_SDK_ROOT = "$ANDROID_HOME"
        FLUTTER_VERSION = '3.24.3'  // Set your desired Flutter version
        PATH = "${WORKSPACE}/flutter/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${env.PATH}"  // Add Flutter and Android SDK to PATH for all stages
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
                        sudo apt-get install -y curl unzip wget git xz-utils
                    '''
                }
            }
        }

        stage('Install Git Safe Directory') {
            steps {
                script {
                    // Mark the flutter directory as safe for Git operations
                    sh "git config --global --add safe.directory ${WORKSPACE}/flutter"
                }
            }
        }

        stages {
        stage('Install Android SDK') {
            steps {
                script {
                    // Define Android SDK URL and the installation directory
                    def androidSdkUrl = 'https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip'
                    def sdkDir = "${env.WORKSPACE}/android-sdk"
                    def toolsDir = "${sdkDir}/cmdline-tools/latest"
                    
                    // Create SDK directory
                    sh "mkdir -p ${sdkDir}/cmdline-tools"

                    // Download the Android SDK command-line tools
                    sh "curl -o commandlinetools.zip ${androidSdkUrl}"

                    // Unzip and set up the SDK
                    sh "unzip commandlinetools.zip -d ${sdkDir}/cmdline-tools"

                    // Move the unzipped files to the 'latest' folder
                    sh "mv ${sdkDir}/cmdline-tools/cmdline-tools ${toolsDir}"

                    // Install required SDK packages
                    sh """
                        yes | sdkmanager --sdk_root=${sdkDir} --licenses
                        yes | sdkmanager --sdk_root=${sdkDir} "platform-tools" "platforms;android-33" "build-tools;33.0.0"
                    """
                }
            }
        }

        stage('Verify SDK Installation') {
            steps {
                // Check SDK installation and print Android SDK tools version
                sh 'sdkmanager --version'
                sh 'adb --version'
                sh 'sdkmanager --list'
            }
        }
    }

        stage('Install Flutter') {
            steps {
                script {
                    echo "Installing Flutter ${FLUTTER_VERSION}..."
                    sh '''
                        # Download Flutter SDK
                        wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -O flutter_linux.tar.xz

                        # Extract Flutter SDK to the workspace
                        tar -xf flutter_linux.tar.xz -C ${WORKSPACE}

                        # Remove the downloaded tarball to save space
                        rm flutter_linux.tar.xz
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
