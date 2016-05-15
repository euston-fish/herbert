require 'daemons'


path = File.expand_path('../slack_server.rb', __FILE__)

Daemons.run(path)