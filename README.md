# 🚀 Jenkins EC2 Master & ECS Fargate Slaves with Automated Backup & Kaniko Integration

## 📌 Project Overview
This project provisions a **Jenkins Master on EC2** and **Jenkins Slave Agents on ECS Fargate**, optimizing costs by:
- **Reducing idle instance time** with automated backup of volumes and restore mechanisms.
- **Using Fargate for on-demand Jenkins Slaves**, eliminating always-on EC2 nodes.
- **Implementing Kaniko** for building Docker images without requiring privileged mode (Docker-in-Docker restriction).


## 🎯 Key Features
✅ **Jenkins Master on EC2**
- Runs as a containerized service.
- Backs up and restores automatically from **Amazon EBS**.
- Uses **Amazon ECR** to store the Jenkins image.

✅ **Jenkins Slave Agents on ECS Fargate**
- Runs as Fargate tasks to handle build jobs.
- Uses **Kaniko** for container image builds (avoiding DinD limitations).
- Connects dynamically to Jenkins Master on private network.

✅ **Cost Optimization**
- **EC2 Snapshot Backup**: Automated EBS snapshot creation via **EventBridge & Lambda** before termination.
- **Auto-Restoration**: When a new EC2 instance launches, it restores from the latest snapshot.

✅ **Security & Accessibility**
- **SSM Session Manager**: Secure access to the Jenkins UI.
- Private networking for Fargate tasks with controlled internet access.

## 📂 Project Structure
```
📦 jenkins-infra
 ┣ 📂 terraform              # Terraform configurations for infrastructure provisioning
 ┣ 📂 scripts                # Scripts to migrate volumes and master docker image to AWS
 ┣ 📜 README.md              # Project documentation
```

## 🔧 Technologies Used
- **AWS Services:** EC2, ECS Fargate, S3, ECR, Lambda, EventBridge, SSM
- **Infrastructure as Code (IaC):** Terraform - backend stored on DynamoDB+S3
- **Configuration Management:** Ansible
- **CI/CD & Containerization:** Jenkins, Kaniko, Docker

## 🚀 Deployment Steps
### 1️⃣ Provision Infrastructure
```sh
cd terraform
terraform init
terraform apply -auto-approve
```
### 2️⃣ Access Jenkins
- Use **AWS SSM** to connect securely:
```sh
aws ssm start-session --target <instance-id>
```
- Forward Jenkins UI to your local machine:
```sh
ssh -L 8080:localhost:8080 ec2-user@<public-ip>
```

## 📌 Future Enhancements
- Automating security mode to deploy VPN and NAT (More expensive option)

---

> **Contributors:** [@jduran](https://github.com/jduran) 🛠️
