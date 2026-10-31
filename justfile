# ==============================================================================
# AGH Logic Unit - Environment & Standards Repository Justfile
# Run 'just --list' to inspect available administrative and build targets
# ==============================================================================

set shell := ["bash", "-uc"]

default:
    @just --list

# ------------------------------------------------------------------------------
# LOCAL CONTAINER BUILDS & TESTING
# ------------------------------------------------------------------------------

# Build local alu-base image
build-base:
    @echo "[BUILD] Building local alu-base image..."
    docker build -f docker/base.Dockerfile -t alu-base:test .
    @echo "✓ alu-base:test built successfully."

# Build local alu-rtl image (tags alu-base:test as ghcr.io/agh-logic-unit/alu-base:latest if needed)
build-rtl:
    @echo "[BUILD] Building local alu-rtl image..."
    @docker tag alu-base:test ghcr.io/agh-logic-unit/alu-base:latest 2>/dev/null || true
    docker build -f docker/rtl.Dockerfile -t alu-rtl:test .
    @echo "✓ alu-rtl:test built successfully."

# Build local alu-pcb image
build-pcb:
    @echo "[BUILD] Building local alu-pcb image..."
    @docker tag alu-base:test ghcr.io/agh-logic-unit/alu-base:latest 2>/dev/null || true
    docker build -f docker/pcb.Dockerfile -t alu-pcb:test .
    @echo "✓ alu-pcb:test built successfully."

# Run a quick interactive smoke test inside alu-rtl
test-rtl:
    docker run --rm -it alu-rtl:test bash -lic "verilator --version && slang --version && just --version && python3 -c 'import cocotb; print(\"Cocotb OK\")'"

# ------------------------------------------------------------------------------
# VERSION MANAGEMENT
# ------------------------------------------------------------------------------

# Show current version of all flavors
versions:
    @echo "alu-base: $(cat docker/base.version)"
    @echo "alu-rtl:  $(cat docker/rtl.version)"
    @echo "alu-pcb:  $(cat docker/pcb.version)"

# ------------------------------------------------------------------------------
# SYNCHRONIZATION WITH MEMBER REPOSITORIES
# ------------------------------------------------------------------------------

# Sync devcontainer template to target repository (e.g. 'just sync-to ../pv-crab-core rtl')
sync-to target flavor="rtl":
    @mkdir -p {{target}}/.devcontainer
    @cp -v devcontainers/{{flavor}}/devcontainer.json {{target}}/.devcontainer/
    @cp -v ai/AGENTS.md {{target}}/
    @echo "✓ Synchronized {{flavor}} DevContainer & AGENTS.md to {{target}}"
