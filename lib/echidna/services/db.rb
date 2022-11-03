# frozen_string_literal: true

require 'sequel'
require 'aws-sdk-dynamodb'
require_relative './logger'

module Echidna
  class DatabaseService
    attr_reader :ddb

    TABLE_NAME = 'echidna_videos'

    def initialize
      @ddb = Aws::DynamoDB::Client.new(
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region: ENV['AWS_REGION']
      )
    end

    def logger
      @logger ||= LogService.new
    end

    def get_video(video_id)
      item = ddb.get_item({
                            key: {
                              'video_id' => video_id
                            },
                            table_name: TABLE_NAME
                          }).item

      if item
        {
          channel_title: item['channel_title'],
          published_at: DateTime.parse(item['published_at']).to_datetime,
          video_id: item['video_id']
        }
      end
    end

    def insert_video(video_id, channel_title, published_at)
      logger.info "DB: Inserting video #{video_id}"
      ddb.put_item({
                     item: {
                       video_id:,
                       channel_title:,
                       published_at: published_at.to_s
                     },
                     table_name: TABLE_NAME
                   })
    end
  end
end
