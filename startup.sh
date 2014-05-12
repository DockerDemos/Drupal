#!/bin/bash

DB_FILE="/db_file.txt"

# Check to see if Drupal is already installed
if [ ! -f "/var/www/html/sites/default/settings.php" ] ; then
  /bin/echo "Drush installing Drupal"
  yes | drush site-install --db-url="$(cat $DB_FILE)" -r /var/www/html
  /bin/echo "0 * * * * /usr/bin/php /var/www/html/cron.php" >> /etc/cron.d/drupal.cron
fi

/bin/echo "Starting init system"
/sbin/runsvdir-start
