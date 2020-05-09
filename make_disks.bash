
parted -a optimal /dev/sda mkpart primary ext4 0% 512M
parted /dev/sda set 1 boot on
parted -a optimal /dev/sda mkpart primary ext4 512M 100%
#parted /dev/sda unit s p free
mkfs.ext4 /dev/sda1 -L BOOT
mkfs.ext4 /dev/sda2 -L SYSTEM
