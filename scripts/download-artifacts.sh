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

RKE2_VERSION="${RKE2_VERSION:-v1.36.0+rke2r1}"
ARCH="${ARCH:-amd64}"
OUTPUT_DIR="${OUTPUT_DIR:-./rke2-artifacts}"
DOWNLOAD_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}"
INSTALL_SH_URL="https://get.rke2.io"

FILES=(
  "rke2.linux-${ARCH}.tar.gz"
  "rke2-images.linux-${ARCH}.tar.zst"
  "sha256sum-${ARCH}.txt"
)

echo "==> Downloading RKE2 ${RKE2_VERSION} (${ARCH}) artifacts..."
mkdir -p "${OUTPUT_DIR}"

retry_download() {
  local url="$1" dest="$2" file_label="$3"
  for ((i = 1; i <= 3; i++)); do
    if curl -fsSL --output "${dest}" "${url}"; then
      return 0
    fi
    if [[ $i -lt 3 ]]; then
      echo "  [retry]  Attempt ${i} failed for ${file_label}, retrying..."
    fi
  done
  echo "  [error]  Failed to download ${file_label} after 3 attempts"
  return 1
}

for FILE in "${FILES[@]}"; do
  DEST="${OUTPUT_DIR}/${FILE}"
  if [[ -f "${DEST}" ]]; then
    echo "  [skip]   ${FILE} (already exists)"
  else
    echo "  [fetch]  ${FILE}"
    retry_download "${DOWNLOAD_URL}/${FILE}" "${DEST}" "${FILE}"
  fi
done

INSTALL_SH_DEST="${OUTPUT_DIR}/install.sh"
if [[ -f "${INSTALL_SH_DEST}" ]]; then
  echo "  [skip]   install.sh (already exists)"
else
  echo "  [fetch]  install.sh (from get.rke2.io)"
  retry_download "${INSTALL_SH_URL}" "${INSTALL_SH_DEST}" "install.sh"
fi

echo ""
echo "==> Verifying checksums..."
pushd "${OUTPUT_DIR}" > /dev/null

for FILE in "rke2.linux-${ARCH}.tar.gz" "rke2-images.linux-${ARCH}.tar.zst"; do
  EXPECTED_LINE=$(grep -E "\s${FILE}$" "sha256sum-${ARCH}.txt")
  if [[ -z "${EXPECTED_LINE}" ]]; then
    echo "  [error]  Checksum entry not found for ${FILE}"
    exit 1
  fi

  EXPECTED_HASH=$(echo "${EXPECTED_LINE}" | awk '{print $1}')
  ACTUAL_HASH=$(sha256sum "${FILE}" | awk '{print $1}')

  if [[ "${ACTUAL_HASH}" != "${EXPECTED_HASH}" ]]; then
    echo "  [error]  Checksum MISMATCH for ${FILE}"
    echo "           expected: ${EXPECTED_HASH}"
    echo "           actual:   ${ACTUAL_HASH}"
    exit 1
  fi

  echo "  [ok] ${FILE}"
done

popd > /dev/null
echo "  [ok] Checksums verified"

echo ""
echo "==> Artifacts saved to: ${OUTPUT_DIR}"
echo "    Ansible will copy them to target nodes during installation."
