# frozen_string_literal: true

require 'pry'
require_relative './echidna/services/youtube'
require_relative './echidna/services/config'
require_relative './echidna/services/db'
require_relative './echidna/services/update'

youtube = YoutubeService.instance
config = ConfigService.new
db = DatabaseService.new
update = UpdateService.new(db, youtube, config)

db.run_migrations
update.update_playlists
