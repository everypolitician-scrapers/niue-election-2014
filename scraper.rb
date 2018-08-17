#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata/fetcher'

def noko_for(url)
  Nokogiri::HTML(open(URI.escape(URI.unescape(url))).read)
end

def wikinames_from(url)
  noko = noko_for(url)
  noko.xpath('.//table[.//th[contains(.,"Candidate")]]').flat_map do |table|
    cols = table.xpath('.//tr[th]/th').map(&:text).map(&:tidy)
    table.xpath('.//tr[td]').map do |tr|
      tds = tr.css('td')
      next unless tds.last.text.downcase.include? 'elected'
      tds[cols.find_index('Candidate')].xpath('a[not(@class="new")]/@title').text
    end
  end.compact.reject(&:empty?)
end

names_2014 = wikinames_from('https://en.wikipedia.org/wiki/Niuean_general_election,_2014')
names_2017 = wikinames_from('https://en.wikipedia.org/wiki/Niuean_general_election,_2017')

EveryPolitician::Wikidata.scrape_wikidata(names: { en: names_2014 | names_2017 })
