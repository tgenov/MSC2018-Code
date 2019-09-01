#!/usr/bin/env ruby
require 'oj'
require 'elasticsearch'
#require 'mysql2'
require 'pry'

##### Pre-canned queries
unique_login_sessions='{ "query" : { "query_string": { "query": "eventid:cowrie.command.input" } }, "_source": [ "session" ] }'


class EasyES

  attr_accessor :client, :scroll_result

  def initialize
    @client = Elasticsearch::Client.new
    @scroll_result = []
  end

  def scroll(body, time_window='5m', size=10000)
    scroll_result = []
    result = client.search body: body, scroll: '5m', index: 'logstash-2018.05.*', size: size
    scroll_id = result['_scroll_id']
    scroll_result = result['hits']['hits']
    scroll_iterate(scroll_id) if scroll_id
  end

  def scroll_iterate(scroll_id)
    result = client.scroll scroll: '5m', body: { scroll_id: scroll_id }
    unless result['hits']['hits'].empty?
      scroll_result.push(*result['hits']['hits'])
      scroll_iterate(scroll_id)
    end
  end

  def query(query)
    client.search body: query
  end

end

#mysql = Mysql2::Client.new(:host => "localhost", :username => "root")
es = EasyES.new
session_ids = es.scroll_result.map { |i| i['_source']['session'] }.uniq
File.open('sessions','w') do |f|
  session_ids.map { |s| f.write("#{s}\n") }
end