#!/bin/bash

mode=$1
if [[ "$2" == "" ]]; then
  home="/var/www/herbert"
else
  home=$2
fi

if [[ "$mode" == "start" ]]; then
  unicorn -c "$home/registration/unicorn.rb" -E production -D
else
  cat "$home/registration/tmp/pids/unicorn.pid" | xargs kill -QUIT
fi

ruby "$home/bot_server/server_daemon.rb" $mode
ruby "$home/mock_slack_server/slack_server_daemon.rb" $mode