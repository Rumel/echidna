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

# playlists = youtube.list_playlists('snippet', mine: true)
# puts JSON.pretty_generate(playlists)
# videos = youtube.list_videos('snippet', id: 'J9gdbUdogbY')
# puts videos.inspect
# channel = youtube.list_channels('snippet', id: 'UCTaLHBpw8mBOU_O3DlJFrhA')
# puts JSON.pretty_generate(channel)

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

channels = [
  "UCMqWeJDl7yjblwPKVNo4XfA", # Huskers
]

football_regex = "((Football).*(Highlights))|((Highlights).*(Football))"
volleyball_regex = "((Volleyball).*(Highlights))|((Highlights).*(Volleyball))"

highlights_id = "PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2"

channels.each do |channel_id|
  # This query can get the uploads id
  channel = youtube.list_channels('contentDetails', id: channel_id)
  uploads_id = channel.items.first.content_details.related_playlists.uploads
  play_list_items_result = youtube.list_playlist_items('snippet', playlist_id: uploads_id, max_results: 25)
  write_json("list-playlist-items-#{channel_id}", play_list_items_result)
  objects = play_list_items_result.items.select do |item|
    item.snippet.title =~ /#{football_regex}/ || item.snippet.title =~ /#{volleyball_regex}/
  end
  objects.each do |object|
    youtube.insert_playlist_item('snippet', { snippet: { resource_id: object.snippet.resource_id, playlist_id: highlights_id } })
  end
end