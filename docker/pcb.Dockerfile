# syntax=docker/dockerfile:1.4
# ==============================================================================
# AGH Logic Unit - PCB & Hardware Environment (alu-pcb)
# Specialized for KiCad CLI, DRC verification, panelization & manufacturing export
# Platforms: linux/amd64, linux/arm64
# ==============================================================================

FROM ghcr.io/agh-logic-unit/alu-base:latest AS pcb

USER root
ARG TARGETARCH
ARG PCB_VERSION=1.0.0

ENV ALU_IMAGE_VERSION=${PCB_VERSION} \
    ALU_FLAVOR="PCB & Hardware"

# Layer 1: KiCad CLI & graphics/diff utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository --yes ppa:kicad/kicad-8.0-releases && \
    apt-get update && apt-get install -y --no-install-recommends \
    diff-pdf-wx \
    gerbv \
    ghostscript \
    imagemagick \
    kicad \
    libgl1 \
    libgl1-mesa-dri \
    poppler-utils \
    xsltproc \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Python PCB tooling (KiKit, InteractiveHtmlBom)
ENV VIRTUAL_ENV=/opt/alu-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m venv --system-site-packages $VIRTUAL_ENV && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir --upgrade pip && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir \
        kikit \
        InteractiveHtmlBom \
        pyyaml \
        click && \
    chown -R vscode:vscode $VIRTUAL_ENV

USER vscode
WORKDIR /workspace

# Smoke test
RUN kicad-cli --version && \
    kikit --version && \
    python3 -c "import kikit; print('✓ ALU PCB Environment Ready')"

CMD ["/bin/bash"]
