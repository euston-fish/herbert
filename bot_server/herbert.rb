require 'realtime-slackbot'
require 'pry'
require 'yaml'
require_relative '../models'

TIME = /\d+([:\.\-]?\d+)(pm|am)?/i

HERBERT_ON = [
  /\A\s*herbert\s*on\s*\Z/i,
  /\Awake\s*up/,
  /\Acome\s*back/
]
HERBERT_OFF = [
  /\A\s*herbert\s*off\s*\Z/i,
  /\Ashut\s*up/i,
  /don'?t\s*remind\s*me/i,
  /don'?t\s*bug\s*(me)/i
]
HERBERT_DELAY = [
  /\A\s*herbert\s*delay\s*(?<delay>\d+)\s*\Z/i,
  /(every|each)\s*(?<delay>\d+)?\s*(?<unit>\w+)?/i
]
THANKS_HERBERT = /thanks|thank\s*you/i
HERBERT_RANGE = [
  /between\s*(?<start>#{TIME})\s*and\s*(?<end>#{TIME})/i,
  /between\s*(?<start>#{TIME})\s*-\s*(?<end>#{TIME})/i,
  /from\s*(?<start>#{TIME})\s*(to|until|til)\s*(?<end>#{TIME})/i
]
HERBERT_TIMESHEET = [
  /what(.?ve i| have i) done/i,
  /what(.s| is).*?timesheet\Z/i
]
HERBERT_STATUS = [
  /are you (on|listen(ing)?|t?here|awake)/i,
  /\Ahello/i
]

DONE_MESSAGES = [
  'Got it!',
  'Done',
  'Noted',
  'Cool',
  'Awesome',
  'Well done'
]
GOOD_EMOJI = '👍✔😀👏🙌👊'.split('')

MIN_GAP_MINUTES = 5

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
        reply "Hey, what're you up to?"
      else
        reply "I'm already here!"
      end
      true
    end
  ],
  [
    HERBERT_OFF,
    proc do |matches|
      if session[:herbert]
        session[:herbert] = false
        reply "*I'll be back*"
      else
        reply "_I'm being quiet_"
      end
      true
    end
  ],
  [
    HERBERT_RANGE,
    lambda do |mat|
      start_h, start_m = mat['start'].split(/\D+/).map(&:to_i)
      end_h, end_m = mat['end'].split(/\D+/).map(&:to_i)
      
      start_h += 12 if start_h < 5
      end_h += 12 if end_h < 8
      
      start_m ||= 0
      end_m ||= 0
      
      if start_h > 23 || end_h > 23 || start_m > 59 || end_m > 59
        reply "That doesn't make sense to me, sorry"
        return true
      end
      start = start_h + (start_m / 60.0)
      fin = end_h + (end_m / 60.0)
      
      channel.session[:start_time] = start
      channel.session[:end_time] = fin
      
      str_start = "#{start_h}:#{'%02d' % start_m}"
      str_end = "#{end_h}:#{'%02d' % end_m}"
      
      reply "I'll only bug you from #{str_start} to #{str_end}"
      true
    end
  ],
  [
    HERBERT_DELAY,
    lambda do |m|
      if m['delay']
        orig_delay = m['delay'].to_i
      else
        orig_delay = 1
      end
      delay = orig_delay
      
      unit = 'minute'
      if m['unit']
        case m['unit'].downcase
        when 'hour', 'hours'
          delay *= 60
          unit = 'hour'
        when 'minutes', 'minute', 'min'
          unit = 'minute'
        when 'day', 'days'
          unit = 'day'
          delay *= 60 * 24
        else
          reply "I don't know what you mean by \"#{m['unit']}\""
          return true
        end
      end
          
      session[:delay] = delay
      unit = delay == 1 ? unit : (unit + 's')
      reply "I'll bug you every #{orig_delay} #{unit}"
      true
    end
  ],
  [
    HERBERT_TIMESHEET,
    proc do |_|
      reply "http://herbert.euston.fish/timesheet/#{user.id}/1"
      true
    end
  ],
  [
    HERBERT_STATUS,
    proc do |_|
      delay = session[:delay]
      start = session[:start_time].to_i
      fin = session[:end_time].to_i
      on = session[:herbert]
      url = "http://herbert.euston.fish/timesheet/#{user.id}/1"
      
      if on
        # TODO show the proper times
        reply "I'm here, reminding you every #{delay} minutes - from #{start} to #{fin}"
      else
        reply "I'm asleep. Wake me up if you want me."
      end
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
      chan.session[:herbert] ||= true
      chan.session[:delay] ||= 60
      chan.session[:start_time] ||= 9
      chan.session[:end_time] ||= 17
    end
    EM.add_periodic_timer 60 do
      time = Time.now
      now = time.to_i
      now_time = time.hour + (time.min / 60.0)
      user_channels.values.each do |chan|
        if chan.session[:herbert]
          unless between_times?(now_time, chan.session[:start_time], chan.session[:end_time])
            next
          end
          if now - chan.session[:last_update] > 60 * chan.session[:delay]
            if now - chan.session[:last_message] > 60 * MIN_GAP_MINUTES
              chan.post "What have you been doing in the last #{chan.session[:delay]} minutes?"
              chan.session[:last_message] = Time.now.to_i
            end
          end
        end
      end
    end
  end
  
  def between_times?(now, start, fin)
    if start < fin
      start <= now && now <= fin
    else
      now >= start || now <= fin
    end
  end
  
  def message(msg)
    if msg['subtype'] == 'bot_message'
      return
    end
    COMMANDS.each do |cond, block|
      do_thing = if cond.is_a? Regexp
        cond.match(msg.text)
      elsif cond.is_a? Array
        mat = nil
        cond.each do |regex|
          mat = regex.match msg.text
          break if mat
        end
        mat
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
