#!/usr/bin/env bash
# step2_generate_bootstrap.sh

set -e

ARCH="aarch64"
REPO_DIR="repo"
ADDITIONAL_PKGS="openjdk-17,openjdk-21,openjdk-25"
REQUIRED_PKGS=(
    apt
    bash
    bzip2
    coreutils
    curl
    dash
    diffutils
    findutils
    gawk
    grep
    gzip
    less
    procps
    psmisc
    sed
    tar
    termux-core
    termux-exec
    termux-keyring
    termux-tools
    util-linux
    xz-utils
)

for cmd in apt-ftparchive awk gzip sed sort xargs; do
    if ! command -v "$cmd" >/dev/null; then
        echo "[!] Required host utility '$cmd' is not available in PATH."
        exit 1
    fi
done

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

SELECTED_ADDITIONAL_PKGS=()
for pkg in ${ADDITIONAL_PKGS//,/ }; do
    if awk -v pkg="$pkg" '
        BEGIN { RS = ""; FS = "\n"; found = 0 }
        {
            for (i = 1; i <= NF; i++) {
                if ($i == "Package: " pkg) {
                    found = 1;
                    exit;
                }
            }
        }
        END { exit(found ? 0 : 1) }
    ' "$REPO_DIR/dists/stable/main/binary-$ARCH/Packages"; then
        SELECTED_ADDITIONAL_PKGS+=("$pkg")
    else
        echo "[!] Skipping requested additional package $pkg (not found)"
    fi
done

echo "[*] Checking bootstrap dependency closure..."
missing_required=$(
    awk -v roots="${REQUIRED_PKGS[*]} ${SELECTED_ADDITIONAL_PKGS[*]}" '
        BEGIN {
            RS = "";
            FS = "\n";
            split(roots, root_list, /[[:space:]]+/);
            for (i in root_list) {
                if (root_list[i] != "") {
                    needed[root_list[i]] = 1;
                }
            }
        }
        {
            pkg = "";
            dep_line = "";
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^Package: /) {
                    pkg = $i;
                    sub(/^Package: /, "", pkg);
                } else if ($i ~ /^Depends: /) {
                    dep_line = $i;
                    sub(/^Depends: /, "", dep_line);
                }
            }
            if (pkg != "") {
                available[pkg] = 1;
                deps[pkg] = dep_line;
            }
        }
        END {
            changed = 1;
            while (changed) {
                changed = 0;
                for (pkg in needed) {
                    if (!available[pkg] || seen[pkg]) {
                        continue;
                    }
                    seen[pkg] = 1;
                    count = split(deps[pkg], dep_list, /,/);
                    for (i = 1; i <= count; i++) {
                        dep = dep_list[i];
                        sub(/^[[:space:]]+/, "", dep);
                        sub(/[[:space:]]+$/, "", dep);
                        sub(/[[:space:]]*[(].*/, "", dep);
                        sub(/[[:space:]]*[|].*/, "", dep);
                        if (dep != "" && !needed[dep]) {
                            needed[dep] = 1;
                            changed = 1;
                        }
                    }
                }
            }
            for (pkg in needed) {
                if (!available[pkg]) {
                    print pkg;
                }
            }
        }
    ' "$REPO_DIR/dists/stable/main/binary-$ARCH/Packages" | sort
)

if [ -n "$missing_required" ]; then
    echo "[!] Missing packages required for this bootstrap:"
    echo "$missing_required" | sed 's/^/    /'
    echo "[!] Build them first, for example:"
    echo "    ./build-package.sh -a $ARCH $(echo "$missing_required" | xargs)"
    exit 1
fi

echo "[*] Generating bootstrap ZIP..."
REPO_PATH=$(realpath "$REPO_DIR")

# --- Patch the bootstrap generator to make "Additional" packages optional ---
# This allows minimal/custom builds to succeed even if ed, nano, etc. are missing.
echo "[*] Patching generate-bootstraps.sh to allow skipping missing additional packages..."
# Using [[:space:]]* to handle varying indentation (like debianutils inside an if-block)
sed -i 's/^[[:space:]]*pull_package \(ed\|debianutils\|dos2unix\|inetutils\|lsof\|nano\|net-tools\|patch\|unzip\)/	[ -n "${PACKAGE_METADATA[\1]}" ] \&\& pull_package \1 || echo "[!] Skipping optional package \1 (not found)"/' ./scripts/generate-bootstraps.sh
sed -i 's/^[[:space:]]*pull_package command-not-found/	[ -n "${PACKAGE_METADATA[command-not-found]}" ] \&\& pull_package command-not-found || echo "[!] Skipping optional package command-not-found (not found)"/' ./scripts/generate-bootstraps.sh

BOOTSTRAP_ARGS=(
    --architectures "$ARCH"
    --repository "file://$REPO_PATH"
)
if [ "${#SELECTED_ADDITIONAL_PKGS[@]}" -ne 0 ]; then
    BOOTSTRAP_ARGS+=(--add "$(IFS=,; echo "${SELECTED_ADDITIONAL_PKGS[*]}")")
fi

./scripts/generate-bootstraps.sh "${BOOTSTRAP_ARGS[@]}"

echo "[*] Step 2 Complete. Bootstrap archive created."
ls -l bootstrap-*.zip
