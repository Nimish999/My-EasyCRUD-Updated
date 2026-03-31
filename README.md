# 🚀 Full CI/CD Pipeline with Jenkins, Docker, Kubernetes (EKS)

This project demonstrates a complete DevOps pipeline where a full-stack application (Frontend + Backend) is containerized using Docker, pushed to Docker Hub, and deployed on Kubernetes (AWS EKS) using Jenkins.

---

# 📌 Architecture Overview

```text
Developer → GitHub → Jenkins → Docker Hub → Kubernetes (EKS) → Application
```

---

# 🧰 Prerequisites

* AWS Account
* Docker Hub Account
* GitHub Repository
* EC2 Instances
* Basic knowledge of:

  * Docker
  * Kubernetes
  * Jenkins
  * AWS

---

# ⚙️ Step 1: Database Setup (MariaDB / RDS)

1. Create an RDS instance (MariaDB/MySQL)
2. Connect:

```bash
mysql -h <rds-endpoint> -u admin -p
```

3. Create database:

```sql
CREATE DATABASE student_db;
```

4. Grant permissions:

```sql
GRANT ALL PRIVILEGES ON student_db.* TO 'admin'@'%' IDENTIFIED BY 'your-password';
FLUSH PRIVILEGES;
```

---

# ⚙️ Step 2: Jenkins Setup

## 🔹 Launch EC2 (Jenkins Server)

Install Java (Official Docs):
👉 https://docs.oracle.com/en/java/javase/17/install/

```bash
sudo apt update
sudo apt install fontconfig openjdk-17-jre -y
```

---

## 🔹 Install Jenkins (Official Docs)

👉 https://www.jenkins.io/doc/book/installing/linux/

```bash
sudo apt install jenkins -y
```

---

## 🔹 Change Jenkins Port (8080 → 8081)

```bash
cd /lib/systemd/system/
sudo nano jenkins.service
```

Update:

```text
--httpPort=8080 → --httpPort=8081
```

Restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

---

# 🔐 Step 3: Configure Credentials in Jenkins

## Docker Hub Credentials

* Jenkins → Manage Credentials
* Add:

  * Username
  * Password

## AWS Credentials

* Access Key
* Secret Key

---

# 🐳 Step 4: CI Pipeline (Build & Push Docker Images)

⚠️ IMPORTANT:

* Replace Docker image names with your own
* Use your own DockerHub credentials
* Update GitHub repo URL

```groovy
pipeline {
    agent any

    stages {
        stage('Clone Repo') {
            steps {
                git url: "YOUR_GITHUB_REPO_URL", branch: "main"
            }
        }

        stage('Build Images') {
            steps {
                sh "docker build -t YOUR_DOCKER_USERNAME/frontend ./frontend"
                sh "docker build -t YOUR_DOCKER_USERNAME/backend ./backend"
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Docker-cred', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    sh "echo $PASSWORD | docker login -u $USERNAME --password-stdin"
                }
            }
        }

        stage('Push Images') {
            steps {
                sh "docker push YOUR_DOCKER_USERNAME/frontend"
                sh "docker push YOUR_DOCKER_USERNAME/backend"
            }
        }
    }
}
```

---

# ☸️ Step 5: EKS Cluster Setup using Terraform (via Jenkins)

Terraform is executed through Jenkins pipeline.

```groovy
pipeline {
    agent any

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }
}
```

---

# 🖥️ Step 6: EKS Control Node Setup (kubectl Machine)

Create a **separate EC2 instance** for Kubernetes operations.

## Install AWS CLI

```bash
sudo snap install aws-cli --classic
```

## Install kubectl (Official Docs)

👉 https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

---

## Configure EKS Access

```bash
aws eks update-kubeconfig --region eu-north-1 --name cluster
kubectl get nodes
```

---

# 🔗 Step 7: Connect Jenkins to EKS Control Node

## Steps:

1. Jenkins → Manage Nodes → New Node
2. Name: `eks-control`
3. Label: `eks-node`
4. Remote directory:

```text
/home/ubuntu
```

---

## Configuration:

* Launch via SSH
* Username: `ubuntu`
* Add SSH private key (.pem)

---

## ⚠️ IMPORTANT FIX

If kubeconfig is configured under root:

```bash
sudo mkdir -p /home/ubuntu/.kube
sudo cp /root/.kube/config /home/ubuntu/.kube/config
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
```

---

## SSH Fix (VERY IMPORTANT)

Set:

```text
Host Key Verification Strategy → Non verifying
```

---

# ☸️ Step 8: Kubernetes Deployment

All Kubernetes YAML files are stored in:

```text
kubernetes/
```

Includes:

* backend-deployment.yaml
* backend-service.yaml
* frontend-deployment.yaml
* frontend-service.yaml

---

# 🚀 Step 9: CD Pipeline (Deploy to Kubernetes - EKS)

```groovy
pipeline {
    agent { label 'eks-node' }

    stages {

        stage('Clone Repo') {
            steps {
                git branch: 'main', url: 'YOUR_GITHUB_REPO'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                cd kubernetes
                kubectl apply -f .
                kubectl rollout restart deployment backend
                kubectl rollout restart deployment frontend
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                kubectl get pods
                kubectl get svc
                '''
            }
        }
    }
}
```

---

# 🌐 Step 10: Access Application

```bash
kubectl get svc
```

Open:

```text
http://<EXTERNAL-IP>
```

---

# ⚠️ Common Issues & Fixes

## kubectl localhost:8080 error

```bash
aws eks update-kubeconfig
```

---

## Jenkins agent issues

* Check SSH key
* Check port 22
* Use non-verifying strategy

---

## Too many DB connections

* Reduce replicas
* Add connection pooling

---

# 🧠 Key Learnings

* CI/CD pipeline automation
* Docker image lifecycle
* Kubernetes service discovery
* AWS EKS provisioning
* Jenkins distributed architecture

---

# 🚀 Future Improvements

* Helm charts
* Ingress + Domain
* HTTPS (SSL)
* Auto-scaling (HPA)
* RDS Proxy

---

# 📌 Conclusion

This project demonstrates a **production-grade DevOps pipeline** integrating:

* Jenkins (CI/CD)
* Docker (Containerization)
* Kubernetes (Orchestration)
* AWS EKS (Managed Kubernetes)

---
