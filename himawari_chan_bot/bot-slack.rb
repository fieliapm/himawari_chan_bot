#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'slack-ruby-client'

require_relative 'core/bot_core'

def slack_bot
  Slack.configure { |config|
    config.token = ENV['SLACK_API_TOKEN']
    config.logger = Logger.new(STDERR)
    config.logger.level = Logger::INFO
    raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
  }

  client = Slack::RealTime::Client.new

  client.on(:hello) {
    $stderr.puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
  }

  client.on(:message) { |data|
    $stderr.puts data
    $stderr.puts data.text
    replys = BotCore::handle_message(data.text)
    if !replys.nil?
      replys = [replys] if !replys.is_a?(Array)
      replys.each { |reply|
        if reply.is_a?(Hash)
          reply_text = reply[:text]
        else
          reply_text = reply
        end
        client.message(channel: data.channel, text: reply_text)
      }
    end
  }

  return client
end

slack_bot.start!
