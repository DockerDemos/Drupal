Drupal
======

Docker container for a push-button Drupal website

* [Drupal](https://drupal.org/)

Maintainer: Chris Collins \<collins.christopher@gmail.com\>

Updated: 2014-05-13

##Caution##

This Docker Container is still being developed.  It will work, however, even when it's reached a stable state, this container is a DEMO of the Drupal software.  Updating Drupal inside a running container is likely to be a challenging process.  Backing up your data will also be somewhat difficult.  Use this at your own risk, and do not use it in a production setup unless you're VERY familiar with both Docker and Drupal.

##Building and Running##

This is a [Docker](http://docker.io) container image.  You need to have Docker installed to build and run the container.

To build the image, change directories into the root of this repository, and run:

`docker build -t Drupal .`  <-- note the period on the end

Once it finishes building, you can run the container with:

`docker run -i -t -d -p 8080:80 Drupal`

Then, open your browser and navigate to [http://localhost:8080](http://localhost:8080) to your new site.

To get your Drupal admin password, run:

`docker logs container_name`, where "container_name" is the Docker container ID or short name. The admin password will be printed visible on the terminal screen.

To improve startup speed, this image will not update with the latest version of the Drupal software automatically once the initial image is built.  When a new update is released, run the `docker build` command from above to get the newest version.

##Making the Site Publicly Available##

To make your site available to the public on port 80 and 443 of your host system, use the following `docker run` command instead of the one above:

`docker run -i -t -d -p 80:80 -p 443:443 Drupal`

The site will now be availble as a normal website if you browse to the domain name or IP of your host system.  (Make sure your host system's firewalls are open on ports 80 and 443 accordingly.)

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
