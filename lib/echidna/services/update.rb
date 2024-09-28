# frozen_string_literal: true

require_relative './config'
require_relative './youtube'
require_relative './db'
require_relative './logger'

module Echidna
  class UpdateService
    def db
      @db ||= DatabaseService.new
    end

    def youtube
      @youtube ||= YoutubeService.new
    end

    def config
      @config ||= ConfigService.new
    end

    def logger
      @logger ||= LogService.new
    end

    def channels
      @channels ||= config.load_channels
    end

    def playlists
      @playlists ||= config.load_playlists
    end

    def map_videos(items)
      items.map do |i|
        db_video = db.get_video(i.snippet.resource_id.video_id)
        if db_video
          {
            channel_title: db_video[:channel_title],
            published_at: db_video[:published_at]
          }
        else
          video = youtube.get_video(i.snippet.resource_id.video_id)
          {
            channel_title: video.snippet.channel_title,
            published_at: video.snippet.published_at
          }
        end
      end
    end

    def add_videos_to_playlists
      count = 0
      channels.each do |current_channel|
        logger.info "Current channel is #{current_channel.name}"

        play_list_items_result = youtube.list_videos_playlist_items(current_channel.id, current_channel.max_results)
        # Maybe make this a config setting?
        live_playlist_items_result = youtube.list_live_playlist_items(current_channel.id, current_channel.max_results)

        objects = []
        [play_list_items_result, live_playlist_items_result].each do |list|
          next if list.nil?

          objects += list.items.select do |item|
            if current_channel.filter.nil?
              true
            else
              item.snippet.title.match(/#{current_channel.filter}/)
            end
          end
        end

        objects.each do |object|
          exists_in_db = !db.get_video(object.snippet.resource_id.video_id).nil?
          if exists_in_db
            logger.info "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists in the database"
            next
          end

          # This is probably an issue
          current_items = youtube.get_all_playlist_items(current_channel.playlist_id)
          current_items_video_ids = current_items.map { |i| i.snippet.resource_id.video_id }
          selected_playlist = playlists.find { |playlist| playlist.id == current_channel.playlist_id }

          exists_in_playlist = current_items_video_ids.include?(object.snippet.resource_id.video_id)
          if exists_in_playlist
            logger.info "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists in playlist"
          else
            playlist_item = {
              snippet: {
                resource_id: object.snippet.resource_id,
                playlist_id: current_channel.playlist_id,
                position: get_position(selected_playlist, map_videos(current_items), object)
              }
            }
            logger.info "Inserting \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id}"
            youtube.insert_playlist_item(playlist_item)
          end
          db.insert_video(object.snippet.resource_id.video_id, object.snippet.channel_title, object.snippet.published_at)
          count += 1
        end
      rescue StandardError => e
        logger.error "Error: #{e.message}"
      end

      puts "Inserted #{count} videos into playlists"
    end

    def remove_videos_from_playlists
      time = Time.now
      playlists.each do |playlist|
        count = 0
        next if playlist.time.nil?

        check_time = (time - playlist.time).to_i

        puts "Checking playlist #{playlist.title} for videos to delete"

        current_items = youtube.get_all_playlist_items(playlist.id)
        current_items.each do |item|
          item_time = item.snippet.published_at.to_time.to_i
          next unless item_time < check_time

          puts "Deleting #{item.snippet.title}"
          begin
            youtube.delete_playlist_item(item.id)
            count += 1
          rescue StandardError => e
            logger.error "Error: #{e.message}"
          end
        end
        puts "Deleted #{count} videos from #{playlist.title}"
      end
    end

    private

    def get_position(selected_playlist, videos, item)
      return 0 if videos.length.zero?

      found = nil
      after_found = false
      case selected_playlist.order
      when 'title'
        channel_videos = videos.select { |v| v[:channel_title] == item.snippet.channel_title }

        if channel_videos.length.positive?
          # Other videos are already inserted for the channel
          found = channel_videos.find { |i| item.snippet.published_at < i[:published_at] }
          # need to handle the case where video is the newest
          unless found
            found = channel_videos.last
            after_found = true
          end
        else
          # First video of title in list
          # It just needs to be inserted before the other channels
          found = videos.find { |i| item.snippet.channel_title < i[:channel_title] }
        end
      when 'date'
        found = videos.find { |i| item.snippet.published_at < i[:published_at] }
      end

      if found
        index = videos.index(found)
        if after_found
          index + 1
        else
          index
        end
      else
        videos.length
      end
    end
  end
end
