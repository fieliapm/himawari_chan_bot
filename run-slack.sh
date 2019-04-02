#!/bin/bash

export SLACK_API_TOKEN=''

`dirname $0`/himawari_chan_bot/bot-slack.rb

export -n SLACK_API_TOKEN
