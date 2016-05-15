require 'realtime-slackbot'
require 'pry'
require 'active_record'
require 'chronic'
require 'yaml'

HERBERT_ON = /\A\s*herbert\s*on\s*\Z/i
HERBERT_OFF = /\A\s*herbert\s*off\s*\Z/i
HERBERT_DELAY = /\A\s*herbert\s*delay\s*(?<delay>\d+)\s*\Z/i

environment = ENV['RACK_ENV'] || 'development'
dbconfig = YAML.load File.read('db/config.yml')
ActiveRecord::Base.establish_connection(dbconfig[environment])
  #:adapter => 'postgresql',
  #:encoding => 'unicode',
  #:database => 'herbert',
  #:user => 'herbert',
  #:password => 'herbert',
  #:pool => 5)

class SlackBot::Message
  def match? reg; text.downcase.match reg end
  def im?; channel.user_channel? end
  def herbert_enabled?; im? && channel.session[:herbert] end
  def herbert_disabled?; im? && !channel.session[:herbert] end
end

class Action < ActiveRecord::Base
end

class HerbertBot < SlackBot::Bot
  def opened()
    user_channels.values.each do |chan|
      chan.session[:last_message] ||= 0
      chan.session[:last_update] ||= 0
      chan.session[:herbert] ||= false
      chan.session[:delay] ||= 5
    end
    EM.add_periodic_timer 10 do
      user_channels.values.each do |chan|
        if chan.session[:herbert]
          if Time.now-Time.at(chan.session[:last_update]) > 60*chan.session[:delay]
            if Time.now-Time.at(chan.session[:last_message]) > 60*5
              chan.post "What have you been doing in the last #{chan.session[:delay]} minutes?"
              chan.session[:last_message] = Time.now.to_i
            end
          end
        end
      end
    end
  end
  def message(msg)
    msg.instance_eval do
      session = channel.session
      session[:last_message] = Time.now.to_i
      if herbert_disabled? and HERBERT_ON =~ text then
        
        session[:herbert] = true
        reply "Herbert turned on for you"
      elsif herbert_enabled? and HERBERT_OFF =~ text then
        session[:herbert] = false
        reply "Herbert turned off for you"
      elsif HERBERT_DELAY =~ text then
        m = HERBERT_DELAY.match(text)
        session[:delay] = m['delay'].to_i
        reply "Herbert's delay set to #{session[:delay]}"
      elsif 
        a = Action.create(timestamp: Time.now, action: msg.text, user_id: msg.user.id)
        session[:last_update] = Time.now.to_i
        reply "Created log with timestamp: " + a.timestamp.to_s
      end
    end
  end
end
