################################################################################
#
# nvidia-proprietary-modules-aarch64
#
################################################################################

# Built from the kernel/ directory of the driver installer unpacked by
# nvidia-driver-aarch64 (same version: the modules must match the userspace).
NVIDIA_PROPRIETARY_MODULES_AARCH64_VERSION = $(NVIDIA_DRIVER_AARCH64_VERSION)
NVIDIA_PROPRIETARY_MODULES_AARCH64_SOURCE =
NVIDIA_PROPRIETARY_MODULES_AARCH64_LICENSE = NVIDIA Proprietary
NVIDIA_PROPRIETARY_MODULES_AARCH64_EXTRACT_DEPENDENCIES = nvidia-driver-aarch64
NVIDIA_PROPRIETARY_MODULES_AARCH64_DEPENDENCIES = linux

define NVIDIA_PROPRIETARY_MODULES_AARCH64_EXTRACT_CMDS
	cp -a $(NVIDIA_DRIVER_AARCH64_DIR)/extracted/kernel/. $(@D)/
endef

NVIDIA_PROPRIETARY_MODULES_AARCH64_MAKE_OPTS = \
	KERNEL_UNAME=$(LINUX_VERSION_PROBED) \
	SYSSRC=$(LINUX_DIR) \
	SYSOUT=$(LINUX_DIR) \
	ARCH=arm64 \
	TARGET_ARCH=aarch64 \
	CROSS_COMPILE=$(TARGET_CROSS) \
	CC=$(TARGET_CC) \
	LD=$(TARGET_LD) \
	OBJDUMP=$(TARGET_OBJDUMP) \
	IGNORE_PREEMPT_RT_PRESENCE=1 \
	NV_KERNEL_MODULES="nvidia nvidia-uvm nvidia-modeset nvidia-drm"

define NVIDIA_PROPRIETARY_MODULES_AARCH64_BUILD_CMDS
	$(MAKE) -C $(@D) $(NVIDIA_PROPRIETARY_MODULES_AARCH64_MAKE_OPTS) \
		modules -j$(PARALLEL_JOBS)
endef

define NVIDIA_PROPRIETARY_MODULES_AARCH64_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/nvidia-proprietary
	for m in nvidia nvidia-uvm nvidia-modeset nvidia-drm; do \
		$(TARGET_STRIP) --strip-debug -o $(TARGET_DIR)/usr/lib/nvidia-proprietary/$$m.ko $(@D)/$$m.ko || exit 1; \
	done
endef

$(eval $(generic-package))
