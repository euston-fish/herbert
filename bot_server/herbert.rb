require 'realtime-slackbot'

class HerbertBot < SlackBot::Bot
  def message(msg)
    # do things
    puts msg
  end
end