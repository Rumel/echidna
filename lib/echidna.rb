# frozen_string_literal: true

require 'dotenv/load'
require_relative './echidna/services/db'
require_relative './echidna/services/update'
require_relative './echidna/services/logger'

logger = Echidna::LogService.new
logger.info 'Starting Echidna'
db = Echidna::DatabaseService.new
update = Echidna::UpdateService.new

update.remove_videos_from_playlists
update.add_videos_to_playlists
