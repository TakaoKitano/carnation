require 'sequel'
require 'mysql2'

dbhost = ENV['CARNATION_MYSQL_HOST']
if dbhost
  p "dbhost=#{dbhost}"
else
  dbhost = "localhost"
end
$DB = Sequel.connect("mysql2://carnation:aFx4mMHb3z7d6dy@#{dbhost}/carnationdb")
Sequel.default_timezone = :utc

require 'resque'
Resque.redis = 'localhost:6379'

require 'aws-sdk'
AWS.config(
  :access_key_id => 'AKIAI2ZSXBHOXAWRFCQA',
  :secret_access_key => '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',
  :region => 'ap-northeast-1')

$s3 = AWS::S3.new

name = ENV['CARNATION_S3_BUCKET_NAME']
if name
  p "bucket name=#{name}"
else
  name = 'carnationdata'
end
$bucket = $s3.buckets[name]


