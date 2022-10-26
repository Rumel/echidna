require 'dotenv/load'
require 'pry'
require_relative './youtube_service.rb'
require_relative './config.rb'

youtube = YoutubeService.instance
config = Config.new

channels = config.load_channels

def get_position(youtube, current_items, item)
  return 0 if current_items.length == 0

  times = current_items.map do |i| 
    youtube.get_video(i.snippet.resource_id.video_id).snippet.published_at
  end

  found = times.find { |i| item.snippet.published_at < i }

  if found
    times.index(found)
  else
    current_items.length
  end
end

channels.each do |current_channel|
  uploads_id = youtube.get_channel_uploads_id(current_channel.id)
  play_list_items_result = youtube.list_playlist_items(uploads_id, current_channel.max_results)

  objects = play_list_items_result.items.select do |item|
    return true if current_channel.filter.nil?

    item.snippet.title.match(/#{current_channel.filter}/)
  end

  objects.each do |object|
    current_items = youtube.get_all_playlist_items(current_channel.playlist_id)
    current_items_video_ids = current_items.map { |i| i.snippet.resource_id.video_id }

    get_position(youtube, current_items, object)

    if current_items_video_ids.include?(object.snippet.resource_id.video_id)
      puts "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists"
    else
      playlist_item = { 
        snippet: { 
          resource_id: object.snippet.resource_id, 
          playlist_id: current_channel.playlist_id,
          position: get_position(youtube, current_items, object)
        }
      }
      puts "Inserting \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id}"
      youtube.insert_playlist_item(playlist_item)
    end
  end
end