# frozen_string_literal: true

require 'yaml'
require_relative '../models/channel'
require_relative '../models/playlist'
require_relative './logger'

module Echidna
  class ConfigService
    def logger
      @logger ||= LogService.new.logger
    end

    def config_file
      './config.yaml'
    end

    def config_exists?
      result = File.exist?(config_file)
      logger.error "Config file #{config_file} does not exist" unless result
      result
    end

    def load_channels
      return [] unless config_exists?

      config = YAML.load_file(config_file)

      config['channels'].map do |channel|
        Channel.new(
          name: channel['name'],
          id: channel['id'],
          filter: channel['filter'],
          max_results: channel['max_results'] || 25,
          playlist_id: channel['playlist_id']
        )
      end
    end

    def load_playlists
      retrun [] unless config_exists?

      config = YAML.load_file(config_file)

      config['playlists'].map do |playlist|
        Playlist.new(
          id: playlist['id'],
          title: playlist['title'],
          order: playlist['order']
        )
      end
    end
  end
end
