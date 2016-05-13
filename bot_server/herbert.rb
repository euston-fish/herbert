require 'realtime-slackbot'

class HerbertBot < SlackBot::Bot
  def message(msg)
    # do things
    puts 'got message'
    @socket.send "lol this will crash"
  end
end