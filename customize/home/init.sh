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

install_yay() {
    if check_md5 ~/.initialized-1-yay install_yay; then
        echo installing yay
        get_file_portion_md5 install_yay > ~/.initialized-1-yay
    fi
}
install_yay

install_docker() {
    if check_md5 ~/.initialized-2-docker install_docker; then
        echo installing dockers
        get_file_portion_md5 install_docker > ~/.initialized-2-docker
    fi
}
install_docker

#vim git docker bash-completion

echo "initialization complete"
get_file_portion_md5 > ~/.initialized