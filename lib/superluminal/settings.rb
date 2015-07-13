require 'settingslogic'
require 'terminal-announce'

# Singleton for loading configs from common paths.
class Settings < Settingslogic
  config_paths = %w(/etc /usr/local/etc ~ .)

  config_paths.each do |config_path|
    config_file = "#{ config_path }/superluminal.yaml"
    source config_file if File.exist? config_file
  end

  load!
  rescue Errno::ENOENT
    Announce.failure "Unable to locate configuration in #{ config_paths }."
    exit
end
