#!/usr/bin/env bash
# step2_generate_bootstrap.sh

set -e

ARCH="aarch64"
REPO_DIR="repo"
ADDITIONAL_PKGS="openjdk-17,openjdk-21,openjdk-25"

echo "[*] Preparing local repository structure..."
mkdir -p "$REPO_DIR/dists/stable/main/binary-$ARCH"

echo "[*] Copying .deb files to repository..."
# Ensure we only copy files that match the architecture or 'all'
cp output/*_${ARCH}.deb "$REPO_DIR/dists/stable/main/binary-$ARCH/" 2>/dev/null || true
cp output/*_all.deb "$REPO_DIR/dists/stable/main/binary-$ARCH/" 2>/dev/null || true

echo "[*] Indexing repository..."
cd "$REPO_DIR"
# Generate Packages index relative to current dir
apt-ftparchive packages . > "dists/stable/main/binary-$ARCH/Packages"
gzip -c "dists/stable/main/binary-$ARCH/Packages" > "dists/stable/main/binary-$ARCH/Packages.gz"
cd ..

echo "[*] Generating bootstrap ZIP..."
REPO_PATH=$(realpath "$REPO_DIR")

./scripts/generate-bootstraps.sh \
    --architectures "$ARCH" \
    --repository "file://$REPO_PATH" \
    --add "$ADDITIONAL_PKGS"

echo "[*] Step 2 Complete. Bootstrap archive created."
ls -l bootstrap-*.zip
