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

/usr/bin/yum clean all
/usr/bin/yum install -y --nogpgcheck git which pwgen cronie tar rsyslogd \
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

/bin/echo 'Pre-install complete'

