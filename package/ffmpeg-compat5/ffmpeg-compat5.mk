################################################################################
#
# ffmpeg-compat5
#
# FFmpeg 5.1.6 for legacy library compatibility
# Provides: libavcodec.so.59, libavformat.so.59, libavutil.so.57, libswscale.so.6
#
################################################################################

FFMPEG_COMPAT5_VERSION = 5.1.6
FFMPEG_COMPAT5_SOURCE = ffmpeg-$(FFMPEG_COMPAT5_VERSION).tar.xz
FFMPEG_COMPAT5_SITE = https://ffmpeg.org/releases
FFMPEG_COMPAT5_LICENSE = LGPL-2.1+, GPL-2.0+ (optional components)
FFMPEG_COMPAT5_LICENSE_FILES = LICENSE.md COPYING.LGPLv2.1 COPYING.GPLv2

# Don't install to staging to avoid conflicts with main ffmpeg
FFMPEG_COMPAT5_INSTALL_STAGING = NO

FFMPEG_COMPAT5_CONF_OPTS = \
	--prefix=/usr \
	--enable-cross-compile \
	--cross-prefix=$(TARGET_CROSS) \
	--sysroot=$(STAGING_DIR) \
	--target-os=linux \
	--arch=$(BR2_ARCH) \
	--disable-static \
	--enable-shared \
	--disable-programs \
	--disable-doc \
	--disable-debug \
	--disable-everything \
	--enable-swscale \
	--enable-avcodec \
	--enable-avformat \
	--enable-avutil \
	--enable-decoder=h264 \
	--enable-decoder=hevc \
	--enable-decoder=vp8 \
	--enable-decoder=vp9 \
	--enable-decoder=mpeg4 \
	--enable-decoder=mjpeg \
	--enable-decoder=png \
	--enable-decoder=rawvideo \
	--enable-decoder=pcm_s16le \
	--enable-decoder=aac \
	--enable-decoder=mp3 \
	--enable-encoder=rawvideo \
	--enable-encoder=mjpeg \
	--enable-encoder=png \
	--enable-parser=h264 \
	--enable-parser=hevc \
	--enable-parser=vp8 \
	--enable-parser=vp9 \
	--enable-parser=mpeg4video \
	--enable-parser=mjpeg \
	--enable-parser=aac \
	--enable-parser=mpegaudio \
	--enable-demuxer=avi \
	--enable-demuxer=mov \
	--enable-demuxer=matroska \
	--enable-demuxer=mp4 \
	--enable-demuxer=mpegts \
	--enable-demuxer=rawvideo \
	--enable-demuxer=image2 \
	--enable-demuxer=v4l2 \
	--enable-muxer=rawvideo \
	--enable-muxer=image2 \
	--enable-muxer=mp4 \
	--enable-protocol=file \
	--enable-protocol=pipe \
	--enable-filter=scale \
	--enable-filter=format \
	--enable-filter=fps \
	--enable-filter=null \
	--enable-filter=anull \
	--enable-swscale-alpha \
	--disable-stripping

# Use software implementations only for compatibility
FFMPEG_COMPAT5_CONF_OPTS += \
	--disable-vaapi \
	--disable-vdpau \
	--disable-cuda \
	--disable-cuvid \
	--disable-nvenc \
	--disable-nvdec

# ARM NEON optimization
ifeq ($(BR2_ARM_CPU_HAS_NEON),y)
FFMPEG_COMPAT5_CONF_OPTS += --enable-neon
endif

# AArch64 optimizations
ifeq ($(BR2_aarch64),y)
FFMPEG_COMPAT5_CONF_OPTS += --enable-neon
endif

define FFMPEG_COMPAT5_CONFIGURE_CMDS
	cd $(@D) && \
	$(TARGET_MAKE_ENV) ./configure $(FFMPEG_COMPAT5_CONF_OPTS)
endef

define FFMPEG_COMPAT5_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define FFMPEG_COMPAT5_INSTALL_TARGET_CMDS
	# Install only the shared libraries we need to /usr/lib
	cp -a $(@D)/libavcodec/libavcodec.so* $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/libavformat/libavformat.so* $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/libavutil/libavutil.so* $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/libswscale/libswscale.so* $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/libswresample/libswresample.so* $(TARGET_DIR)/usr/lib/
endef

$(eval $(generic-package))
