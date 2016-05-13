require 'em-websocket'
require 'pry'
require 'json'

HOST = 'localhost'
PORT = '8080'

class SlackServer
  
  def initialize(host, port, bot)
    @host, @port = host, port
    @bot = bot
  end
  
  def run
    EM.run do
      EM::WebSocket.run(host: @host, port: @port) do |ws|
        ws.onopen do |handshake|
          token = handshake.path[1..-1]
          if token_valid? token
            puts "Opened: #{token}"
            res = { type: "hello" }.to_json
            ws.send res
          else
            puts "Invalid token: #{token}"
            ws.close
          end
        end

        ws.onclose do
          puts "Connection closed :("
        end

        ws.onmessage do |msg|
          log :message, msg
          begin
            json = JSON.parse msg.to_s
            message(ws, json)
          rescue JSON::ParserError
            log :warn, 'Connection dropped due to nasty JSON'
            ws.close
          end
        end
      end
    end
  end
  
  def log(tag, msg)
    puts "#{tag}: #{msg}"
  end
  
  def message(socket, json)
    puts json
  end
  
  def token_valid?(token)
    # TODO :(
    true
  end
end

SlackServer.new(HOST, PORT, nil).run