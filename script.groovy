#!/usr/bin/env groovy

def deploy(String imageName) {

    def dockerCmd = """
        docker pull ${imageName}
        docker stop java-app || true
        docker rm java-app || true
        docker run -d --name java-app -p 8081:8081 ${imageName}
    """

    sshagent(['ec2-server-key']) {
        sh """
            ssh -o StrictHostKeyChecking=no ec2-user@63.177.99.170 '${dockerCmd}'
        """
    }
}

return this
