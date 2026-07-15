# 🚀 Java CI/CD Pipeline with Jenkins, Docker & Automated Versioning

[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Maven](https://img.shields.io/badge/Maven-C71A36?style=for-the-badge&logo=apachemaven&logoColor=white)](https://maven.apache.org/)
[![Java](https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)](https://openjdk.org/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/)

This project demonstrates a production-inspired **CI/CD pipeline** that automates the build, versioning, containerization, and deployment of a Java (Maven) application. The pipeline compiles the application into a JAR file, automatically increments its version, builds and tags a Docker image with the updated version, and publishes the image to Docker Hub. To promote reusability and maintainability, the core build and Docker operations are encapsulated within a **Jenkins Shared Library**.

During the development of this pipeline, I encountered and resolved several real-world challenges commonly faced in production Jenkins environments, including application version management, GitHub authentication using a Personal Access Token (PAT), and Docker socket permission issues. This README explains the pipeline architecture, its implementation, and the solutions used to address each of these challenges.


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

<img width="1366" height="768" alt="Screenshot (29)" src="https://github.com/user-attachments/assets/f093654e-d500-4a3c-9b6e-3bc2437fab2f" />

> **Note:** The `deploy` stage is currently implemented as a placeholder (`script.groovy`). The next phase of this project is to automate deployment to **AWS**, where the Docker image will be pulled from Docker Hub and deployed to the target environment.

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

## ⚙️ CI/CD Pipeline Stages

| # | Stage                     | What Happens |
|---|----------------------------|---------------|
| 1 | **Increment Version**      | Maven's `build-helper` and `versions` plugins bump the patch version in `pom.xml`, and the new version is read into `env.IMAGE_NAME`. |
| 2 | **Build JAR**               | The shared library's `buildJar()` function executes `mvn clean package` to generate the deployable JAR file. The `clean` phase removes artifacts from previous builds ensuring that each pipeline execution starts with a fresh workspace and produces a new JAR without reusing outdated build files. |
| 3 | **Build & Push Image**      | Shared library builds a Docker image tagged with the new version, logs in to Docker Hub using Jenkins Credentials, and pushes the image. |
| 4 | **Deploy**                  | Placeholder stage (`script.groovy`) — reserved for a future deployment automation project. |
| 5 | **Commit Version Update**   | The updated `pom.xml` is committed and pushed back to GitHub using a PAT, so the next pipeline run starts from the latest version. |

---

## 📚 Jenkins Shared Library

To avoid duplicating Maven and Docker commands across multiple pipelines, I extracted the common build logic into a Jenkins Shared Library. This keeps the Jenkinsfile clean and focused on orchestrating the pipeline, while the implementation of the build and deployment tasks is centralized in a reusable library.

The shared library follows the standard Jenkins Shared Library structure:

- **`src/com/example/Docker.groovy`** — a Groovy class holding the actual implementation (`buildDockerImage`, `dockerLogin`, `dockerPush`), implementing `Serializable` so it works safely inside a pipeline's CPS execution model.
- **`vars/*.groovy`** – Contains lightweight wrapper scripts such as `buildImage.groovy`, `dockerLogin.groovy`, and `dockerPush.groovy`. These wrappers expose the methods defined in the `Docker` class as simple, reusable pipeline steps, allowing them to be invoked directly from the `Jenkinsfile`

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

### Dynamic Docker Image Tagging

The Docker image name is **not hardcoded** within the Jenkins Shared Library. Instead, it is defined in the `Jenkinsfile`, allowing the shared library to remain reusable across different projects.

The process works as follows:

1. The base Docker image name (for example, `ada045/java-app`) is defined in the `Jenkinsfile`.
2. During the pipeline execution, the automatically incremented application version is appended to the image name to generate a versioned Docker image tag, such as `ada045/java-app:1.11`.
3. The complete image name, including the version tag, is then passed as a parameter to the shared library functions (such as `buildImage` and `dockerPush`), allowing the library to build and push the correct image without containing any project-specific information.

```groovy
def imageName = "ada045/java-app:${env.IMAGE_NAME}"

buildImage imageName
dockerPush imageName
```

As the application version is incremented on each successful pipeline execution, the Docker image is automatically tagged with the corresponding version:

```text
ada045/java-app:1.10
ada045/java-app:1.11
ada045/java-app:1.12
```
**Why this design matters:** the shared library only ever receives a ready-made image name as a string. It doesn't know or care which project it's building for. This means any other Java project can use the same library, pass in its own image name, and get the same versioning and tagging behavior without any changes to the library code.

---

## 🧩 Challenges & Solutions

### 1. Versioning — every build produced the same Docker tag

**Problem:** Initially, the version increment was only applied within the Jenkins workspace and was not persisted back to the source repository. As a result, each pipeline execution started from the same version defined in the `pom.xml` file. This caused every build to generate the same incremented version instead of continuing from the version produced by the previous successful build.

```text
Initial version: 1.10

Build 1:
1.10 → 1.11

Build 2:
1.10 → 1.11   ❌ Expected: 1.12
```

Since the updated version was never committed back to GitHub, subsequent pipeline executions always read the original version from the repository, resulting in duplicate Docker image tags and inconsistent versioning.

**Solution:** To resolve this issue, the pipeline was enhanced to automatically commit the updated `pom.xml` file back to GitHub after successfully building and pushing the Docker image. This ensures that the latest application version is persisted in the repository before the pipeline completes.

As a result, every subsequent pipeline execution clones the most recent version of the repository, allowing the application version to continue incrementing from the previous successful build rather than restarting from the original version.

```text
Initial version: 1.10
        │
        ▼
Build 1: 1.11
        │
        ├── Commit & Push updated pom.xml
        ▼
Next pipeline clones the latest repository
        │
        ▼
Build 2: 1.12
        │
        ├── Commit & Push updated pom.xml
        ▼
Build 3: 1.13
```
<img width="1366" height="768" alt="Screenshot (27)" src="https://github.com/user-attachments/assets/04be43e3-e64d-435a-8547-6858def21262" />

<img width="1366" height="768" alt="Screenshot (28)" src="https://github.com/user-attachments/assets/a2f7d411-3594-4bbf-abf4-196deecc8338" />

This approach guarantees continuous versioning, prevents duplicate Docker image tags, and ensures that each build produces a uniquely versioned application and Docker image.

### 2. Authentication — Git push from Jenkins was failing

**Problem:** During implementation, I encountered an authentication issue when attempting to push changes back to GitHub from the Jenkins pipeline. GitHub no longer supports username and password authentication for Git operations over HTTPS, so the pipeline was unable to authenticate using standard credentials.

**Solution:**

To securely authenticate the pipeline, I:

Generated a GitHub Personal Access Token (PAT) with the required repository permissions.
Stored the PAT securely in Jenkins Credentials as a usernamePassword credential.
Used Jenkins' withCredentials step to inject the credentials into the pipeline at runtime.
Updated the Git remote URL to use the injected credentials before pushing the changes back to the repository.

```groovy
withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
    sh 'git remote set-url origin https://${USER}:${PASS}@github.com/Ada045/jenkins-app-deployment.git'
    sh 'git push origin HEAD:master'
}
```

The token is never printed or hardcoded — it only ever exists as a masked environment variable during the credential-scoped block.

### 3. Docker permission denied inside the Jenkins container

**Problem:** Jenkins could not run `docker build` / `docker push` commands. The Jenkins process didn't have permission to access the Docker socket (`/var/run/docker.sock`) on the host, resulting in a permission-denied error.

<img width="1366" height="768" alt="Screenshot (23)" src="https://github.com/user-attachments/assets/0d8ecfb5-8475-41af-8baf-e48520f65e72" />

**Solution:** Entered the running Jenkins container as `root` and granted access to the socket:

```bash
docker exec -u 0 -it <container-id> bash
chmod 666 /var/run/docker.sock
```
<img width="1366" height="768" alt="Screenshot (22)" src="https://github.com/user-attachments/assets/d05e108b-31d1-4bd4-9ebe-7dd11880a1ad" />

This fixed the issue because it gave the `jenkins` user read/write access to the Docker daemon's socket, so the Jenkins process could talk to the host's Docker engine.

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
