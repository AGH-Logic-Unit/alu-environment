# syntax=docker/dockerfile:1.4
# ==============================================================================
# AGH Logic Unit - Firmware Development Environment (alu-fw)
# Platforms: linux/amd64, linux/arm64
# ==============================================================================

FROM ghcr.io/agh-logic-unit/alu-base:latest AS fw

USER root
ARG TARGETARCH
ARG FW_VERSION=1.0.0
ENV ALU_IMAGE_VERSION=${FW_VERSION} \
    ALU_FLAVOR="Firmware Development"

# Layer 1: The compilers and stuff
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils-riscv64-unknown-elf \
    build-essential \
    cmake \
    device-tree-compiler \
    gcc-riscv64-unknown-elf \
    gdb-multiarch \
    picolibc-riscv64-unknown-elf \
    && rm -rf /var/lib/apt/lists/*

# Symlink riscv-none-elf to riscv64-unknown-elf
RUN for tool in /usr/bin/riscv64-unknown-elf-*; do \
        target_name=$(basename "$tool" | sed 's/riscv64-unknown-elf-/riscv-none-elf-/'); \
        ln -sf "$tool" "/usr/local/bin/$target_name"; \
    done

# Layer 2: Python firmware tooling
ENV VIRTUAL_ENV=/opt/alu-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m venv --system-site-packages $VIRTUAL_ENV && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir --upgrade pip && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir \
        intelhex \
        pyelftools \
        pyserial \
        pytest \
        rich && \
    chown -R vscode:vscode $VIRTUAL_ENV

USER vscode
WORKDIR /workspace

# Smoke test
RUN riscv64-unknown-elf-gcc --version && \
    riscv-none-elf-gcc --version && \
    gdb-multiarch --version && \
    python3 -c "import elftools, intelhex; print('✓ ALU Firmware Environment Ready')"

CMD ["/bin/bash"]
