#!/bin/bash

export TELEGRAM_BOT_TOKEN=''

`dirname $0`/himawari_chan_bot/bot-telegram.rb

export -n TELEGRAM_BOT_TOKEN
