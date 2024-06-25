require 'dotenv/load'
require_relative './echidna/services/youtube'

yt = Echidna::YoutubeService.new
search_term = ARGV.join(' ')
puts "Searching for '#{search_term}'"

result = yt.get_channel_id(search_term)
result.each do |r|
  puts "#{r[:channel_title]} #{r[:channel_id]}"
end
