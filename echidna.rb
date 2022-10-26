require 'dotenv/load'
require 'pry'
require 'json'
require 'time'
require_relative './youtube_service.rb'
require_relative './models/channel.rb'

highlights_id = "PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2"

youtube = YoutubeService.instance

channels = [
  Channel.new(
    name: "Huskers", 
    id: "UCMqWeJDl7yjblwPKVNo4XfA",
    filter: "((Football).*(Highlights))|((Highlights).*(Football))|((Volleyball).*(Highlights))|((Highlights).*(Volleyball))|((Basketball).*(Highlights))|((Highlights).*(Basketball))",
    max_results: 25
  ),
  Channel.new(
    name: "NHL",
    id: "UCqFMzb-4AUf6WAIbl132QKA",
    filter: "(Blues).*(Highlights)",
    max_results: 50
  ),
  Channel.new(
    name: "Cardinals",
    id: "UCwaMqLYzbyp2IbFgcF_s5Og",
    filter: "Highlights",
    max_results: 25
  ),
  Channel.new(
    name: "MatthewLovesBall",
    id: "UC4GNCKohtEHRccrxKQiDJNg",
    filter: "Nebraska",
    max_results: 50
  ),
  Channel.new(
    name: "Formula 1",
    id: "UCB_qr75-ydFVKSF9Dmo6izg",
    filter: "Highlights",
    max_results: 25
  ),
  Channel.new(
    name: "Liverpool FC",
    id: "UC9LQwHZoucFT94I2h6JOcjw",
    filter: "HIGHLIGHTS",
    max_results: 25
  )
]

def get_position(current_items, item)
  return 0 if current_items.length == 0

  times = current_items.map { |i| i.snippet.published_at }

  found = times.find { |i| item.snippet.published_at < i }

  if found
    times.index(found)
  else
    current_items.length
  end
end

# snippet.position can be used
channels.each do |current_channel|
  # This query can get the uploads id
  uploads_id = youtube.get_channel_uploads_id(current_channel.id)
  play_list_items_result = youtube.list_playlist_items(uploads_id, current_channel.max_results)

  objects = play_list_items_result.items.select do |item|
    return true if current_channel.filter.nil?

    item.snippet.title =~ /#{current_channel.filter}/ 
  end

  objects.each do |object|
    current_items = youtube.get_all_playlist_items(highlights_id)
    current_items_video_ids = current_items.map { |i| i.snippet.resource_id.video_id }

    get_position(current_items, object)

    if current_items_video_ids.include?(object.snippet.resource_id.video_id)
      puts "Skipping \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id} because it already exists"
    else
      playlist_item = { 
        snippet: { 
          resource_id: object.snippet.resource_id, 
          playlist_id: highlights_id,
          position: get_position(current_items, object)
        }
      }
      puts "Inserting \"#{object.snippet.title}\" - #{object.snippet.resource_id.video_id}"
      youtube.insert_playlist_item(playlist_item)
    end
  end
end