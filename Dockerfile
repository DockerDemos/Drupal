# Docker container for a Drupal website
# http://drupal.org
#
# Build from lastest stable source code


FROM centos
MAINTAINER Chris Collins <collins.christopher@gmail.com>

ADD pre-install.sh /pre-install.sh
RUN /pre-install.sh

ADD httpd.conf /etc/httpd/conf/httpd.conf

EXPOSE 80 
EXPOSE 443 

CMD ["/sbin/runsvdir-start"]
