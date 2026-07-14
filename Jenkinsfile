#!/usr/bin/env groovy

@Library ('jenkins-shared-library')
def gv

pipeline{
    agent any
    tools {
        maven 'maven'
    }
    stages {
        stage("build jar") {
            steps {
                script {
                    buildJar()
                }
            }
        }
        stage("build and push image") {
            steps {
                script {
                    buildImage 'ada045/java-app:1.0'
                    dockerLogin()
                    dockerPush 'ada045/java-app:1.0'
                }
            }
        }
        stage("deploy") {
            steps {
                script {
                    // Load and invoke inside the same stage to avoid CPS/serialization
                    // issues that can make the loaded script object null across stages.
                    def gvLocal = load 'script.groovy'
                    if (gvLocal == null) {
                        error "Failed to load script.groovy: returned null"
                    }
                    gvLocal.deploy()
                }
            }
        }
    }
}
