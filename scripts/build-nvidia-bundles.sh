#!/usr/bin/env bash
#
# Build the NVIDIA CUDA toolkit, cuDNN, NCCL and NVSHMEM bundles for this system.
#
# Each bundle is a squashfs image of NVIDIA's prebuilt aarch64 (SBSA)
# libraries. They are installed on the device in /root/nvidia/ (see
# `mix nvidia.bundles.upload`) and mounted by nvidia-init on
# /opt/nvidia/<component>. Versions come from ../nvidia-versions.
#
# Usage: scripts/build-nvidia-bundles.sh [--with-devtools] [OUTPUT_DIR]
#
# --with-devtools adds ptxas and nvlink to the CUDA bundle. XLA (EXLA) needs
# them to compile GPU kernels. They are CUDA developer tools that NVIDIA's
# license only allows for your internal use: fine on your own devices, but a
# bundle built this way must not be distributed (published, shipped in
# products or shared images).
#
# OUTPUT_DIR defaults to $NERVES_DL_DIR/nvidia-bundles (~/.nerves/dl/...).
# NVIDIA downloads are cached in $NERVES_DL_DIR/<package>/, the same place
# Buildroot uses for the in-image packages.
#
# Needs: bash, curl, tar, xz, gzip, mksquashfs with zstd support.
#
# Licensing: the bundles only contain files NVIDIA lists as redistributable
# (CUDA EULA Attachment A, cuDNN runtime .so files, NVSHMEM; NCCL is
# BSD-3-Clause), and the CUDA/cuDNN/NVSHMEM licenses only allow
# redistributing them as part of your
# application, not as a stand-alone product. Build them from NVIDIA's
# downloads with this script and install them on your devices; don't publish
# them on their own.

set -euo pipefail

SYSTEM_DIR=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../nvidia-versions
. "$SYSTEM_DIR/nvidia-versions"

DL_DIR=${NERVES_DL_DIR:-$HOME/.nerves/dl}
WITH_DEVTOOLS=no
if [ "${1:-}" = "--with-devtools" ]; then
    WITH_DEVTOOLS=yes
    shift
fi
OUT_DIR=${1:-$DL_DIR/nvidia-bundles}
GITHUB_ASSET_LIMIT=2147483648

CUDA_RUN=cuda_${NVIDIA_STACK_CUDA_VERSION}_${NVIDIA_STACK_CUDA_DRIVER_VERSION}_linux_sbsa.run
CUDA_URL=https://developer.download.nvidia.com/compute/cuda/$NVIDIA_STACK_CUDA_VERSION/local_installers/$CUDA_RUN
CUDNN_TAR=cudnn-linux-sbsa-${NVIDIA_STACK_CUDNN_VERSION}_cuda${NVIDIA_STACK_CUDNN_CUDA_VERSION}-archive.tar.xz
CUDNN_URL=https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-sbsa/$CUDNN_TAR
NCCL_TAR=nccl-linux-sbsa-${NVIDIA_STACK_NCCL_VERSION}-archive.tar.xz
NCCL_URL=https://developer.download.nvidia.com/compute/nccl/redist/nccl/linux-sbsa/$NCCL_TAR
NVSHMEM_TAR=libnvshmem-linux-sbsa-${NVIDIA_STACK_NVSHMEM_VERSION}_cuda12-archive.tar.xz
NVSHMEM_URL=https://developer.download.nvidia.com/compute/nvshmem/redist/libnvshmem/linux-sbsa/$NVSHMEM_TAR

log() { printf '\033[1m==> %s\033[0m\n' "$*"; }

if ! mksquashfs -help-comp zstd >/dev/null 2>&1; then
    echo "mksquashfs with zstd support is required" >&2
    exit 1
fi

# Extraction needs several GB: work next to the download cache, not in /tmp.
mkdir -p "$DL_DIR"
WORK=$(mktemp -d "$DL_DIR/.nvidia-bundles-work.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT_DIR"

# fetch <package> <file> <url>: path of the cached download
fetch() {
    local path=$DL_DIR/$1/$2
    if [ ! -f "$path" ]; then
        log "Downloading $2"
        mkdir -p "$DL_DIR/$1"
        curl -fL --retry 3 -o "$path.partial" "$3"
        mv "$path.partial" "$path"
    fi
    echo "$path"
}

# prune <lib dir>: keep the same libraries as the in-image build. The
# cleanup script applies its keep-list to scoped usr/lib/nvidia-* directories.
prune() {
    mkdir -p "$WORK/prune/usr/lib"
    ln -sfn "$1" "$WORK/prune/usr/lib/nvidia-bundle"
    "$SYSTEM_DIR/post-build-nvidia-cleanup.sh" "$WORK/prune" >/dev/null
    rm -rf "$WORK/prune"
}

# copy_libs <src lib dir> <dest lib dir>
copy_libs() {
    [ -d "$1" ] || return 0
    cp -a "$1"/*.so* "$2"/ 2>/dev/null || true
}

# finish <component> <id> <staging dir> <source file...>
finish() {
    local component=$1 id=$2 dir=$3
    shift 3
    local image=$OUT_DIR/$id-aarch64.squashfs

    {
        echo "id=$id"
        echo "component=$component"
        echo "cuda=$NVIDIA_STACK_CUDA_VERSION"
        echo "cudnn=$NVIDIA_STACK_CUDNN_VERSION"
        echo "nccl=$NVIDIA_STACK_NCCL_VERSION"
        echo "nvshmem=$NVIDIA_STACK_NVSHMEM_VERSION"
        [ "$component" = cuda ] && echo "devtools=$WITH_DEVTOOLS"
        for src in "$@"; do
            echo "source=$(basename "$src") sha256=$(sha256sum "$src" | cut -d' ' -f1)"
        done
    } > "$dir/NVIDIA_BUNDLE"

    log "Creating $(basename "$image")"
    rm -f "$image"
    mksquashfs "$dir" "$image" -comp zstd -Xcompression-level 19 -b 1M \
        -all-root -no-xattrs -mkfs-time 0 -all-time 0 -noappend -quiet -no-progress
    (cd "$OUT_DIR" && sha256sum "$(basename "$image")" > "$(basename "$image").sha256")

    local size
    size=$(stat -c %s "$image")
    echo "    $(numfmt --to=iec "$size")  $image"
    if [ "$size" -ge "$GITHUB_ASSET_LIMIT" ]; then
        echo "    WARNING: larger than a GitHub release asset allows (2 GiB)" >&2
    fi
}

build_cuda() {
    local id=nvidia-cuda-$NVIDIA_STACK_CUDA_VERSION
    local run src=$WORK/cuda-src dir=$WORK/cuda
    run=$(fetch nvidia-cuda-toolkit "$CUDA_RUN" "$CUDA_URL")

    log "Extracting $CUDA_RUN"
    mkdir -p "$src" "$dir/lib" "$dir/nvvm/lib64" "$dir/nvvm/libdevice"
    sh "$run" --tar -xf --directory "$src"

    # Runtime libraries only: compilers and other developer tools (nvcc,
    # ptxas, cicc, ...) and headers are not redistributable (CUDA EULA 1.1.2),
    # except with --with-devtools (see the usage notes above).
    local b=$src/builds
    for c in cuda_cudart libcublas libcufft libcurand libcusparse libcusolver libnpp cuda_nvrtc libnvjitlink; do
        copy_libs "$b/$c/targets/sbsa-linux/lib" "$dir/lib"
    done
    # libnvvm and libdevice are redistributable (Attachment A); XLA uses them
    # to compile kernels.
    cp -a "$b/cuda_nvcc/nvvm/lib64"/libnvvm.so* "$dir/nvvm/lib64"/
    cp -a "$b/cuda_nvcc/nvvm/libdevice/libdevice.10.bc" "$dir/nvvm/libdevice"/
    find "$src" -maxdepth 2 -name EULA.txt -exec cp {} "$dir/" \; -quit
    ln -s lib "$dir/lib64"

    if [ "$WITH_DEVTOOLS" = yes ]; then
        log "Adding ptxas and nvlink (internal use only, do not distribute this bundle)"
        mkdir -p "$dir/bin"
        install -m 0755 "$b/cuda_nvcc/bin/ptxas" "$b/cuda_nvcc/bin/nvlink" "$dir/bin/"
        cat > "$dir/DEVTOOLS-NOT-REDISTRIBUTABLE" <<'NOTICE'
This bundle contains bin/ptxas and bin/nvlink, CUDA developer tools that the
NVIDIA CUDA EULA (EULA.txt, section 1.1.2) only allows for internal use.
Use it on your own devices; do not publish or distribute it.
NOTICE
    fi

    prune "$dir/lib"
    finish cuda "$id" "$dir" "$run"
}

# build_redist <component> <id> <package> <tarball> <url> <prune|noprune> <lib glob...>
build_redist() {
    local component=$1 id=$2 name=$4 prune_mode=$6 tarball
    local src=$WORK/$component-src dir=$WORK/$component
    tarball=$(fetch "$3" "$4" "$5")
    shift 6

    log "Extracting $name"
    mkdir -p "$src" "$dir/lib"
    tar xJf "$tarball" -C "$src" --strip-components=1
    for glob in "$@"; do
        cp -a "$src"/lib/$glob "$dir/lib"/
    done
    cp "$src/LICENSE"* "$dir/" 2>/dev/null || true

    [ "$prune_mode" = prune ] && prune "$dir/lib"
    finish "$component" "$id" "$dir" "$tarball"
}

build_cuda
build_redist cudnn "nvidia-cudnn-$NVIDIA_STACK_CUDNN_VERSION" nvidia-cudnn "$CUDNN_TAR" "$CUDNN_URL" \
    prune 'libcudnn*.so*'
build_redist nccl "nvidia-nccl-$NVIDIA_STACK_NCCL_VERSION" nvidia-nccl "$NCCL_TAR" "$NCCL_URL" \
    prune 'libnccl*.so*'
# Only the host library and the bootstrap/transport plugins XLA links; the
# others need MPI, UCX, libfabric, ... which this system doesn't have.
build_redist nvshmem "nvidia-nvshmem-$NVIDIA_STACK_NVSHMEM_VERSION" nvidia-nvshmem "$NVSHMEM_TAR" "$NVSHMEM_URL" \
    noprune 'libnvshmem_host.so*' 'nvshmem_bootstrap_uid.so*' 'nvshmem_transport_ibrc.so*'

log "Bundles in $OUT_DIR"
