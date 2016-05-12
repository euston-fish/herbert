require 'erb'

template = ERB.new(File.read('team_template.json'))

@team = {}
@current_user = {}

puts template.result binding