require 'em-websocket'
require 'json'

HOST = 'localhost'
PORT = '8080'

class SlackServer
  
  def initialize(host, port)
    @host, @port = host, port
  end
  
  def run
    EM.run do
      EM::WebSocket.run(host: @host, port: @port) do |ws|
        ws.onopen do |handshake|
          puts "WebSocket connection open"
          res = { type: "hello" }.to_json
          ws.send res
        end

        ws.onclose do
          puts "Connection closed :("
        end

        ws.onmessage do |msg|
          puts "Recieved message: #{msg}"
          begin
            json = JSON.parse msg.to_s
            message(ws, json)
          rescue JSON::ParserError
            ws.close
          end
        end
      end
    end
  end
  
  def message(socket, json)
    puts json
  end
end

SlackServer.new(HOST, PORT).run