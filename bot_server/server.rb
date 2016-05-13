require_relative 'herbert'
require 'json'
require 'redis'

NEW_TEAM_CHANNEL = 'new_teams'
DO_BOTS_LOG = true

class BotServer
  def initialize(redis)
    @redis = redis
    @teams = Hash.new
  end
  
  def create(info)
    puts "Received info: #{info['team_id']}"
    self.store_team info
    thread = start_bot(info['bot']['bot_access_token'])
    @teams[info['team_id']] = thread
  end
  
  def store_team(hash)
    team_id = hash['team_id']
    
    webhook_url = hash['incoming_webhook']['url']
    access_token = hash['access_token']
    bot_access_token = hash['bot']['bot_access_token']
    
    @redis["team:#{team_id}:webhook_url"] = webhook_url
    @redis["team:#{team_id}:access_token"] = access_token
    @redis["team:#{team_id}:bot_access_token"] = bot_access_token
    @redis.sadd 'team_ids', team_id
  end
  
  def start_teams
    puts 'starting teams'
    team_ids = @redis.smembers 'team_ids'
    puts team_ids.inspect
    team_ids.each do |team_id|
      puts "starting team #{team_id}"
      access_token = @redis["team:#{team_id}:bot_access_token"]
      if access_token
        @teams[team_id] = start_bot(access_token)
      else
        puts "No access token for #{team_id}"
      end
    end
  end
  
  def start_bot(access_token)
    Thread.new do
      hbot = HerbertBot.new access_token, log: DO_BOTS_LOG
      hbot.run
    end
  end
end

redis = Redis.new
bot_server = BotServer.new redis
bot_server.start_teams

pub_sub = Redis.new

pub_sub.subscribe(NEW_TEAM_CHANNEL) do |on|  
  on.message do |channel, msg|
    bot_server.create JSON.parse(msg)
  end
end
