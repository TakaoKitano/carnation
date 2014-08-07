#!/bin/bash
PWD=`pwd`
mkdir -p log
sudo docker run -d                            \
-v $PWD/log:/home/carnation/magoch_server/log \
-v $PWD/log/nginx:/var/log/nginx              \
-p 437:437 -p 80:80 -p 9292:9292              \
-e "CARNATION_S3_BUCKET_NAME=$CARNATION_S3_BUCKET_NAME"             \
-e "CARNATION_MYSQL_HOST=$CARNATION_MYSQL_HOST"                     \
-e "CARNATION_REDIS_HOST=$CARNATION_REDIS_HOST"                     \
-e "CARNATION_PARSE_APPLICATION_ID=$CARNATION_PARSE_APPLICATION_ID" \
-e "CARNATION_PARSE_REST_API_KEY=$CARNATION_PARSE_REST_API_KEY"     \
-e "RACK_ENV=$RACK_ENV"                                             \
chikaku/carnation:latest
