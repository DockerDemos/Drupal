# Docker container for a Drupal website
# http://drupal.org
#
# Build from lastest stable source code


FROM centos
MAINTAINER Chris Collins <collins.christopher@gmail.com>

ADD pre-install.sh /pre-install.sh
RUN /pre-install.sh

EXPOSE 80 
EXPOSE 443 

CMD ["/sbin/runsvdir-start"]
