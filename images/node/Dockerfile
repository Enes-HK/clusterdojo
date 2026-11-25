# kind node image with what a practice instance needs: sshd, a sudo-capable "student" user, vim, helm.
# The two sysctl files removed below set kernel.* values, which are not per container: `sysctl --system` on a node
# would change the host's kernel. Only per-network-namespace settings stay in sysctl.d.
FROM kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
# amd64 or arm64 (Apple Silicon, Linux on ARM), set by docker build
ARG TARGETARCH

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-server openssh-client sudo vim less bash-completion jq openssl dnsutils tree procps iputils-ping \
 && rm -rf /var/lib/apt/lists/* \
 && systemctl enable ssh \
 && rm -f /usr/lib/sysctl.d/10-coredump-debian.conf /usr/lib/sysctl.d/50-pid-max.conf \
 && : > /etc/motd && rm -f /etc/update-motd.d/* && sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config

RUN arch=${TARGETARCH:-$(dpkg --print-architecture)} \
 && curl -fsSL https://get.helm.sh/helm-v3.22.1-linux-$arch.tar.gz | tar xz -C /tmp \
 && mv /tmp/linux-$arch/helm /usr/local/bin/helm && rm -rf /tmp/linux-$arch

RUN useradd -m -s /bin/bash student \
 && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
 && mkdir -p /home/student/.ssh /root/.ssh /home/student/.kube \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

COPY keys/id_ed25519.pub /home/student/.ssh/authorized_keys
COPY keys/id_ed25519.pub /root/.ssh/authorized_keys
COPY keys/id_ed25519 /home/student/.ssh/id_ed25519
COPY common/ssh_config /home/student/.ssh/config
COPY common/vimrc /home/student/.vimrc
COPY common/vimrc /root/.vimrc
COPY common/bashrc /etc/exam-bashrc

RUN cat /etc/exam-bashrc >> /home/student/.bashrc \
 && cat /etc/exam-bashrc >> /root/.bashrc \
 && chown -R student:student /home/student \
 && chmod 700 /home/student/.ssh /root/.ssh \
 && chmod 600 /home/student/.ssh/* /root/.ssh/authorized_keys
