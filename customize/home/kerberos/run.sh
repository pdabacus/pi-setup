#!/bin/bash
name=cam1
root=/home/pavan/kerberos
docker run --name $name \
   -p 80:80 -p 8889:8889 \
   -v $root/config:/etc/opt/kerberosio/config \
   -v $root/capture:/etc/opt/kerberosio/capture \
   -v $root/logs:/etc/opt/kerberosio/logs \
   -v $root/webconfig:/var/www/web/config \
   --device=/dev/video0 \
   -d kerberos/kerberos

