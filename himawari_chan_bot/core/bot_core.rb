#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'nokogiri'

module BotCore
  YOUTUBE_WEBSITE = 'https://www.youtube.com'

  def self.get_youtube_video_info(video_tag)
    thumbnail_tag = video_tag.xpath('.//div[contains(@class, "yt-lockup-thumbnail")]//img').first
    anchor_tag = video_tag.xpath('.//div[contains(@class, "yt-lockup-content")]//a').first

    if !thumbnail_tag.nil? && !anchor_tag.nil?
      title = anchor_tag.xpath('.//text()').text

      anchor = anchor_tag.attribute('href').value

      thumbnail_attr = thumbnail_tag.attribute('data-thumb')
      if thumbnail_attr.nil?
        thumbnail_attr = thumbnail_tag.attribute('src')
      end
      thumbnail = thumbnail_attr.value

      if /^\/watch\?/ =~ anchor
        video_info = {
          title: title,
          anchor: YOUTUBE_WEBSITE + anchor,
          thumbnail: thumbnail,
        }

        if video_info[:title].length <= 0
          video_info[:title] = '(no-name)'
        end
        video_info[:text] = "%s\n%s" % [video_info[:title], video_info[:anchor]]

        return video_info
      end
    end
    return nil
  end

  def self.search_youtube(query_string)
    uri = URI(YOUTUBE_WEBSITE + '/results')
    params = { 'search_query' => query_string }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      doc = Nokogiri::HTML(response.body)
      video_tags_with_ads = doc.xpath('/html/body//div[@id="results"]/ol[contains(@class, "section-list")]/li[2]/ol[contains(@class, "item-section")]/li/div[contains(@class, "yt-lockup")]')
      video_infos_with_ads = video_tags_with_ads.map { |video_tag|
        get_youtube_video_info(video_tag)
      }
      video_infos = video_infos_with_ads.select { |video_info|
        !video_info.nil?
      }
      video_infos.each { |video_info|
        return video_info
      }
      raise RuntimeError.new('parse result failed')
    else
      raise RuntimeError.new('cannot query youtube')
    end
    return video_url
  end

  def self.handle_message(message)
    case message
    when /^(.*)\.(avi|wmv|mov|mp4|mkv|webm|mpg|m2v|ts|m2ts|flv|rm)$/
      video_info = search_youtube($1)
      video_info[:type] = 'video'
      reply = [
        #{ type: 'text', text: '來點片片' },
        #{ type: 'text', text: video_info[:text] },
        video_info,
      ]
      # for message test
      #when /(長輩|長老|蘿路)/
      #  reply = '先別提"' + message + '"了,你知道長老母湯是一種信仰嗎?'
      #when /(奶|ろへ|ㄋㄟ)/
      #  reply = ['各位', 'ろへろへ讚!']
      #when /(FTMM|ふともも|大腿|腿腿|腿控)/
      #  reply = ['想舔腿腿', '(ぺろぺろ)']
      #when /(明治|大正|昭和|平成|令和)/
      #  reply = ['万歳~! 万歳~!']
    else
      reply = nil
    end
    return reply
  end
end
