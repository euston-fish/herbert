require_relative 'herbert'
require 'pry'

SlackBot::SLACK_AUTH_URL = 'http://localhost:4567/api/rtm.start?token='

class MockUserBot < SlackBot::Bot
  
  def opened
    chan = user_channels.values.first || channels.values.first
    puts chan
    EM.add_periodic_timer 5 do
      puts 'sending stuff'
      post chan, "msg at #{Time.now}" 
    end
  end
  
  def message(msg)
    @chan = msg.channel
  end
end

bot = MockUserBot.new ARGV[0], log: true

binding.pry