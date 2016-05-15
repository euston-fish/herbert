require 'daemons'

path = File.expand_path('../server.rb', __FILE__)

Daemons.run(path)