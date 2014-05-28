# Docker container for a Drupal website
# http://drupal.org
#
# Build from lastest stable source code


FROM centos
MAINTAINER Chris Collins <collins.christopher@gmail.com>

ADD . /build
RUN /build/pre-install.sh 
RUN /build/config.sh
RUN /build/post-install.sh

EXPOSE 80 
EXPOSE 443 

CMD ["/bin/bash", "/startup.sh"]
