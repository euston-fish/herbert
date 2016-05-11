require 'drb/drb'

URI = 'druby://localhost:3474'

class BotServer
  def create(options)
    puts 'Got some things!'
    puts options
  end
end

$SAFE = 1   # disable eval() and friends

DRb.start_service(URI, BotServer.new)
DRb.thread.join