#!/usr/bin/env groovy

@Library('jenkins-shared-library') _

pipeline{
    agent any
    tools {
        maven 'maven'
    }
    stages {
        stage("increment version") {
            steps {
                script {
                    sh 'mvn build-helper:parse-version versions:set -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version"
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
                    def imageName = "ada045/java-app:${env.IMAGE_NAME}"
                    buildImage imageName
                    dockerLogin()
                    dockerPush imageName
                }
            }
        }
        stage("deploy") {
            steps {
                script {
                    deploy '63.177.52.3', 'ec2-server-key', "ada045/java-app:${env.IMAGE_NAME}", 'java-app', '8081', '8080'
                }
            }
        }
        stage("commit version update") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'
                        sh 'git remote set-url origin https://${USER}:${PASS}@github.com/Ada045/jenkins-app-deployment.git'
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:master'
                    }
                }
            }
        }
    }
}
