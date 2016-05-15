require 'realtime-slackbot'
require 'json'
require 'pry'

class SlackBot::Channel
  attr_accessor :socket
end

module SlackServerBot
  include SlackBot
  
  attr_accessor :team_info
  def get_url; end
  def run;
  end
  
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
  
  def init_channels
    user_channels.values.each do |chan|
      chan.session[:last_message] ||= 0
      chan.session[:last_update] ||= 0
      chan.session[:herbert] ||= false
      chan.session[:delay] ||= 5
      chan.session[:start_time] ||= 9
      chan.session[:end_time] ||= 17
    end
  end
  
  def add_channel(chan)
    user_channels
    @user_channels[chan.id] = chan
  end
  
  def add_user(user)
    users
    @users[user.id] = user
  end
  
  def send_hook(*args)
    hook(*args)
  end
  def session
    @session ||= create_session(team_info['team']['id'])
  end
end
