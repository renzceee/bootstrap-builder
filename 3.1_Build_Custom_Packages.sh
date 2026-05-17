#!/usr/bin/env bash
# 3.1_Build_Custom_Packages.sh

set -e

# --- Configuration ---
CUSTOM_PKG_NAME=$(grep "^TERMUX_APP__PACKAGE_NAME=" scripts/properties.sh | cut -d'"' -f2)
ARCH="aarch64"

echo "--- Custom Package Builder ---"
read -p "Enter space-separated packages to build (e.g., git vim openjdk-17): " MANUAL_PKGS
PKGS_TO_BUILD=($MANUAL_PKGS)

if [ ${#PKGS_TO_BUILD[@]} -eq 0 ]; then
    echo "[!] No packages specified. Exiting."
    exit 0
fi

# --- Apply OpenJDK Fixes if detected in the list ---
for pkg in "${PKGS_TO_BUILD[@]}"; do
    if [[ $pkg == openjdk-* ]]; then
        BUILD_SH="packages/$pkg/build.sh"
        if [ -f "$BUILD_SH" ]; then
            echo "[*] Applying JVM feature fix for $pkg"
            sed -i 's/__jvm_features="-link-time-opt"/__jvm_features=""/g' "$BUILD_SH"
        fi
    fi
done

echo "[*] Starting build..."
for pkg in "${PKGS_TO_BUILD[@]}"; do
    if [ -d "packages/$pkg" ]; then
        echo "[>] Building $pkg..."
        ./build-package.sh -a "$ARCH" "$pkg"
    else
        echo "[!] Skipping $pkg: Directory packages/$pkg not found."
    fi
done

echo "[*] Step 3.1 Complete."
