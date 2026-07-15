# 🚀 Java CI/CD Pipeline with Jenkins, Docker & Automated Versioning

[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Maven](https://img.shields.io/badge/Maven-C71A36?style=for-the-badge&logo=apachemaven&logoColor=white)](https://maven.apache.org/)
[![Java](https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)](https://openjdk.org/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/)

A production-style **CI/CD pipeline** that builds a Java (Maven) application, automatically versions it, packages it into a Docker image, and publishes it to Docker Hub — all orchestrated by a **reusable Jenkins Shared Library**.

While building this, I ran into real versioning, authentication, and permission issues that come up in production Jenkins setups. This README documents explains how the pipeline works and how each of those problems was diagnosed and fixed.

---

## 📖 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Technologies Used](#-technologies-used)
- [Project Structure](#-project-structure)
- [CI/CD Pipeline Stages](#-cicd-pipeline-stages)
- [Jenkins Shared Library](#-jenkins-shared-library)
- [Dynamic Docker Image Tagging](#-dynamic-docker-image-tagging)
- [Challenges & Solutions](#-challenges--solutions)
- [Skills Demonstrated](#-skills-demonstrated)
- [Getting Started](#-getting-started)
- [Screenshots](#-screenshots)
- [Future Improvements](#-future-improvements)

---

## 📌 Project Overview

This repository contains a Java application whose build, versioning, containerization, and publishing process is fully automated through a **Jenkins declarative pipeline**. The pipeline logic itself doesn't live directly in the `Jenkinsfile` — instead, the reusable steps like building the JAR, building the Docker image, logging in and pushing to Docker Hub are abstracted into a **Jenkins Shared Library**, so the same library can drive the pipeline for other Java/Docker projects with minimal changes.

Every successful pipeline run:

1. Pulls the latest source code
2. Bumps the application's semantic version
3. Builds a fresh JAR with Maven
4. Builds a Docker image tagged with that new version
5. Pushes the image to Docker Hub
6. Commits and pushes the version bump back to GitHub — so the *next* build starts from a clean, incremented baseline

> **Note:** The `deploy` stage is currently a placeholder (`script.groovy`). Actual deployment automation (e.g., to a server or Kubernetes) is being built as a separate, follow-up project.

---

## 🏗 Architecture

```mermaid
flowchart TD
    A[Developer pushes code to GitHub] --> B[Jenkins Pipeline Triggered]
    B --> C[Stage: Increment Version]
    C --> D[Stage: Build JAR - Maven]
    D --> E[Stage: Build Docker Image]
    E --> F[Stage: Docker Login via Jenkins Credentials]
    F --> G[Stage: Push Image to Docker Hub]
    G --> H[Stage: Deploy - placeholder]
    H --> I[Stage: Commit & Push Version Bump]
    I --> J[GitHub repo updated with new version]
    J -.next build starts here.-> C

    subgraph SharedLib [Jenkins Shared Library]
        L1[buildJar]
        L2[buildImage]
        L3[dockerLogin]
        L4[dockerPush]
    end

    D -.calls.-> L1
    E -.calls.-> L2
    F -.calls.-> L3
    G -.calls.-> L4
```

```mermaid
sequenceDiagram
    participant GH as GitHub
    participant JK as Jenkins
    participant LIB as Shared Library
    participant DH as Docker Hub

    GH->>JK: Webhook / manual trigger
    JK->>JK: mvn versions:set (increment version)
    JK->>LIB: buildJar()
    LIB->>JK: JAR built (target/*.jar)
    JK->>LIB: buildImage(image:tag)
    LIB->>JK: Docker image built
    JK->>LIB: dockerLogin()
    LIB->>DH: Authenticate (Jenkins Credentials)
    JK->>LIB: dockerPush(image:tag)
    LIB->>DH: Push image
    JK->>GH: git commit + push (PAT auth) - version bump
```

---

## ✨ Features

- ✅ Fully automated Maven build → Docker image → Docker Hub publish pipeline
- ✅ Automatic semantic version incrementing on every build
- ✅ Dynamic, non-hardcoded Docker image tagging tied to the app version
- ✅ Reusable **Jenkins Shared Library** for Maven and Docker logic
- ✅ Secure Docker Hub authentication via **Jenkins Credentials**
- ✅ Secure Git authentication via **GitHub Personal Access Token (PAT)**
- ✅ Self-updating repository — the pipeline commits its own version bumps back to GitHub
- ✅ Minimal, secure runtime container image (non-root user, slim JRE base)

---

## 🛠 Technologies Used

| Category            | Tool / Technology                     |
|----------------------|----------------------------------------|
| Language / Runtime   | Java 17                               |
| Build Tool           | Maven                                 |
| CI/CD Orchestration  | Jenkins (Declarative Pipeline)        |
| Reusable Automation  | Jenkins Shared Library (Groovy)       |
| Containerization     | Docker                                |
| Image Registry       | Docker Hub                            |
| Version Control      | Git & GitHub                          |
| Secrets Management   | Jenkins Credentials Store             |
| Authentication       | GitHub Personal Access Token (PAT)    |
| Base Image           | `eclipse-temurin:17-jre-jammy`        |

---

## 📁 Project Structure

```
.
├── Jenkinsfile                  # Declarative pipeline definition
├── Dockerfile                   # Container image definition for the Java app
├── script.groovy                # Placeholder deploy step (future project)
├── pom.xml                      # Maven project descriptor
├── src/                         # Java application source code
│   └── main/java/...
└── README.md

jenkins-shared-library/
├── src/
│   └── com/example/
│       └── Docker.groovy        # Core reusable Docker logic class
└── vars/
    ├── buildJar.groovy          # Wraps Maven build step
    ├── buildImage.groovy        # Wraps Docker.buildDockerImage()
    ├── dockerLogin.groovy       # Wraps Docker.dockerLogin()
    └── dockerPush.groovy        # Wraps Docker.dockerPush()
```

> The shared library lives in its own repository, registered in Jenkins under **Manage Jenkins → Configure System → Global Pipeline Libraries** as `jenkins-shared-library`, and is imported into the `Jenkinsfile` with `@Library('jenkins-shared-library') _`.

---

## ⚙️ CI/CD Pipeline Stages

| # | Stage                     | What Happens |
|---|----------------------------|---------------|
| 1 | **Increment Version**      | Maven's `build-helper` and `versions` plugins bump the patch version in `pom.xml`, and the new version is read into `env.IMAGE_NAME`. |
| 2 | **Build JAR**               | Shared library's `buildJar()` runs `mvn package` (skipping tests) to produce the deployable JAR. |
| 3 | **Build & Push Image**      | Shared library builds a Docker image tagged with the new version, logs in to Docker Hub using Jenkins Credentials, and pushes the image. |
| 4 | **Deploy**                  | Placeholder stage (`script.groovy`) — reserved for a future deployment automation project. |
| 5 | **Commit Version Update**   | The updated `pom.xml` is committed and pushed back to GitHub using a PAT, so the next pipeline run starts from the latest version. |

**Pipeline snippet:**

```groovy
@Library('jenkins-shared-library') _
pipeline {
    agent any
    tools { maven 'maven' }
    stages {
        stage("increment version") { ... }
        stage("build jar") {
            steps { script { buildJar() } }
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
        stage("deploy") { ... }
        stage("commit version update") { ... }
    }
}
```

---

## 📚 Jenkins Shared Library

Rather than repeating Maven and Docker logic inline in every `Jenkinsfile`, the reusable pieces were extracted into a **Jenkins Shared Library**. This keeps the `Jenkinsfile` itself short and declarative, while the "how" of building and pushing lives in one place.

The library follows the standard Jenkins Shared Library layout:

- **`src/com/example/Docker.groovy`** — a Groovy class holding the actual implementation (`buildDockerImage`, `dockerLogin`, `dockerPush`), implementing `Serializable` so it works safely inside a pipeline's CPS execution model.
- **`vars/*.groovy`** — thin global-variable wrappers (`buildImage.groovy`, `dockerLogin.groovy`, `dockerPush.groovy`) that expose the class methods as simple, callable pipeline steps like `dockerPush(imageName)`.

Example — `vars/dockerPush.groovy`:

```groovy
import com.example.Docker

def call(String imageName) {
    return new Docker(this).dockerPush(imageName)
}
```

**Why this matters:** every function in the library takes parameters (image name, credentials ID) instead of hardcoding project-specific values. That means the same library, and the same `Jenkinsfile` pattern, can run the pipeline for a different Java/Docker project just by changing what's passed in.

---

## 🏷 Dynamic Docker Image Tagging

The Docker image name is **not hardcoded inside the shared library**. Instead:

1. The image name (e.g. `ada045/java-app`) is defined in the `Jenkinsfile`, at the project level.
2. It's combined with the automatically incremented application version to form the full tag, e.g. `ada045/java-app:1.11`.
3. That fully-formed tag is passed as a **parameter** into the shared library's functions (`buildImage`, `dockerPush`) — the library never needs to know what the image is actually called.

```groovy
def imageName = "ada045/java-app:${env.IMAGE_NAME}"
buildImage imageName
dockerPush imageName
```

Resulting tags over successive builds:

```
my-image:1.10
my-image:1.11
my-image:1.12
```

**Why this design matters:** the shared library only ever receives a ready-made image name as a string. It doesn't know or care which project it's building for. This means any other Java project can use the same library, pass in its own image name, and get the same versioning and tagging behavior without any changes to the library code.

---

## 🧩 Challenges & Solutions

### 1. Versioning — every build produced the same Docker tag

**Problem:** Initially, the version bump only happened inside the workspace and was never persisted anywhere. Every pipeline run started from the *same* `pom.xml` version, so every build incremented from the same baseline instead of the previous build's result:

```
1.10 → 1.11   (build 1)
1.10 → 1.11   (build 2 — should have been 1.12!)
```

**Solution:** After building and pushing the image, the pipeline now commits the updated `pom.xml` back to GitHub and pushes it. This means each new build clones a repo that already reflects the previous build's version, so versions increment correctly and continuously:

```
1.10
  ↓
1.11 → commit & push
  ↓
(next build clones latest)
  ↓
1.12
  ↓
1.13 → commit & push
```

### 2. Authentication — Git push from Jenkins was failing

**Problem:** Plain GitHub username/password authentication doesn't work for automated Git operations (GitHub disabled password auth for Git over HTTPS).

**Solution:**
- Generated a **GitHub Personal Access Token (PAT)**.
- Stored it securely as a `usernamePassword` credential in **Jenkins Credentials**.
- Injected it at pipeline runtime with `withCredentials`, and used it to rewrite the remote URL for authenticated push:

```groovy
withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
    sh 'git remote set-url origin https://${USER}:${PASS}@github.com/Ada045/jenkins-app-deployment.git'
    sh 'git push origin HEAD:master'
}
```

The token is never printed or hardcoded — it only ever exists as a masked environment variable during the credential-scoped block.

### 3. Docker permission denied inside the Jenkins container

**Problem:** Jenkins could not run `docker build` / `docker push` commands. The Jenkins process didn't have permission to access the Docker socket (`/var/run/docker.sock`) on the host, resulting in a permission-denied error.

**Solution:** Entered the running Jenkins container as `root` and granted access to the socket:

```bash
docker exec -u 0 -it <container-id> bash
chmod 666 /var/run/docker.sock
```

This fixed the issue because it gave the `jenkins` user read/write access to the Docker daemon's socket, so the Jenkins process could talk to the host's Docker engine.

> ⚠️ **Production note:** `chmod 666` on the Docker socket is a quick fix, not a secure long-term solution — it grants any process on the host root-equivalent access to Docker. In a production environment, the safer approach is to add the `jenkins` user to the `docker` group (or run a rootless/sidecar Docker setup) so permissions are scoped properly rather than opened to everyone.

---

## 🎯 Skills Demonstrated

| Category | Skills |
|---|---|
| **CI/CD** | Jenkins, Declarative Pipelines, Pipeline Automation |
| **Automation Design** | Jenkins Shared Libraries, Version Automation, Image Tagging |
| **Build Tools** | Maven |
| **Containerization** | Docker, Docker Hub, Dockerfile design |
| **Source Control** | Git, GitHub, GitHub Personal Access Tokens |
| **Security** | Jenkins Credentials, Docker Socket Management |
| **Troubleshooting** | Diagnosing and resolving real pipeline failures (permissions, auth, versioning) |

---

## 🚦 Getting Started

### Prerequisites

- Jenkins with the Maven, Docker, and Git plugins
- A Docker Hub account and access token
- A GitHub Personal Access Token with `repo` scope
- Docker installed on the Jenkins agent

### Setup

1. **Register the shared library** in Jenkins:
   `Manage Jenkins → Configure System → Global Pipeline Libraries` → name it `jenkins-shared-library` and point it at its repository.
2. **Add credentials** in Jenkins:
   - `docker-credentials` → Docker Hub username/password
   - `github-pat` → GitHub username + PAT
3. **Create a Pipeline job** pointing at this repository's `Jenkinsfile`.
4. **Run the pipeline** — it will build, version, containerize, and push automatically.

### Running the app locally (without Jenkins)

```bash
mvn clean package
docker build -t my-image:local .
docker run -p 8081:8081 my-image:local
```

---

## 📸 Screenshots

> _Add screenshots below to showcase the pipeline in action._

**Jenkins Pipeline Overview**
`![Pipeline Overview](./screenshots/pipeline-overview.png)`

**Successful Build Stages**
`![Build Stages](./screenshots/build-stages.png)`

**Docker Hub Repository with Tagged Images**
`![Docker Hub Tags](./screenshots/dockerhub-tags.png)`

**GitHub Commit History (Automated Version Bumps)**
`![Version Commits](./screenshots/version-commits.png)`

---

## 🔮 Future Improvements

- [ ] Implement the actual **deploy stage** (e.g., deploy to a remote server, Docker Swarm, or Kubernetes)
- [ ] Add automated **unit/integration tests** as a pipeline stage before the build
- [ ] Replace `chmod 666` on the Docker socket with `docker` group membership or rootless Docker
- [ ] Add Slack/email notifications on pipeline success or failure
- [ ] Introduce a `Jenkinsfile` parameter for choosing major/minor/patch version bumps
- [ ] Add a vulnerability scan stage (e.g., Trivy) before pushing images to Docker Hub
- [ ] Migrate secrets management to a dedicated vault (e.g., HashiCorp Vault) for larger-scale use

---

## 📄 License

This project is available under the MIT License.
