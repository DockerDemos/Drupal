#!/bin/bash

/bin/chown -R root.root /etc/service/
/bin/find /etc/service/ -exec /bin/chmod a+x {} \;

/bin/echo 'SV:123456:respawn:/sbin/runsvdir-start' >> /etc/inittab
