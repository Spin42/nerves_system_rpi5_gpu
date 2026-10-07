################################################################################
#
# nvidia-driver-aarch64
#
################################################################################
NVIDIA_DRIVER_AARCH64_VERSION = 580.95.05
NVIDIA_DRIVER_AARCH64_SOURCE = NVIDIA-Linux-aarch64-$(NVIDIA_DRIVER_AARCH64_VERSION).run
NVIDIA_DRIVER_AARCH64_SITE = https://us.download.nvidia.com/XFree86/aarch64/$(NVIDIA_DRIVER_AARCH64_VERSION)
NVIDIA_DRIVER_AARCH64_LICENSE = NVIDIA Proprietary

# This package is the libopencl provider, so packages using OpenCL (e.g.
# clinfo) depend on it. Pull in the Khronos ICD loader so libOpenCL and the
# CL headers are in staging before they build.
ifeq ($(BR2_PACKAGE_OPENCL_ICD_LOADER),y)
NVIDIA_DRIVER_AARCH64_DEPENDENCIES += opencl-icd-loader
endif

# Don't try to extract automatically - it's a self-extracting archive.
# The installer decompresses with `zstd` from PATH and otherwise falls back to
# its bundled zstd, which is an aarch64 binary and can't run on the build host.
NVIDIA_DRIVER_AARCH64_EXTRACT_DEPENDENCIES = host-python3 host-zstd

define NVIDIA_DRIVER_AARCH64_EXTRACT_CMDS
    rm -rf $(@D)/extracted
    chmod +x $(NVIDIA_DRIVER_AARCH64_DL_DIR)/$(NVIDIA_DRIVER_AARCH64_SOURCE)
    PATH=$(BR_PATH) $(NVIDIA_DRIVER_AARCH64_DL_DIR)/$(NVIDIA_DRIVER_AARCH64_SOURCE) \
        --extract-only \
        --target $(@D)/extracted
endef

define NVIDIA_DRIVER_AARCH64_INSTALL_TARGET_CMDS
    # ============================================================================
    # nvidia-driver-aarch64 (580.95.05) - NVIDIA Userspace Driver Libraries
    # ============================================================================
    mkdir -p $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64
    
    # Core libraries
    $(INSTALL) -D -m 0755 $(@D)/extracted/libnvidia-ml.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/libnvidia-ml.so.$(NVIDIA_DRIVER_AARCH64_VERSION)
    ln -sf nvidia-driver-aarch64/libnvidia-ml.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libnvidia-ml.so.1
    ln -sf libnvidia-ml.so.1 \
        $(TARGET_DIR)/usr/lib/libnvidia-ml.so

    $(INSTALL) -D -m 0755 $(@D)/extracted/libcuda.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/libcuda.so.$(NVIDIA_DRIVER_AARCH64_VERSION)
    ln -sf nvidia-driver-aarch64/libcuda.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libcuda.so.1
    ln -sf libcuda.so.1 \
        $(TARGET_DIR)/usr/lib/libcuda.so

    $(INSTALL) -D -m 0755 $(@D)/extracted/libnvcuvid.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/libnvcuvid.so.$(NVIDIA_DRIVER_AARCH64_VERSION)
    ln -sf nvidia-driver-aarch64/libnvcuvid.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libnvcuvid.so.1
    ln -sf libnvcuvid.so.1 \
        $(TARGET_DIR)/usr/lib/libnvcuvid.so

    # Additional NVIDIA libraries
    for lib in $(@D)/extracted/libnvidia-*.so.$(NVIDIA_DRIVER_AARCH64_VERSION); do \
        $(INSTALL) -D -m 0755 $$lib $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/$$(basename $$lib); \
    done

    # Libraries dlopen'ed by SONAME (OpenCL compiler, CUDA PTX JIT)
    ln -sf nvidia-driver-aarch64/libnvidia-ptxjitcompiler.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libnvidia-ptxjitcompiler.so.1
    ln -sf nvidia-driver-aarch64/libnvidia-nvvm.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libnvidia-nvvm.so.4
    ln -sf nvidia-driver-aarch64/libnvidia-gpucomp.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
        $(TARGET_DIR)/usr/lib/libnvidia-gpucomp.so.$(NVIDIA_DRIVER_AARCH64_VERSION)

    # nvidia-smi and other tools
    $(INSTALL) -D -m 0755 $(@D)/extracted/nvidia-smi \
        $(TARGET_DIR)/usr/bin/nvidia-smi

    # Firmware
    mkdir -p $(TARGET_DIR)/lib/firmware/nvidia/$(NVIDIA_DRIVER_AARCH64_VERSION)
    cp -r $(@D)/extracted/firmware/* \
        $(TARGET_DIR)/lib/firmware/nvidia/$(NVIDIA_DRIVER_AARCH64_VERSION)/ || true

    # OpenCL ICD loader and NVIDIA OpenCL implementation
    if [ -f "$(@D)/extracted/libOpenCL.so.1.0.0" ]; then \
        $(INSTALL) -D -m 0755 $(@D)/extracted/libOpenCL.so.1.0.0 \
            $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/libOpenCL.so.1.0.0; \
        ln -sf nvidia-driver-aarch64/libOpenCL.so.1.0.0 $(TARGET_DIR)/usr/lib/libOpenCL.so.1.0.0; \
        ln -sf libOpenCL.so.1.0.0 $(TARGET_DIR)/usr/lib/libOpenCL.so.1; \
        ln -sf libOpenCL.so.1 $(TARGET_DIR)/usr/lib/libOpenCL.so; \
    fi
    if [ -f "$(@D)/extracted/libnvidia-opencl.so.$(NVIDIA_DRIVER_AARCH64_VERSION)" ]; then \
        $(INSTALL) -D -m 0755 $(@D)/extracted/libnvidia-opencl.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
            $(TARGET_DIR)/usr/lib/nvidia-driver-aarch64/libnvidia-opencl.so.$(NVIDIA_DRIVER_AARCH64_VERSION); \
        ln -sf nvidia-driver-aarch64/libnvidia-opencl.so.$(NVIDIA_DRIVER_AARCH64_VERSION) \
            $(TARGET_DIR)/usr/lib/libnvidia-opencl.so.1; \
        ln -sf libnvidia-opencl.so.1 $(TARGET_DIR)/usr/lib/libnvidia-opencl.so; \
    fi
    # OpenCL ICD configuration
    mkdir -p $(TARGET_DIR)/etc/OpenCL/vendors
    echo "libnvidia-opencl.so.1" > $(TARGET_DIR)/etc/OpenCL/vendors/nvidia.icd
endef

$(eval $(generic-package))
