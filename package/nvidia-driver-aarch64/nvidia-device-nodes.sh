#!/bin/sh
#
# Create NVIDIA device nodes
#

case "$1" in
    start)
        echo "Creating NVIDIA device nodes..."

        # Load NVIDIA kernel modules
        modprobe nvidia
        modprobe nvidia-uvm
        modprobe nvidia-modeset

        # Wait a moment for devices to appear
        sleep 1

        # Create device nodes if they don't exist (udev should handle this, but just in case)
        if [ ! -e /dev/nvidia0 ]; then
            mknod -m 666 /dev/nvidia0 c 195 0
        fi

        if [ ! -e /dev/nvidiactl ]; then
            mknod -m 666 /dev/nvidiactl c 195 255
        fi

        if [ ! -e /dev/nvidia-uvm ]; then
            # Get the major number dynamically
            NVIDIA_UVM_MAJOR=$(grep nvidia-uvm /proc/devices | awk '{print $1}')
            if [ -n "$NVIDIA_UVM_MAJOR" ]; then
                mknod -m 666 /dev/nvidia-uvm c "$NVIDIA_UVM_MAJOR" 0
                mknod -m 666 /dev/nvidia-uvm-tools c "$NVIDIA_UVM_MAJOR" 1
            fi
        fi

        if [ ! -e /dev/nvidia-modeset ]; then
            mknod -m 666 /dev/nvidia-modeset c 195 254
        fi

        echo "NVIDIA device nodes created."
        ;;
    stop)
        echo "Removing NVIDIA modules..."
        rmmod nvidia-uvm 2>/dev/null
        rmmod nvidia-modeset 2>/dev/null
        rmmod nvidia 2>/dev/null
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac

exit 0
