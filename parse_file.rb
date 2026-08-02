# frozen_string_literal: true

require_relative 'link_check'

# Reads a URL list, checks each link, and writes TSV results.
class ParseFile
  DEFAULT_SAVE_FILE = 'results.tsv'
  DEFAULT_INPUT_FILE = 'pages.csv'
  DEFAULT_REPLACE = 'http://studiocenter.com/'
  DEFAULT_NEW_URL = 'http://studiocenter.com/'

  def initialize(
    save_file: DEFAULT_SAVE_FILE,
    input_file: DEFAULT_INPUT_FILE,
    replace: DEFAULT_REPLACE,
    new_url: DEFAULT_NEW_URL,
    timeout: LinkCheck::DEFAULT_TIMEOUT,
    redirect_limit: LinkCheck::DEFAULT_REDIRECT_LIMIT,
    verify_ssl: true
  )
    @save_file = save_file
    @input_file = input_file
    @replace = replace
    @new_url = new_url
    @checker_options = {
      timeout: timeout,
      redirect_limit: redirect_limit,
      verify_ssl: verify_ssl
    }
  end

  def self.prompt(label, default)
    print "#{label} (default: #{default}): "
    value = $stdin.gets&.chomp
    value.nil? || value.empty? ? default : value
  end

  def self.from_prompts
    new(
      save_file: prompt('Where would you like to save your results?', DEFAULT_SAVE_FILE),
      input_file: prompt('What file stores your list of links?', DEFAULT_INPUT_FILE),
      replace: prompt('Which URL do you want to replace within your URL list?', DEFAULT_REPLACE),
      new_url: prompt('What replacement URL would you like to use?', DEFAULT_NEW_URL)
    )
  end

  def parse_list
    unless File.file?(@input_file)
      warn "Input file not found: #{@input_file}"
      exit 1
    end

    checker = LinkCheck.new(**@checker_options)
    totals = { redirects: 0, success: 0, errors: 0 }

    File.open(@save_file, 'w') do |output|
      output.puts "status\turl\tredirects\tresponse_time"

      File.foreach(@input_file) do |line|
        url = normalize_url(line.sub(@replace, @new_url))
        next if url.empty?

        checker.reset
        result = checker.fetch(url)

        totals[:redirects] += checker.redirect_count
        totals[:success] += checker.success_count
        totals[:errors] += checker.error_count

        status = checker.redirects.any? ? checker.responses.join(',') : result[:res]
        redirects = checker.redirects.join(',')
        output.puts [status, url, redirects, format('%.6f', result[:res_time])].join("\t")
      end

      print_summary(totals)
    end
  end

  private

  def normalize_url(link)
    link = link.strip
    return '' if link.empty?
    return link if link.match?(%r{\Ahttps?://}i)

    if link.start_with?('//')
      "https:#{link}"
    elsif link.start_with?('/')
      "http:/#{link}"
    else
      "http://#{link}"
    end
  end

  def print_summary(totals)
    puts "Redirects: #{totals[:redirects]}"
    puts "200 OK: #{totals[:success]}"
    puts "Other responses: #{totals[:errors]}"
    puts "Results saved to #{@save_file}"
    puts 'DONE!'
  end
end
