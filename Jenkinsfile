pipeline {
  agent {
    node {
      label 'ubuntu'
    }

  }
  stages {
    stage('Admit') {
      steps {
        sh 'echo "Admitted!"'
      }
    }

    stage('Build') {
      steps {
        sh 'echo "Built!"'
      }
    }

    stage('Test') {
      steps {
        sh 'echo "Some minor test ..."'
        sh 'echo "Tested!"'
      }
    }

  }
  environment {
    EXAMPLE_ENV = 'example_value'
  }
}
