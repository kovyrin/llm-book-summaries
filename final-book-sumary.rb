#!/usr/bin/env ruby

require 'ruby/openai'
require 'pry'
require 'set'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID')
end

client = OpenAI::Client.new

book_name = ARGV[0]

if book_name.nil?
  puts "Usage: #{$PROGRAM_NAME} <book name>"
  exit(1)
end

book_dir = "data/books/#{book_name}"

metadata_file = File.join(book_dir, 'metadata.json')
metadata = JSON.parse(File.read(metadata_file))

summaries = []
characters = Hash.new(0)
keywords = Hash.new(0)

segment_dirs = Dir.glob(File.join(book_dir, 'segments', '*')).sort_by { |segment_dir| segment_dir.split('/').last.to_i }
segment_dirs.each do |segment_dir|
  summary_file = File.join(segment_dir, 'summary.json')
  summary = JSON.parse(File.read(summary_file))

  summaries << summary["summary"]
  summary["characters"].each do |character|
    characters[character.capitalize] += 1
  end

  summary["keywords"].each do |keyword|
    keywords[keyword.downcase] += 1
  end
end

# Remove all keywords and characters that only appear once
keywords.delete_if { |_, count| count == 1 }
characters.delete_if { |_, count| count == 1 }

puts "Summary for #{metadata["title"]} by #{metadata["author"]}:"
puts summaries.join("\n")
puts
puts "Characters: #{characters.sort_by { |_, count| -count }.map { |character, _| character }.join(', ')}"
puts
puts "Keywords: #{keywords.sort_by { |_, count| -count }.map { |keyword, _| keyword }.join(', ')}"
puts

# system_prompt = <<~PROMPT
#   You are given a summary of a book along with additional metadata about it.
#   You need to help with analyzing the book and coming up with a set of genres for the book, a set of adjectives describing the book, and a set of unique keywords describing the book.
#   Do not use the book name, author name or any character names as keywords.
# PROMPT

# metadata_prompt = <<~PROMPT
#   Book metadata in JSON format:
#   #{metadata.to_json}
# PROMPT

# summary_prompt = <<~PROMPT
#   Summary:
#   #{summary_override || summaries.join("\n")}
# PROMPT

# json_prompt = <<~PROMPT
#   Please provide result as a JSON object with the following structure:
#   {
#     "genres": ["Genre 1", "Genre 2"],
#     "adjectives": ["Adjective 1", "Adjective 2"],
#     "keywords": ["Keyword 1", "Keyword 2"]
#   }
#   Do not add any additional content into your response, keep it to JSON only.
# PROMPT

# request_params = {
#   model: "gpt-3.5-turbo",
#   messages: [
#     { role: "system", content: system_prompt },
#     { role: "user", content: metadata_prompt },
#     { role: "system", content: summary_prompt},
#     { role: "user", content: json_prompt }
#   ]
# }

# response = client.chat(parameters: request_params)
# binding.pry
