pipeline{
 agent any

 environment {
  PATH = "$PATH:/snap/bin"
 }

 stages {
  stage('Checkout code') {
     steps {
        git branch: 'main', url: 'https://github.com/anicetkeric/flutter_firebase_distribution.git'
      }
    }
 
    stage('flutter doctor') {
            steps {
                sh '''
                  flutter doctor -v
                  '''
            }
        }
 stage('dependencies') {
            steps {
                sh '''
                   flutter pub get
                   '''
            }
        }

   stage('test') {
            steps {
                sh '''
                  flutter test
                  '''
            }
        }

  stage('Build') {
            steps {
                sh '''
                    flutter build apk 
                  '''
            }
        }
 }

 post {
  always {
            echo 'Always message'
  }

  success {
            echo 'Success message'
        }

  failure {
            echo 'Failed :( message'
        }

  changed {
            echo 'Things were different before...'
        }

  aborted  {
         echo "Aborted message"
  }
 }
}
