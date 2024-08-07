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
      config.load_channels
    end

    def playlists
      config.load_playlists
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

    def update_playlists
      channels.each do |current_channel|
        begin
          logger.info "Current channel is #{current_channel.name}"

          # uploads_id = youtube.get_channel_uploads_id(current_channel.id)
          # https://stackoverflow.com/questions/71192605/how-do-i-get-youtube-shorts-from-youtube-api-data-v3
          videos_id = current_channel.id.sub('UC', 'UULF') # Only grab the videos, no shorts

          # unless uploads_id
          #   puts "#{current_channel.id} does not exist anymore, please remove"
          #   next
          # end

          play_list_items_result = youtube.list_playlist_items(videos_id, current_channel.max_results)

          objects = play_list_items_result.items.select do |item|
            if current_channel.filter.nil?
              true
            else
              item.snippet.title.match(/#{current_channel.filter}/)
            end
          end

          objects.each do |object|
            exists_in_db = !db.get_video(object.snippet.resource_id.video_id).nil?
            if exists_in_db
              logger.info "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists in the database"
              next
            end

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
          end
        rescue Exception => e
          logger.error "Error: #{e.message}"
        end
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
