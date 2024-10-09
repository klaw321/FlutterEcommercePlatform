pipeline {
    agent any

    environment {
        ANDROID_SDK_ROOT = "${WORKSPACE}/Android/Sdk"
        ANDROID_HOME = "${ANDROID_SDK_ROOT}"
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

        stage('Install Android SDK') {
    steps {
        sh '''
            set -e
            echo "Downloading Android SDK Command-line Tools..."
            wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O cmdline-tools.zip
            
            echo "Extracting cmdline-tools.zip..."
            unzip -o cmdline-tools.zip -d /var/jenkins_home/workspace/flutterapkbuild/Android/Sdk/cmdline-tools/temp
            
            CMDLINE_DIR="/var/jenkins_home/workspace/flutterapkbuild/Android/Sdk/cmdline-tools/temp/cmdline-tools"
            LATEST_DIR="/var/jenkins_home/workspace/flutterapkbuild/Android/Sdk/cmdline-tools/latest"
            
            if [ -d "$CMDLINE_DIR" ]; then
                echo "Extraction successful. Preparing to move cmdline-tools."
                
                if [ -d "$LATEST_DIR" ]; then
                    echo "'latest' directory exists. Removing it for a clean installation."
                    rm -rf "$LATEST_DIR"
                fi
                
                echo "Moving cmdline-tools to 'latest' directory."
                mv "$CMDLINE_DIR" "$LATEST_DIR"
                echo "Android SDK Command-line Tools installed successfully."
            else
                echo "Extraction failed. 'cmdline-tools' directory not found."
                exit 1
            fi
            
            echo "Cleaning up temporary files."
            rm -rf /var/jenkins_home/workspace/flutterapkbuild/Android/Sdk/cmdline-tools/temp
            rm -f cmdline-tools.zip
        '''
    }
}

        stage('Install Android SDK Components') {
            steps {
                script {
                    echo 'Installing Android SDK components...'
                    sh '''
                        # Define variables for better readability
                        SDK_ROOT="${ANDROID_SDK_ROOT}"
                        CMDLINE_TOOLS_BIN="${SDK_ROOT}/cmdline-tools/latest/bin"
                        PLATFORM_TOOLS="${SDK_ROOT}/platform-tools"

                        # Add cmdline-tools/latest/bin and platform-tools to PATH
                        export PATH="${CMDLINE_TOOLS_BIN}:${PLATFORM_TOOLS}:${PATH}"

                        # Update sdkmanager to ensure it's the latest version
                        sdkmanager --update

                        # Accept all Android SDK licenses
                        yes | sdkmanager --licenses

                        # Install essential SDK components
                        sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

                        # (Optional) Install additional SDK components as needed
                        # sdkmanager "extras;android;m2repository" "extras;google;m2repository"
                    '''
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
