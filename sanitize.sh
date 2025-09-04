#!/bin/bash
# ============================================
# Jellyfin Kubernetes Sanitization Script
# ============================================
# Generates a public-safe version of this folder
# ============================================

PRIVATE_DIR="$(pwd)"
PUBLIC_DIR="${PRIVATE_DIR}-public"

echo "==> Cleaning old public folder..."
rm -rf "$PUBLIC_DIR"
mkdir -p "$PUBLIC_DIR"

echo "==> Copying original files..."
# Copy everything except the .git folder
rsync -av \
  --exclude '.git/' \
  "$PRIVATE_DIR/" "$PUBLIC_DIR/"

# --------------------------------------------
# STEP 1: Sanitize OCI volumeHandle
# --------------------------------------------
echo "==> Sanitizing volumeHandle values..."
find "$PUBLIC_DIR" -type f -name "*.yaml" -exec \
  sed -i 's/volumeHandle: .*/volumeHandle: <REPLACE_WITH_YOUR_VOLUME_HANDLE>/' {} \;

# --------------------------------------------
# STEP 2: Sanitize DuckDNS domains
# --------------------------------------------
echo "==> Sanitizing DuckDNS domain names..."
find "$PUBLIC_DIR" -type f -name "*.yaml" -exec \
  sed -i 's/[a-zA-Z0-9.-]*\.duckdns\.org/<YOUR_DOMAIN>/g' {} \;

# --------------------------------------------
# STEP 3: Remove sensitive cluster issuer
# --------------------------------------------
if [ -f "$PUBLIC_DIR/cluster-issuer.yaml" ]; then
  echo "==> Removing cluster-issuer.yaml..."
  rm "$PUBLIC_DIR/cluster-issuer.yaml"
fi

# --------------------------------------------
# STEP 4: Verify sanitization
# --------------------------------------------
echo "==> Scanning for sensitive values..."
if grep -R "duckdns.org" "$PUBLIC_DIR"; then
  echo "WARNING: Found uncleaned duckdns.org domains!"
fi
if grep -R "ocid1.filesystem" "$PUBLIC_DIR"; then
  echo "WARNING: Found uncleaned OCI filesystem IDs!"
fi
if grep -R "10\.0\." "$PUBLIC_DIR"; then
  echo "WARNING: Found private IP addresses!"
fi

echo "==> Sanitized files ready at: $PUBLIC_DIR"
