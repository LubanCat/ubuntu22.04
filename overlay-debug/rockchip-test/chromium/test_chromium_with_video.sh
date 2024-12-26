#!/bin/bash -e

# Set PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Export mpp_syslog_perror
export mpp_syslog_perror=1

# Get kernel version
KERNEL_VERSION=$(uname -r)

# Set rk_vcodec debug parameter based on kernel version
if echo "$KERNEL_VERSION" | grep -q '^4\.4'; then
    echo 0x100 > /sys/module/rk_vcodec/parameters/debug
else
    echo 0x100 > /sys/module/rk_vcodec/parameters/mpp_dev_debug
fi

## Set CPU governor to performance
# Find all CPU governor files
GOVERNOR_FILES=$(find /sys/ -name *governor)

# Set governor to performance
echo performance | tee $GOVERNOR_FILES > /dev/null 2>&1 || true

# Check if Chromium is installed
if command -v chromium &> /dev/null; then
    chromium --no-sandbox file:///usr/local/test.mp4
else
    echo "Please ensure the config/rockchip_xxxx_defconfig includes 'chromium.config'."
fi

echo "The CPU governor is now set to performance. Please restart if needed."
