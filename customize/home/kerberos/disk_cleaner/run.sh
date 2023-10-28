#!/bin/bash
name=disk_cleaner1
root=/home/pavan/kerberos
docker run --name $name \
   -v $root/capture:/mnt/capture \
   -d disk_cleaner

