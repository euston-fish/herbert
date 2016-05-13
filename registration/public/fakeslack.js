var socket;

var ChatWindow = function(base) {
  this.base = base;
  this.message_area = $("<div/>", {"class": "message_area"});
  this.input_area = $("<div/>");
  this.message_input = $("<input/>", {"class": "message_input", "type": "text"});
  this.send_button = $("<input/>", {"type": "button", "value": "Send"});
  this.input_area.append(this.message_input, this.send_button);
  this.base.append(this.message_area, this.input_area);
  this.disable();
  this.on_send = null;
  var that = this;
  var onclick = function() {
    var msg = that.message_input.val();
    if(that.on_send) {
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
  pushMsg: function(message) {
    var m = $("<div/>");
    m.append(message);
    this.message_area.append(m);
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
  var cw = new ChatWindow($("#fakeSlack"));

  var fs = new FakeSlack(teamInfo);

  fs.onopen = function() {
    cw.pushMsg("Connected");
    cw.enable();
    cw.on_send = function(msg) {
      fs.send(msg);
      cw.pushMsg(msg);
      return true;
    }
  }

  fs.onmessage = function(data) {
    if(data.type === "message" && data.text) {
      cw.pushMsg(data.text);
    }
  }


  fs.onclose = function() {
    cw.pushMsg("Disconected");
    cw.disable();
    cw.on_send = null;
  }
}

$.get('/api/rtm.start?token=randomtoken', function(data) {
  console.log(data);
  doSlack(data);
});
