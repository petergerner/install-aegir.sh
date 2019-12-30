#! /bin/bash
#
# Aegir 3.x install script for Debian / Ubuntu
# (install-aegir.sh)
# on Github: https://github.com/petergerner/install-aegir.sh
#

# ***********************************
# set versions for Aegir & Drush
DRUSH_VERSION="8.3.2"  # 2019-11-26
# https://github.com/drush-ops/drush/releases
AEGIR_VERSION="3.182"  # 2019-10-08
# https://docs.aegirproject.org
#
# TODO
#   choose webserver: now only Nginx, later: Apache or Nginx
#   choose PHP version: now the default PHP on the server, later: set explicit version
#   choose how to run PHP: now PHP-FPM, later PHP-FMP or mod_php
# TODO
MYSQL_ROOT_PASSWORD     = "strongpassword"
MYSQL_AEGIR_DB_USER     = "aegir_root"
MYSQL_AEGIR_DB_PASSWORD = "strongpassword"
#
# ***********************************
#
#
# 1. install software requirements for Aegir
apt update -y

# all aegir dependencies as per control file, and the mc
# https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control
# deps: sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client
# Debian 10:
# apt -y install adduser
# apt -y install lsb-base
# apt -y install sudo
# apt -y install ucf
apt -y install curl
apt -y install git-core
apt -y install nfs-client
apt -y install rsync
apt -y install unzip
# just for fun
apt -y install mc
# SSL, TBC     !!!!
apt -y install ssl-cert

# TODO: UFW install + config !!!!!!!
# apt -y install ufw

# Database
apt -y install mariadb-client
apt -y install mariadb-server

# MTA
# TODO: Postfix config !!!!!!!
apt -y install postfix

# PHP packages
#   1. how to run PHP
# install the default PHP package on distro
apt -y install php-fpm
# explicit PHP version:   apt -y install php7.2-fpm
# alternative to php-fpm: apt -y install libapache2-mod-php7.2

#   2. PHP libraries for Drupal & Aegir
apt -y install php-mysql php-gd php-xml
# apt -y install php7.2-mysql php7.2-gd php7.2-xml

#   3. PHP libraries for CiviCRM
apt -y install php-mbstring php-curl php-zip
# apt -y install php7.2-mbstring php7.2-curl php7.2-zip

# Webserver
apt -y install nginx
# apt -y install apache2


# 2. LAMP configurations
#
# TODO: set higher PHP limits for Nginx, Apache: upload file, memory_limit, ...
# sed -i 's/memory_limit = -1/memory_limit = 192M/' /etc/php5/cli/php.ini
# sed -i 's/memory_limit = 128M/memory_limit = 192M/' /etc/php5/apache2/php.ini
#
# Apache
# a2enmod rewrite
# ln -s /var/aegir/config/apache.conf /etc/apache2/conf-available/aegir.conf
# a2enconf aegir
#
# nginx
# TODO: make sure your nginx installation is up and running
ln -s /var/aegir/config/nginx.conf /etc/nginx/conf.d/aegir.conf
# Do not reload/restart Nginx after running these commands, it will fail.

# MySQL
# remove the anonymous, passwordless login
mysql_secure_installation
# create user aegir_root
mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" \
--execute="GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_AEGIR_DB_USER'@'%' \
IDENTIFIED BY '$MYSQL_AEGIR_DB_PASSWORD' WITH GRANT OPTION;"

# enable all IP addresses to bind, not just localhost
# TODO: locate .cnf file: sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
service mysql restart

# add Aegir user
adduser --system --group --home /var/aegir aegir --shell /usr/bin/bash
adduser aegir www-data
# TDC: usermod -aG www-data aegir
# TBC: usermod -aG users aegir

# sudo rights for the Aegir user to restart Apache
echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  | tee /tmp/aegir
# echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' | tee /tmp/aegir
chmod 0440 /tmp/aegir
mv /tmp/aegir /etc/sudoers.d/aegir

# Install composer
compvers=ba13e3fc70f1c66250d1ea7ea4911d593aa1dba5
wget https://raw.githubusercontent.com/composer/getcomposer.org/$compvers/web/installer -O - -q | php -- --quiet
sudo mv composer.phar /usr/bin/composer
su - aegir -c "composer --version"

# Drush 8
# Pick the latest stable Dursh 8 version
# https://github.com/drush-ops/drush/releases
wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar -O - -q > /usr/local/bin/drush
chmod +x /usr/local/bin/drush
su - aegir -c "drush init  --add-path=/var/aegir --bg -y"

# variables for Aegir
echo "ÆGIR | -------------------------"
echo 'ÆGIR | Hello! '
echo 'ÆGIR | We will install Aegir with the following options:'
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
