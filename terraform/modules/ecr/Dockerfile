# Base images for Kaniko executor and Jenkins agent
FROM gcr.io/kaniko-project/executor:debug AS kaniko
FROM jenkins/inbound-agent

# Set to root user for installing dependencies
USER root

# Install base tools
RUN apt-get update && apt-get install -y \
  curl \
  gnupg \
  unzip \
  apt-transport-https \
  ca-certificates \
  libc6 \
  software-properties-common \
  bash \
  procps \
  iputils-ping \
  net-tools \
  netcat-openbsd \
  lsof \
  vim \
  jq \
  wget \
  git \
  dnsutils \
  htop \
  tree \
  strace \
  psmisc \
  tzdata


# Install JDK 17 (from OpenJDK)
RUN apt-get update && apt-get install -y openjdk-17-jdk

# Set JAVA environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Maven 3.9.11: # Note: Updated to 3.9.11 as per the latest stable release. If there's a new realease, check the official Apache Maven site.https://maven.apache.org/download.cgi
RUN curl -fsSL https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz -o maven.tar.gz && \
    tar -xzf maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.11 /opt/maven && \
    ln -s /opt/maven/bin/mvn /usr/bin/mvn

# Set Maven environment variables
ENV M2_HOME=/opt/maven
ENV PATH=$M2_HOME/bin:$PATH

# Install Gradle 8.6
RUN curl -fsSL https://services.gradle.org/distributions/gradle-8.6-bin.zip -o gradle.zip && \
    unzip gradle.zip -d /opt/ && \
    ln -s /opt/gradle-8.6 /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/bin/gradle

ENV GRADLE_HOME=/opt/gradle
ENV PATH=$GRADLE_HOME/bin:$PATH

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

# Copy Kaniko binaries to this image
COPY --from=kaniko /kaniko/ /kaniko/
COPY config.json /kaniko/.docker/config.json

# Set Kaniko environment
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG=/kaniko/.docker
ENV PATH=$PATH:/kaniko/
ENV LATESTPUSH=YES
# Jenkins agent requires root
USER root


