pipeline{
 agent any

 environment {
  PATH = "$PATH:/opt/flutter/bin"
 }
 
 options {
        timestamps()
        disableConcurrentBuilds()
  // Timeout counter starts AFTER agent is allocated
        timeout(time: 30, unit: 'MINUTES')
  // Keep the 10 most recent builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

 stages {
  stage('Checkout code') {
              steps {
                  git branch: 'main', url: 'https://github.com/klaw321/FlutterEcommercePlatform.git'
                  }
    }
 stage('Get app version') {
            steps {
             script {
            APP_VERSION = sh(returnStdout: true, script: "cat pubspec.yaml | grep version: | awk '{print \$2}'").trim()
          }
            }
        }


 stage('dependencies') {
            steps {
                sh '''
      flutter pub get
  '''
            }
        }

        stage('Build') {
            steps {
    sh "flutter build apk --build-name=${APP_VERSION} --build-number=${BUILD_NUMBER}"
            }
        }
  
  stage('Deploy to Firebase App Distribution') {
            steps {
                sh '''
    firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk  \
     --app $FIREBASE_APP_ID --token $FIREBASE_TOKEN\
     --release-notes "Bug fixes and improvements" --groups "team-qa"
  '''
            }
        }
  
  stage('Cleanup') {
   steps {
    sh "flutter clean"
   }
  }  
 }

 post {
  always {
         echo 'build have finished'
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
