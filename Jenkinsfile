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
                    // Verify the built artifact exists in the workspace before building image
                    def jars = findFiles(glob: 'target/*.jar')
                    if (jars == null || jars.length == 0) {
                        error "No JAR found in target/*.jar; ensure buildJar() produced the artifact before building the image."
                    }

                    def imageName = 'ada045/java-app:1.0'
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
