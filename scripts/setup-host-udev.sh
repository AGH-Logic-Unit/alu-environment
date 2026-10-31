#!/usr/bin/env bash
# ==============================================================================
# AGH Logic Unit - Host Udev Rules Installer for Hardware Debuggers & Programmers
# Supported: Digilent (Nexys 4 DDR, Basys, Arty, Zybo), FTDI, ST-Link, CMSIS-DAP, Gowin
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo " AGH Logic Unit - Hardware Udev & JTAG Installer"
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run this script as root (e.g. sudo bash $0)"
    exit 1
fi

CURRENT_USER="${SUDO_USER:-$USER}"
UDEV_FILE="/etc/udev/rules.d/99-agh-logic-unit.rules"

echo "[1/4] Creating udev rules file at: ${UDEV_FILE}"

cat << 'EOF' > "${UDEV_FILE}"
# Digilent JTAG / FTDI (Nexys 4 DDR, Basys, Arty, Zybo)
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# ST-Link (v2, v2-1, v3)
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# CMSIS-DAP / Raspberry Pi Debug Probe
ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# Gowin Semi FPGA USB Programmer Cable
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# USB-UART Converters (CH340, CP2102)
ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout", TAG+="uaccess"
ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout", TAG+="uaccess"
EOF

echo "[2/4] Ensuring hardware groups exist (plugdev, dialout)..."
groupadd -f plugdev
groupadd -f dialout

echo "[3/4] Adding user '${CURRENT_USER}' to hardware groups..."
usermod -aG plugdev,dialout "${CURRENT_USER}"

echo "[4/4] Reloading udev subsystem rules..."
udevadm control --reload-rules || true
udevadm trigger || true

echo "----------------------------------------------------------"
echo "✓ Success! USB/JTAG permissions have been successfully configured."
echo "If running on Windows WSL2, attach your device in PowerShell via:"
echo "   usbipd list"
echo "   usbipd bind --busid <BUSID>"
echo "   usbipd attach --wsl --busid <BUSID>"
echo "On native Linux, please log out and log back in for group membership to take effect."
echo "=========================================================="
