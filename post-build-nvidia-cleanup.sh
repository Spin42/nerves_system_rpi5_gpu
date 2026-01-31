#!/bin/bash
# ============================================================================
# NVIDIA Library Cleanup Script
# ============================================================================
# This script removes unused NVIDIA libraries based on actual runtime 
# dependencies from exla and evision applications.
# 
# Usage: ./post-build-nvidia-cleanup.sh [TARGET_DIR]
# 
# If TARGET_DIR is not provided, it defaults to current working directory
# ============================================================================

TARGET_DIR="${1:-.}"
LIBDIR_64="${TARGET_DIR}/usr/lib64"
LIBDIR="${TARGET_DIR}/usr/lib"

# Ensure globs that don't match expand to nothing
shopt -s nullglob

# Required NVIDIA libraries - based on ldd output from exla and evision
REQUIRED_LIBS=(
	# NCCL
	"libnccl.so*"
	
	# CUDA Driver
	"libcuda.so*"
	
	# CUDA Runtime
	"libcudart.so*"
	
	# cuDNN Core
	"libcudnn.so*"
	"libcudnn_engines_precompiled.so*"
	"libcudnn_ops.so*"
	"libcudnn_graph.so*"
	"libcudnn_cnn.so*"
	"libcudnn_adv.so*"
	"libcudnn_engines_runtime_compiled.so*"
	"libcudnn_heuristic.so*"
	
	# CUDA Compilation/Runtime Compilation
	"libnvrtc.so*"
	"libnvJitLink.so*"
	
	# CUDA Math Libraries (core functionality)
	"libcublas.so*"
	"libcublasLt.so*"
	"libcufft.so*"
	"libcusolver.so*"
	"libcusparse.so*"
	
	# Image Processing (used by evision)
	"libnppc.so*"
	"libnppig.so*"
	"libnppial.so*"
	"libnppicc.so*"
	"libnppidei.so*"
	"libnppist.so*"
	"libnppif.so*"
	"libnppim.so*"
	"libnppitc.so*"
)

# Patterns to remove (unused NVIDIA libraries)
UNUSED_PATTERNS=(
	# Deprecated/unused CUDA libraries
	"libcuinj*"
	"libcudadevrt*"
	"libcudart_static*"
	"libcupti*"
	"libnvvm*"
	
	# Unused image processing modules
	"libnpp[^ig]*"
	"libnpps*"
	"libnppsu*"
	
	# Unused GPU modules
	"libcurand*"
	"libcusolver_static*"
	"libcublas_static*"
	
	# OpenCL (not needed for exla/evision)
	"libnvidia-opencl*"
	"libOpenCL*"
	
	# Unused CUDA utilities
	"libcufftw*"
	"libnvfatbin*"
	"libnvptxcompiler*"
	"libnvrtc-builtins*"
	
	# NCCL plugin/debug libs (optional)
	"libnccl-net*"
	"libnccl_net*"
	
	# Unused NVIDIA libraries
	"libnvidia-ml*"
	"libnvidia-nvcuvid*"
	"libnvidia-encode*"
	"libnvidia-ptxjitcompiler*"
)

cleanup_directory() {
	local lib_dir="$1"
	local dir_name=$(basename "$lib_dir")
	
	if [ ! -d "$lib_dir" ]; then
		echo "Directory $lib_dir not found, skipping..."
		return 0
	fi
	
	echo "Cleaning up $lib_dir..."
	local removed_count=0
	
	# Find all .so* files in the directory
	for lib_file in "$lib_dir"/*.so*; do
		[ -e "$lib_file" ] || continue
		
		lib_name=$(basename "$lib_file")
		is_required=0
		
		# Check if this library is in the required list
		for pattern in "${REQUIRED_LIBS[@]}"; do
			if [[ "$lib_name" == $pattern ]]; then
				is_required=1
				break
			fi
		done
		
		# If not required, check if it matches an unused pattern
		if [ $is_required -eq 0 ]; then
			should_remove=0
			for pattern in "${UNUSED_PATTERNS[@]}"; do
				if [[ "$lib_name" == $pattern ]]; then
					should_remove=1
					break
				fi
			done
			
			if [ $should_remove -eq 1 ]; then
				echo "  Removing: $lib_name"
				rm -f "$lib_file"
				((removed_count++))
			fi
		fi
	done
	
	echo "  Removed $removed_count libraries from $dir_name"
}

is_nvidia_lib() {
	local lib_name="$1"
	case "$lib_name" in
		libcuda.so*|libcud*.so*|libcu*.so*|libnv*.so*|libnvidia*.so*|libnccl.so*|libnpp*.so*|libOpenCL.so*)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

cleanup_scoped_directory() {
	local scoped_dir="$1"
	local root_dir="$2"
	local dir_name=$(basename "$scoped_dir")
	local removed_count=0

	if [ ! -d "$scoped_dir" ]; then
		return 0
	fi

	echo "Cleaning scoped directory $scoped_dir..."

	for lib_file in "$scoped_dir"/*.so*; do
		[ -e "$lib_file" ] || continue

		lib_name=$(basename "$lib_file")
		is_required=0

		for pattern in "${REQUIRED_LIBS[@]}"; do
			if [[ "$lib_name" == $pattern ]]; then
				is_required=1
				break
			fi
		done

		if [ $is_required -eq 0 ] && is_nvidia_lib "$lib_name"; then
			echo "  Removing: $dir_name/$lib_name"
			rm -f "$lib_file"
			((removed_count++))

			# Remove corresponding root copy/symlink if present
			if [ -e "$root_dir/$lib_name" ]; then
				rm -f "$root_dir/$lib_name"
			fi
		fi
	done

	echo "  Removed $removed_count libraries from $dir_name"
}

cleanup_scoped_directories() {
	local base_dir="$1"
	local scoped_dir

	for scoped_dir in "$base_dir"/nvidia-*; do
		[ -d "$scoped_dir" ] || continue
		cleanup_scoped_directory "$scoped_dir" "$base_dir"
	done
}

# Main cleanup
echo "============================================================================"
echo "NVIDIA Library Cleanup"
echo "============================================================================"
echo ""

if [ -d "$LIBDIR_64" ]; then
	cleanup_directory "$LIBDIR_64"
	cleanup_scoped_directories "$LIBDIR_64"
else
	echo "Warning: $LIBDIR_64 not found"
fi

if [ -d "$LIBDIR" ]; then
	cleanup_directory "$LIBDIR"
	cleanup_scoped_directories "$LIBDIR"
else
	echo "Warning: $LIBDIR not found"
fi

echo ""
echo "============================================================================"
echo "Cleanup complete!"
echo "============================================================================"
