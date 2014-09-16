#!/bin/bash
#
# copy scripts to a server
#
if [ $# -lt 2 ]
then
   echo "deploy {production|test|development} server_address"
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
elif [[ $env_name = 'development' ]]
then
  echo "config carnation server as development server"
else
  echo "unknown option"
  exit
fi
scp -i doc/magoaws.pem scripts/*  core@${address}:
scp -i doc/magoaws.pem -r conf core@${address}:
ssh -i doc/magoaws.pem core@${address} "cp ${env_name}.env carnation.env"
ssh -i doc/magoaws.pem core@${address} "./config_service.sh"
