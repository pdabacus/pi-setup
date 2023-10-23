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
        echo "installing yay" && \
        git clone "https://aur.archlinux.org/yay/" && \
        cd yay && \
        makepkg && \
        sudo pacman -U --noconfirm yay*pkg.tar* && \
        cd .. && \
        rm -rf yay && \
        get_file_portion_md5 install_yay > ~/.initialized-1-yay || \
        ( echo "error: couldnt setup docker"; exit 1 ) || exit 1
    fi
}
install_yay

install_docker() {
    if check_md5 ~/.initialized-2-docker install_docker; then
        echo "installing docker"
        yay -Sy --noconfirm docker && \
        echo "adding '$(whoami)' to docker group" && \
        sudo usermod -a -G docker $(whoami) && \
        echo "starting docker daemon" && \
        sudo systemctl enable --now docker && \
        get_file_portion_md5 install_docker > ~/.initialized-2-docker || \
        ( echo "error: couldnt setup docker"; exit 1 ) || exit 1
    fi
}
install_docker

echo "initialization complete"
get_file_portion_md5 > ~/.initialized
