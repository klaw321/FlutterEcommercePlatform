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
                    // Extract the current version line from pubspec.yaml
                    def versionLine = sh(script: "grep ^version: pubspec.yaml", returnStdout: true).trim()
                    echo "Extracted version line: ${versionLine}"
                    
                    // Increment the build number (assuming format: x.y.z+build)
                    def newVersion = versionLine.replaceAll(/(\+\d+)$/, { fullMatch, p1 -> 
                        def buildNumber = p1[1..-1].toInteger()
                        return "+${buildNumber + 1}"
                    })
                    
                    // Update pubspec.yaml with the new version
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
                script {
                    echo 'Installing Android SDK Command Line Tools...'
                    sh '''
                        # Define variables for better readability
                        SDK_ROOT="${ANDROID_SDK_ROOT}"
                        CMDLINE_TOOLS_DIR="${SDK_ROOT}/cmdline-tools"
                        LATEST_DIR="${CMDLINE_TOOLS_DIR}/latest"
                        TEMP_DIR="${CMDLINE_TOOLS_DIR}/temp"

                        # Create necessary directories
                        mkdir -p "${LATEST_DIR}"

                        # Download the Command Line Tools ZIP
                        wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip

                        # Unzip the Command Line Tools into a temporary directory
                        unzip -o cmdline-tools.zip -d "${TEMP_DIR}"

                        # Check if the extracted folder contains 'cmdline-tools'
                        if [ -d "${TEMP_DIR}/cmdline-tools" ]; then
                            # Move all contents from temp/cmdline-tools to latest/
                            mv "${TEMP_DIR}/cmdline-tools/"* "${LATEST_DIR}/"
                        else
                            # If 'cmdline-tools' folder does not exist, move all temp contents to latest/
                            mv "${TEMP_DIR}/"* "${LATEST_DIR}/"
                        fi

                        # Clean up temporary files and directories
                        rm -rf "${TEMP_DIR}"
                        rm cmdline-tools.zip

                        # Ensure sdkmanager is executable
                        chmod +x "${LATEST_DIR}/bin/sdkmanager"
                    '''
                }
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
