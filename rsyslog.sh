#!/bin/bash

f_syslog() {
  /bin/echo '$template ExampleFormat,"%HOSTNAME%.docker %msg%"' >> /etc/rsyslog.conf
  /bin/echo "*.* @@$SYSLOGSERVER:514;ExampleFormat" >> /etc/rsyslog.conf
}

# Setup rsyslog
if [[ ! -z "${SYSLOGSERVER}" ]] ; then
  SYSLOGSERVER="${SYSLOGSERVER}"
  f_syslog
else
  if [[ ! -z "${DOMAIN}" ]] ; then
  DOMAIN="${DOMAIN}"
  SYSLOGSERVER="syslog.$DOMAIN"
  f_syslog
  else
  /bin/echo "No Syslog server specified..."
  fi
fi

/bin/mkdir -p /etc/service/rsyslogd

/bin/cat << EOF > /etc/service/rsyslogd/run
#!/bin/sh
exec /sbin/rsyslogd -n
EOF

chmod -R +x /etc/service/rsyslogd

