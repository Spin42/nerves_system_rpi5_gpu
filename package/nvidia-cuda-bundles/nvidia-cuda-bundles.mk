################################################################################
#
# nvidia-cuda-bundles
#
################################################################################

# Nothing to download: the libraries come from bundles built outside
# Buildroot (scripts/build-nvidia-bundles.sh) and installed on the device.
NVIDIA_CUDA_BUNDLES_VERSION = $(NVIDIA_STACK_CUDA_VERSION)
NVIDIA_CUDA_BUNDLES_SOURCE =
NVIDIA_CUDA_BUNDLES_LICENSE = NVIDIA-CUDA-EULA

# "<component> <bundle id>" lines; the bundle file is <id>-aarch64.squashfs
define NVIDIA_CUDA_BUNDLES_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc
	printf '%s\n' \
		'cuda nvidia-cuda-$(NVIDIA_STACK_CUDA_VERSION)' \
		'cudnn nvidia-cudnn-$(NVIDIA_STACK_CUDNN_VERSION)' \
		'nccl nvidia-nccl-$(NVIDIA_STACK_NCCL_VERSION)' \
		'nvshmem nvidia-nvshmem-$(NVIDIA_STACK_NVSHMEM_VERSION)' \
		> $(TARGET_DIR)/etc/nvidia-bundles
	mkdir -p $(TARGET_DIR)/opt/nvidia/cuda $(TARGET_DIR)/opt/nvidia/cudnn $(TARGET_DIR)/opt/nvidia/nccl $(TARGET_DIR)/opt/nvidia/nvshmem
	mkdir -p $(TARGET_DIR)/usr/local
	rm -rf $(TARGET_DIR)/usr/local/cuda
	ln -sfn /opt/nvidia/cuda $(TARGET_DIR)/usr/local/cuda
endef

$(eval $(generic-package))
