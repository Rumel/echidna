# frozen_string_literal: true

require 'dotenv/load'
require_relative 'echidna/services/youtube'

yt = Echidna::YoutubeService.new
search_term = ARGV.join(' ')

if search_term.empty?
  puts 'Please provide a search term'
  exit 0
end

puts "Searching for '#{search_term}'"

result = yt.get_channel_id(search_term)
result.each do |r|
  puts "#{r[:channel_title]} #{r[:channel_id]}"
end
