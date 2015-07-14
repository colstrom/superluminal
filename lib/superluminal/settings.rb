require 'settingslogic'
require 'terminal-announce'

# Singleton for loading configs from common paths.
class Settings < Settingslogic
  config_paths = %w(/etc /usr/local/etc ~/.config .)

  config_paths.each do |config_path|
    config_file = File.expand_path "#{ config_path }/superluminal.yaml"
    source config_file if File.exist? config_file
  end

  load!
rescue Errno::ENOENT
  Announce.failure "Unable to locate configuration in #{ config_paths }."
  abort
end
