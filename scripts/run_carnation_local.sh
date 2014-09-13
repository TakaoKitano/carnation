#!/bin/bash
echo CARNATION_S3_BUCKET_NAME=$CARNATION_S3_BUCKET_NAME
echo CARNATION_MYSQL_HOST=$CARNATION_MYSQL_HOST
echo CARNATION_REDIS_HOST=$CARNATION_REDIS_HOST
PWD=`pwd`
mkdir -p log
echo "stop container" && sudo docker kill carnation
echo "remove container image" && sudo docker rm carnation
sudo docker run -d                            \
--net=host                                    \
-v /var/run/mysqld:/var/run/mysqld            \
-v $PWD/log:/home/carnation/magoch_server/log \
-v $PWD/conf:/home/carnation/magoch_server/conf \
-v $PWD/log/nginx:/var/log/nginx              \
-p 443:443 -p 80:80 -p 9292:9292              \
-e "CARNATION_S3_BUCKET_NAME=$CARNATION_S3_BUCKET_NAME"             \
-e "CARNATION_S3_ACCESS_KEY_ID=$CARNATION_S3_ACCESS_KEY_ID"         \
-e "CARNATION_S3_SECRET_ACCESS_KEY=$CARNATION_S3_SECRET_ACCESS_KEY" \
-e "CARNATION_MYSQL_HOST=$CARNATION_MYSQL_HOST"                     \
-e "CARNATION_MYSQL_PASSWORD=$CARNATION_MYSQL_PASSWORD"             \
-e "CARNATION_REDIS_HOST=$CARNATION_REDIS_HOST"                     \
-e "CARNATION_PARSE_APPLICATION_ID=$CARNATION_PARSE_APPLICATION_ID" \
-e "CARNATION_PARSE_REST_API_KEY=$CARNATION_PARSE_REST_API_KEY"     \
-e "RACK_ENV=$RACK_ENV"                                             \
--name=carnation \
chikaku/carnation
