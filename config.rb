require "yaml"
require_relative "./models/channel.rb"

class Config
  def config_file
    "./config.yaml"
  end

  def config_exists?
    result = File.exist?(config_file)
    if !result
      puts "Config file #{config_file} does not exist"
    end
    result
  end

  def load_channels
    return [] unless config_exists?

    config = YAML.load_file(config_file)

    config["channels"].map do |channel|
      Channel.new(
        name: channel["name"],
        id: channel["id"],
        filter: channel["filter"],
        max_results: channel["max_results"] || 25,
        playlist_id: channel["playlist_id"]
      )
    end
  end
end