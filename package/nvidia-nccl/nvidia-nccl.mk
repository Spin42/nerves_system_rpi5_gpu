################################################################################
#
# nvidia-nccl (NVIDIA Collective Communication Library)
#
################################################################################
# Uses pre-built NCCL from NVIDIA for aarch64

NVIDIA_NCCL_VERSION = 2.29.2
NVIDIA_NCCL_CUDA_VERSION = 12.9
NVIDIA_NCCL_SOURCE = nccl-linux-sbsa-$(NVIDIA_NCCL_VERSION)-archive.tar.xz
NVIDIA_NCCL_SITE = https://developer.download.nvidia.com/compute/nccl/redist/nccl/linux-sbsa
NVIDIA_NCCL_LICENSE = NVIDIA-NCCL-EULA
NVIDIA_NCCL_REDISTRIBUTE = YES

NVIDIA_NCCL_DEPENDENCIES = nvidia-driver-aarch64 nvidia-open-gpu-modules-aarch64

define NVIDIA_NCCL_EXTRACT_CMDS
	mkdir -p $(@D)/extracted
	tar xJf $(NVIDIA_NCCL_DL_DIR)/$(NVIDIA_NCCL_SOURCE) -C $(@D)/extracted --strip-components=1
endef

define NVIDIA_NCCL_INSTALL_TARGET_CMDS
	# ============================================================================
	# nvidia-nccl (2.29.2) - Collective Communication Library
	# ============================================================================
	# Libraries: libnccl.so.2.29.2 [349 MB]
	mkdir -p $(TARGET_DIR)/usr/lib/nvidia-nccl
	mkdir -p $(TARGET_DIR)/usr/include

	# Copy shared libraries to scoped directory
	if [ -d "$(@D)/extracted/lib" ]; then \
		cp -a $(@D)/extracted/lib/libnccl*.so* $(TARGET_DIR)/usr/lib/nvidia-nccl/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-nccl/*.so*; do \
			ln -sf nvidia-nccl/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi

	# Copy headers
	if [ -d "$(@D)/extracted/include" ]; then \
		cp -a $(@D)/extracted/include/nccl*.h $(TARGET_DIR)/usr/include/ 2>/dev/null || true; \
	fi
endef

$(eval $(generic-package))
