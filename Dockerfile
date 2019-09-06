FROM debian:buster-slim
LABEL maintainer="Jan Borsodi <jborsodi@gmail.com>"

RUN apt-get update && apt-get install -y openssh-server tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./sshd_config /tmp/sshd_config
RUN mkdir /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keygen -A && \
    cat /tmp/sshd_config >>/etc/ssh/sshd_config && \
    sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config && \
    rm /tmp/sshd_config

# Prepare ssh folder and scripts, and disable password for root user
COPY ssh-forward-agent.sh ssh-update-keys.sh /root/
RUN chmod +x /root/*.sh && \
    mkdir /var/run/sshd && \
    sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth && \
    echo 'root:*' | chpasswd -e && sed -i 's/^root:\*:/root::/' /etc/shadow

EXPOSE 22

# Use /docker-ssh as the shared volume and force ssh to create sockets in this folder
# by linking /tmp to it.
VOLUME /docker-ssh
RUN rm -rf /tmp && \
    ln -s /docker-ssh /tmp

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/usr/sbin/sshd","-D"]
