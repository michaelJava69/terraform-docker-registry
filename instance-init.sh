#!/bin/bash

# Setups the registry machine to have a running
# Docker registry that makes use of the instance
# profile set in the machine to authenticate
# against the S3 bucket set for storing registry's
# data.

set -o errexit
set -o nounset

main() {
  install_docker
  run_registry
  install_nginx
  # conf_nginx_sblock
}





# Installs the latest `docker-ce` from `apt` using
# the installation script provided by the folks
# at Docker.
install_docker() {
  echo "INFO:
  Installing docker.
  "

  curl -fsSL get.docker.com -o get-docker.sh
  sudo sh ./get-docker.sh


}



conf_nginx_sblock() {
  echo "INFO:
  Configuring  nginx sblock
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.
  "
  



}



install_nginx() {
  echo "INFO:
  Installing nginx
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.
  "

 sudo apt-get update
 # sudo apt-get --yes --force-yes install nginx
 echo "y" | sudo apt-get install nginx

}



# Runs the registry making use of the registry configuration
# that should exist under `/etc/registry.yml`.
#
# Such configuration must be placed before running this one.
run_registry() {
  echo "INFO:
  Starting docker registry. ***********************************************************************************
  ************************************************************************************************************
**********************************************************************************************************8
  "

  if [[ ! -f "/etc/registry.yml" ]]; then
    echo "ERROR:
  File /etc/registry.yml does not exist.
  "
    exit 1
  fi

docker run \
  --name registry \
  --detach \
  --network host \
  --volume /etc/registry.yml:/etc/docker/registry/config.yml \
  registry
}


# Variables

MY_S1=’terraform.mydocker.ga’
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
WEB_USER='www-data'
USER='yourusername'
NGINX_SCHEME='$scheme'
NGINX_REQUEST_URI='$request_uri'

# Functions
ok() { echo -e '\e[32m'$MY_S1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$MY_S1'\e[m'; exit 1; }




main
