require_relative 'herbert'
require 'pry'

bot = HerbertBot.new(ARGV[0], log: true)
binding.pry