#!/usr/bin/env groovy

def deploy(String imageName) {
    def dockerCmd = "docker run -p 8081:8081 -d ${imageName}"
    sshagent(['ec2-server-key']) {
        sh "ssh -o StrictHostKeyChecking=no ec2-user@63.177.99.170 ${dockerCmd}"
    }
}
return this
