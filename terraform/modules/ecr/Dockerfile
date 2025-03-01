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

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install


# Copy Kaniko binaries to this image
COPY --from=kaniko /kaniko/ /kaniko/
COPY config.json /kaniko/.docker/config.json

# Set environment variables for Kaniko
ENV SSL_CERT_DIR /kaniko/ssl/certs
ENV PATH $PATH:/kaniko/
ENV DOCKER_CONFIG /kaniko/.docker

# Set user to root for Jenkins inbound agent permissions
USER root
