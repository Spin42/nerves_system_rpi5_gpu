# Raspberry Pi 5 Model B (64-bit)

[![Hex version](https://img.shields.io/hexpm/v/nerves_system_rpi5.svg "Hex version")](https://hex.pm/packages/nerves_system_rpi5)
[![CI](https://github.com/nerves-project/nerves_system_rpi5/actions/workflows/ci.yml/badge.svg)](https://github.com/nerves-project/nerves_system_rpi5/actions/workflows/ci.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-project/nerves_system_rpi5)](https://api.reuse.software/info/github.com/nerves-project/nerves_system_rpi5)

This is the base Nerves System configuration for the Raspberry Pi 5 Model B.

![Raspberry Pi 5 image](assets/images/RaspberryPi_5B.svg)
<br><sup>[Efa / Wikimedia Commons / CC BY-SA
4.0](https://en.wikipedia.org/wiki/Raspberry_Pi#/media/File:RaspberryPi_5B_28-08-2024.svg)</sup>

| Feature              | Description                      |
| -------------------- | -------------------------------- |
| CPU                  | 2.4 GHz quad-core Cortex-A76     |
| Memory               | 4 GB or 8 GB DRAM                |
| Storage              | MicroSD                          |
| Linux kernel         | 6.12 w/ Raspberry Pi patches     |
| IEx terminal         | HDMI and USB keyboard (can be changed to UART) |
| GPIO, I2C, SPI       | Yes - [Elixir Circuits](https://github.com/elixir-circuits) |
| ADC                  | No                               |
| PWM                  | Yes, but no Elixir support       |
| UART                 | 2 available - `ttyAMA10`, `ttyAMA0` |
| Display              | HDMI or 7" RPi Touchscreen       |
| Camera               | Official RPi Cameras (libcamera) |
| Ethernet             | Yes                              |
| WiFi                 | Yes - VintageNet                 |
| Bluetooth            | Untested                         |
| Audio                | HDMI/Stereo out                  |

## Using

The most common way of using this Nerves System is create a project with `mix
nerves.new` and to export `MIX_TARGET=rpi5`. See the [Getting started
guide](https://hexdocs.pm/nerves/getting-started.html#creating-a-new-nerves-app)
for more information.

If you need custom modifications to this system for your device, clone this
repository and update as described in [Making custom
systems](https://hexdocs.pm/nerves/customizing-systems.html).

## Supported WiFi devices

The base image includes drivers for the onboard Raspberry Pi 5 WiFi module
(`brcmfmac` driver).

## Camera

This system supports the official Raspberry Pi camera modules via
[`libcamera`](https://libcamera.org/). The `libcamera` applications are included so it's
possible to replicate many of the examples in the official [Raspberry Pi Camera
Documentation](https://www.raspberrypi.com/documentation/computers/camera_software.html).

Here's an example commandline to run:

```elixir
cmd("libcamera-jpeg -n -v -o /data/test.jpeg")
```

On success, you'll get an image in `/data` that you can copy off with `sftp`.

Since `libcamera` is being used instead of MMAL, the Elixir
[picam](https://hex.pm/packages/picam) library won't work.

## Audio

The Raspberry Pi has many options for audio output. This system supports the
HDMI and stereo audio jack output. The Linux ALSA drivers are used for audio
output.

The general Raspberry Pi audio documentation mostly applies to Nerves. For
example, to force audio out the HDMI port, run:

```elixir
cmd("amixer cset numid=3 2")
```

Change the last argument to `amixer` to `1` to output to the stereo output jack.

## RP1 PIO

The `rpi1-pio` device driver allows use of the PIO hardware using
[`piolib`](https://github.com/raspberrypi/utils/tree/master/piolib). If you
don't see `/dev/pio0`, the most likely cause is that you need to update your
Raspberry Pi's boot EEPROM. See
[rpi-eeprom](https://github.com/raspberrypi/rpi-eeprom) for binaries. It may be
easier to upgrade the EEPROM via RaspberryPi OS if the instructions aren't
clear.

## Provisioning devices

This system supports storing provisioning information in a small key-value store
outside of any filesystem. Provisioning is an optional step and reasonable
defaults are provided if this is missing.

Provisioning information can be queried using the Nerves.Runtime KV store's
[`Nerves.Runtime.KV.get/1`](https://hexdocs.pm/nerves_runtime/Nerves.Runtime.KV.html#get/1)
function.

Keys used by this system are:

Key                    | Example Value     | Description
:--------------------- | :---------------- | :----------
`nerves_serial_number` | `"12345678"`      | By default, this string is used to create unique hostnames and Erlang node names. If unset, it defaults to part of the Raspberry Pi's device ID.

The normal procedure would be to set these keys once in manufacturing or before
deployment and then leave them alone.

For example, to provision a serial number on a running device, run the following
and reboot:

```elixir
iex> cmd("fw_setenv nerves_serial_number 12345678")
```

This system supports setting the serial number offline. To do this, set the
`NERVES_SERIAL_NUMBER` environment variable when burning the firmware. If you're
programming MicroSD cards using `fwup`, the commandline is:

```sh
sudo NERVES_SERIAL_NUMBER=12345678 fwup path_to_firmware.fw
```

Serial numbers are stored on the MicroSD card so if the MicroSD card is
replaced, the serial number will need to be reprogrammed. The numbers are stored
in a U-boot environment block. This is a special region that is separate from
the application partition so reformatting the application partition will not
lose the serial number or any other data stored in this block.

Additional key value pairs can be provisioned by overriding the default
provisioning.conf file location by setting the environment variable
`NERVES_PROVISIONING=/path/to/provisioning.conf`. The default provisioning.conf
will set the `nerves_serial_number`, if you override the location to this file,
you will be responsible for setting this yourself.

## NVIDIA GPU Support

This system supports NVIDIA GPUs on the PCIe slot, primarily for machine
learning with [EXLA](https://hex.pm/packages/exla) and
[Evision](https://hex.pm/packages/evision). The stack is split in two:

* **In the system image:** what must match the kernel: the open GPU kernel
  modules, GSP firmware and the driver userspace (`libcuda`, NVML,
  `nvidia-smi`, the OpenCL ICD and its compilers).
* **NVIDIA bundles:** the CUDA toolkit libraries, cuDNN and NCCL (~4 GB
  uncompressed). They are squashfs images installed once on the data
  partition and mounted at boot, so they are not part of the system
  artifact or firmware updates.

| Component | Version | Where |
| --------- | ------- | ----- |
| `nvidia-open-gpu-modules-aarch64` | [mariobalanica/open-gpu-kernel-modules](https://github.com/mariobalanica/open-gpu-kernel-modules) @ `non-coherent-arm-fixes` | system |
| `nvidia-driver-aarch64` | 580.95.05 | system |
| CUDA toolkit runtime libraries (cuBLAS, cuFFT, cuSPARSE, cuSOLVER, NPP, NVRTC, nvJitLink, libnvvm/libdevice) | 12.9.0 | `nvidia-cuda-12.9.0` bundle |
| cuDNN | 9.18.1.3 | `nvidia-cudnn-9.18.1.3` bundle |
| NCCL | 2.29.2 | `nvidia-nccl-2.29.2` bundle |

Versions are set in [`nvidia-versions`](nvidia-versions).

At boot, `/usr/sbin/nvidia-init` (erlinit `--pre-run-exec`) loads the
modules, creates `/dev/nvidia*`, enables persistence mode and mounts each
bundle listed in `/etc/nvidia-bundles` from
`/root/nvidia/<id>-aarch64.squashfs` on `/opt/nvidia/<component>`.
`LD_LIBRARY_PATH` points at the bundles' `lib` directories and
`/usr/local/cuda` links to `/opt/nvidia/cuda`. Without the bundles the GPU,
`nvidia-smi` and OpenCL still work; only CUDA applications fail. Messages go
to the kernel log (`dmesg | grep nvidia-init`).

### Installing the NVIDIA bundles

Build the bundles from NVIDIA's downloads (cached in `~/.nerves/dl`, a few
minutes; needs `mksquashfs` with zstd support):

```sh
scripts/build-nvidia-bundles.sh      # writes ~/.nerves/dl/nvidia-bundles/
```

Then, from your firmware project, upload them to a device. This verifies the
checksums, removes old versions and mounts them without a reboot:

```sh
mix nvidia.bundles.upload nerves.local
```

Bundles live on the application data partition, so they survive firmware
updates; reinstall them after a full reflash that erases `/root`.

**Licensing:** the bundles only contain files NVIDIA allows to be
redistributed (CUDA EULA Attachment A, cuDNN runtime libraries; NCCL is
BSD-3-Clause). The CUDA and cuDNN licenses only permit redistributing them as
part of your application, not as a stand-alone product, so this project
doesn't publish the bundles: build them with the script, which downloads
from NVIDIA, and install them on your devices.

### Building the stack into the image instead

The `nvidia-cuda-toolkit`, `nvidia-cudnn` and `nvidia-nccl` packages are still
available for an all-in-one image: enable them instead of
`nvidia-cuda-bundles` in `nerves_defconfig`. The `post-build-nvidia-cleanup.sh`
script (also used for the bundles) keeps only the libraries needed by
EXLA/Evision; edit its `REQUIRED_LIBS` and `UNUSED_PATTERNS` arrays to
customize it. Note that these packages also install CUDA developer tools and
headers, which NVIDIA's license doesn't allow you to redistribute.

### Building the system

Hosts newer than Buildroot supports (e.g. Ubuntu 26.04) must build in Docker:
set `NERVES_BUILD_RUNNER=docker`. `support/docker/Dockerfile` remaps the
container's build user to your uid/gid.

## Linux kernel and RPi firmware/userland

There's a subtle coupling between the `nerves_system_br` version and the Linux
kernel version used here. `nerves_system_br` provides the versions of
`rpi-userland` and `rpi-firmware` that get installed. I prefer to match them to
the Linux kernel to avoid any issues. Unfortunately, none of these are tagged by
the Raspberry Pi Foundation so I either attempt to match what's in Raspbian or
take versions of the repositories that have similar commit times.

## Linux kernel configuration

The Linux kernel compiled for Nerves is a stripped down version of the default
Raspberry Pi Linux kernel. This is done to remove unnecessary features, select
some Nerves-specific features like F2FS and SquashFS support, and to save space.

