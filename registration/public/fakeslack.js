var socket;

var ChatWindow = function(base) {
  this.base = base;
  this.message_template = $('#message-template div').first().clone();
  this.message_area = this.base.children().filter(".message_area");
  this.input_area = this.base.children().filter(".input_area");
  this.message_input = this.input_area.children().filter(".message_input");
  this.send_button = this.input_area.children().filter(".send_button");
  this.disable();
  this.on_send = null;
  var that = this;
  var onclick = function() {
    var msg = that.message_input.val();
    if(that.on_send && that.message_input.val()) {
      if(that.on_send(msg)) {
        that.message_input.val("");
      }
    }
  };
  this.send_button.click(onclick);
  this.input_area.keypress(function(e) {
    if(e.which == 10 || e.which == 13) {
      onclick();
    }
  });
  return this;
};

ChatWindow.prototype = {
  pushMsg: function(data) {
    var message = data.message;
    
    var msgCont = this.message_template.clone();
    
    msgCont.addClass(data.classes);
    msgCont.find('.content').text(message)
    
    msgCont.find('.username').text(data.username);
    msgCont.find('.avatar').attr('src', data.avatar);
    
    this.message_area.append(msgCont);
    msgCont.show();
    var childs = this.message_area.children()
    var height = childs.height();
    this.message_area.scrollTop(childs.length * height);
  },
  
  able: function(state) {
    this.message_input.prop("disabled", state);
    this.send_button.prop("disabled", state);
  },
  
  enable: function() {
    this.able(false);
  },

  disable: function() {
    this.able(true);
  },
}

var FakeSlack = function(teamInfo) {
  if(!("WebSocket" in window)) {
    throw "WebSocket not available";
  }
  
  this.teamInfo = teamInfo;
  var that = this;

  this._socket = new WebSocket(teamInfo.url);
  this._socket.onopen = function() {
    that.onopen();
  }

  this._socket.onmessage = function(msg) {
    var data = JSON.parse(msg.data);
    that.onmessage(data);
  }

  this._socket.onclose = function() {
    that.onclose();
  }
}

FakeSlack.prototype = {
  send: function(message) {
    this._socket.send(JSON.stringify({
      "type": "message",
      "text": message,
      "channel": this.teamInfo.users[0].id
    }));
  }
}


function doSlack(teamInfo) {
  var me = teamInfo.users[0];
  var bot = teamInfo.bots[0];
  
  var cw = new ChatWindow($("#fakeSlack"));

  var fs = new FakeSlack(teamInfo);

  fs.onopen = function() {
    cw.pushMsg({
      message: 'Connected',
      classes: 'update'
    });
    cw.enable();
    cw.on_send = function(msg) {
      fs.send(msg);
      cw.pushMsg({
        message: msg,
        avatar: me.profile.avatar,
        username: me.name
      });
      return true;
    }
  }

  fs.onmessage = function(data) {
    if(data.type === "message" && data.text) {
      cw.pushMsg({
        message: data.text,
        avatar: bot.profile.avatar,
        username: bot.name
      });
    }
  }


  fs.onclose = function() {
    cw.pushMsg({
      message: 'Disconected',
      classes: 'update'
    });
    cw.disable();
    cw.on_send = null;
  }
}

$(document).ready(function() {
  $('.message_area').height($(window).height() - ($('.input_area').height() * 2));
});

$.get('/api/rtm.start?token=randomtoken', function(data) {
  doSlack(data);
});