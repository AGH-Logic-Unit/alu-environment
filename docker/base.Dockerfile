# syntax=docker/dockerfile:1.4
# ==============================================================================
# AGH Logic Unit - Unified Development Environment (alu-ude)
# Targets: linux/amd64, linux/arm64
# ==============================================================================

FROM ubuntu:24.04 AS base

LABEL org.opencontainers.image.title="AGH Logic Unit Unified Dev Environment" \
      org.opencontainers.image.vendor="AGH Logic Unit" \
      org.opencontainers.image.licenses="Apache-2.0"


ARG BASE_VERSION=1.0.0
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC \
    ALU_IMAGE_BASE_VERSION=${BASE_VERSION} \
    ALU_FLAVOR="Base"

# Layer 1: Core OS utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ccache \
    curl \
    git \
    htop \
    jq \
    make \
    ninja-build \
    openssh-client \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    sudo \
    tar \
    unzip \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Just
ARG TARGETARCH
ENV JUST_VERSION=1.39.0
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        JUST_ARCH="aarch64-unknown-linux-musl"; \
    else \
        JUST_ARCH="x86_64-unknown-linux-musl"; \
    fi && \
    curl -sSL \
    "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin just && \
    chmod +x /usr/local/bin/just

# Layer 3: vscode user
ARG USERNAME=vscode
ARG USER_UID=1100
ARG USER_GID=1100

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME


# Layer 4: Standards
RUN mkdir -p /opt/alu/standards
COPY standards/ /opt/alu/standards

COPY scripts/baner.sh /etc/profile.d/baner.sh
RUN chmod +x /etc/profile.d/baner.sh && \
    echo "source /etc/profile.d/baner.sh" >> /home/vscode/.bashrc

# Layer 5: Pre-create cache directories
ENV CCACHE_DIR=/home/vscode/.cache/ccache \
    CCACHE_MAXSIZE=10G
RUN mkdir -p /home/vscode/.cache/ccache && \
    chown -R $USERNAME:$USERNAME /home/vscode/.cache

USER $USERNAME
WORKDIR /workspace

CMD ["/bin/bash"]