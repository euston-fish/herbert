require 'realtime-slackbot'
require 'erb'
require 'json'
require 'pry'

class SlackBot::Channel
  attr_accessor :socket
end

class MockHerbertBot < SlackBot::Bot
  attr_accessor :team_info
  def get_url; end
  def run; end
  
  def post(chan, message)
    if chan.is_a? String
      chan = channel(chan)
    elsif !chan.is_a?(Channel)
      raise "Not a valid channel: #{chan} #{chan.class}"
    end
    data = {
      id: 1,
      type: 'message',
      channel: chan.id,
      text: message.to_s
    }
    chan.socket.send data.to_json
  end
  
  def add_channel(chan)
    channels
    @channels[chan.id] = chan
  end
  def add_user(user)
    users
    @users[user.id] = user
  end
  
  def send_hook(*args)
    hook(*args)
  end
  
  def message(msg)
    msg.reply "Message from #{msg.user}: #{msg.text}"
  end
end
