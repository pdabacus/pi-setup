#!/bin/bash
root=/home/pavan/kerberos
max_size=$((100 * 1024 * 1024)) #100mb
#max_size=$((300 * 1024 * 1024)) #100mb
if [[ -f "$root/capture/max_usage.conf" ]]; then
    max_size=$(cat "$root/capture/max_usage.conf")
fi

calc() {
    bc <<< "scale=60; $@" | awk '{printf "%.16f\n", $0}'
}

round() {
    echo $@ | awk '{printf "%.2f\n", $0}'
}

files=( $(find "$root/capture" -type f -name "*.mp4" | sort) )
sizes=( $(du ${files[@]} | awk '{print $1*1024}') )
total_size=0
for s in ${sizes[@]}; do
    (( total_size += $s ))
done
total_gb=$(round $(calc "$total_size / 1024 / 1024 / 1024"))
max_gb=$(round $(calc "$max_size / 1024 / 1024 / 1024"))
echo "kerberos disk usage: ${total_gb}GB / ${max_gb}GB"

if (( EUID != 0 )); then
    echo "error: run as root"
    exit 1
fi

if [[ "$total_size" -lt "$max_size" ]]; then
    exit 0
else
    echo "removing old video files"
fi

N=${#files[@]}
for i in ${!files[@]}; do
    f=${files[$i]}
    s=${sizes[$i]}
    s_mb=$(round $(calc "$s / 1024 / 1024"))
    (( total_size -= $s ))
    echo "$((i+1))/$N freed ${s_mb}MB $(basename $f)"
    rm $f
    if [[ "$total_size" -lt "$max_size" ]]; then
        break
    fi
done
total_gb=$(round $(calc "$total_size / 1024 / 1024 / 1024"))
echo "kerberos disk usage: ${total_gb}GB / ${max_gb}GB"
