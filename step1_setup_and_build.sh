#!/usr/bin/env bash
# step1_setup_and_build.sh

set -e

# --- Configuration ---
CUSTOM_PKG_NAME="com.yourname.termux"
ARCH="aarch64"
CORE_PACKAGES=(
    apt bash bzip2 command-not-found coreutils curl dash diffutils 
    findutils gawk grep gzip less procps psmisc sed tar termux-core 
    termux-exec termux-keyring termux-tools util-linux xz-utils ed 
    debianutils dos2unix inetutils lsof nano net-tools patch unzip
)
JDK_VERSIONS=("17" "21" "25")

echo "[*] Updating properties.sh with custom package name: $CUSTOM_PKG_NAME"
sed -i "s/^TERMUX_APP__PACKAGE_NAME=.*/TERMUX_APP__PACKAGE_NAME=\"$CUSTOM_PKG_NAME\"/" scripts/properties.sh

echo "[*] Updating system and installing dependencies..."
sudo apt update -y
sudo apt install -y apt-utils

# --- OpenJDK Fixes ---
for ver in "${JDK_VERSIONS[@]}"; do
    if [ -d "packages/openjdk-$ver" ]; then
        echo "[*] Applying JVM feature fix for openjdk-$ver"
        # Opt out of link-time-opt if it exists
        sed -i 's/__jvm_features="-link-time-opt"/__jvm_features=""/g' packages/openjdk-$ver/build.sh
    fi
done

echo "[*] Starting build of CORE_PACKAGES..."
for pkg in "${CORE_PACKAGES[@]}"; do
    echo "[>] Building $pkg..."
    ./build-package.sh -a "$ARCH" "$pkg"
done

echo "[*] Starting build of OpenJDK versions..."
for ver in "${JDK_VERSIONS[@]}"; do
    pkg="openjdk-$ver"
    if [ -d "packages/$pkg" ]; then
        echo "[>] Building $pkg..."
        ./build-package.sh -a "$ARCH" "$pkg"
    else
        echo "[!] Skipping $pkg: Directory packages/$pkg not found."
    fi
done

echo "[*] Step 1 Complete. All packages built in output/ directory."
