#!/usr/bin/env groovy

/****************************************************************************
 * vars/runContinuousIntegrationPipeline.groovy 
 * Logic for the Continuous Integration pipeline
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.  The
 * ASF licenses this file to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 ****************************************************************************/

def call() {
  pipeline {
    options {
      checkoutToSubdirectory('nuttx')
    }
    agent {
      node {
        label 'ubuntu'
      }
    }
    environment {
      EXAMPLE_ENV = 'example_value'
      // GIT_CREDENTIALS_ID = '<uuid>'
      NUTTX_APPS_REPO_URL = 'https://github.com/apache/incubator-nuttx-apps'
      NUTTX_TESTING_REPO_URL = 'https://github.com/apache/incubator-nuttx-testing'
    }
    stages {
      stage('Clean') { // just in case the workspace cleaning is not enabled/working at job level
        steps {
          sh 'cd nuttx && git clean -fdx' // clean everything not in git at nuttx/ directory
          sh 'ls -a | grep -v "^nuttx$" | grep -v \'^[.]$\' | grep -v \'^[.][.]$\' | xargs echo rm -rf' // remove everything but nuttx/ directory
          sh 'ls -a nuttx'
          sh 'ls -a'
        }
      }
      stage('Checkout') {
        steps {
          sh 'printenv'
          ////////////////////////////////////////////
          // incubator-nuttx-apps repository master //
          ////////////////////////////////////////////
          checkout([
              $class: 'GitSCM',
              // branches: [[name: '*/master']], // default one
              doGenerateSubmoduleConfigurations: false,
              extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'apps']],
              submoduleCfg: [],
              userRemoteConfigs: [[
                  // credentialsId: "${GIT_CREDENTIALS_ID}",
                  url: "${NUTTX_APPS_REPO_URL}",
                  refspec: '+refs/heads/master:refs/remotes/origin/master',
              ]]
          ])
          ///////////////////////////////////////////////
          // incubator-nuttx-testing repository master //
          ///////////////////////////////////////////////
          checkout([
              $class: 'GitSCM',
              // branches: [[name: '*/master']], // default one
              doGenerateSubmoduleConfigurations: false,
              extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'testing']],
              submoduleCfg: [],
              userRemoteConfigs: [[
                  // credentialsId: "${GIT_CREDENTIALS_ID}",
                  url: "${NUTTX_TESTING_REPO_URL}",
                  refspec: '+refs/heads/master:refs/remotes/origin/master',
              ]]
          ])
          /////////////////////////////////////////////
          // some commands to check everything is ok //
          /////////////////////////////////////////////
          sh 'ls'
          sh 'cd apps; git show'
          sh 'cd testing; git show'
        }
      }
      stage('Builds') {
        steps {
          sh './testing/cibuild.sh -i -b full'
        }
      }
    } // stages
    post {
      // see https://jenkins.io/doc/book/pipeline/syntax/#post
      always {
        echo 'CI pipeline finished'
        deleteDir() // clean up our workspace
      }
      success {
        echo 'CI pipeline result: success :)'
      }
      failure {
        echo 'CI pipeline result: failed :('
      }
    }
  } // pipeline
} // call

// vim: ft=groovy
