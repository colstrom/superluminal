require 'aws-sdk'
require 'terminal-announce'
require_relative 'settings'

# Module for dealing with S3.
module SimpleStorageService
  def self.connect(region: Settings.default_region)
    Aws::S3::Client.new region: region
  end

  def self.create_buckets(project, environments = Settings.environments)
    environments.each do |environment|
      with_api = connect region: environment.region
      bucket_name = "#{ project }-#{ environment.name }"
      create_bucket "#{ Settings.s3.namespace }-#{ bucket_name }", with_api: with_api
    end
  end

  def self.create_bucket(bucket_name, with_api: connect)
    with_api.create_bucket bucket: bucket_name
    Announce.success "#{ bucket_name } created."
    rescue Aws::S3::Errors::BucketAlreadyExists
      Announce.failure "#{ bucket_name } already exists."
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
      Announce.info "#{ bucket_name } is already owned by this account."
  end
end
