require_relative 'herbert'
require 'redis'

bot = HerbertBot.new(ARGV[0], log: true, session: {
  use: SlackBot::Ext::RedisSession,
  store: Redis.new
}).run
