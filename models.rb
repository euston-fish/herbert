require 'sinatra/activerecord'
require_relative 'config.rb'

ActiveRecord::Base.establish_connection(Config['db'])

class Action < ActiveRecord::Base
end
