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

if ! check_md5 ~/.initialized; then
    exit 0
fi

install_yay() {
    if check_md5 ~/.initialized-1-yay install_yay; then
        sleep 5
        test_wifi && \
        echo "setting timedatectl ntp" && \
        sudo timedatectl net-ntp true && \
        echo "installing yay" && \
        git clone "https://aur.archlinux.org/yay/" && \
        cd yay && \
        makepkg && \
        sudo pacman -U --noconfirm yay*pkg.tar* && \
        cd .. && \
        rm -rf yay && \
        get_file_portion_md5 install_yay > ~/.initialized-1-yay || \
        ( echo "error: couldnt setup yay"; exit 1 ) || exit 1
    fi
}
install_yay

clean_space() {
    if check_md5 ~/.initialized-2-clean clean_space; then
        echo "cleaning space on sdcard"
        get_file_portion_md5 clean_space > ~/.initialized-2-lean || \
        ( echo "error: couldnt clean space"; exit 1 ) || exit 1
    fi
}
clean_space

post_install_reboot() {
    if check_md5 ~/.initialized-3-reboot post_install_reboot; then
        get_file_portion_md5 post_install_reboot > ~/.initialized-3-reboot
        sudo reboot now
    fi
}
post_install_reboot

echo "initialization complete"
get_file_portion_md5 > ~/.initialized
