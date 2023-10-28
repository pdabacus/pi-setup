#!/bin/bash

get_file_portion_md5() {
    if [[ -z "$1" ]]; then
        cat $0 | md5sum | awk '{print $1}'
    else
        cat $0 | awk "/^$1/ {x=1-x}; x==1 {print}" | md5sum | awk '{print $1}'
    fi
}

check_md5() {
    if [[ -e $1 ]]; then
        prev_md5=$(cat $1)
        current_md5=$(get_file_portion_md5 $2)
        if [[ "${current_md5}" = "${prev_md5}" ]]; then
            return 1
        else
            echo "running init script $2"
            return 0
        fi
    fi
}

if ! check_md5 ~/.initialized; then
    exit 0
fi

setup_user() {
    if check_md5 ~/.initialized-1-user setup_user; then
        echo -n "setting hostname to "
        cat ~/hostname
        cp ~/hostname /etc/hostname
        default_user=$(cat ~/username)
        echo "setting up user '${default_user}'"
        etcpasswd=$(getent passwd 1000)
        etcgroup=$(getent group 1000)
        cur_user=$(echo ${etcpasswd} | cut -d":" -f1)
        cur_group=$(echo ${etcgroup} | cut -d":" -f1)
        if [[ "${cur_group}" != "${default_user}" ]]; then
            echo "changing group '${cur_group}' to '${default_user}'"
            groupmod -n "${default_user}" "${cur_group}"
        fi
        if [[ "${cur_user}" != "${default_user}" ]]; then
            echo "moving user '${cur_user}' to '${default_user}'"
            usermod -d "/home/${default_user}" -l "${default_user}" "${cur_user}"
            rm -rf "/home/${cur_user}"
            chown -R "${default_user}:${default_user}" "/home/${default_user}"
        fi
        if ! groups "${default_user}" | grep wheel >/dev/null; then
            echo "adding '${default_user}' to wheel group"
            usermod -a -G wheel "${default_user}"
        fi

        etcpasswd=$(getent passwd 1000)
        etcgroup=$(getent group 1000)
        cur_user=$(echo ${etcpasswd} | cut -d":" -f1)
        cur_group=$(echo ${etcgroup} | cut -d":" -f1)
        if [[ "${cur_group}" != "${default_user}" ]] || [[ "${cur_user}" != "${default_user}" ]]; then
            echo "error: couldn't setup default user '${default_user}'"
            exit 1
        fi
        get_file_portion_md5 setup_user > ~/.initialized-1-user
    fi
}
setup_user

setup_keyring() {
    if check_md5 ~/.initialized-2-keyring setup_keyring; then
        echo "setting up archlinux arm keyring"
        pacman-key --init && \
        pacman-key --populate archlinuxarm && \
        get_file_portion_md5 setup_keyring > ~/.initialized-2-keyring || \
        ( echo "error: couldnt setup arch keyring"; exit 1 ) || exit 1
    fi
}
setup_keyring

test_wifi() {
    echo "testing internet connection"
    curl -s archlinux.org > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "success"
        return 0
    else
        echo "testing connection again"
        sleep 20
        curl -s archlinux.org > /dev/null
        if [[ $? -eq 0 ]]; then
            echo "success"
            return 0
        else
            echo "failed"
            return 1
        fi
    fi
}
setup_wifi() {
    if check_md5 ~/.initialized-3-wifi setup_wifi; then
        echo "setting up wifi"
        nic=$(ip link | grep -Eo "[0-9]+:.+w[a-zA-Z0-9]+" | awk '{print $2}')
        if [[ -z "${nic}" ]]; then
            echo "error: couldnt find wireless nic, exitting init"
            exit 1
        fi
        echo "found wireless nic '${nic}'"
        cp ~/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-${nic}.conf
        echo "creating systemd units for wpa_supplicant"
        systemctl enable --now dhcpcd
        systemctl enable --now wpa_supplicant@$nic
        sleep 10
        test_wifi && \
        get_file_portion_md5 setup_wifi > ~/.initialized-3-wifi || \
        ( echo "error: couldnt setup wifi"; exit 1 ) || exit 1
    fi
}
setup_wifi

sync_time() {
    if check_md5 ~/.initialized-4-time sync_time; then
        sleep 5
        test_wifi && \
        echo "setting timezone to mountain time" && \
        ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime && \
        echo "setting time based on google server" && \
        timedatectl set-ntp false && \
        time_srv=$(date +"%b %d %H:%M:%S" -d "$(curl -v google.com |& grep Date | sed 's/< Date: //')") && \
        timedatectl set-time "$time_srv" && \
        echo "installing ntpd" && \
        pacman -Sy --noconfirm openntpd && \
        systemctl enable --now openntpd && \
        echo "syncing time with ntp" && \
        timedatectl set-ntp true && \
        timedatectl && \
        get_file_portion_md5 sync_time > ~/.initialized-4-time || \
        ( echo "error: couldnt sync timezones and hwclock"; exit 1 ) || exit 1
    fi
}
sync_time

install_sudo() {
    if check_md5 ~/.initialized-5-sudo install_sudo; then
        sleep 5
        test_wifi && \
        echo "installing sudo" && \
        pacman -Sy --noconfirm sudo && \
        sed -i -r "s|#.*(%wheel.+ALL.+NOPASSWD.+)|\1|" /etc/sudoers && \
        get_file_portion_md5 install_sudo > ~/.initialized-5-sudo || \
        ( echo "error: couldnt install sudo"; exit 1 ) || exit 1
    fi
}
install_sudo

update_packages() {
    if check_md5 ~/.initialized-6-update update_packages; then
        sleep 5
        test_wifi && \
        echo "installing and updating packages" && \
        pacman -Sy --noconfirm archlinux-keyring && \
        pacman -Sc --noconfirm && \
        pacman -Su --noconfirm && \
        pacman -Sc --noconfirm && \
        pacman -S base-devel python vim && \
        pacman -Sc --noconfirm && \
        get_file_portion_md5 update_packages > ~/.initialized-6-update || \
        ( echo "error: couldnt update packages"; exit 1 ) || exit 1
    fi
}
update_packages

setup_auto_login() {
    default_user=$(cat ~/username)
    echo "setting autologin to ${default_user} with systemd getty@tty1"
    getty_service=$(find "/usr/lib/systemd" | grep "/getty@.service" | tail -n 1)
    systemd_dir="/etc/systemd/system"
    ln -sf "${getty_service}" "${systemd_dir}/getty.target.wants/getty@tty1.service"
    mkdir -p "${systemd_dir}/getty@tty1.service.d/"
cat << EOF > "${systemd_dir}/getty@tty1.service.d/override.conf"
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${default_user} --noclear %I $TERM
EOF
}
setup_auto_login

echo "initialization complete"
get_file_portion_md5 > ~/.initialized

echo "rebooting in 30s"
sleep 30
reboot now
