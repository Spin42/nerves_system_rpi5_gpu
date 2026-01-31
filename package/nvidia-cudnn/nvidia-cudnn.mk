################################################################################
#
# nvidia-cudnn (NVIDIA CUDA Deep Neural Network Library)
#
################################################################################
# Uses pre-built cuDNN from NVIDIA for aarch64

NVIDIA_CUDNN_VERSION = 9.18.1.3
NVIDIA_CUDNN_CUDA_VERSION = 12
NVIDIA_CUDNN_SOURCE = cudnn-linux-sbsa-$(NVIDIA_CUDNN_VERSION)_cuda$(NVIDIA_CUDNN_CUDA_VERSION)-archive.tar.xz
NVIDIA_CUDNN_SITE = https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-sbsa
NVIDIA_CUDNN_LICENSE = NVIDIA-cuDNN-EULA
NVIDIA_CUDNN_REDISTRIBUTE = YES

NVIDIA_CUDNN_DEPENDENCIES = nvidia-driver-aarch64 nvidia-open-gpu-modules-aarch64

define NVIDIA_CUDNN_EXTRACT_CMDS
	mkdir -p $(@D)/extracted
	tar xJf $(NVIDIA_CUDNN_DL_DIR)/$(NVIDIA_CUDNN_SOURCE) -C $(@D)/extracted --strip-components=1
endef

define NVIDIA_CUDNN_INSTALL_TARGET_CMDS
	# ============================================================================
	# nvidia-cudnn (9.18.1.3) - Deep Neural Network Library
	# ============================================================================
	# Libraries: libcudnn*.so* [468 MB + 100 MB + 51 MB + 26 MB + ...]
	mkdir -p $(TARGET_DIR)/usr/lib/nvidia-cudnn
	mkdir -p $(TARGET_DIR)/usr/include

	# Copy shared libraries to scoped directory
	if [ -d "$(@D)/extracted/lib" ]; then \
		cp -a $(@D)/extracted/lib/libcudnn*.so* $(TARGET_DIR)/usr/lib/nvidia-cudnn/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cudnn/*.so*; do \
			ln -sf nvidia-cudnn/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi

	# Copy headers
	if [ -d "$(@D)/extracted/include" ]; then \
		cp -a $(@D)/extracted/include/cudnn*.h $(TARGET_DIR)/usr/include/ 2>/dev/null || true; \
	fi

	# Create version symlinks if needed
	cd $(TARGET_DIR)/usr/lib && \
	for lib in libcudnn_adv.so libcudnn_cnn.so libcudnn_engines_precompiled.so \
	           libcudnn_engines_runtime_compiled.so libcudnn_graph.so \
	           libcudnn_heuristic.so libcudnn_ops.so libcudnn.so; do \
		if [ ! -e "$$lib" ]; then \
			target=$$(ls $${lib}.* 2>/dev/null | head -1); \
			if [ -n "$$target" ]; then \
				ln -sf $$(basename $$target) $$lib 2>/dev/null || true; \
			fi; \
		fi; \
	done
endef

$(eval $(generic-package))
