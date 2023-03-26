#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'pry'

book_name = ARGV[0]
if book_name.nil?
  puts "Usage: #{$PROGRAM_NAME} <book name>"
  exit(1)
end

segment_size = 10_000
books_dir = 'data/books'
book_dir = File.join(File.expand_path(books_dir), book_name)
book_file = File.join(book_dir, "#{book_name}.txt")

# Read the book file
book = File.readlines(book_file)
book.map! do |line|
  line.gsub!(/[[:space:]]+/, " ")
end

# Split the book into segments of up to segment_size characters. Try to split on a sentence boundary.
segments = []
current_segment = []
book.each do |line|
  next if line.strip.empty?

  if current_segment.sum(&:length) + line.length > segment_size
    segments << current_segment.join("\n")
    current_segment = []
  end
  current_segment << line
end

# Prepare the segments directory
segments_dir = File.join(book_dir, 'segments')
FileUtils.rm_rf(segments_dir)
Dir.mkdir(segments_dir)

# Write segments to files
segments.each_with_index do |segment, index|
  segment_dir = File.join(segments_dir, index.to_s)
  segment_file = File.join(segment_dir, "segment.txt")
  Dir.mkdir(segment_dir)
  File.write(segment_file, segment)
end
