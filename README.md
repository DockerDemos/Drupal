Drupal
======

Docker container for a push-button Drupal website

* [Drupal](https://drupal.org/)

Maintainer: Chris Collins \<collins.christopher@gmail.com\>

Updated: 2014-05-28

##Caution##

This Docker Container is still being developed.  It will work, however, even when it's reached a stable state, this container is a DEMO of the Drupal software.  Updating Drupal inside a running container is likely to be a challenging process.  Backing up your data will also be somewhat difficult.  Use this at your own risk, and do not use it in a production setup unless you're VERY familiar with both Docker and Drupal.

##Building and Running##

This is a [Docker](http://docker.io) container image.  You need to have Docker installed to build and run the container.

To build the image, change directories into the root of this repository, and run:

`docker build -t drupal .`  <-- note the period on the end

Once it finishes building, you can run the container with:

`docker run -i -t -d -p 8080:80 drupal`

Then, open your browser and navigate to [http://localhost:8080](http://localhost:8080) to view your new site.

To get your Drupal admin password, run:

`docker logs container_name`, where "container_name" is the Docker container ID or short name. The admin password will be printed visible on the terminal screen.

To improve startup speed, this image will not update with the latest version of the Drupal software automatically once the initial image is built.  When a new update is released, run the `docker build` command from above to get the newest version.

##Making the Site Publicly Available##

To make your site available to the public on port 80 and 443 of your host system, use the following `docker run` command instead of the one above:

`docker run -i -t -d -p 80:80 -p 443:443 drupal`

The site will now be availble as a normal website if you browse to the domain name or IP of your host system.  (Make sure your host system's firewalls are open on ports 80 and 443 accordingly.)

##Customizations##

There are a few ways to customize your Drupal container to your environment:

###HTTPS/SSL###

If you want to setup SSL for your container, just copy the SSL certificate and key into the root of the image (alongside the Dockerfile).  Name them "localhost.crt" and "localhost.key", and when you run the `docker build` command, SSL will be automatically setup for you, using your cert and key.

###Email###

You can start your container with email delivery to a custom SMTP server by setting the SMTPSERVER environmental variable when you run the container.  Just add:

`-e "SMTPSERVER=my.smtp.server"` to the flags with the `docker run` command.

Optionally, you can specify:

`-e "DOMAIN=my.domain"`, and the container will use "my.domain" as the SMTP server rewrite domain.  If you don't specify it, then the container will try to infer it from the SMTP server you provide.

Finally, if you provide your own ssmtp.conf file in the root of the image (alongside the Dockerfile), the container will use that ssmtp.conf file instead of creating it's own.

###Syslog###

You can specify a Syslog server to receive log messages from the container.  Just add:

`-e "SYSLOGSERVER=my.syslog.server"` to the flags with the `docker run` command.

##Known Issues##

Tracked on Github: [https://github.com/DockerDemos/Drupal/issues](https://github.com/DockerDemos/Drupal/issues)

##Acknowledgements##

Thanks to:

* Ian Meyer [https://github.com/imeyer](https://github.com/imeyer) for his Runit rpm spec file and build script for RHEL-based systems.

##Copyright Information##

Copyright (C) 2014 Chris Collins

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
