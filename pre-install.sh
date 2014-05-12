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
/usr/bin/yum update -y --nogpgcheck
/usr/bin/yum install -y --nogpgcheck git which pwgen cronie \
httpd mod_ssl mysql-server \
php php-fpm php-gd php-mbstring php-mysql php-pecl-apc php-xml php-zts \
rpm-build rpmdevtools redhat-rpm-config make gcc glibc-static

# Build the Runit RPM
RPMUSER="rpmbuilder"
RPMHOME="/home/$RPMUSER"
ARCH="$(arch)"

/usr/sbin/useradd $RPMUSER

/bin/mkdir -p $RPMHOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
/bin/echo '%_topdir %(echo $HOME)/rpmbuild' > $RPMHOME/.rpmmacros 
/bin/chown -R $RPMUSER $RPMHOME 

/bin/su -c '/usr/bin/git clone https://github.com/imeyer/runit-rpm.git' - rpmbuilder
/bin/su -c '/home/rpmbuilder/runit-rpm/build.sh' - rpmbuilder

/usr/bin/yum install -y /home/rpmbuilder/rpmbuild/RPMS/$ARCH/runit-2.1.1-6.el6.$ARCH.rpm

# Setup Apache

##TO DO.  Also add SSL case for custom SSL certs if provided. ##

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

/bin/echo "apc.rfc1867 = 1" >> /etc/php.d/apc.ini




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
mysql="/usr/bin/mysqld_safe"
datadir="/var/lib/mysql"
socketfile="\$datadir/mysql.sock"
errlogfile="/var/log/mysqld-error.log"
slologfile="/var/log/mysqld-slow.log"
genlogfile="/var/log/mysqld-general.log"
mypidfile="/var/run/mysqld/mysqld.pid"

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

/bin/echo "SV:123456:respawn:/sbin/runsvdir-start" >> /etc/inittab

# Install Drupal
DRUSH="https://github.com/drush-ops/drush/archive/master.tar.gz"
COMPOSER="https://getcomposer.org/installer"

/bin/echo "Downloading Drupal to /var/www/html"
/bin/chmod 755 /var/www/html
/usr/bin/git clone http://git.drupal.org/project/drupal.git /var/www/html
cd /var/www/html
/usr/bin/git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) 

cd /
/bin/echo "Creating /drush"
/bin/mkdir /drush

/bin/echo "Downloading Composer"
/usr/bin/wget -nv -O - $COMPOSER | php
/bin/mv composer.phar /usr/bin/composer

/bin/echo "Downloading and extracting drush to /drush"
/usr/bin/wget -nv -O - $DRUSH |tar xz -C /drush --strip-components=1
/bin/chmod u+x /drush/drush
/bin/ln -s /drush/drush /usr/bin/drush

cd /drush
composer install
composer global require drush/drush:6.*

/bin/kill -15 `cat /var/run/mysqld/mysqld.pid`
sleep 10

/bin/echo "Pre-install complete"

