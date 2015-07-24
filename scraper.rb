#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'wikidata'

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

def wikidata(node)
  link = node.xpath('a[not(@class="new")]/@href').text
  return {} if link.to_s.empty?

  title = node.xpath('a/@title').text
  wd = Wikidata::Item.find_by_title title

  property = ->(elem, attr='title') { 
    prop = wd.property(elem) or return
    prop.send(attr)
  }

  fromtime = ->(time) { 
    return unless time
    DateTime.parse(time.time).to_date.to_s 
  }

  # party = P102
  # freebase = P646
  return { 
    wikipedia: URI.join('https://en.wikipedia.org/', link).to_s,
    wikidata: wd.id,
    family_name: property.('P734'),
    given_name: property.('P735'),
    image: property.('P18', 'url'),
    gender: property.('P21'),
    birth_date: fromtime.(property.('P569', 'value')),
  }
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
      }.merge wikidata(candidate)
      puts data
      ScraperWiki.save_sqlite([:name], data)
    end
  end
end

scrape_list('https://en.wikipedia.org/w/index.php?title=Niuean_general_election,_2014&oldid=605601691')
