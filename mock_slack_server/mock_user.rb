require 'realtime-slackbot'
require 'json'
require 'pry'

class MockUserBot < SlackBot::Bot
  
  def opened
    EM.add_periodic_timer 5 do
      puts 'running'
      (user_channels.values + channels.values).each do |chan|
        puts "#{chan}"
        post chan, "msg at #{Time.now}" 
      end
    end
  end
  
  def message(msg)
    puts msg
  end
end


bot = MockUserBot.new ARGV[0], log: true
bot.auth_url = 'http://localhost:4567/api/rtm.start?token='
bot.run