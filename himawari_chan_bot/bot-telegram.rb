#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

################################################################################
#
# himawari_chan_bot - a simple chat bot example
#                     for line, telegram, slack, discord
# Copyright (C) 2019-present Himawari Tachibana <fieliapm@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

require 'telegram/bot'
require 'logger'

require_relative 'core/bot_core'

class WebhooksController < Telegram::Bot::UpdatesController
  def message(message)
    $stderr.puts message
    if message.key?('text')
      $stderr.puts message['text']
      replys = BotCore::handle_message(message['text'])
      if !replys.nil?
        replys = [replys] if !replys.is_a?(Array)
        replys.each { |reply|
          if reply.is_a?(Hash)
            reply_text = reply[:text]
          else
            reply_text = reply
          end
          respond_with(:message, text: reply_text)
        }
      end
    end
  end

  #def inline_query(query, offset)
  #  $stderr.puts 'inline_query'
  #  $stderr.puts query
  #  $stderr.puts offset
  #end
end

bot = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])

# poller-mode
logger = Logger.new(STDERR)
poller = Telegram::Bot::UpdatesPoller.new(bot, WebhooksController, logger: logger)
poller.start
