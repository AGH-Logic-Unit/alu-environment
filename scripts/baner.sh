#!/usr/bin/env bash
# ==============================================================================
# AGH Logic Unit - Interactive Terminal MOTD & Version Information
# ==============================================================================

# 1. Hard guard: Run only in interactive shells attached to a terminal
if [[ $- != *i* ]] || [ ! -t 1 ]; then
    return 0 2>/dev/null || exit 0
fi

# 2. Session guard: Execute exactly once per terminal tab/window
if [ -n "${ALU_BANNER_SHOWN:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
export ALU_BANNER_SHOWN=1

# 3. Dynamic version & flavor detection
FLAVOR="${ALU_FLAVOR:-Base}"
VERSION="${ALU_IMAGE_VERSION:-1.0.0}"
BASE_VER="${ALU_IMAGE_BASE_VERSION:-1.0.0}"

# 4. Display ASCII Banner & Environment Metadata
cat << 'EOF'

     _    ____ _   _   _                _        _   _       _ _   
    / \  / ___| | | | | |    ___   __ _(_) ___  | | | |_ __ (_) |_ 
   / _ \| |  _| |_| | | |   / _ \ / _` | |/ __| | | | | '_ \| | __|
  / ___ \ |_| |  _  | | |__| (_) | (_| | | (__  | |_| | | | | | |_ 
 /_/   \_\____|_| |_| |_____\___/ \__, |_|\___|  \___/|_| |_|_|\__|
                                  |___/                            

EOF

echo -e "\e[1;34m>> AGH Logic Unit Environment\e[0m [\e[1;32mFlavor: ${FLAVOR}\e[0m | \e[1;36mv${VERSION}\e[0m (Base: v${BASE_VER})]"

# 5. Background non-blocking check for image updates
UPDATE_FLAG="/tmp/.alu_update_available"
if [ -f "$UPDATE_FLAG" ]; then
    echo -e "\e[1;35m💡 A new container version is available!\e[0m"
else
    (
        if command -v curl >/dev/null 2>&1; then
            LATEST=$(curl -s --max-time 1 https://api.github.com/repos/AGH-Logic-Unit/alu-environment/releases/latest 2>/dev/null | grep '"tag_name":' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
            if [ -n "$LATEST" ] && [ "$LATEST" != "v${VERSION}" ]; then
                touch "$UPDATE_FLAG"
            fi
        fi
    ) >/dev/null 2>&1 &
fi
echo ""
