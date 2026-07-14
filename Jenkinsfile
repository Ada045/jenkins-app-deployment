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
                    def gvLocal = load 'script.groovy'
                    gvLocal.deploy()
                }
            }
        }
        stage("commit version update") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'git-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'
                        
                        sh 'git status'
                        sh 'git branch'
                        sh 'git config --list'

                        sh 'git remote set-url origin https://${USER}:${PASS}@github.com/Ada045/jenkins-app-deployment.git'
                        sh 'git add .'
                        sh 'git commit -m "ci: version bumb"'
                        sh 'git push origin HEAD:master'
                    }
                }
            }
        }
    }
}
