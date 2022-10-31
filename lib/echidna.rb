# frozen_string_literal: true

require 'pry'
require_relative './echidna/services/db'
require_relative './echidna/services/update'
require_relative './echidna/services/logger'

Echidna::LogService.new.logger.info 'Starting Echidna'

db = Echidna::DatabaseService.new
update = Echidna::UpdateService.new

db.run_migrations
update.update_playlists
