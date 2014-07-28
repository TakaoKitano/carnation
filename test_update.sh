#!/bin/bash
rake resque:stop
rake server:stop
. ./test.env
echo CARNATION_S3_BUCKET_NAME:$CARNATION_S3_BUCKET_NAME
echo CARNATION_MYSQL_HOST:$CARNATION_MYSQL_HOST
echo CARNATION_REDIS_HOST:$CARNATION_REDIS_HOST
rake resque:start
rake server:start
