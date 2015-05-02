#!/bin/ruby
require 'rubygems'
require 'net/http'
require 'json'

if ARGV.count < 2
  puts "Syntax: tester.rb <field_type> <input_file>"
  exit
end

@server = 'http://localhost:8080/solr/collection1/analysis/field?wt=json&analysis.showmatch=true&analysis.fieldvalue=%s&analysis.fieldtype=%t'

@type = ARGV[0]
@file = ARGV[1]

File.open(@file+'.'+@type, 'w') do |output|
  results = []
  File.open(@file).each do |line|
    log = line
    line.gsub!("\n",'')
    next if line.length == 0
    input = line.split('/')
    result = {}
    input.each do |search|
      address = @server.gsub('%t',URI.encode(@type)).gsub('%s',URI.encode(search))  
      response = Net::HTTP.get_response(URI.parse(address))
      data = JSON.parse(response.body)
      stem = data["analysis"]["field_types"][@type]["index"].last
      next if stem.count == 0
      stem = stem.last["text"]
      result[stem.to_sym] = 0 unless result.key?(stem.to_sym)
      result[stem.to_sym] = result[stem.to_sym] + 1
      log = log+" "+stem
    end
    sum = result.collect{ |item,val| val}.reduce :+
    sorted = result.sort_by { |name, count| count }
    results << sorted.last.last.to_f / sum.to_f
    log = log + " " + results.last.to_s
    puts log
    output.write log+"\n"
  end
  log = 'avg success: '+ (results.inject{ |sum, el| sum + el }.to_f / results.size).to_s
  puts log
  output.write log+"\n"
  log = 'success %: '+ (results.inject{ |sum, el| el == 1 ? sum + 1 : sum  }.to_f / results.size).to_s
  puts log
  output.write log+"\n"
end


