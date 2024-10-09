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
    }
}
