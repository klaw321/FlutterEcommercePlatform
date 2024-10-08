pipeline {
    agent any

    environment {
        ANDROID_HOME = "${env.WORKSPACE}/Android/Sdk"
        FLUTTER_HOME = "${env.WORKSPACE}/flutter"
        PATH = "${env.PATH}:${env.ANDROID_HOME}/cmdline-tools/latest/bin:${env.ANDROID_HOME}/platform-tools:${env.FLUTTER_HOME}/bin"
        CHROME_EXECUTABLE = "/usr/bin/google-chrome" // Adjust if necessary
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Increment Build Number') {
            steps {
                script {
                    // Extract the version line that starts with 'version:'
                    def versionLine = sh(script: "grep '^version:' pubspec.yaml", returnStdout: true).trim()
                    
                    // Debugging: Print the extracted version line
                    echo "Extracted version line: ${versionLine}"

                    // Split the version line to get version and build number
                    def versionParts = versionLine.split(':')[1].trim().split('\\+')
                    
                    if (versionParts.length != 2) {
                        error "Invalid version format in pubspec.yaml. Expected format: version: x.y.z+buildNumber"
                    }
                    
                    def version = versionParts[0]
                    def buildNumber = versionParts[1].toInteger() + 1
                    
                    // Update the pubspec.yaml with the new build number
                    sh """
                        sed -i 's/version: ${version}+${buildNumber - 1}/version: ${version}+${buildNumber}/' pubspec.yaml
                    """
                    
                    echo "Updated version to ${version}+${buildNumber}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Update package list and install required packages
                    sh '''
                        sudo apt-get update
                        sudo apt-get install -y curl unzip wget git
                    '''
                }
            }
        }

        stage('Install Android SDK') {
            steps {
                script {
                    // Check if Android SDK is already installed
                    if (!fileExists("${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager")) {
                        echo "Installing Android SDK Command Line Tools..."
                        sh '''
                            mkdir -p ${ANDROID_HOME}/cmdline-tools
                            wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip
                            unzip cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools
                            mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest
                            rm cmdline-tools.zip
                        '''
                    } else {
                        echo "Android SDK Command Line Tools already installed."
                    }

                    // Accept licenses and install required SDK components
                    sh '''
                        yes | sdkmanager --licenses
                        sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0" "ndk;23.1.7779620" "extras;google;google_play_services"
                    '''
                }
            }
        }

        stage('Install Other Dependencies') {
            steps {
                script {
                    // Install Clang, CMake, Ninja, pkg-config, and Chrome
                    sh '''
                        sudo apt-get update
                        sudo apt-get install -y clang cmake ninja-build pkg-config

                        # Install Google Chrome if not installed
                        if ! command -v google-chrome &> /dev/null
                        then
                            echo "Installing Google Chrome..."
                            wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
                            sudo apt install -y ./google-chrome-stable_current_amd64.deb
                            rm google-chrome-stable_current_amd64.deb
                        else
                            echo "Google Chrome already installed."
                        fi
                    '''
                }
            }
        }

        stage('Install Flutter') {
            steps {
                script {
                    if (!fileExists("${FLUTTER_HOME}/bin/flutter")) {
                        echo "Installing Flutter..."
                        sh '''
                            git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}
                        '''
                    } else {
                        echo "Flutter is already installed."
                    }
                    sh "${FLUTTER_HOME}/bin/flutter doctor -v"
                }
            }
        }

        stage('Verify Flutter Installation') {
            steps {
                sh "${FLUTTER_HOME}/bin/flutter --version"
            }
        }

        stage('Configure Flutter for Android') {
            steps {
                script {
                    sh '''
                        flutter config --android-sdk ${ANDROID_HOME}
                        flutter doctor -v
                    '''
                }
            }
        }

        stage('Install Flutter Dependencies') {
            steps {
                sh "${FLUTTER_HOME}/bin/flutter pub get"
            }
        }

        stage('Build APK') {
            steps {
                sh "${FLUTTER_HOME}/bin/flutter build apk --release"
            }
        }

        stage('Archive APK') {
            steps {
                archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
            }
        }

        stage('Deploy to Firebase') {
            steps {
                // Add your Firebase deployment steps here
                echo "Deploying to Firebase..."
                // Example:
                // sh 'firebase deploy --only hosting'
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'rm -f service_credentials.json'
        }
        failure {
            echo 'Build failed.'
        }
    }
}
