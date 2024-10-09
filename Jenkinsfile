stage('Setup Flutter') {
    steps {
        script {
            echo "Setting up Flutter..."
            sh '''
                flutter config --android-sdk $ANDROID_HOME
                flutter config --enable-web
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

stage('Install Android SDK Components') {
    steps {
        script {
            sh '''
                sdkmanager --install "platform-tools" "platforms;android-30" "build-tools;30.0.3"
            '''
        }
    }
}

stage('Install Flutter Dependencies') {
    steps {
        script {
            sh '''
                export ANDROID_HOME=$ANDROID_HOME
                export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
                flutter pub get
            '''
        }
    }
}

stage('Build APK') {
    steps {
        script {
            echo 'Building APK...'
            sh '''
                export ANDROID_HOME=$ANDROID_HOME
                export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
                flutter build apk --release
            '''
        }
    }
}
