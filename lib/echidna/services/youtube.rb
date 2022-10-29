# frozen_string_literal: true

require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'json'
require 'time'

class YoutubeService
  attr_reader :youtube, :videos

  @instance = nil

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
    token_store = Google::Auth::Stores::FileTokenStore.new(file: token_store_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

    user_id = 'default'

    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in your browser and authorize the application.'
      puts url
      puts 'Enter the authorization code:'
      code = gets.chomp
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id:, code:, base_url: OOB_URI
      )
    end
    credentials
  end

  def initialize
    @youtube = Google::Apis::YoutubeV3::YouTubeService.new
    @youtube.authorization = user_credentials_for(Google::Apis::YoutubeV3::AUTH_YOUTUBE)
    @videos = {}
  end

  def self.instance
    @instance ||= new
  end

  def write_json(partial_filename, data)
    Dir.mkdir('json') unless Dir.exist?('json')
    File.open("./json/#{partial_filename}-#{Time.now.utc.iso8601}.json", 'w') do |f|
      f.write(JSON.pretty_generate(data))
    end
  end

  def list_playlists_mine
    result = youtube.list_playlists('snippet', mine: true, max_results: 50)
    write_json(__method__, result)
    result
  end

  def get_all_playlist_items(playlist_id)
    playlist_items = []
    page_token = nil
    loop do
      result = youtube.list_playlist_items('snippet', playlist_id:, page_token:)
      playlist_items += result.items
      page_token = result.next_page_token
      break if page_token.nil?
    end
    write_json(__method__, playlist_items)
    playlist_items
  end

  # Get the uploads id for a channel
  def get_channel_uploads_id(channel_id)
    result = youtube.list_channels('contentDetails', id: channel_id)
    write_json(__method__, result)
    result.items.first.content_details.related_playlists.uploads
  end

  def list_playlist_items(playlist_id, max_results = 25)
    result = youtube.list_playlist_items('snippet', playlist_id:, max_results:)
    write_json(__method__, result)
    result
  end

  def insert_playlist_item(item)
    youtube.insert_playlist_item('snippet', item)
  end

  def get_video(video_id)
    videos[video_id] ||= youtube.list_videos(%w[snippet contentDetails], id: video_id).items.first
  end

  # Expensive query
  # Available so I can get channel ids
  def search(query)
    result = youtube.list_searches('snippet', q: query, max_results: 25)
    write_json(__method__, result)
    result
  end
end
