#!/usr/bin/env groovy

@Library ('jenkins-shared-library')
def gv

pipeline{
    agent any
    tools {
        maven 'maven'
    }
    stages {
        stage("init") {
            steps {
                script {
                    gv = load "script.groovy"
                }
            }
        }
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
                    gv.deploy()
                }
            }
        }
    }
}
