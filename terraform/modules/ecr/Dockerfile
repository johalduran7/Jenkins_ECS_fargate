# Base images for Kaniko executor and Jenkins agent
FROM gcr.io/kaniko-project/executor:debug AS kaniko
FROM jenkins/inbound-agent

# Set to root user for installing dependencies
USER root

# Install required tools and packages
RUN apt-get update -y && apt-get install -y \
  libc6 \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  unzip 

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \ 
chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
apt-get update -y && apt-get install -y kubectl

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod 700 get_helm.sh && \
./get_helm.sh

# Copy Kaniko binaries to this image
COPY --from=kaniko /kaniko/ /kaniko/

# Set environment variables for Kaniko
ENV SSL_CERT_DIR /kaniko/ssl/certs
ENV PATH $PATH:/kaniko
ENV DOCKER_CONFIG /root/.docker

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

RUN chown -R jenkins:jenkins /kaniko /bin && \
    chmod -R 755 /kaniko /bin

# Set user to root for Jenkins inbound agent permissions
USER root
