#!/usr/bin/env bash
# RKE2 Airgap Artifact Downloader
#
# Run on a machine with internet access.
# Ansible copies these artifacts to target nodes during prerequisites.
#
# Usage:
#   ./scripts/download-artifacts.sh
#   RKE2_VERSION=v1.31.5+rke2r1 ./scripts/download-artifacts.sh
set -euo pipefail

RKE2_VERSION="${RKE2_VERSION:-v1.31.4+rke2r1}"
ARCH="${ARCH:-amd64}"
OUTPUT_DIR="${OUTPUT_DIR:-./rke2-artifacts}"
DOWNLOAD_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}"

FILES=(
  "rke2.linux-${ARCH}.tar.gz"
  "rke2-images.linux-${ARCH}.tar.zst"
  "sha256sum-${ARCH}.txt"
  "install.sh"
)

echo "==> Downloading RKE2 ${RKE2_VERSION} (${ARCH}) artifacts..."
mkdir -p "${OUTPUT_DIR}"

for FILE in "${FILES[@]}"; do
  DEST="${OUTPUT_DIR}/${FILE}"
  if [[ -f "${DEST}" ]]; then
    echo "  [skip]   ${FILE} (already exists)"
  else
    echo "  [fetch]  ${FILE}"
    curl -fsSL --retry 3 --output "${DEST}" "${DOWNLOAD_URL}/${FILE}"
  fi
done

echo ""
echo "==> Verifying checksums..."
pushd "${OUTPUT_DIR}" > /dev/null

for FILE in "rke2.linux-${ARCH}.tar.gz" "rke2-images.linux-${ARCH}.tar.zst"; do
  grep "${FILE}" "sha256sum-${ARCH}.txt" | sha256sum --check --status
  echo "  [ok] ${FILE}"
done

popd > /dev/null
echo "  [ok] Checksums verified"

echo ""
echo "==> Artifacts saved to: ${OUTPUT_DIR}"
echo "    Ansible will copy them to target nodes during installation."
