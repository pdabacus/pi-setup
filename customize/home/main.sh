#!/bin/bash

echo "testing wifi"
curl -s archlinux.org > /dev/null
if [[ $? -ne 0 ]]; then
    sleep 10
    echo "testing wifi again"
    curl -s archlinux.org > /dev/null
    if [[ $? -ne 0 ]]; then
        sleep 10
        echo "testing wifi again"
        curl -s archlinux.org > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "error: cant connect to wifi"
            exit 1
        fi
    fi
fi
ip addr show


echo "########################################"
echo "# main                                 #"
echo "########################################"
python -c "print('hello')"

