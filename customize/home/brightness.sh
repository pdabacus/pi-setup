#!/bin/bash
b=150
e=150
g=20
gamma=60
if [[ -n "$1" ]]; then b=$1; fi
if [[ -n "$2" ]]; then e=$2; fi

#v4l2-ctl -d /dev/video0 -L

v4l2-ctl -d /dev/video0 --set-ctrl=brightness=$b
v4l2-ctl -d /dev/video0 --set-ctrl=exposure=$e
v4l2-ctl -d /dev/video0 --set-ctrl=gain=$g
v4l2-ctl -d /dev/video0 --set-ctrl=gamma=$gamma
