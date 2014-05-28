#!/bin/bash

# Setup mail, if container started with "-e SMTPSERVER"
MAILCONF='/etc/ssmtp/ssmtp.conf'

if [[ ! -z "${SMTPSERVER}" ]] ; then
  SMTPSERVER="${SMTPSERVER}"
  if [[ -z "${DOMAIN}" ]] ; then
    DOMAIN="$(echo ${SMTPSERVER} | awk -F. '{print $(NF-1)"."$NF}')"
  else
    DOMAIN="${DOMAIN}"
  fi

  /bin/cat <<- EOF > $MAILCONF
root=postmaster
mailhub=$SMTPSERVER:465
ReweriteDomain=$DOMAIN
FromLineOverride=YES
UseTLS=YES
TLS_CA_FILE=/etc/pki/tls/certs/ca-bundle.crt
EOF

  PHPINI='/etc/php.ini'
  SENDMAIL='sendmail_path = \/usr\/sbin\/sendmail -t -i'
  SSMTPMAIL='sendmail_path = \/usr\/sbin\/ssmtp -t'

  /bin/sed -i "/$SENDMAIL/c\\$SSMTPMAIL" $PHPINI

elif [[ -f "/build/ssmtp.conf" ]] ; then
  # If we have a custom conf, use that instead
  cp /build/ssmtp.conf $MAILCONF
fi

