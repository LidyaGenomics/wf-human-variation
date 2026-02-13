#!/bin/bash
# Mirror ONT pipeline images from Docker Hub to Huawei SWR
# Uses crane for reliable registry-to-registry copy (no Docker daemon quirks).
#
# Prerequisites:
#   docker login swr.tr-west-1.myhuaweicloud.com -u <org>@<ak> -p <login_key>
#   (crane reads credentials from ~/.docker/config.json)
#
# Usage:
#   bash mirror_images_to_swr.sh

set -euo pipefail

SWR_REGISTRY="swr.tr-west-1.myhuaweicloud.com/lidyagenomics"

# Install crane if not present
if ! command -v crane &>/dev/null; then
    echo "Installing crane..."
    curl -sL "https://github.com/google/go-containerregistry/releases/latest/download/go-containerregistry_Linux_x86_64.tar.gz" | tar -xz -C /tmp crane
    CRANE="/tmp/crane"
else
    CRANE="crane"
fi

# Image name -> tag mappings from base.config
declare -A IMAGES=(
    ["ontresearch/wf-human-variation"]="sha8ecee6d351b0c2609b452f3a368c390587f6662d"
    ["ontresearch/wf-human-variation-snp"]="sha8cc7e88ff71bf593d7852309a31d3adb29a7caeb"
    ["ontresearch/wf-human-variation-sv"]="sha8134f9fef5e19605c7fb4c1348961d6771f1af79"
    ["ontresearch/modkit"]="sha489d708a48c66368e5d1e118538e5dca68203a64"
    ["ontresearch/wf-cnv"]="sha428cb19e51370020ccf29ec2af4eead44c6a17c2"
    ["ontresearch/wf-human-variation-str"]="shadd2f2963fe39351d4e0d6fa3ca54e1064c6ec057"
    ["ontresearch/spectre"]="sha42472d37a5a992c3ee27894a23dce5e2fff66d27"
    ["ontresearch/snpeff"]="sha367007eed5a09f992c2067f77776d9878806302a"
    ["ontresearch/wf-common"]="shafdd79f8e4a6faad77513c36f623693977b92b08e"
    ["ontresearch/longphase"]="sha4ff1cd9a6eee338a414082cb24f943bcc4ce8e7c"
)

for SOURCE_IMAGE in "${!IMAGES[@]}"; do
    TAG="${IMAGES[$SOURCE_IMAGE]}"
    IMAGE_NAME="${SOURCE_IMAGE#ontresearch/}"

    SOURCE="docker.io/${SOURCE_IMAGE}:${TAG}"
    TARGET="${SWR_REGISTRY}/${IMAGE_NAME}:${TAG}"

    echo "============================================"
    echo "Mirroring: ${SOURCE}"
    echo "       To: ${TARGET}"
    echo "============================================"

    # crane copies directly between registries, no local Docker daemon involved
    "${CRANE}" copy --platform linux/amd64 "${SOURCE}" "${TARGET}"

    echo "Done: ${IMAGE_NAME}"
    echo ""
done

echo "All images mirrored successfully!"
