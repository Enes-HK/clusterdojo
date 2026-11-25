# The main "student@base" machine: you start here and ssh into the exam instances.
# It also runs the exam web UI (port 8080), the browser terminal (ttyd, port 7681) and the Helm chart repo (port 8879).
FROM ubuntu:24.04
# amd64 or arm64 (Apple Silicon, Linux on ARM), set by docker build
ARG TARGETARCH

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-client vim nano less bash-completion curl ca-certificates jq python3 python3-markdown python3-yaml \
      tree iputils-ping dnsutils openssl sudo tmux tzdata \
 && rm -rf /var/lib/apt/lists/*

RUN arch=${TARGETARCH:-$(dpkg --print-architecture)} \
 && case $arch in amd64) ttyd=x86_64 ;; arm64) ttyd=aarch64 ;; *) echo "unsupported architecture: $arch"; exit 1 ;; esac \
 && curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.37.0/bin/linux/$arch/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && curl -fsSL https://get.helm.sh/helm-v3.22.1-linux-$arch.tar.gz | tar xz -C /tmp \
 && mv /tmp/linux-$arch/helm /usr/local/bin/helm && rm -rf /tmp/linux-$arch \
 && curl -fsSLo /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$ttyd \
 && chmod +x /usr/local/bin/ttyd

RUN useradd -m -s /bin/bash student \
 && mkdir -p /home/student/.ssh /root/.ssh \
 && echo base > /etc/exam-name

COPY keys/id_ed25519 /home/student/.ssh/id_ed25519
COPY keys/id_ed25519 /root/.ssh/id_ed25519
COPY common/ssh_config /home/student/.ssh/config
COPY common/vimrc /home/student/.vimrc
COPY common/bashrc /etc/exam-bashrc

# root uses the same aliases but logs into the nodes as root (used by setup and grading scripts)
RUN sed 's/User student/User root/' /home/student/.ssh/config > /root/.ssh/config \
 && cat /etc/exam-bashrc >> /home/student/.bashrc \
 && chown -R student:student /home/student \
 && chmod 700 /home/student/.ssh /root/.ssh \
 && chmod 600 /home/student/.ssh/* /root/.ssh/*

CMD ["/root/exam/bin/entrypoint.sh"]
