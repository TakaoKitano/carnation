require 'sequel'
require 'mysql2'

$DB = Sequel.connect('mysql://carnation:aFx4mMHb3z7d6dy@localhost/carnationdb')
Sequel.default_timezone = :utc

require 'resque'
Resque.redis = 'localhost:6379'

require 'aws-sdk'
AWS.config(
  :access_key_id => 'AKIAI2ZSXBHOXAWRFCQA',
  :secret_access_key => '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',
  :region => 'ap-northeast-1')

$s3 = AWS::S3.new
$bucket = $s3.buckets['carnationdata']


