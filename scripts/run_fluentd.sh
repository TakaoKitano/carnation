#!/bin/bash
#
# check env file
#
PWD=`pwd`
docker stop fluentd
docker rm fluentd
docker run -d                                   \
-v $PWD/log:/home/carnation/magoch_server/log   \
-v $PWD/conf:/home/carnation/magoch_server/conf \
-v $PWD/log/nginx:/var/log/nginx                \
--name=fluentd                                  \
chikaku/fluentd
