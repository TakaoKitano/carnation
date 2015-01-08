#!/bin/bash
#
# copy scripts to a server
#
if [ $# -lt 2 ]
then
   echo "deploy {production|test} server_address"
   exit
fi
env_name=$1
address=$2
echo "env_name:${env_name}"
echo "server address:${address}"
if [[ $env_name = 'production' ]]
then
  echo "config carnation server as production server"
elif [[ $env_name = 'test' ]]
then
  echo "config carnation server as test server"
else
  echo "unknown option"
  exit
fi

echo "copying script files..."
scp scripts/*  core@${address}:

echo "copying conf file..."
scp -r conf/ core@${address}:

echo "copying env file..."
scp envfiles/${env_name}.env core@${address}:carnation.env


echo "configure services on the target machine..."
ssh core@${address} "cp conf/fluentd.${env_name}.conf conf/fluentd.conf"
ssh core@${address} "./config_service.sh"
