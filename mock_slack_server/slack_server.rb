require 'em-websocket'
require 'erb'
require 'pry'
require 'digest/sha1'
require 'json'
require 'redis'

require_relative '../config'
require_relative 'slack_server_bot'
require_relative '../bot_server/herbert'

HOST = Config['websocket']['host']
PORT = Config['websocket']['port']

NEW_DEMO_CHANNEL = Config['redis_channels']['new_demo']

class SlackServer
  def initialize(host, port, bot)
    @host, @port = host, port
    @bot = bot
    @bot_socket = nil
    @token_to_channel = Hash.new
  end
  
  def run
    EM.run do
      EM::WebSocket.run(host: @host, port: @port) do |ws|
        ws.onopen do |handshake|
          url_token = handshake.path.split('/').last
          channel_id = @token_to_channel.delete(url_token)
          puts "Opened: #{url_token}, #{channel_id}"
          if token_valid?(url_token) && @bot.channel(channel_id)
            res = { type: "hello" }.to_json
            ws.send res
            
            @bot.channel(channel_id).socket = ws
          else
            puts "Invalid token: #{url_token}"
            ws.close
          end
        end

        ws.onclose do
          # TODO remove the channel from the bot channel list
          puts "Connection closed :("
        end

        ws.onmessage do |msg|
          log :message, msg
          begin
            json = JSON.parse msg.to_s
            json['user'] = json['channel']
            type = json.delete('type')
            msg = SlackBot::Message.new json, @bot
            if type
              @bot.send_hook(type, msg)
            end
          rescue JSON::ParserError
            log :warn, 'Connection dropped due to nasty JSON'
            ws.close
          end
        end
      end
    end
  end
  
  def create_channel(user)
    id = user['dm_id']
    data = {
      "id" => id,
      "is_im" => true,
      "user" => user['id'],
      "created" => 1458275992,
      "has_pins" => false,
      "last_read" => "0000000000.000000",
      "latest" => nil,
      "unread_count" => 0,
      "unread_count_display" => 0,
      "is_open" => true
    }
    puts "Creating channel #{id}"
    chan = SlackBot::Channel.new data, @bot
    @bot.add_channel(chan)
    usr = SlackBot::User.new user, @bot
    @bot.add_user(usr)
    
    url_token = Digest::SHA1.hexdigest(user['token'] + user['dm_id'])
    @token_to_channel[url_token] = user['dm_id']
  end
  
  def log(tag, msg)
    puts "#{tag}: #{msg}"
  end
  
  def token_valid?(token)
    # TODO :(
    true
  end
end

HerbertBot.send(:include, SlackServerBot)
herb = HerbertBot.new 'authkey', log: true

template ||= ERB.new(File.read(File.expand_path('team_template.json', File.dirname(__FILE__))))

team = {}
user = {}
bot = {}
# This needs team, user and bot to generate the JSON
herb.team_info = JSON.parse template.result(binding)

slack_server = SlackServer.new(HOST, PORT, herb)

Thread.new do
  begin
    slack_server.run
  rescue Exception => e
    puts e.message
    binding.pry
  end
end

pubsub = Redis.new

pubsub.subscribe(NEW_DEMO_CHANNEL) do |on|  
  on.message do |channel, msg|
    slack_server.create_channel JSON.parse(msg)
  end
end
