# NVIDIA CUDA stack versions shared by several packages. Included here, not
# from the packages: Buildroot derives a package's name from the last
# included makefile.
include $(NERVES_DEFCONFIG_DIR)/nvidia-versions

# Include custom packages
include $(sort $(wildcard $(NERVES_DEFCONFIG_DIR)/package/*/*.mk))
