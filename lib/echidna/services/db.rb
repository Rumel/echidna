# frozen_string_literal: true

require 'sequel'
require_relative './logger'

module Echidna
  class DatabaseService
    attr_reader :db

    def initialize
      @db = Sequel.sqlite('youtube.db')
    end

    def logger
      @logger ||= LogService.new
    end

    def run_migrations
      db.create_table? :videos do
        primary_key :id
        String :video_id, unique: true
        String :channel_title
        DateTime :published_at
      end
    end

    def get_video(video_id)
      video = db[:videos].where(video_id:).first
      if video
        {
          id: video[:id],
          video_id: video[:video_id],
          channel_title: video[:channel_title],
          published_at: video[:published_at].to_datetime
        }
      end
    end

    def insert_video(video_id, channel_title, published_at)
      logger.info "DB: Inserting video #{video_id}"
      db[:videos].insert(video_id:, channel_title:, published_at:)
    end
  end
end
