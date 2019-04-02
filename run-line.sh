#!/bin/bash

export LINE_CHANNEL_ID=''
export LINE_CHANNEL_SECRET=''

`dirname $0`/himawari_chan_bot/bot-line.rb

export -n LINE_CHANNEL_ID
export -n LINE_CHANNEL_SECRET
