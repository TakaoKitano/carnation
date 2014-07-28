require 'sequel'
require 'mysql2'

mysql_host = ENV['CARNATION_MYSQL_HOST']
if not mysql_host
  mysql_host = "localhost"
end
p "CARNATION_MYSQL_HOST=#{mysql_host}"

redis_host = ENV['CARNATION_REDIS_HOST']
if not redis_host
  redis_host = "localhost"
end
p "CARNATION_REDIS_HOST=#{redis_host}"

s3_bucket_name = ENV['CARNATION_S3_BUCKET_NAME']
if not s3_bucket_name
  s3_bucket_name = 'carnationtest'
end
p "CARNATION_S3_BUCKET_NAME=#{s3_bucket_name}"

$DB = Sequel.connect("mysql2://carnation:aFx4mMHb3z7d6dy@#{mysql_host}/carnationdb")
Sequel.default_timezone = :utc

require 'resque'
require 'resque-retry'
require 'resque-timeout'
Resque.redis = "redis://#{redis_host}:6379"
Resque.logger = Logger.new(STDOUT)
Resque.logger.level = Logger::INFO
#Resque.logger.level = Logger::DEBUG
Resque::Plugins::Timeout.timeout = 900
require 'redlock'
$DLM = Redlock.new("redis://#{redis_host}:6379")

require 'aws-sdk'
AWS.config(
  :access_key_id => 'AKIAI2ZSXBHOXAWRFCQA',
  :secret_access_key => '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',
  :region => 'ap-northeast-1')
$s3 = AWS::S3.new
$bucket = $s3.buckets[s3_bucket_name]


