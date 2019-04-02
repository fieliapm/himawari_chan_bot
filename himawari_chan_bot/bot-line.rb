#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'sinatra/base'
require 'line/bot'

require_relative 'core/bot_core'

TOKEN_EXPIRE_LAST_SECOND = 60

module LineClient
  def self.client
    if @token_info.nil? || @token_info['expired_at'] <= Time.now.to_i + TOKEN_EXPIRE_LAST_SECOND
      channel_id = ENV['LINE_CHANNEL_ID']
      channel_secret = ENV['LINE_CHANNEL_SECRET']
      @token_info = refresh_token(channel_id, channel_secret)
      $stderr.puts 'refresh token:', @token_info

      @client_instance = Line::Bot::Client.new { |config|
        config.channel_secret = channel_secret
        config.channel_token = @token_info['access_token']
      }
    end
    @client_instance
  end

  def self.refresh_token(client_id, client_secret)
    uri = URI('https://api.line.me/v2/oauth/accessToken')
    response = Net::HTTP.post_form(uri, 'grant_type' => 'client_credentials', 'client_id' => client_id, 'client_secret' => client_secret)
    if response.code == '200'
      token_info = JSON.parse(response.body)
      token_info['expired_at'] = Time.now.to_i + token_info['expires_in']
    else
      raise RuntimeError.new('refresh token failed')
    end
    return token_info
  end

  def self.handle_reply(event, replys)
    replys = [replys] if replys.is_a?(String)
    client.reply_message(
      event['replyToken'],
      replys.map { |reply|
        if reply.is_a?(Hash) && reply[:type] == 'video'
          convert_video_info_to_line_flex_message(reply)
        elsif reply.is_a?(String)
          { type: 'text', text: reply }
        else
          reply
        end
      }
    )
  end

  def self.convert_video_info_to_line_flex_message(video_info)
    flex_message = {
      type: 'flex',
      altText: video_info[:text],
      contents: {
        type: 'bubble',
        hero: {
          type: 'image',
          url: video_info[:thumbnail],
          size: 'full',
          aspectRatio: '16:9',
          action: {
            type: 'uri',
            uri: video_info[:anchor],
          },
        },
        footer: {
          type: 'box',
          layout: 'vertical',
          contents: [
            {
              type: 'box',
              layout: 'baseline',
              contents: [
                {
                  type: 'text',
                  text: video_info[:title],
                  wrap: true,
                  size: 'sm',
                  weight: 'bold',
                },
              ],
            },
            {
              type: 'box',
              layout: 'baseline',
              contents: [
                {
                  type: 'text',
                  text: video_info[:anchor],
                  wrap: true,
                  size: 'sm',
                },
              ],
            },
          ],
        },
      },
    }
    return flex_message
  end
end

class HimawariChanBot < Sinatra::Base
  before { }

  post('/webhook/line') {
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless LineClient::client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = LineClient::client.parse_events_from(body)

    events.each { |event|
      $stderr.puts event

      Thread.new {
        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            $stderr.puts event.message
            reply = BotCore::handle_message(event.message['text'])
            if !reply.nil?
              LineClient::handle_reply(event, reply)
            end
            #when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
            #  response = LineClient::client.get_message_content(event.message['id'])
          end
        when Line::Bot::Event::Join
          $stderr.puts 'Join'
        when Line::Bot::Event::Leave
          $stderr.puts 'Leave'
        end
      }
    }

    'OK'
  }
end

HimawariChanBot.run!(:bind => '0.0.0.0', :port => 4567, :server => :thin)
