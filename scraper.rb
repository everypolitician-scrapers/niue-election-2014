#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def wikilink(node)
  local = node.xpath('a[not(@class="new")]/@href').text
  return if local.to_s.empty?
  return URI.join('https://en.wikipedia.org/', local).to_s 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('.//table[.//th[contains(.,"Candidate")]]').each do |table|
    cols = table.xpath('.//tr[th]/th').map(&:text)
    table.xpath('.//tr[td]').each do |tr|
      tds = tr.css('td')
      next unless tds.last.text.include? 'Elected'
      candidate = tds[cols.find_index('Candidate')]
      data = { 
        name: candidate.text,
        wikipedia: wikilink(candidate),
      }
      puts data
      ScraperWiki.save_sqlite([:name, :term], data)
    end
  end
end

scrape_list('https://en.wikipedia.org/w/index.php?title=Niuean_general_election,_2014&oldid=605601691')
