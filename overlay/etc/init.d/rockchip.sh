#!/bin/bash -e
### BEGIN INIT INFO
# Provides:          rockchip
# Required-Start:
# Required-Stop:
# Default-Start:
# Default-Stop:
# Short-Description:
# Description:       Setup rockchip platform environment
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

install_packages() {
    case $1 in
        rk3288)
		MALI=midgard-t76x-r18p0-r0p0
		ISP=rkisp
		# 3288w
		cat /sys/devices/platform/*gpu/gpuinfo | grep -q r1p0 && \
		MALI=midgard-t76x-r18p0-r1p0
		sed -i "s/always/none/g" /etc/X11/xorg.conf.d/20-modesetting.conf
		;;
        rk3399|rk3399pro)
		MALI=midgard-t86x-r18p0
		ISP=rkisp
		sed -i "s/always/none/g" /etc/X11/xorg.conf.d/20-modesetting.conf
		;;
        rk3328|rk3528)
		MALI=utgard-450
		ISP=rkisp
		sed -i "s/always/none/g" /etc/X11/xorg.conf.d/20-modesetting.conf
		;;
        rk3326|px30)
		MALI=bifrost-g31-g13p0
		ISP=rkisp
		sed -i "s/always/none/g" /etc/X11/xorg.conf.d/20-modesetting.conf
		;;
        rk3128|rk3036)
		MALI=utgard-400
		ISP=rkisp
		sed -i "s/always/none/g" /etc/X11/xorg.conf.d/20-modesetting.conf
		;;
        rk3568|rk3566)
		MALI=bifrost-g52-g13p0
		ISP=rkaiq_rk3568
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2.tar -C /
		;;
        rk3562)
		MALI=bifrost-g52-g13p0
		ISP=rkaiq_rk3562
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2.tar -C /
		;;
        rk3576)
		MALI=bifrost-g52-g13p0
		ISP=rkaiq_rk3576
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2.tar -C /
		;;
        rk3588|rk3588s)
		ISP=rkaiq_rk3588
		MALI=valhall-g610-g24p0
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2.tar -C /
		;;
    esac
}

# Upgrade NPU FW
update_npu_fw() {
    /usr/bin/npu-image.sh
    sleep 1
    /usr/bin/npu_transfer_proxy &
}


compatible=$(cat /proc/device-tree/compatible)
chipname=""
case "$compatible" in
    *rk3288*)  chipname="rk3288" ;;
    *rk3328*)  chipname="rk3328" ;;
    *rk3399pro*)
        chipname="rk3399pro"
        update_npu_fw
        ;;
    *rk3399*)  chipname="rk3399" ;;
    *rk3326*)  chipname="rk3326" ;;
    *px30*)    chipname="px30" ;;
    *rk3128*)  chipname="rk3128" ;;
    *rk3528*)  chipname="rk3528" ;;
    *rk3562*)  chipname="rk3562" ;;
    *rk3566*)  chipname="rk3566" ;;
    *rk3568*)  chipname="rk3568" ;;
    *rk3576*)  chipname="rk3576" ;;
    *rk3588*)  chipname="rk3588" ;;
    *rk3036*)  chipname="rk3036" ;;
    *rk3308*)  chipname="rk3208" ;;
    *rv1126*)  chipname="rv1126" ;;
    *rv1109*)  chipname="rv1109" ;;
    *)
        echo "Please check if the SoC is supported on Rockchip Linux!"
        exit 1
        ;;
esac
compatible="${compatible#rockchip,}"
boardname="${compatible%%rockchip,*}"

/etc/init.d/boot_init.sh

sleep 3s

# first boot configure
if [ ! -e "/usr/local/first_boot_flag" ]; then
    echo "It's the first time booting. The rootfs will be configured."

    Mem_Size=$(free -m | grep Mem | awk '{print $2}')
    if [ '1500' -gt $Mem_Size  ] ;
    then
        echo 'Mem_Size =' $Mem_Size 'MB , make swap memory '
        swapoff -a
        dd if=/dev/zero of=/var/swapfile bs=1M count=1024
        mkswap /var/swapfile
        swapon /var/swapfile
        echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    # Force rootfs synced
    mount -o remount,sync /

    install_packages "$chipname" || exit 1

    if [ -e /usr/bin/gst-launch-1.0 ]; then
        setcap CAP_SYS_ADMIN+ep /usr/bin/gst-launch-1.0
    fi

    if [ -e "/dev/rfkill" ]; then
        rm /dev/rfkill
    fi

    rm -rf /*.deb /*.tar

    # # The base target does not come with lightdm/rkaiq_3A
    # if [ -e /etc/gdm3/daemon.conf ]; then
    #     systemctl restart gdm3.service || true
    # elif [ -e /etc/lightdm/lightdm.conf ]; then
    #     systemctl restart lightdm.service || true
    # fi

    # if [ -e /usr/lib/systemd/system/rkisp_3A.service ]; then
    #     systemctl restart rkisp_3A.service || true
    # elif [ -e /usr/lib/systemd/system/rkaiq_3A.service ]; then
    #     systemctl restart rkaiq_3A.service || true
    # fi

    touch /usr/local/first_boot_flag
fi

# #usb configfs reset
# /usr/bin/usbdevice restart

# support power management
if [ -e "/usr/sbin/pm-suspend" ] && [ -e /etc/Powermanager ]; then
    if [ "$chipname" == "rk3399pro" ]; then
        mv /etc/Powermanager/01npu /usr/lib/pm-utils/sleep.d/
        mv /etc/Powermanager/02npu /lib/systemd/system-sleep/
        service input-event-daemon restart
    fi
    rm -rf /etc/Powermanager
fi

# Create dummy video node for chromium V4L2 VDA/VEA with rkmpp plugin
echo dec > /dev/video-dec0
echo enc > /dev/video-enc0
chmod 660 /dev/video-*
chown root:video /dev/video-*

# The chromium using fixed pathes for libv4l2.so
ln -rsf /usr/lib/*/libv4l2.so /usr/lib/
if [ -e /usr/lib/aarch64-linux-gnu/ ]; then
    ln -Tsf lib /usr/lib64
fi

# sync system time
hwclock --systohc
