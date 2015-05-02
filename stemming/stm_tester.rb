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

def format(string)
  string.gsub!('ž','z')
  string.gsub!('Ž','Z')
  string.gsub!('š','s')
  string.gsub!('Š','S')
  string.gsub!('č','c')
  string.gsub!('Č','C')
  string.gsub!('Ř','R')
  string.gsub!('ř','r')
  string.gsub!('ď','d')
  string.gsub!('Ď','D')
  string.gsub!('Ť','T')
  string.gsub!('ť','t')
  string.gsub!('Ň','N')
  string.gsub!('ň','n')
  string.gsub!('á','a')
  string.gsub!('Á','A')
  string.gsub!('ě','e')
  string.gsub!('Ě','E')
  string.gsub!('É','E')
  string.gsub!('é','e')
  string.gsub!('í','i')
  string.gsub!('Í','i')
  string.gsub!('Ó','O')
  string.gsub!('ó','o')
  string.gsub!('Ú','U')
  string.gsub!('ú','u')
  string.gsub!('Ů','U')
  string.gsub!('ů','u')
  string.gsub!('Ý','Y')
  string.gsub!('ý','y')
  string.downcase!
  string
end

File.open(@file+'.'+@type, 'w') do |output|
  results = []
  File.open(@file).each do |line|
    line.gsub!("\n",'')
    next if line.length == 0
    input = line.split('/')
    input.drop(results.count).each do
      results << 0
    end
    search = input[0]
    address = @server.gsub('%t',URI.encode(@type)).gsub('%s',URI.encode(search))
    response = Net::HTTP.get_response(URI.parse(address))
    data = JSON.parse(response.body)
    stem = data["analysis"]["field_types"][@type]["index"].last
    next if stem.count == 0
    stem = stem.last["text"]
    variants = input.drop(1)
    log = line+" "+stem+" 0"
    results[0] += 1
    variants.each_with_index do |variant, index|
      if(format(stem)==format(variant))
	results[index+1] += 1
        log = line+" "+stem+" "+(index+1).to_s
        break
      end
    end
    puts log
    output.write log+"\n"
  end
  log = 'count: '+results[0].to_s
  results.drop(1).each_with_index do |result, index|
    log += '; variant'+(index+1).to_s+': '+result.to_s
  end
  puts log
  output.write log+"\n"
end


