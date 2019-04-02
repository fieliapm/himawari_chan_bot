#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'slack-ruby-client'

require_relative 'core/bot_core'

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
