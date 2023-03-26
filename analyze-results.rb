#!/usr/bin/env ruby
# frozen_string_literal: true

require "pry"
require "json"

price_per_1000_tokens = 0.002

book_dir = 'data/books/children-of-memory'
segments_dir = File.join(book_dir, 'segments')
segment_dirs = Dir.glob(File.join(segments_dir, '*'))

total_tokens = 0

segment_dirs.each do |segment_dir|
  result_file = File.join(segment_dir, 'result.json')
  result = JSON.parse(File.read(result_file))
  tokens = result["usage"]["total_tokens"]
  total_tokens += tokens
end

puts "Total tokens: #{total_tokens}"
puts "Price: #{total_tokens * price_per_1000_tokens / 1000}"
