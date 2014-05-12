#!/bin/bash

DB_USER="drupal"
DB_PASS="$(pwgen -c -n -1 12)"
DB_HOST="localhost"
DB_NAME="drupal"
DB_URL="mysql://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME"
DB_DEFAULTS="/root/.my.cnf"

# Check to see if Drupal is already installed
if [ ! -f "/var/www/html/sites/default/settings.php" ] ; then
  # Start MySQL for database setup
  /usr/bin/mysqld_safe &
  sleep 5

  # Create the DB, then install Drupal
  mysql --defaults-extra-file=$DB_DEFAULTS -e "CREATE DATABASE $DB_NAME; GRANT ALL PRIVILEGES ON $DB_NAME.* TO \"$DB_USER\"@\"$DB_HOST\" IDENTIFIED BY \"$DB_PASS\"; FLUSH PRIVILEGES;"

  /bin/echo "Drush installing Drupal"
  yes | drush site-install --db-url="$DB_URL" -r /var/www/html

  /bin/echo "0 * * * * /usr/bin/php /var/www/html/cron.php" >> /etc/cron.d/drupal.cron

  # Stop the rogue MySQL instance so we can run it with a supervisor
  /bin/kill -15 `cat /var/run/mysqld/mysqld.pid`
  sleep 10
fi



/bin/echo "Starting init system"
/sbin/runsvdir-start
