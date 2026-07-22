#!/usr/bin/env groovy

def deploy() {
    def dockerCmd = 'docker run -p 8081:8081 -d ada045/java-app:1.1.2'
    sshagent(['ec2-server-key']) {
        sh "ssh -o StricitHostKeyChecking=no ec2-user@63.177.99.170 ${dockerCmd}"
    }
}
return this
