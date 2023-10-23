#!/bin/bash

############################################################
# setup rasp pi sdcard with kerberos camera server and wifi
############################################################
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3

workdir="/home/pavan/setup_pi"
cd "$workdir"
verify_os=0
format_sdcard=0
install_os=0

os_file="ArchLinuxARM-rpi-aarch64-latest.tar.gz"
os_url="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
os_md5_url="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz.md5"
boot_part_size_mb=$(cat customize/boot_part_size_mb)
alarm_user=$(cat customize/root/username)
########################################
# download operating system tar
########################################
if [[ "${verify_os}" -eq 1 ]]; then
    echo "checking for '${os_file}'"
    os_md5=$(curl -L "${os_md5_url}" 2>/dev/null | awk '{print $1}')
    if [[ -r "${os_file}" ]]; then
        echo -n "verifying '${os_file}'..."
        file_md5=$(md5sum "${os_file}" | awk '{print $1}')
        if [[ "${os_md5}" = "${file_md5}" ]]; then
            echo "done"
            dl=0
        else
            echo "failed"
            dl=1
        fi
    else
        dl=1
    fi
    if [[ "${dl}" -eq 1 ]]; then
        echo "downloading '${os_file}'"
        curl -L "${os_url}" -o "${os_file}"
        echo -n "verifying '${os_file}'..."
        file_md5=$(md5sum "${os_file}" | awk '{print $1}')
        if [[ "${os_md5}" = "${file_md5}" ]]; then
            echo "done"
        else
            echo "failed"
            exit 1
        fi
    fi
fi

########################################
# setup sdcard fdisk
########################################
lsblk
echo "select sdcard for rasp pi operating system (ex. /dev/mmcblk0)"
read -p ">> " device
if [[ ! ${device} =~ ^/dev/* ]]; then
    device="/dev/${device}"
fi
if [[ ! -e "${device}" ]]; then
    echo "error: couldnt find device '${device}'"
    exit 2
fi
if [[ ! -w "${device}" ]]; then
    echo "error: permission denied: cant write to '${device}'"
    exit 2
fi
if [[ "${format_sdcard}" -eq 1 ]]; then
    fdisk "${device}" << EOF
o
n
p
1

+${boot_part_size_mb}M
y
t
c
n
p
2


t
2
linux
w
EOF
fi

#discover partitions
partitions=( $(fdisk -l "${device}" | grep -A10 -E "^Device" | grep -v -E "^Device"| awk '{print $1}') )
boot_part=""
root_part=""
for p in ${partitions[@]}; do
    s=$(fdisk -l "${p}" | grep -Eo "Disk.+bytes" | grep -Eo "[0-9]+.?bytes" | grep -Eo "[0-9]+")
    if (( ($boot_part_size_mb-1)*1024*1024 < $s )) && (( $s <($boot_part_size_mb+1)*1024*1024 )); then
        echo "${p}: ${s} bytes /boot"
        boot_part=${p}
    else
        echo "${p}: ${s} bytes /"
        root_part=${p}
    fi
done
if [[ -z "${boot_part}" ]]; then
    echo "error: failed to find boot partition"
    exit 3
fi
if [[ -z "${root_part}" ]]; then
    echo "error: failed to find root partition"
    exit 3
fi
if [[ "${format_sdcard}" -eq 1 ]]; then
    echo "formatting partitions"
    mkfs.vfat -F32 -n BOOT ${boot_part}
    mkfs.ext4 -L root ${root_part}
fi

########################################
# copy os onto sdcard
########################################
root_mount=$(mktemp -d "tmp.root.XXXXX")
mount "${root_part}" "${root_mount}"
if ! grep "${root_mount}" /proc/mounts >/dev/null 2>/dev/null; then
    echo "error: couldn't mount '${root_part}'"
    exit 4
fi
if [[ "${install_os}" -eq 1 ]]; then
    echo "extracting os onto '${root_part}'"
    tar -zxvpf "${os_file}" -C "${root_mount}"
    sync
fi
boot_mount=$(mktemp -d "tmp.boot.XXXXX")
mount "${boot_part}" "${boot_mount}"
if ! grep "${boot_mount}" /proc/mounts >/dev/null 2>/dev/null; then
    echo "error: couldn't mount '${boot_part}'"
    exit 4
fi
if [[ "${install_os}" -eq 1 ]]; then
    echo "creating boot files on '${boot_part}'"
    mv "${root_mount}"/boot/* "${boot_mount}"
    sync
fi

echo "customizing boot config.txt"
echo "########################################"
echo "# old config.txt                       #"
echo "########################################"
cat "${boot_mount}"/config.txt
cp customize/boot/config.txt "${boot_mount}"/config.txt
echo "########################################"
echo "# new config.txt                       #"
echo "########################################"
cat "${boot_mount}"/config.txt
echo "########################################"

echo "customizing rasp pi: pushing root/init.sh"
cp -a customize/root/. "${root_mount}/root/"

echo "customizing rasp pi: pushing user home folder"
cp -a customize/home/. "${root_mount}/home/${alarm_user}"

echo "setting autologin to root with systemd getty@tty1"
getty_service=$(find "${root_mount}/usr/lib/systemd" | grep "/getty@.service" | tail -n 1 | sed -r "s/^${root_mount}//")
systemd_dir="${root_mount}/etc/systemd/system"
ln -sf "${getty_service}" "${systemd_dir}/getty.target.wants/getty@tty1.service"
mkdir -p "${systemd_dir}/getty@tty1.service.d/"
cat << EOF > "${systemd_dir}/getty@tty1.service.d/override.conf"
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM
EOF

echo "unmounting partitions"
umount "${root_mount}"
rmdir "${root_mount}"
umount "${boot_mount}"
rmdir "${boot_mount}"

