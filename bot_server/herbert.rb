require 'realtime-slackbot'
require 'pry'
require 'yaml'
require_relative '../models'

HERBERT_ON = /\A\s*herbert\s*on\s*\Z/i
HERBERT_OFF = /\A\s*herbert\s*off\s*\Z/i
HERBERT_DELAY = /\A\s*herbert\s*delay\s*(?<delay>\d+)\s*\Z/i
THANKS_HERBERT = /thanks|thank\s*you/i

DONE_MESSAGES = [
  'Got it!',
  'Done',
  'Noted',
  'Cool',
  'Awesome',
  'Well done'
]
GOOD_EMOJI = '👍✔😀👏🙌👊'.split('')

COMMANDS = [
  [
    true,
    proc do |_|
      session[:last_message] = Time.now.to_i
      false
    end
  ],
  [
    THANKS_HERBERT,
    proc do |_|
      if user.first_name != ""
        reply "You're welcome #{user.first_name}"
      else
        reply "You're welcome"
      end
      true
    end
  ],
  [
    HERBERT_ON,
    proc do |matches|
      unless session[:herbert]
        session[:herbert] = true
        reply 'Herbert turned on for you'
      else
        reply 'Herbert is already on'
      end
      true
    end
  ],
  [
    HERBERT_OFF,
    proc do |matches|
      if session[:herbert]
        session[:herbert] = false
        reply 'Herbert turned off for you'
      else
        reply 'Herbert is already off'
      end
      true
    end
  ],
  [
    HERBERT_DELAY,
    proc do |m|
      session[:delay] = m['delay'].to_i
      reply "Herbert's delay set to #{session[:delay]}"
      true
    end
  ],
  [
    true,
    proc do |_|
      a = Action.create(timestamp: Time.now, action: text, user_id: user.id)
      session[:last_update] = Time.now.to_i
      reply "#{DONE_MESSAGES.sample}! #{GOOD_EMOJI.sample}"
      true
    end
  ]
]

class SlackBot::Message
  def match? reg; text.downcase.match reg end
  def im?; channel.user_channel? end
  def herbert_enabled?; im? && channel.session[:herbert] end
  def herbert_disabled?; im? && !channel.session[:herbert] end
  def session; channel.session end
end

class HerbertBot < SlackBot::Bot
  def opened()
    user_channels.values.each do |chan|
      chan.session[:last_message] ||= 0
      chan.session[:last_update] ||= 0
      chan.session[:herbert] ||= false
      chan.session[:delay] ||= 5
    end
    EM.add_periodic_timer 60 do
      now = Time.now.to_i
      user_channels.values.each do |chan|
        if chan.session[:herbert]
          if now - chan.session[:last_update] > 60 * chan.session[:delay]
            if now - chan.session[:last_message] > 60 * 5
              chan.post "What have you been doing in the last #{chan.session[:delay]} minutes?"
              chan.session[:last_message] = Time.now.to_i
            end
          end
        end
      end
    end
  end
  def message(msg)
    COMMANDS.each do |cond, block|
      do_thing = if cond.is_a? Regexp
        cond.match(msg.text)
      else
        cond
      end
      if do_thing
        stop = msg.instance_exec(do_thing, &block)
        break if stop
      end
    end
  end
end
