#!/usr/bin/env ruby
require 'oj'
require 'elasticsearch'

client = Elasticsearch::Client.new
result = client.search q: "session:#{ARGV[0]}, eventid:cowrie.command.input"
puts Oj.dump(result['hits']['hits'])