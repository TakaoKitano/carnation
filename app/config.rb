require 'sequel'
require 'mysql2'

module CarnationConfig
  module_function
  def logger
    if not @logger
      @logger = Logger.new(STDOUT) unless @logger
      @logger.level = Logger::INFO
    end
    return @logger
  end

  def default_timezone
    return 9 # JST
  end

  def mysql_host
    @mysql_host ||= 'localhost'
  end
  def mysql_host=(val)
    @mysql_host = val
  end
  def mysql_password
    @mysql_password ||= 'password'
  end
  def mysql_password=(val)
    @mysql_password = val
  end
  def sequel_init
    @db = Sequel.connect("mysql2://carnation:#{mysql_password}@#{mysql_host}/carnationdb")
    Sequel.default_timezone = :utc
  end

  def redis_host
    @redis_host ||= 'localhost'
  end
  def redis_host=(val)
    @redis_host = val
  end
  def redis_port
    @redis_port ||= 6379
    return @redis_port
  end

  def s3_bucketname
    @s3_bucketname ||= 'xxx'
  end
  def s3_bucketname=(val)
    @s3_bucketname = val
  end
  def s3bucket
    if not @s3bucket
      s3_init
    end
    @s3bucket
  end
  def s3_access_key_id
    @s3_access_key_id ||= 'xxxxx'
  end
  def s3_access_key_id=(val)
    @s3_access_key_id = val
  end
  def s3_secret_access_key
    @s3_secret_access_key ||= 'xxxxx'
  end
  def s3_secret_access_key=(val)
    @s3_secret_access_key = val
  end
  
  def s3_init
    require 'aws-sdk'
    AWS.config(
      :access_key_id => s3_access_key_id,
      :secret_access_key => s3_secret_access_key,
      :region => 'ap-northeast-1')
    @s3 = AWS::S3.new
    @s3bucket ||= @s3.buckets[s3_bucketname]
  end

  def resque_init
    require 'resque'
    require 'resque-retry'
    require 'resque-timeout'
    Resque.redis = "redis://#{redis_host}:#{redis_port}"
    Resque.logger = CarnationConfig.logger
    Resque::Plugins::Timeout.timeout = 900
  end

  def dlm
    require 'redlock'
    @dlm ||= Redlock.new("redis://#{redis_host}:#{redis_port}")
    return @dlm
  end

  def parse_application_id
    @parse_application_id ||= "lnVlRH1NEDwYoHPX3iEnfXqY5CmgmkAM3p6HpOyj"
  end
  def parse_application_id=(val)
    @parse_application_id = val
  end

  def parse_rest_api_key
    @parse_rest_api_key ||= "UCSpbRxtpHPCmHkbfPblDMsB32glHTMkyHS32P7A"
  end
  def parse_rest_api_key=(val)
    @parse_rest_api_key = val
  end

  def init
    sequel_init
    resque_init
    s3_init
  end
end

CarnationConfig.mysql_host=ENV['CARNATION_MYSQL_HOST']
CarnationConfig.mysql_password=ENV['CARNATION_MYSQL_PASSWORD']
CarnationConfig.redis_host=ENV['CARNATION_REDIS_HOST']
CarnationConfig.s3_bucketname=ENV['CARNATION_S3_BUCKET_NAME']
CarnationConfig.s3_access_key_id=ENV['CARNATION_S3_ACCESS_KEY_ID']
CarnationConfig.s3_secret_access_key=ENV['CARNATION_S3_SECRET_ACCESS_KEY']
CarnationConfig.parse_application_id=ENV['CARNATION_PARSE_APPLICATION_ID']
CarnationConfig.parse_rest_api_key=ENV['CARNATION_PARSE_REST_API_KEY']
CarnationConfig.init
CarnationConfig.logger.info "mysql_host=#{CarnationConfig.mysql_host}"
CarnationConfig.logger.info "redis_host=#{CarnationConfig.redis_host}"
CarnationConfig.logger.info "s3_bucketname=#{CarnationConfig.s3_bucketname}"
CarnationConfig.logger.info "parse_application_id=#{CarnationConfig.parse_application_id}"
CarnationConfig.logger.info "parse_rest_api_key=#{CarnationConfig.parse_rest_api_key}"
