#!/bin/bash

delay=8
total=${1:-10000}
CNT=/data/rockchip-test/reboot_cnt

if [ ! -e "/data/rockchip-test" ]; then
	echo "no /data/rockchip-test"
	mkdir -p /data/rockchip-test
fi

if [ ! -e "/data/rockchip-test/auto_reboot.sh" ]; then
	cp -f /rockchip-test/auto_reboot/auto_reboot.sh /data/rockchip-test/
	cp -f /rockchip-test/auto_reboot/auto_reboot_test.sh /etc/init.d/
	cp -f /rockchip-test/auto_reboot/rockchip_reboot.service /lib/systemd/system/
	ln -sf /lib/systemd/system/rockchip_reboot.service /etc/systemd/system/multi-user.target.wants/
	echo $total > /data/rockchip-test/reboot_total_cnt
	sync
fi

while true
do

if [ -e $CNT ]
then
    cnt=`cat $CNT`
else
    echo reset Reboot count.
    echo 0 > $CNT
fi

echo  Reboot after $delay seconds.

let "cnt=$cnt+1"

if [ $cnt -ge $total ]
then
    echo AutoReboot Finisned.
    echo "off" > $CNT
    echo "do cleaning ..."
    rm -rf /data/rockchip-test/auto_reboot.sh
    rm -rf /data/rockchip-test/reboot_total_cnt
    rm -f $CNT
    sync
    exit 0
fi

echo $cnt > $CNT
echo "current cnt = $cnt, total cnt = $total"
echo "You can stop reboot by: echo off > /data/rockchip-test/reboot_cnt"
sleep $delay
cnt=`cat $CNT`
if [ $cnt != "off" ]; then
    sync
    if [ -e /var/lib/systemd/pstore/console-ramoops-0 ]; then
        echo "check console-ramoops-0 message"
        grep -q "Restarting system" /var/lib/systemd/pstore/console-ramoops-0
        if [ $? -ne 0 -a $cnt -ge 2 ]; then
		echo "no found 'Restarting system' log in last time kernel message"
		grep -q "panic" /var/lib/systemd/pstore/console-ramoops-0
		if [ $? -eq 0 ]; then
			echo "Found 'panic' log in last kernel message"
			echo "Consider kernel crash in last reboot test"
			echo "Quit reboot test"
			rm -rf /data/rockchip-test/auto_reboot.sh
			rm -rf /data/rockchip-test/reboot_total_cnt
			sync
			exit 1
		else
			echo "Warning: Maybe Potential data loss in last reboot"
			reboot
		fi
        else
	   reboot
        fi
    else
	   reboot
    fi
else
    echo "Auto reboot is off"
    rm -rf /data/rockchip-test/auto_reboot.sh
    rm -rf /data/rockchip-test/reboot_total_cnt
    rm -f $CNT
    sync
fi
exit 0
done
