################################################################################
#
# nvidia-open-gpu-modules-aarch64
#
################################################################################

NVIDIA_OPEN_GPU_MODULES_AARCH64_VERSION = non-coherent-arm-fixes
NVIDIA_OPEN_GPU_MODULES_AARCH64_SITE = https://github.com/mariobalanica/open-gpu-kernel-modules.git
NVIDIA_OPEN_GPU_MODULES_AARCH64_SITE_METHOD = git
NVIDIA_OPEN_GPU_MODULES_AARCH64_GIT_DEPTH = 1
NVIDIA_OPEN_GPU_MODULES_AARCH64_LICENSE = MIT/GPL-2.0
NVIDIA_OPEN_GPU_MODULES_AARCH64_LICENSE_FILES = COPYING

NVIDIA_OPEN_GPU_MODULES_AARCH64_DEPENDENCIES = linux

# Build against the Nerves kernel
define NVIDIA_OPEN_GPU_MODULES_AARCH64_BUILD_CMDS
    $(MAKE) -C $(@D) \
        KERNEL_UNAME=$(LINUX_VERSION_PROBED) \
        KERNEL_PATH=$(LINUX_DIR) \
        SYSSRC=$(LINUX_DIR) \
        SYSOUT=$(LINUX_DIR) \
        ARCH=arm64 \
        TARGET_ARCH=aarch64 \
        CROSS_COMPILE=$(TARGET_CROSS) \
        CC=$(TARGET_CC) \
        CXX=$(TARGET_CXX) \
        LD=$(TARGET_LD) \
        AR=$(TARGET_AR) \
        OBJCOPY=$(TARGET_OBJCOPY) \
        IGNORE_PREEMPT_RT_PRESENCE=1 \
        modules -j$(PARALLEL_JOBS)
endef

define NVIDIA_OPEN_GPU_MODULES_AARCH64_INSTALL_TARGET_CMDS
    $(MAKE) -C $(@D) \
        KERNEL_UNAME=$(LINUX_VERSION_PROBED) \
        SYSSRC=$(LINUX_DIR) \
        SYSOUT=$(LINUX_DIR) \
        INSTALL_MOD_PATH=$(TARGET_DIR) \
        modules_install

    # Run depmod
    $(HOST_DIR)/sbin/depmod -a -b $(TARGET_DIR) $(LINUX_VERSION_PROBED)
endef

$(eval $(generic-package))
