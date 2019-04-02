#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

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
