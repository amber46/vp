#!/bin/bash
#

DST="/mnt/dst"
SRCIP="37"

# step 1
parted /dev/sda mklabel msdos
parted -a optimal /dev/sda mkpart primary ext4 0% 512M
parted /dev/sda set 1 boot on
parted -a optimal /dev/sda mkpart primary ext4 512M 100%
#parted /dev/sda unit s p free
mkfs.ext4 /dev/sda1 -L BOOT
mkfs.ext4 /dev/sda2 -L SYSTEM

# step 2
mkdir -p $DST
mount -L SYSTEM $DST
mkdir -p $DST/boot
mount -L BOOT $DST/boot


# step 5
rsync -ahPHAXx --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/var/tmp/*,/run/*,/mnt/*,/media/*,/var/log/android/*,/home/vpn_android/data/*,/lost+found} -e "ssh -p 1111" root@$SRCIP:/ /mnt/dst/

# step 9
MACADDR_ETH0=$(cat /sys/class/net/eth0/address)
MACADDR_VGN0=$(cat /sys/class/net/eth1/address)

cat <<EOT > $DST/etc/udev/rules.d/10-network.rules
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MACADDR_ETH0",KERNEL=="*", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MACADDR_VGN0",KERNEL=="*", NAME="vgn0"
EOT

cat <<EOT > $DST/etc/fstab
# / was on /dev/sda2 during installation
LABEL=SYSTEM / ext4 errors=remount-ro 0 1
# /boot was on /dev/sda1 during installation
LABEL=BOOT /boot ext4 defaults 0 2
EOT

# step 10 
mount --rbind /dev $DST/dev
mount -t proc /proc $DST/proc
mount --rbind /sys $DST/sys
mount --rbind /tmp $DST/tmp
chroot $DST /bin/bash

#Correct GRUB
grub-install --no-floppy /dev/sda 
grub-mkconfig -o /boot/grub/grub.cfg

#repair missing folder
rsync -av -f"+ */" -f"- *" --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/var/log/android/*,/home/vpn_android/data/*,/lost+found} -e "ssh -p 1111" root@source-ip:/ /
