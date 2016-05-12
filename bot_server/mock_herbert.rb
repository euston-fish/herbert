require_relative 'herbert'
require 'pry'

SlackBot::SLACK_AUTH_URL = 'http://localhost:4567/api/rtm.start?token='

bot = HerbertBot.new ARGV[0], log: true

binding.pry