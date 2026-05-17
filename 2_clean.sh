#!/usr/bin/env bash
# step0_clean_all.sh

echo "[*] Cleaning up previous build artifacts..."

# 1. Remove the build output directory (where .debs are stored)
if [ -d "output" ]; then
    echo "[>] Removing output/ directory..."
    rm -rf output
fi

# 2. Remove the local repository used for bootstrap generation
if [ -d "repo" ]; then
    echo "[>] Removing repo/ directory..."
    rm -rf repo
fi

# 3. Remove any generated bootstrap zip files
if ls bootstrap-*.zip 1> /dev/null 2>&1; then
    echo "[>] Removing bootstrap ZIP files..."
    rm bootstrap-*.zip
fi

# 4. Optional: Run the official Termux clean script if it exists
# This cleans up specific package build directories and src folders
if [ -f "./clean.sh" ]; then
    echo "[>] Running official ./clean.sh..."
    ./clean.sh
fi

# 5. Remove temporary files from previous bootstrap generation attempts
echo "[>] Cleaning /tmp for bootstrap-tmp folders..."
rm -rf /tmp/bootstrap-tmp.*

echo "[*] Cleanup complete. You are ready for a fresh Step 1."
