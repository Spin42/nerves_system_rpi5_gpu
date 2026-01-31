# NVIDIA Packages Analysis for Nerves

## Partition Size Calculation

### Problem
The squashfs rootfs image exceeded the partition size limit:
```
.fwup: file size assertion failed on 'combined.squashfs'
Size is 1822556160 bytes. It must be <= 1073741824 bytes (2097152 blocks)
```

### Calculation Method

1. **Get the actual squashfs size:**
   ```bash
   ls -lh _build/custom_rpi5_dev/_nerves-tmp/combined.squashfs
   ```

2. **Convert to blocks (512 bytes per block):**
   ```
   Required blocks = File size in bytes / 512
   ```

3. **Calculate with safety margin (10-20%):**
   ```
   Final blocks = Required blocks × 1.2
   ```

### Example Calculation
- Squashfs size: 1,822,556,160 bytes (~1.7 GB)
- Required blocks: 1,822,556,160 / 512 = 3,559,680 blocks
- With 20% margin: 3,559,680 × 1.2 = 4,271,616 blocks
- Rounded to: **4,194,304 blocks** (2 GB)

### Configuration Location
File: `fwup_include/fwup-common.conf`
```
define(ROOTFS_A_PART_COUNT, 4194304)
```

---

## NVIDIA Package Size Analysis

### Commands Used

**List all large files (>10MB) in nvidia packages:**
```bash
find /path/to/build -path "*nvidia*" -type f -size +10M -exec ls -lh {} \; | sort -k5 -h
```

**Get total size per package:**
```bash
du -sh /path/to/build/nvidia-*/
```

### Results Summary

| Package | Total Size |
|---------|------------|
| nvidia-cuda-toolkit-12.2.0 | **5.8 GB** |
| nvidia-driver-aarch64-580.95.05 | 1.0 GB |
| nvidia-nccl-2.21.5-1 | 502 MB |
| nvidia-open-gpu-modules-aarch64 | 290 MB |

### Largest Files by Package

#### nvidia-cuda-toolkit (5.8 GB total)

| File | Size | Component | Required? |
|------|------|-----------|-----------|
| `libcublasLt_static.a` | 735 MB | cuBLAS Lt static | ❌ No |
| `libcublasLt.so.12.2.1.16` | 470 MB | cuBLAS Lt (tensor ops) | ⚠️ Maybe |
| `libcusparse_static.a` | 290 MB | Sparse matrices static | ❌ No |
| `NVIDIA-Linux-aarch64-535.54.03.run` | 264 MB | Embedded driver | ❌ No (redundant) |
| `libcusparse.so.12.1.1.53` | 249 MB | Sparse matrices | ⚠️ Maybe |
| `libQt6WebEngineCore.so.6` | 247 MB | nsight_systems Qt | ❌ No |
| `libcufft_static.a` | 188 MB | FFT static | ❌ No |
| `libcufft_static_nocallback.a` | 188 MB | FFT static | ❌ No |
| `libcufft.so.11.0.8.15` | 170 MB | FFT | ⚠️ Maybe |
| `libcublas_static.a` | 146 MB | cuBLAS static | ❌ No |
| `libcusolver_static.a` | 122 MB | Solvers static | ❌ No |
| `libcublas.so.12.2.1.16` | 108 MB | cuBLAS | ✅ Yes |
| `libcusolver.so.11.5.0.53` | 109 MB | Solvers | ⚠️ Maybe |

**Nsight tools (profiling, can be excluded):**
| File | Size |
|------|------|
| `nsight_systems/` | ~400 MB |
| `nsight_compute/` | ~300 MB |

**libnpp (image processing, can be excluded if not used):**
| File | Size |
|------|------|
| `libnppif.so` + static | ~185 MB |
| `libnppig.so` + static | ~77 MB |
| `libnppist.so` + static | ~74 MB |

#### nvidia-nccl (502 MB total)

| File | Size | Required? |
|------|------|-----------|
| `libnccl_static.a` | 262 MB | ❌ No |
| `libnccl.so.2.21.5` | 240 MB | ✅ Yes |

#### nvidia-driver-aarch64 (1.0 GB total)

| File | Size | Required? |
|------|------|-----------|
| `nv-kernel.o_binary` | 109 MB | ✅ Yes (kernel module) |
| `libnvidia-rtcore.so` | 99 MB | ⚠️ Ray tracing |
| `libnvoptix.so` | 99 MB | ⚠️ OptiX ray tracing |
| `libcuda.so` | 92 MB | ✅ Yes (CUDA driver) |
| `libnvidia-opencl.so` | 86 MB | ⚠️ OpenCL |
| `libnvidia-nvvm.so` | 73 MB | ✅ Yes (NVVM) |
| `gsp_ga10x.bin` | 72 MB | ✅ Yes (GPU firmware) |
| `nvoptix.bin` | 59 MB | ⚠️ OptiX |

---

## Size Optimization Recommendations

### Option 1: Minimal CUDA Runtime (~400 MB)
Only install essential runtime libraries:
- `libcudart.so` - CUDA runtime
- `libcuda.so` - CUDA driver (from nvidia-driver-aarch64)
- `libnvidia-ml.so` - NVIDIA management library

### Option 2: Standard CUDA (~1.2 GB)
Add commonly used libraries:
- All from Option 1
- `libcublas.so` - Linear algebra
- `libcurand.so` - Random numbers
- `libcusolver.so` - Solvers
- `libnvrtc.so` - Runtime compilation
- `libnvJitLink.so` - JIT linking

### Option 3: Full CUDA with ML (~1.8 GB)
Add ML/AI libraries:
- All from Option 2
- `libcublasLt.so` - Tensor operations
- `libcusparse.so` - Sparse matrices
- `libcufft.so` - FFT
- `libnccl.so` - Multi-GPU communication

### Files to Always Exclude

1. **Static libraries (`*.a`)** - Save ~1.8 GB
   - Not needed for runtime, only for static linking at build time

2. **Nsight tools** - Save ~700 MB
   - `nsight_systems/` - Profiling GUI
   - `nsight_compute/` - Profiling GUI

3. **Embedded NVIDIA driver** - Save ~264 MB
   - `NVIDIA-Linux-aarch64-*.run` - Redundant with nvidia-driver-aarch64

4. **Source archives** - Save ~62 MB
   - `cuda-gdb-*.src.tar.gz`

5. **Development tools** (if not needed on target) - Save ~100 MB
   - `nvdisasm` - 49 MB
   - `cicc` - 34 MB

### Makefile Modifications

To exclude static libraries, modify `nvidia-cuda-toolkit.mk`:
```makefile
# Don't copy static libraries
# cp -a $(@D)/extracted/builds/*/targets/sbsa-linux/lib/*.a ... 
```

To exclude nsight tools, don't install from:
- `$(@D)/extracted/builds/nsight_systems/`
- `$(@D)/extracted/builds/nsight_compute/`

---

## Quick Reference

### Block Size Conversion
- 1 block = 512 bytes
- 1 MB = 2,048 blocks
- 1 GB = 2,097,152 blocks

### Common Partition Sizes
| Size | Blocks |
|------|--------|
| 512 MB | 1,048,576 |
| 1 GB | 2,097,152 |
| 2 GB | 4,194,304 |
| 4 GB | 8,388,608 |
| 8 GB | 16,777,216 |
