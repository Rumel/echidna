require 'pry'
require_relative './youtube_service.rb'
require_relative './config.rb'
require_relative './db.rb'

youtube = YoutubeService.instance
config = Config.new
db = DatabaseService.new

db.run_migrations

channels = config.load_channels
playlists = config.load_playlists

def get_position(db, youtube, selected_playlist, current_items, item)
  return 0 if current_items.length == 0

  videos = current_items.map do |i|
    db_video = db.get_video(i.snippet.resource_id.video_id)
    if db_video
      {
        channel_title: db_video[:channel_title],
        published_at: db_video[:published_at], 
      }
    else
      video = youtube.get_video(i.snippet.resource_id.video_id)
      {
        channel_title: video.snippet.channel_title,
        published_at: video.snippet.published_at 
      }
    end
  end

  found = nil
  after_found = false
  if selected_playlist.order == "title"
    channel_videos = videos.select { |v| v[:channel_title] == item.snippet.channel_title }

    if channel_videos.length > 0
      # Other videos are already inserted for the channel
      found = videos.find { |i| item.snippet.published_at < i[:published_at] }
      # need to handle the case where video is the newest
      if !found
        found = videos.last
        after_found = true
      end
    else
      # First video of title in list
      # It just needs to be inserted before the other channels
      found = videos.find { |i| item.snippet.channel_title < i[:channel_title] }
    end
  elsif selected_playlist.order == "date"
    found = videos.find { |i| item.snippet.published_at < i[:published_at] }
  end

  if found
    index = videos.index(found)
    if after_found
      index += 1
    else
      index
    end
  else
    current_items.length
  end
end

channels.each do |current_channel|
  uploads_id = youtube.get_channel_uploads_id(current_channel.id)
  play_list_items_result = youtube.list_playlist_items(uploads_id, current_channel.max_results)

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
      puts "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists in the database"
      next
    end

    current_items = youtube.get_all_playlist_items(current_channel.playlist_id)
    current_items_video_ids = current_items.map { |i| i.snippet.resource_id.video_id }
    selected_playlist = playlists.find { |playlist| playlist.id == current_channel.playlist_id } 

    exists_in_playlist = current_items_video_ids.include?(object.snippet.resource_id.video_id)
    if exists_in_playlist 
      puts "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists in playlist"
      db.insert_video(object.snippet.resource_id.video_id, object.snippet.channel_title, object.snippet.published_at)
    else
      playlist_item = { 
        snippet: { 
          resource_id: object.snippet.resource_id, 
          playlist_id: current_channel.playlist_id,
          position: get_position(db, youtube, selected_playlist, current_items, object)
        }
      }
      puts "Inserting \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id}"
      youtube.insert_playlist_item(playlist_item)
      db.insert_video(object.snippet.resource_id.video_id, object.snippet.channel_title, object.snippet.published_at)
    end
  end
end