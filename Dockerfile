# Docker container for a Drupal website
# http://drupal.org
#
# Build from lastest stable source code


FROM centos
MAINTAINER Chris Collins <collins.christopher@gmail.com>

ADD pre-install.sh /pre-install.sh
ADD startup.sh /startup.sh
ADD httpd.conf /etc/httpd/conf/httpd.conf
ADD ssl.conf /etc/httpd/conf.d/ssl.conf
ADD certs/* /certs/

RUN /pre-install.sh

EXPOSE 80 
EXPOSE 443 

CMD ["/bin/bash", "/startup.sh"]
