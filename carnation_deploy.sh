#!/bin/bash
#
# copy scripts to a server
#
if [ $# -lt 2 ]
then
   echo "deploy {test|production} server_address"
   exit
fi
env_name=$1
address=$2
echo "env_name:${env_name}"
echo "server address:${address}"
scp -i doc/magoaws.pem scripts/*  core@${address}:
scp -i doc/magoaws.pem -r conf core@${address}:
ssh -i doc/magoaws.pem core@${address} "cp ${env_name}.env carnation.env 2>&1"
ssh -i doc/magoaws.pem core@${address} "./config_service.sh"
