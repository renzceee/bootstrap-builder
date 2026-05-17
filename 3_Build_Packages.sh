#!/usr/bin/env bash
# 3_Build_Packages.sh

set -e

CUSTOM_PKG_NAME="com.renzxce.servermanager"
if [ -z "$CUSTOM_PKG_NAME" ]; then
    CUSTOM_PKG_NAME="com.termux"
fi

ARCH="aarch64"

# --- Interactive Profile Selection ---
while true; do
    echo " "
    echo "--- Termux Build Profile Selection ---"
    echo "1) Core (Standard Termux bootstrap - Recommended)"
    echo "2) Core-Minimal (Reduced package set for smaller footprint)"
    echo " "
    read -p "Select profile [1/2]: " profile_choice

    case "$profile_choice" in
        1)
            echo "[*] Selected profile: Core (Standard)"
            CORE_PACKAGES=(
                apt bash libbz2 command-not-found coreutils libcurl dash diffutils 
                findutils gawk grep gzip less procps psmisc sed tar termux-core 
                termux-exec termux-keyring termux-tools util-linux liblzma ed 
                debianutils dos2unix inetutils lsof nano net-tools patch unzip
            )
            break
            ;;
        2)
            echo "[*] Selected profile: Core-Minimal"
            CORE_PACKAGES=(
                apt bash libbz2 coreutils libcurl diffutils findutils gzip 
                termux-core termux-exec termux-keyring termux-tools util-linux 
                liblzma
            )
            break
            ;;
        *)
            echo "[!] Invalid selection. Please enter 1 or 2."
            echo ""
            ;;
    esac
done

echo "[*] Using Package Name: $CUSTOM_PKG_NAME"
echo "[*] Ensuring scripts/properties.sh is in sync..."
sed -i "s/^TERMUX_APP__PACKAGE_NAME=.*/TERMUX_APP__PACKAGE_NAME=\"$CUSTOM_PKG_NAME\"/" scripts/properties.sh

echo "[*] Updating system and installing dependencies..."
sudo apt update -y
sudo apt install -y apt-utils

echo "[*] Starting build of CORE_PACKAGES..."
for pkg in "${CORE_PACKAGES[@]}"; do
    echo "[>] Building $pkg..."
    ./build-package.sh -a "$ARCH" "$pkg"
done

echo "[*] Step 3 Complete. Core packages built in output/ directory."
echo "[*] If you need to build OpenJDK or other custom packages, run ./3.1_Build_Custom_Packages.sh"
