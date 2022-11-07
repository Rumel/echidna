# frozen_string_literal: true

require 'sequel'
require 'aws-sdk-dynamodb'
require 'dotenv/load'
require 'pry'

TABLE_NAME = 'echidna_videos'

@ddb = Aws::DynamoDB::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

def get_item(video_id)
  resp = @ddb.get_item({
                         key: {
                           'video_id' => video_id
                         },
                         table_name: TABLE_NAME
                       })
  resp.item
end

def put_item(item)
  exists = get_item(item[:video_id])
  puts exists

  unless exists
    puts "Adding #{item[:video_id]} #{item[:channel_title]}"
    @ddb.put_item({
                    item:,
                    table_name: TABLE_NAME
                  })
  end
end

db = Sequel.sqlite('youtube.db')
videos = db[:videos]
videos.each do |video|
  put_item({
             video_id: video[:video_id],
             channel_title: video[:channel_title],
             published_at: video[:published_at].to_s
           })
end
