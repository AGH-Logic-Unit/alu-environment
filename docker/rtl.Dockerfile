# syntax=docker/dockerfile:1.4
# ==============================================================================
# AGH Logic Unit - Digital UDE (alu-rtl-ude)
# Platforms: linux/amd64, linux/arm64
# ==============================================================================

FROM ghcr.io/agh-logic-unit/alu-base:latest AS rtl

USER root
ARG TARGETARCH
ARG RTL_VERSION=1.0.0
ENV ALU_IMAGE_VERSION=${RTL_VERSION} \
    ALU_FLAVOR="RTL & Digital"

# Layer 1: Hardware build essentials & compilers
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    build-essential \
    clang \
    clang-format \
    clang-tidy \
    clangd \
    cmake \
    device-tree-compiler \
    flex \
    g++ \
    gawk \
    gcc \
    gcc-riscv64-unknown-elf \
    gdb-multiarch \
    help2man \
    lcov \
    libboost-all-dev \
    libevent-dev \
    libffi-dev \
    libfl-dev \
    libfl2 \
    libftdi1-dev \
    libhidapi-dev \
    libmpc-dev \
    libmpfr-dev \
    libncurses-dev \
    libreadline-dev \
    libsystemc-dev \
    libudev-dev \
    libusb-1.0-0-dev \
    libz3-dev \
    openocd \
    iverilog \
    picolibc-riscv64-unknown-elf \
    yosys \
    z3 \
    zlib1g \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Symlink riscv-none-elf to riscv64-unknown-elf
RUN for tool in /usr/bin/riscv64-unknown-elf-*; do \
        target_name=$(basename "$tool" | sed 's/riscv64-unknown-elf-/riscv-none-elf-/'); \
        ln -sf "$tool" "/usr/local/bin/$target_name"; \
    done


# Layer 2: Pre-compiled CLI utilities (Verible, Slang)
ENV VERIBLE_VERSION=v0.0-4135-g7807ee1a
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        VERIBLE_ARCH="arm64"; \
    else \
        VERIBLE_ARCH="x86_64"; \
    fi && \
    curl -sSL "https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/verible-${VERIBLE_VERSION}-linux-static-${VERIBLE_ARCH}.tar.gz" | \
    tar -xz -C /tmp && \
    cp /tmp/verible-*/bin/* /usr/local/bin/ && \
    rm -rf /tmp/verible*

ENV SLANG_VERSION=v12.1
RUN if [ "$TARGETARCH" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then \
        git clone --depth=1 --branch ${SLANG_VERSION} https://github.com/MikePopoloski/slang.git /tmp/slang && \
        cd /tmp/slang && \
        cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DSLANG_INCLUDE_TESTS=OFF -DSLANG_INCLUDE_DOCS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local && \
        cmake --build build --parallel $(nproc) && \
        cmake --install build && \
        rm -rf /tmp/slang; \
    else \
        curl -sSL "https://github.com/MikePopoloski/slang/releases/download/${SLANG_VERSION}/slang-linux-x86_64.tar.gz" | \
        tar -xz -C /usr/local/bin && \
        chmod +x /usr/local/bin/slang; \
    fi


# Layer 3: Verilator 5.x & Spike & riscv-tests & SymbiYosys
ENV VERILATOR_VERSION=5.034
RUN wget https://github.com/verilator/verilator/archive/refs/tags/v${VERILATOR_VERSION}.tar.gz -O /tmp/verilator.tar.gz && \
    tar -xzf /tmp/verilator.tar.gz -C /tmp && \
    cd /tmp/verilator-${VERILATOR_VERSION} && \
    autoconf && \
    ./configure --prefix=/usr/local && \
    touch verilator.1 verilator_coverage.1 verilator_gantt.1 verilator_profcfunc.1 && \
    make -C src -j$(nproc) opt && \
    cp bin/verilator_bin bin/verilator_bin_dbg && \
    cp bin/verilator_bin bin/verilator_coverage_bin_dbg && \
    make install-all && \
    rm -rf /tmp/verilator-${VERILATOR_VERSION} /tmp/verilator.tar.gz /usr/local/share/man /usr/local/share/doc/verilator

# Spike Golden Simulator
RUN git clone --depth=1 --recurse-submodules https://github.com/riscv-software-src/riscv-isa-sim.git /tmp/spike && \
    cd /tmp/spike && \
    mkdir build && cd build && \
    ../configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/spike

# Pre-compiled riscv-tests
ENV RISCV_TESTS=/opt/riscv-tests
RUN git clone --depth=1 --recurse-submodules https://github.com/riscv/riscv-tests ${RISCV_TESTS} && \
    cd ${RISCV_TESTS} && \
    autoconf && \
    ./configure --prefix=${RISCV_TESTS}/install && \
    (make -k -j$(nproc) isa 2>/dev/null || true) && \
    chmod -R a+rX ${RISCV_TESTS}

# SymbiYosys (sby)
RUN git clone --depth=1 https://github.com/YosysHQ/sby.git /tmp/sby && \
    make -C /tmp/sby install PREFIX=/usr/local && \
    rm -rf /tmp/sby


# Layer 4: Python Virtual Environment & Testing Stack
ENV VIRTUAL_ENV=/opt/alu-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m venv $VIRTUAL_ENV && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir \
        cocotb==2.0.1 \
        cocotb-test==0.2.6 \
        cocotb-bus \
        cocotb-coverage \
        pytest>=9.0 \
        pytest-xdist \
        pytest-html \
        pytest-timeout \
        pytest-rerunfailures \
        pyelftools \
        scipy \
        matplotlib \
        junit-xml \
        deepdiff \
        bitwuzla \
        z3-solver==4.13.0.0 \
        pyslang>=12.0 \
        riscof \
        fastmcp \
        ruff>=0.15 \
        mypy \
        rich \
        pyyaml>=6.0 \
        zensical>=0.0.40 && \
    chown -R vscode:vscode $VIRTUAL_ENV


USER vscode
WORKDIR /workspace

# Smoke test
RUN verilator --version && \
    slang --version && \
    verible-verilog-format --version && \
    riscv64-unknown-elf-gcc --version && \
    python3 -c "import cocotb, pytest, ruff, z3; print('✓ ALU UDE Ready')"

CMD ["/bin/bash"]