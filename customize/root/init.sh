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
        default_user=$(cat ~/username)
        echo "setting up user '${default_user}'"
        etcpasswd=$(getent passwd 1000)
        etcgroup=$(getent group 1000)
        cur_user=$(echo ${etcpasswd} | cut -d":" -f1)
        cur_group=$(echo ${etcgroup} | cut -d":" -f1)
        if [[ "${cur_user}" != "${default_user}" ]]; then
            echo "moving user '${cur_user}' to '${default_user}'"
            usermod -d "/home/${default_user}" -l "${default_user}" "${cur_user}"
            rm -rf "/home/${cur_user}"
            chown -R "${default_user}:${default_user}" "/home/${default_user}"
        fi
        if [[ "${cur_group}" != "${default_user}" ]]; then
            echo "changing group '${cur_group}' to '${default_user}'"
            groupmod -n "${default_user}" "${cur_group}"
        fi
        if ! groups "${default_user}" | grep wheel >/dev/null; then
            echo "adding '${default_user}' to wheel group"
            usermod -a -G wheel "${default_user}"
        fi
        get_file_portion_md5 setup_user > ~/.initialized-1-user
    fi
}
setup_user

setup_keyring() {
    if check_md5 ~/.initialized-2-keyring setup_keyring; then
        echo "setting up archlinux arm keyring"
        pacman-key --init
        pacman-key --populate archlinuxarm
        get_file_portion_md5 setup_keyring > ~/.initialized-2-keyring
    fi
}
setup_keyring

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
        sleep 5
        echo "testing connection"
        get_file_portion_md5 setup_wifi > ~/.initialized-3-wifi
    fi
}
setup_wifi

install_sudo() {
    if check_md5 ~/.initialized-4-sudo install_sudo; then
        echo "installing sudo"
        pacman -Sy --noconfirm sudo
        sed -i -r "s|#.*(%wheel.+ALL.+NOPASSWD.+)|\1|" /etc/sudoers
        get_file_portion_md5 install_sudo > ~/.initialized-4-sudo
    fi
}
install_sudo

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
ExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM
EOF
}
setup_auto_login

echo "initialization complete"
get_file_portion_md5 > ~/.initialized
