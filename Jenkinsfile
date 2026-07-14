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
                    // Run the shared-library step that builds the project
                    buildJar()

                    // Ensure the build produced a JAR and archive it for later stages
                    def jars = findFiles(glob: 'target/*.jar')
                    if (jars == null || jars.length == 0) {
                        error "No JAR found in target/*.jar after buildJar()"
                    }
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
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
