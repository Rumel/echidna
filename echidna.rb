require 'dotenv/load'
require 'google/apis/youtube_v3'
require 'pry'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'json'
require 'time'

# OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
OOB_URI = 'http://localhost'

def token_store_path
  './credentials.yaml'
end

def client_secrets_path
  './client_secrets.json'
end

def user_credentials_for(scope)
  FileUtils.mkdir_p(File.dirname(token_store_path))

  client_id = Google::Auth::ClientId.from_file(client_secrets_path)
  token_store = Google::Auth::Stores::FileTokenStore.new(:file => token_store_path)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

  user_id = 'default'

  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts "Open the following URL in your browser and authorize the application."
    puts url
    puts "Enter the authorization code:"
    code = gets.chomp
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

youtube = Google::Apis::YoutubeV3::YouTubeService.new
youtube.authorization = user_credentials_for(Google::Apis::YoutubeV3::AUTH_YOUTUBE)

def write_json(partial_filename, data)
  File.open("json/#{partial_filename}-#{Time.now.utc.iso8601}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end

playlists_result = youtube.list_playlists('snippet', mine: true)
write_json('list-playlists-mine', playlists_result)
# playlists_result.items.each do |playlist|
#   puts JSON.pretty_generate(playlist)
# end

class Channel
  attr_accessor :id, :filter, :max_results, :name

  def initialize(h = {})
    h.each {|k,v| public_send("#{k}=",v)}
  end

  def max_results
    @max_results || 25 
  end
end

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

highlights_id = "PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2"

def get_playlist_items(youtube, playlist_id)
  playlist_items = []
  page_token = nil
  loop do
    result = youtube.list_playlist_items('snippet', playlist_id: playlist_id, page_token: page_token)
    playlist_items += result.items
    page_token = result.next_page_token
    break if page_token.nil?
  end
  playlist_items
end

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
  channel = youtube.list_channels('contentDetails', id: current_channel.id)
  uploads_id = channel.items.first.content_details.related_playlists.uploads
  play_list_items_result = youtube.list_playlist_items('snippet', playlist_id: uploads_id, max_results: current_channel.max_results)
  write_json("list-playlist-items-#{current_channel.id}", play_list_items_result)
  objects = play_list_items_result.items.select do |item|
    return true if current_channel.filter.nil?

    item.snippet.title =~ /#{current_channel.filter}/ 
  end
  objects.each do |object|
    current_items = get_playlist_items(youtube, highlights_id)
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
      youtube.insert_playlist_item('snippet', playlist_item)
    end
  end
end