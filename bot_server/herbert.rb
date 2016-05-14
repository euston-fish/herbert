require 'realtime-slackbot'

class HerbertBot < SlackBot::Bot
  def message(msg)
    msg.reply msg.text.upcase
  end
end