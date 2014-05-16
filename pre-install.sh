#!/bin/bash

# Epel repo for pwgen
/bin/cat << EOF > /etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
EOF

# PHP-FPM Expects this
touch /etc/sysconfig/network

/usr/bin/yum clean all
/usr/bin/yum install -y --nogpgcheck git which pwgen cronie tar \
httpd mod_ssl mysql-server \
php php-fpm php-gd php-mbstring php-mysql php-pecl-apc php-xml php-zts \
rpm-build rpmdevtools redhat-rpm-config make gcc glibc-static

# Build the Runit RPM
RPMUSER='rpmbuilder'
RPMHOME="/home/$RPMUSER"
ARCH="$(arch)"

/usr/sbin/useradd $RPMUSER

/bin/mkdir -p $RPMHOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
/bin/echo '%_topdir %(echo $HOME)/rpmbuild' > $RPMHOME/.rpmmacros
/bin/chown -R $RPMUSER $RPMHOME

/bin/su -c '/usr/bin/git clone https://github.com/imeyer/runit-rpm.git' - rpmbuilder
/bin/su -c '/home/rpmbuilder/runit-rpm/build.sh 1>/dev/null' - rpmbuilder

/usr/bin/yum install -y /home/rpmbuilder/rpmbuild/RPMS/$ARCH/runit-2.1.1-6.el6.$ARCH.rpm

# Setup Apache
CONF='/etc/httpd/conf/httpd.conf'

/bin/sed -i '/ServerTokens OS/c\ServerTokens ProductOnly' $CONF
/bin/sed -i '/Timeout 60/c\Timeout 120' $CONF
/bin/sed -i '/ServerSignature On/c\ServerSignature Off' $CONF

/bin/echo 'AliasMatch \.svn /non-existant-page' >> $CONF
/bin/echo 'AliasMatch \.git /non-existant-page' >> $CONF
/bin/echo 'TraceEnable Off' >> $CONF

/bin/cat << EOF > /etc/httpd/conf.d/site.conf
<VirtualHost *:80>

  DocumentRoot '/var/www/html'

  <Directory '/var/www/html'>
    Options FollowSymlinks
    AllowOverride All
    Order allow,deny
    Allow from all
  </Directory>

  ErrorLog logs/error_log
  CustomLog logs/access_log combined

</VirtualHost>
EOF

if [[ -f /certs/localhost.crt ]] ; then
  /bin/echo 'Certificate exists in /certs - setting up SSL'
  /bin/cp /certs/localhost.key /etc/pki/tls/private/
  /bin/cp /certs/localhost.crt /etc/pki/tls/certs/

  SSLCONF='/etc/httpd/conf.d/ssl.conf'
  SSLPROTO='SSLProtocol all -SSLv2 -SSLv3'
  SSLHONOR='SSLHonorCipherOrder on'
  SSLCIPHER='SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK'

  /bin/sed -i "/SSLProtocol all -SSLv2/c\\$SSLPROTO\n$SSLHONOR" $SSLCONF
  /bin/sed -i "/SSLCipherSuite ALL/c\\$SSLCIPHER" $SSLCONF

  /bin/cat <<- EOF > /etc/httpd/conf.d/site-ssl.conf
  <VirtualHost *:443>

    DocumentRoot '/var/www/html'

    <Directory '/var/www/html'>
      Options FollowSymlinks
      AllowOverride All
      Order allow,deny
      Allow from all
    </Directory>

    SSLEngine on
    SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
    SSLCertificateFile    /etc/pki/tls/certs/localhost.crt

    ErrorLog logs/ssl_error_log
    CustomLog logs/ssl_access_log combined

  </VirtualHost>
EOF
fi

# Setup MySQL
/bin/chown -R mysql.mysql /var/lib/mysql
mysql_install_db --user=mysql

/usr/bin/mysqld_safe &
sleep 5

MYSQL_ROOT_PASS="$(pwgen -c -n -1 12)"

cat << EOF > /root/.my.cnf
[mysqladmin]
user            = root
password        = $MYSQL_ROOT_PASS

[client]
user            = root
password        = $MYSQL_ROOT_PASS
protocol        = TCP
EOF

mysqladmin -uroot password $MYSQL_ROOT_PASS

## TO DO: Setup PHP-FPM ##
APCINI='/etc/php.d/apc.ini'
/bin/echo 'apc.rfc1867 = 1' >> $APCINI

# Setup the init system
/bin/mkdir -p /etc/service/httpd
/bin/mkdir -p /etc/service/mysqld
/bin/mkdir -p /etc/service/php-fpm

/bin/cat << EOF > /etc/service/httpd/run
#!/bin/sh
exec /usr/sbin/httpd -DFOREGROUND
EOF

/bin/cat << EOF > /etc/service/mysqld/run
#!/bin/sh
mysql='/usr/bin/mysqld_safe'
datadir='/var/lib/mysql'
socketfile="\$datadir/mysql.sock"
errlogfile='/var/log/mysqld-error.log'
slologfile='/var/log/mysqld-slow.log'
genlogfile='/var/log/mysqld-general.log'
mypidfile='/var/run/mysqld/mysqld.pid'

if [[ ! -f "\$errlogfile" ]] ; then
  touch "\$errlogfile" 2>/dev/null
  touch "\$slologfile" 2>/dev/null
  touch "\$genlogfile" 2>/dev/null
fi

chown mysql:mysql "\$errlogfile" "\$slologfile" "\$genlogfile"
chmod 0640 "\$errlogfile" "\$slologfile" "\$genlogfile"

if [[ ! -d "\$datadir" ]] ; then
  mkdir -p "\$datadir"
  chown mysql:mysql "\$datadir"
  chmod 0755 "\$datadir"
  /usr/bin/mysql_install_db --datadir="\$datadir" --user=mysql
  chmod 0755 "\$datadir"
fi

chown mysql:mysql "\$datadir"
chmod 0755 "\$datadir"

\$mysql   --datadir="\$datadir" --socket="\$socketfile" \
         --pid-file="\$mypidfile" \
         --basedir=/usr --user=mysql >/dev/null 2>&1 & wait
EOF

## TO DO: PHP-FPM ##

/bin/chown -R root.root /etc/service/
/bin/find /etc/service/ -exec /bin/chmod a+x {} \;

/bin/echo 'SV:123456:respawn:/sbin/runsvdir-start' >> /etc/inittab

# Install Drupal
DRUSH='https://github.com/drush-ops/drush/archive/master.tar.gz'
COMPOSER='https://getcomposer.org/installer'

/bin/echo 'Downloading Drupal to /var/www/html'
/bin/chmod 755 /var/www/html
/usr/bin/git clone http://git.drupal.org/project/drupal.git /var/www/html
cd /var/www/html
/usr/bin/git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

cd /
/bin/echo 'Creating /drush'
/bin/mkdir /drush

/bin/echo 'Downloading Composer'
/usr/bin/wget -nv -O - $COMPOSER | php
/bin/mv composer.phar /usr/bin/composer

/bin/echo 'Downloading and extracting drush to /drush'
/usr/bin/wget -nv -O - $DRUSH |tar xz -C /drush --strip-components=1
/bin/chmod u+x /drush/drush
/bin/ln -s /drush/drush /usr/bin/drush

cd /drush
composer install
composer global require drush/drush:6.*

/bin/kill -15 `cat /var/run/mysqld/mysqld.pid`
sleep 10

/bin/echo 'Pre-install complete'

