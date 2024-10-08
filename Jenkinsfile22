pipeline {
    agent {
        docker {
            image 'your-docker-image:latest' // Specify your Docker image
        }
    }
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/klaw321/FlutterEcommercePlatform.git'
            }
        }
        stage('Build APK') {
            steps {
                sh 'flutter pub get'
                sh 'flutter build apk --release'
            }
        }
        stage('Upload to Firebase') {
            steps {
                // Assuming you have the Firebase CLI set up in your Docker image
                sh 'firebase deploy --only hosting' // Adjust this based on your deployment needs
            }
        }
    }
}
