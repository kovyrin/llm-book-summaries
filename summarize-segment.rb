#!/usr/bin/env ruby

require 'ruby/openai'
require 'pry'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID')
end

client = OpenAI::Client.new

book_name = ARGV[0]
segment_number = ARGV[1]

if book_name.nil? || segment_number.nil?
  puts "Usage: #{$PROGRAM_NAME} <book name> <segment number>"
  exit(1)
end

book_dir = "data/books/#{book_name}"
metadata_file = File.join(book_dir, 'metadata.json')
metadata = JSON.parse(File.read(metadata_file))

segment_dir = File.join(book_dir, "segments", segment_number)
segment_file = File.join(segment_dir, 'segment.txt')
request_file = File.join(segment_dir, 'request.json')
response_file = File.join(segment_dir, 'result.json')
summary_file = File.join(segment_dir, 'summary.json')

if File.exist?(summary_file)
  summary = JSON.parse(File.read(summary_file))
  puts "Summary already exists for #{segment_dir}:"
  pp(summary)
  exit(0)
end

puts "Generating summary for #{segment_dir}..."
segment = File.read(segment_file)

system_prompt = <<~PROMPT
  Your job is to summarize the given snippet from a book called "#{metadata.fetch("title")}" by #{metadata.fetch("author")}.
  The resulting summary should be concise and should be less than 1000 characters long.
  Along with the summary, please provide a list of all known characters in the segment.
  Additionally, please provide a list of 10 keywords that describe the segment (do not use character names or the book title as keywords).
PROMPT

snippet_prompt = <<~PROMPT
  Snippet:
  #{segment}
PROMPT

json_prompt = <<~PROMPT
  Please provide result as a JSON object with the following structure:
  {
    "summary": "The summary",
    "characters": ["Character 1", "Character 2"],
    "keywords": ["Keyword 1", "Keyword 2"]
  }
PROMPT

request_params = {
  model: "gpt-3.5-turbo",
  messages: [
    { role: "system", content: system_prompt },
    { role: "user", content: snippet_prompt },
    { role: "user", content: json_prompt }
  ]
}
File.write(request_file, JSON.pretty_generate(request_params))

response = client.chat(parameters: request_params)
File.write(response_file, response.to_s)

summary = JSON.parse(response['choices'][0]['message']['content'].gsub('`', ''))
File.write(summary_file, JSON.pretty_generate(summary))
puts "Summary generated:"
pp(summary)
