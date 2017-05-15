#!/bin/env ruby
# encoding: utf-8

require 'rest-client'
require 'scraperwiki'
require 'wikidata/fetcher'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(URI.escape(URI.unescape(url))).read) 
end

def wikinames_from(url)
  noko = noko_for(url)
  wikinames = []
  noko.xpath('.//table[.//th[contains(.,"Candidate")]]').each do |table|
    cols = table.xpath('.//tr[th]/th').map(&:text)
    table.xpath('.//tr[td]').each do |tr|
      tds = tr.css('td')
      next unless tds.last.text.include? 'Elected'
      candidate = tds[cols.find_index('Candidate')]
      wikiname = candidate.xpath('a[not(@class="new")]/@title').text
      wikinames << wikiname unless wikiname.to_s.empty?
    end
  end
  raise "No names found in #{url}" if wikinames.count.zero?
  return wikinames
end

names = wikinames_from('https://en.wikipedia.org/wiki/Niuean_general_election,_2014')
EveryPolitician::Wikidata.scrape_wikidata(names: { en: names })




