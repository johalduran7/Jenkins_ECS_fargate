FROM gcr.io/kaniko-project/executor:debug AS kaniko-builder

FROM openjdk:17-jdk-slim-buster 

LABEL maintainer="johalduran@gmail.com"

USER root
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    build-essential \
    python3 \
    python3-pip \
    sudo \
    jq \
    bc \
    net-tools \
    telnet \
    openssh-client \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Maven
ARG MAVEN_VERSION=3.9.6 # Specify the Maven version you want
ARG MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

RUN mkdir -p /usr/share/maven && \
    wget -q -O /tmp/apache-maven.tar.gz ${MAVEN_URL} && \
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 && \
    rm /tmp/apache-maven.tar.gz

ENV M2_HOME=/usr/share/maven
ENV PATH="${M2_HOME}/bin:${PATH}"

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

ARG JENKINS_AGENT_VERSION="5.14" # Check https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/
ARG JENKINS_AGENT_JAR_URL="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_AGENT_VERSION}/remoting-${JENKINS_AGENT_VERSION}.jar"

# Download the Jenkins agent JAR
RUN wget -q -O /usr/local/bin/jenkins-agent.jar ${JENKINS_AGENT_JAR_URL} && \
    chmod +x /usr/local/bin/jenkins-agent.jar

# Create the Jenkins user and set up necessary directories and permissions
RUN groupadd -r jenkins && useradd -m -r -g jenkins -s /bin/bash jenkins && \
    mkdir -p /home/jenkins/.ssh && chown jenkins:jenkins /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh

FROM jenkins/inbound-agent AS inbound-agent-source
COPY --from=inbound-agent-source /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent


COPY --from=kaniko-builder /kaniko/ /kaniko/
# make sure you update the account in config.json_overrride and name it as config.json
COPY config.json /kaniko/.docker/config.json 

# Set environment variables for Kaniko
ENV SSL_CERT_DIR /kaniko/ssl/certs
ENV PATH $PATH:/kaniko/ # Add kaniko to PATH for the jenkins user too
ENV DOCKER_CONFIG /kaniko/.docker

# Switch to the Jenkins user and set the working directory
USER jenkins
WORKDIR /home/jenkins

# Define the entrypoint for the Jenkins agent
ENTRYPOINT ["/usr/local/bin/jenkins-agent"]

# Expose standard Jenkins agent port (though Fargate security groups handle this)
EXPOSE 50000
