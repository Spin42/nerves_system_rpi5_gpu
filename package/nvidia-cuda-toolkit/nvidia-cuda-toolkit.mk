################################################################################
#
# nvidia-cuda-toolkit
#
################################################################################

NVIDIA_CUDA_TOOLKIT_VERSION = 12.9.0
NVIDIA_CUDA_TOOLKIT_DRIVER_VERSION = 575.51.03
NVIDIA_CUDA_TOOLKIT_SOURCE = cuda_$(NVIDIA_CUDA_TOOLKIT_VERSION)_$(NVIDIA_CUDA_TOOLKIT_DRIVER_VERSION)_linux_sbsa.run
NVIDIA_CUDA_TOOLKIT_SITE = https://developer.download.nvidia.com/compute/cuda/$(NVIDIA_CUDA_TOOLKIT_VERSION)/local_installers
NVIDIA_CUDA_TOOLKIT_LICENSE = NVIDIA-CUDA-EULA

NVIDIA_CUDA_TOOLKIT_DEPENDENCIES = nvidia-driver-aarch64 nvidia-open-gpu-modules-aarch64

# Don't try to extract automatically - it's a self-extracting archive
# Use --tar to extract the embedded archive without running the installer
define NVIDIA_CUDA_TOOLKIT_EXTRACT_CMDS
	mkdir -p $(@D)/extracted
	chmod +x $(NVIDIA_CUDA_TOOLKIT_DL_DIR)/$(NVIDIA_CUDA_TOOLKIT_SOURCE)
	$(NVIDIA_CUDA_TOOLKIT_DL_DIR)/$(NVIDIA_CUDA_TOOLKIT_SOURCE) \
		--tar -xf \
		--directory $(@D)/extracted
endef

define NVIDIA_CUDA_TOOLKIT_INSTALL_TARGET_CMDS
	# ============================================================================
	# nvidia-cuda-toolkit (12.9.0) - CUDA Runtime Libraries & Tools
	# ============================================================================
	# Create CUDA directories
	mkdir -p $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit
	mkdir -p $(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/lib64
	mkdir -p $(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include
	mkdir -p $(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/bin

	# Install libraries and headers from each component in builds/
	# ---- cuda_cudart - CUDA runtime (libcudart.so, libcudart_static.a)
	if [ -d "$(@D)/extracted/builds/cuda_cudart/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/cuda_cudart/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		cp -a $(@D)/extracted/builds/cuda_cudart/targets/sbsa-linux/lib/*.a \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/cuda_cudart/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/cuda_cudart/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libcublas - Basic Linear Algebra (libcublas.so, libcublasLt.so) [681 MB]
	if [ -d "$(@D)/extracted/builds/libcublas/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libcublas/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libcublas*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libcublas/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libcublas/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libcufft - Fast Fourier Transform (libcufft.so) [257 MB]
	if [ -d "$(@D)/extracted/builds/libcufft/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libcufft/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libcufft*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libcufft/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libcufft/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libcurand - Random Number Generation (libcurand.so) [155 MB]
	if [ -d "$(@D)/extracted/builds/libcurand/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libcurand/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libcurand*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libcurand/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libcurand/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libcusparse - Sparse Matrix Operations (libcusparse.so) [460 MB]
	if [ -d "$(@D)/extracted/builds/libcusparse/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libcusparse/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libcusparse*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libcusparse/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libcusparse/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libcusolver - Linear Solvers (libcusolver.so, libcusolverMg.so) [274 MB + 160 MB]
	if [ -d "$(@D)/extracted/builds/libcusolver/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libcusolver/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libcusolver*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libcusolver/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libcusolver/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libnpp - NVIDIA Performance Primitives (libnpp*.so) [102 MB + 97 MB + 67 MB + 67 MB]
	if [ -d "$(@D)/extracted/builds/libnpp/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libnpp/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libnpp*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libnpp/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libnpp/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- cuda_nvrtc - Runtime Compilation (libnvrtc.so) [97 MB]
	if [ -d "$(@D)/extracted/builds/cuda_nvrtc/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/cuda_nvrtc/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libnvrtc*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/cuda_nvrtc/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/cuda_nvrtc/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- libnvjitlink - JIT Linker (libnvJitLink.so) [88 MB]
	if [ -d "$(@D)/extracted/builds/libnvjitlink/targets/sbsa-linux/lib" ]; then \
		cp -a $(@D)/extracted/builds/libnvjitlink/targets/sbsa-linux/lib/*.so* \
			$(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/ 2>/dev/null || true; \
		for lib in $(TARGET_DIR)/usr/lib/nvidia-cuda-toolkit/libnvJitLink*.so*; do \
			ln -sf nvidia-cuda-toolkit/$$(basename $$lib) $(TARGET_DIR)/usr/lib/$$(basename $$lib) 2>/dev/null || true; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/libnvjitlink/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/libnvjitlink/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- cuda_cccl - C++ Core Compute Libraries (headers only)
	if [ -d "$(@D)/extracted/builds/cuda_cccl/targets/sbsa-linux/include" ]; then \
		cp -a $(@D)/extracted/builds/cuda_cccl/targets/sbsa-linux/include/* \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/include/ 2>/dev/null || true; \
	fi

	# ---- cuda_nvcc - Compiler Binaries (nvcc, ptxas, fatbinary, cicc, cudafe++)
	if [ -d "$(@D)/extracted/builds/cuda_nvcc/bin" ]; then \
		for bin in nvcc ptxas fatbinary cicc cudafe++; do \
			if [ -f "$(@D)/extracted/builds/cuda_nvcc/bin/$$bin" ]; then \
				$(INSTALL) -D -m 0755 "$(@D)/extracted/builds/cuda_nvcc/bin/$$bin" \
					$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/bin/$$bin; \
			fi; \
		done; \
	fi
	if [ -d "$(@D)/extracted/builds/cuda_nvcc/nvvm" ]; then \
		cp -a $(@D)/extracted/builds/cuda_nvcc/nvvm \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/; \
	fi

	# ---- cuda_cuobjdump - Binary Tools
	if [ -f "$(@D)/extracted/builds/cuda_cuobjdump/bin/cuobjdump" ]; then \
		$(INSTALL) -D -m 0755 "$(@D)/extracted/builds/cuda_cuobjdump/bin/cuobjdump" \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/bin/cuobjdump; \
	fi

	# ---- cuda_nvdisasm - Disassembler
	if [ -f "$(@D)/extracted/builds/cuda_nvdisasm/bin/nvdisasm" ]; then \
		$(INSTALL) -D -m 0755 "$(@D)/extracted/builds/cuda_nvdisasm/bin/nvdisasm" \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/bin/nvdisasm; \
	fi

	# ---- cuda_nvprune - Kernel Pruning Tool
	if [ -f "$(@D)/extracted/builds/cuda_nvprune/bin/nvprune" ]; then \
		$(INSTALL) -D -m 0755 "$(@D)/extracted/builds/cuda_nvprune/bin/nvprune" \
			$(TARGET_DIR)/usr/local/cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION)/bin/nvprune; \
	fi

	# Create cuda symlink (remove if exists to avoid circular link)
	rm -f $(TARGET_DIR)/usr/local/cuda
	ln -sf cuda-$(NVIDIA_CUDA_TOOLKIT_VERSION) $(TARGET_DIR)/usr/local/cuda

	# Add CUDA to path via profile.d
	mkdir -p $(TARGET_DIR)/etc/profile.d
	echo 'export PATH=/usr/local/cuda/bin:$$PATH' > $(TARGET_DIR)/etc/profile.d/cuda.sh
	echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$$LD_LIBRARY_PATH' >> $(TARGET_DIR)/etc/profile.d/cuda.sh
	chmod 0755 $(TARGET_DIR)/etc/profile.d/cuda.sh
endef

$(eval $(generic-package))

