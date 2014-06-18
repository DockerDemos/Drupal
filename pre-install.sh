#!/bin/bash

# Epel repo for pwgen
/bin/cat << EOF > /etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
EOF

# Build the RPM
RPMUSER='rpmbuilder'
RPMHOME="/home/$RPMUSER"
ARCH="$(arch)"

/usr/sbin/useradd $RPMUSER

/bin/mkdir -p $RPMHOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
/bin/echo '%_topdir %(echo $HOME)/rpmbuild' > $RPMHOME/.rpmmacros
/bin/chown -R $RPMUSER $RPMHOME

f_build() {
	RPMSOURCE="$1"
	RPM="$2"
	/bin/su -c "/usr/bin/git clone $RPMSOURCE $RPM" - rpmbuilder
	/bin/su -c "/home/rpmbuilder/$RPM/build.sh $RPM 1>/dev/null" - rpmbuilder
}

BUILDPKGS='rpm-build rpmdevtools redhat-rpm-config make gcc glibc-static \
	   autoconf automake httpd httpd-devel apr-devel'

/usr/bin/yum clean all
/usr/bin/yum install -y $BUILDPKGS git which pwgen cronie tar rsyslogd

f_build 'https://github.com/clcollins/mod_fastcgi-rpm.git' 'mod_fastcgi'
f_build 'https://github.com/imeyer/runit-rpm.git' 'runit-rpm'

/usr/bin/yum install -y $RPMHOME/rpmbuild/RPMS/*/*.rpm

/bin/echo 'Pre-install complete'
