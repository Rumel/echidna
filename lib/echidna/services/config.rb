# frozen_string_literal: true

require 'yaml'
require_relative '../models/channel'
require_relative '../models/playlist'
require_relative 'logger'

module Echidna
  class ConfigService
    def logger
      @logger ||= LogService.new
    end

    def find_config_file
      paths = []
      paths << File.join(ENV['XDG_CONFIG_HOME'], 'echidna', 'config.yaml') if ENV['XDG_CONFIG_HOME']
      paths << File.join(Dir.home, '.config', 'echidna', 'config.yaml') if Dir.home
      paths << File.join(Dir.pwd, 'config.yaml')

      found_path = nil
      paths.each do |path|
        next if found_path

        found_path = path if File.exist?(path)
      end

      if found_path
        found_path
      else
        logger.error 'Config file does not exist'
        logger.error 'Looked in $XDG_CONFIG_HOME/echidna/config.yaml'
        logger.error 'Looked in $HOME/echidna/config.yaml'
        logger.error 'Looked in ./config.yaml'

        nil
      end
    end

    def config_file
      @config_file ||= find_config_file
    end

    def load_channels
      return [] unless config_file

      config = YAML.load_file(config_file, aliases: true)

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
      retrun [] unless config_file

      config = YAML.load_file(config_file, aliases: true)

      config['playlists'].map do |playlist|
        Playlist.new(
          id: playlist['id'],
          title: playlist['title'],
          order: playlist['order'],
          time: playlist['time']
        )
      end
    end
  end
end
