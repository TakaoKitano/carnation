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

  def mysql_host
    @host ||= 'localhost'
  end
  def mysql_host=(val)
    @host = val
  end
  def mysql_password
    @password ||= 'aFx4mMHb3z7d6dy'
  end
  def mysql_password=(val)
    @password = val
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
    @s3_bucketname ||= 'carnationtest'
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
  def s3_init
    require 'aws-sdk'
    AWS.config(
      :access_key_id => 'AKIAI2ZSXBHOXAWRFCQA',
      :secret_access_key => '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',
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

  def init
    sequel_init
    resque_init
    s3_init
  end
end

CarnationConfig.mysql_host=ENV['CARNATION_MYSQL_HOST']
CarnationConfig.redis_host=ENV['CARNATION_REDIS_HOST']
CarnationConfig.s3_bucketname=ENV['CARNATION_S3_BUCKET_NAME']
CarnationConfig.init
CarnationConfig.logger.info "mysql_host=#{CarnationConfig.mysql_host}"
CarnationConfig.logger.info "redis_host=#{CarnationConfig.redis_host}"
CarnationConfig.logger.info "s3_bucketname=#{CarnationConfig.s3_bucketname}"
