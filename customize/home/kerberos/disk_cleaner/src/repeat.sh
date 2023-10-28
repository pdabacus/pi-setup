#!/bin/bash
dt=3600 #1hr
while :; do
    ./clean_disk.sh
    sleep $dt
done
