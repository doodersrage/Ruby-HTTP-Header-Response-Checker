#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'parse_file'

options = {
  interactive: false,
  save_file: ParseFile::DEFAULT_SAVE_FILE,
  input_file: ParseFile::DEFAULT_INPUT_FILE,
  replace: ParseFile::DEFAULT_REPLACE,
  new_url: ParseFile::DEFAULT_NEW_URL,
  timeout: LinkCheck::DEFAULT_TIMEOUT,
  redirect_limit: LinkCheck::DEFAULT_REDIRECT_LIMIT,
  verify_ssl: true
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  opts.on('-i', '--interactive', 'Prompt for file paths and URL replacement values') do
    options[:interactive] = true
  end
  opts.on('-o', '--output FILE', 'Output TSV file') { |value| options[:save_file] = value }
  opts.on('-f', '--input FILE', 'Input URL list file') { |value| options[:input_file] = value }
  opts.on('-r', '--replace URL', 'URL prefix to replace in the input list') { |value| options[:replace] = value }
  opts.on('-n', '--new-url URL', 'Replacement URL prefix') { |value| options[:new_url] = value }
  opts.on('-t', '--timeout SECONDS', Integer, 'HTTP open/read timeout') { |value| options[:timeout] = value }
  opts.on('--redirect-limit COUNT', Integer, 'Maximum redirects to follow') do |value|
    options[:redirect_limit] = value
  end
  opts.on('--no-ssl-verify', 'Disable SSL certificate verification') do
    options[:verify_ssl] = false
  end
  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!

parser =
  if options[:interactive]
    ParseFile.from_prompts
  else
    ParseFile.new(
      save_file: options[:save_file],
      input_file: options[:input_file],
      replace: options[:replace],
      new_url: options[:new_url],
      timeout: options[:timeout],
      redirect_limit: options[:redirect_limit],
      verify_ssl: options[:verify_ssl]
    )
  end

parser.parse_list
