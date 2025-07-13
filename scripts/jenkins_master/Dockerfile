FROM jenkins/jenkins:lts

USER root
# install dependencies
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install sudo -y 
RUN apt-get install inetutils-ping -y
RUN apt-get install openssh-client -y
RUN apt-get install openssh-server -y
RUN apt-get install -y vim
RUN apt-get install net-tools -y
RUN apt-get install python3 -y
RUN apt-get install git -y
RUN apt-get install default-jdk -y
RUN apt-get install netcat-traditional -y
RUN apt-get install jq -y
RUN apt-get install -y libaio1 wget unzip 
RUN	apt-get clean
RUN apt-get install bc -y
RUN apt-get install telnet -y
RUN apt-get install ufw -y
# disable ipv6 not to have issues with ufw
RUN sed  -i 's/ipv6=yes/ipv6=no/g' /etc/default/ufw 
RUN echo 'root:1234' | chpasswd
RUN mkdir /run/sshd
RUN sed  -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN ssh-keygen -t rsa -b 4096 -f ~/.ssh/ubuntu-agent1 -N "holahola"
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install && rm -rf awscliv2.zip aws/
RUN curl -fsSL https://get.docker.com | sudo bash
EXPOSE 22 2376
USER jenkins
CMD ["/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
