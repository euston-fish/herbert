require 'realtime-slackbot'

class HerbertBot < SlackBot::Bot
  def message(msg)
    # do things
    puts 'got message'
    msg.reply 'hey'
  end
end