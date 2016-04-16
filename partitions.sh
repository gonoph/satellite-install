parted /dev/sdb mklabel gpt
parted /dev/sdc mklabel gpt
parted /dev/sdb -- unit cyl mkpart var xfs 0 -1
parted /dev/sdc -- unit cyl mkpart mongodb xfs 0 -1
sync
sleep 1
mkfs.xfs /dev/disk/by-partlabel/mongodb
mkfs.xfs /dev/disk/by-partlabel/var
mount /dev/disk/by-partlabel/var /mnt && rsync -avP /var/ /mnt/
