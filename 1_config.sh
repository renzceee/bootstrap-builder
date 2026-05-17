#!/usr/bin/env bash
# step_config.sh

# Function to validate package name format (e.g., com.example.termux)
validate_package_name() {
    local pkg_name=$1
    if [[ $pkg_name =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
        return 0
    else
        return 1
    fi
}

echo "--- Termux Customization Configurator ---"
echo "Current Package Name in properties.sh:"
grep "^TERMUX_APP__PACKAGE_NAME=" scripts/properties.sh || echo "Not found"

echo ""
read -p "Enter new package name (e.g., com.myname.termux): " NEW_PKG
echo ""

if validate_package_name "$NEW_PKG"; then
    echo "[*] Updating scripts/properties.sh with: $NEW_PKG"
    sed -i "s/^TERMUX_APP__PACKAGE_NAME=.*/TERMUX_APP__PACKAGE_NAME=\"$NEW_PKG\"/" scripts/properties.sh
    
    # Update 3_Build_Packages.sh to keep it in sync
    if [ -f "./3_Build_Packages.sh" ]; then
        echo "[*] Syncing new package name to 3_Build_Packages.sh..."
        sed -i "s/^CUSTOM_PKG_NAME=.*/CUSTOM_PKG_NAME=\"$NEW_PKG\"/" ./3_Build_Packages.sh
    fi
    
    echo "[V] Success! Package name updated."
else
    echo "[X] Error: '$NEW_PKG' is not a valid Android package name format."
    echo "Example of valid format: com.custom.termux"
    exit 1
fi
