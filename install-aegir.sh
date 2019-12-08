#! /bin/bash
#
# Aegir 3.x install script for Debian / Ubuntu
# (install-aegir.sh)
# on Github: https://github.com/petergerner/install-aegir.sh
#

# ***********************************
# set versions Aegir & Drush versions
DRUSH_VERSION="8.3.2"
# see: https://github.com/drush-ops/drush/releases
#
AEGIR_VERSION="3.182"
#
# TBD
MYSQL_ROOT_PASSWORD="strongpassword"
MYSQL_AEGIR_DB_USER="aegir_root"
MYSQL_AEGIR_DB_PASSWORD="strongpassword"
#
# ***********************************
#
#
# 1. install software requirements for Aegir

# apt update -qq &> /dev/null
apt update -y

# aegir dependencies as per control file, and the mc
# https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control
# sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client

# apt -y install adduser    &> /dev/null
apt -y install curl       &> /dev/null
apt -y install git-core   &> /dev/null
# apt -y install lsb-base   &> /dev/null
apt -y install nfs-client &> /dev/null
apt -y install rsync      &> /dev/null
# apt -y install sudo       &> /dev/null
# apt -y install ucf        &> /dev/null
apt -y install unzip      &> /dev/null
# just for fun
apt -y install mc         &> /dev/null

# SSL, TBC     !!!!
apt -y install ssl-cert &> /dev/null

# UFW TBD  install + config !!!!!!!
# apt -y install ufw &> /dev/null


# Database
apt -y install mariadb-client &> /dev/null
apt -y install mariadb-server &> /dev/null

# MTA
# add no config option
apt -y install postfix &> /dev/null

# PHP packages
#   1. worker
# apt -y install php7.2-fpm &> /dev/null
apt -y install php-fpm &> /dev/null

#   alternative to php-fpm:
# apt -y install libapache2-mod-php7.2 &> /dev/null

#   2. for Drupal & Aegir
# apt -y install php7.2-mysql php7.2-gd php7.2-xml &> /dev/null
apt -y install php-mysql php-gd php-xml

#   3. for CiviCRM
# apt -y install php7.2-mbstring php7.2-curl php7.2-zip &> /dev/null
apt -y install php-mbstring php-curl php-zip

# webserver
apt -y install nginx &> /dev/null
# apt -y install apache2 &> /dev/null


# 2. LAMP configurations
#
# PHP: set higher memory limits
# sed -i 's/memory_limit = -1/memory_limit = 192M/' /etc/php5/cli/php.ini
# sed -i 's/memory_limit = 128M/memory_limit = 192M/' /etc/php5/apache2/php.ini
#
# Apache
# a2enmod rewrite
# ln -s /var/aegir/config/apache.conf /etc/apache2/conf.d/aegir.conf

# on Ubuntu 14.04+
# ln -s /var/aegir/config/apache.conf /etc/apache2/conf-available/aegir.conf
# a2enconf aegir

#
# nginx
# make sure your nginx installation is up and running
ln -s /var/aegir/config/nginx.conf /etc/nginx/conf.d/aegir.conf
# Do not reload/restart Nginx after running these commands, it will fail.

# MySQL
# remove the anonymous, passwordless login
mysql_secure_installation

# create user aegir_root
# If you are running your Aegir databases on a remote DB server, you will want to create this aegir_root user.
mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" --execute="GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_AEGIR_DB_USER'@'%' IDENTIFIED BY '$MYSQL_AEGIR_DB_PASSWORD' WITH GRANT OPTION;"

# enable all IP addresses to bind, not just localhost
# sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
service mysql restart

# add Aegir user
adduser --system --group --home /var/aegir aegir
adduser aegir www-data

# usermod -aG www-data aegir
# usermod -aG users aegir

#
# sudo rights for the Aegir user to restart Apache
echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  | tee /tmp/aegir
echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' | tee -a /tmp/aegir
chmod 0440 /tmp/aegir
mv /tmp/aegir /etc/sudoers.d/aegir

# Install composer
compvers=ba13e3fc70f1c66250d1ea7ea4911d593aa1dba5
wget https://raw.githubusercontent.com/composer/getcomposer.org/$compvers/web/installer -O - -q | php -- --quiet
sudo mv composer.phar /usr/bin/composer
# composer --version

# Drush 8
# Pick the latest stable Dursh 8 version
# https://github.com/drush-ops/drush/releases
DRUSH_VERSION=8.3.2  # 2019-11-26
wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar -O - -q > /usr/local/bin/drush
chmod +x /usr/local/bin/drush
drush init  --add-path=/var/aegir --bg -y

# variables for Aegir
echo "ÆGIR | -------------------------"
echo 'ÆGIR | Hello! '
echo 'ÆGIR | When the database is ready, we will install Aegir with the following options:'
HOSTNAME=`hostname --fqdn`
# AEGIR_MAKEFILE="http://cgit.drupalcode.org/provision/plain/aegir-release.make?h=$AEGIR_VERSION"
# AEGIR_MAKEFILE="https://raw.githubusercontent.com/omega8cc/provision/4.x/aegir-release.make"

### TBD !!!!!!!!!!!!!!!
# use own makefile using BOA head (or the default Aegir makefile):
# if [ "${_AEGIR_VERSION}" = "HEAD" ]; then
# git clone --branch feature/3.1.x-profile https://github.com/omega8cc/hostmaster.git
#  ${gCb} feature/3.1.x-profile ${gitHub}/hostmaster.git    &> /dev/null
#  ${gCb} feature/3.1.x-hosting ${gitHub}/hosting.git       &> /dev/null
#  ${gCb} feature/3.1.x-eldir ${gitHub}/eldir.git           &> /dev/null


AEGIR_HOSTMASTER_ROOT="/var/aegir/hostmaster-$AEGIR_VERSION"
PROVISION_VERSION="$AEGIR_VERSION"
AEGIR_CLIENT_EMAIL="aegir@debian.local"
AEGIR_CLIENT_NAME="admin"
AEGIR_PROFILE="hostmaster"
AEGIR_WORKING_COPY="0"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Hostname: $HOSTNAME"
echo "ÆGIR | Version: $AEGIR_VERSION"
echo "ÆGIR | Database Host: localhost"
echo "ÆGIR | Makefile: $AEGIR_MAKEFILE"
echo "ÆGIR | Profile: $AEGIR_PROFILE"
echo "ÆGIR | Root: $AEGIR_HOSTMASTER_ROOT"
echo "ÆGIR | Client Name: $AEGIR_CLIENT_NAME"
echo "ÆGIR | Client Email: $AEGIR_CLIENT_EMAIL"
echo "ÆGIR | Working Copy: $AEGIR_WORKING_COPY"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Checking Aegir directory..."
ls -lah /var/aegir
echo "ÆGIR | -------------------------"
echo "ÆGIR | Running 'drush cc drush' ... "
drush cc drush
echo 'ÆGIR | Checking drush status...'
drush status

#### Install or upgrade provision
# http://docs.aegirproject.org/en/3.x/install/#43-install-provision
# it checks whether Provision is installed only at /var/aegir/.drush/commands
echo "ÆGIR | -------------------------"
DRUSH_COMMANDS_DIRECTORY="/var/aegir/.drush/commands"
if [ -d "$DRUSH_COMMANDS_DIRECTORY/provision" ]; then
    OLDVERSION=`cat $DRUSH_COMMANDS_DIRECTORY/provision/provision.info | grep "version="`
    echo "ÆGIR | Upgrading provision from $OLDVERSION to $AEGIR_VERSION."
else
    echo "ÆGIR | Provision Commands not found! Installing version $AEGIR_VERSION."
fi
# TBC: it should overwrite existing directory
# drush dl provision-$AEGIR_VERSION --destination=$DRUSH_COMMANDS_DIRECTORY -y
# ${gCb} ${_BRANCH_PRN} ${gitHub}/provision.git /var/aegir/.drush/sys/provision &> /dev/null
# git clone --branch 4.x https://github.com/omega8cc/provision.git $DRUSH_COMMANDS_DIRECTORY
su -s /bin/bash - aegir -c "git clone --branch 4.x https://github.com/omega8cc/provision.git $DRUSH_COMMANDS_DIRECTORY"

echo "ÆGIR | Provision Commands installed / upgaded."

#### Check apache and database
echo "ÆGIR | -------------------------"
echo "ÆGIR | Starting apache2 now to reduce downtime."
sudo apache2ctl graceful
# sudo apache2ctl configtest

# Returns true once mysql can connect.
while ! mysqladmin ping -hlocalhost --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database on localhost ..."
done
echo "ÆGIR | Database is active!"


drush @hostmaster vget site_name > /dev/null 2>&1
if [ ${PIPESTATUS[0]} == 0 ]; then
  echo "ÆGIR | Hostmaster site found. Checking for upgrade platform..."

  # Only upgrade if site not found in current containers platform.
  if [ ! -d "$AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME" ]; then
      echo "ÆGIR | Site not found at $AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME, upgrading!"
      echo "ÆGIR | Clear Hostmaster caches and migrate ... "
      drush @hostmaster cc all
      echo "ÆGIR | Running 'drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER_ROOT -y'...!"
      drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER_ROOT -y -v
  else
      echo "ÆGIR | Site found at $AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME"
      # TBD: check drupal version and upgrade if needed !!!
  fi

# if @hostmaster is not accessible, install it.
else
  echo "ÆGIR | Hostmaster not found. Continuing with install!"

  echo "ÆGIR | -------------------------"
  echo "ÆGIR | Running: drush cc drush"
  drush cc drush

  echo "ÆGIR | -------------------------"
  echo "ÆGIR | Running: drush hostmaster-install"

  # set -ex

  # hibák
  # 1.   SQLSTATE[HY000] [1698] Access denied for user 'root'@'localhost'
  # 2.   aegir sudo test kell előtte
su -s /bin/bash - aegir -c " \
  drush hostmaster-install -y --strict=0 $HOSTNAME \
    --aegir_db_host     = 'localhost' \
    --aegir_db_pass     = $MYSQL_AEGIR_DB_PASSWORD \
    --aegir_db_port     = '3306' \
    --aegir_db_user     = $MYSQL_AEGIR_DB_USER \
    --aegir_host        = $HOSTNAME \
    --client_name       = $AEGIR_CLIENT_NAME \
    --client_email      = $AEGIR_CLIENT_EMAIL \
    --makefile          = $AEGIR_MAKEFILE \
    --http_service_type = 'nginx' \
    --profile           = $AEGIR_PROFILE \
    --root              = $AEGIR_HOSTMASTER_ROOT \
    --working-copy      = $AEGIR_WORKING_COPY \
"
  sleep 3

  # Exit on the first failed line.
  # emmi??? set -e

  echo "ÆGIR | Running 'drush cc drush' ... "
  drush cc drush

  # enable modules
  echo "ÆGIR | Enabling hosting queued..."
  drush @hostmaster en hosting_queued -y

  echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
  # fix_permissions, fix_ownership, hosting_civicrm, hosting_civicrm_cron
  drush @hostmaster en hosting_civicrm_cron -y
fi
