#!/bin/bash
#
# check env
#
[ -z "$CARNATION_S3_BUCKET_NAME" ] && echo "need to export CARNATION_S3_BUCKET_NAME" && exit 1
[ -z "$CARNATION_MYSQL_HOST" ] && echo "need to export CARNATION_MYSQL_HOST" && exit 1
[ -z "$CARNATION_REDIS_HOST" ] && echo "need to export CARNATION_REDIS_HOST" && exit 1
[ -z "$CARNATION_PARSE_APPLICATION_ID" ] && echo "need to export CARNATION_PARSE_APPLICATION_ID" && exit 1
[ -z "$CARNATION_PARSE_REST_API_KEY" ] && echo "need to export CARNATION_PARSE_REST_API_KEY" && exit 1
PWD=`pwd`
mkdir -p log
sudo docker kill carnation
sudo docker rm carnation
sudo docker run -d                            \
-v $PWD/log:/home/carnation/magoch_server/log \
-v $PWD/log/nginx:/var/log/nginx              \
-p 443:443 -p 80:80 -p 9292:9292              \
-e "CARNATION_S3_BUCKET_NAME=$CARNATION_S3_BUCKET_NAME"             \
-e "CARNATION_MYSQL_HOST=$CARNATION_MYSQL_HOST"                     \
-e "CARNATION_REDIS_HOST=$CARNATION_REDIS_HOST"                     \
-e "CARNATION_PARSE_APPLICATION_ID=$CARNATION_PARSE_APPLICATION_ID" \
-e "CARNATION_PARSE_REST_API_KEY=$CARNATION_PARSE_REST_API_KEY"     \
-e "RACK_ENV=$RACK_ENV"                                             \
--name=carnation                                                    \
chikaku/carnation:latest
