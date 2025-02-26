# Use the official Jenkins inbound agent Alpine image as the base
FROM jenkins/inbound-agent:alpine

# Switch to root user to install dependencies
USER root

# Install dependencies
RUN apk add --no-cache \
    jq \
    curl \
    python3 \
    py3-pip \
    docker-cli \
    && python3 -m venv /opt/awscli \
    && /opt/awscli/bin/pip install --upgrade awscli

# Add the virtual environment's bin directory to PATH
ENV PATH="/opt/awscli/bin:${PATH}"

# Verify installations
RUN aws --version \
    && jq --version \
    && curl --version \
    && docker --version

# Switch back to the jenkins user (optional, but recommended for security)
USER jenkins
