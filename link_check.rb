# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'uri'

# Checks HTTP response codes and follows redirects.
class LinkCheck
  DEFAULT_TIMEOUT = 15
  DEFAULT_REDIRECT_LIMIT = 10

  attr_reader :redirects, :responses, :redirect_count, :success_count, :error_count

  def initialize(timeout: DEFAULT_TIMEOUT, redirect_limit: DEFAULT_REDIRECT_LIMIT, verify_ssl: true)
    @timeout = timeout
    @redirect_limit = redirect_limit
    @verify_ssl = verify_ssl
    reset
  end

  def reset
    @redirects = []
    @responses = []
    @redirect_count = 0
    @success_count = 0
    @error_count = 0
  end

  def fetch(url, limit = @redirect_limit, start_time = nil)
    start_time ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
    uri = URI(url)

    response = http_get(uri)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    case response
    when Net::HTTPSuccess
      @success_count += 1
      { res: response.code, res_time: elapsed }
    when Net::HTTPRedirection
      @redirect_count += 1
      location = response['location']
      unless location
        @error_count += 1
        return { res: response.code, res_time: elapsed, error: 'redirect missing Location header' }
      end

      next_uri = URI.join(uri, location).to_s
      warn "#{uri} redirected to #{next_uri}" if $VERBOSE

      @redirects << next_uri
      @responses << response.code

      if limit <= 1
        @error_count += 1
        return { res: response.code, res_time: elapsed, error: 'redirect limit exceeded' }
      end

      fetch(next_uri, limit - 1, start_time)
    else
      @error_count += 1
      { res: response.code, res_time: elapsed }
    end
  rescue URI::InvalidURIError => e
    @error_count += 1
    { res: 'ERR', res_time: 0, error: "invalid URI: #{e.message}" }
  rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
    @error_count += 1
    { res: '408', res_time: 0, error: 'request timed out' }
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH => e
    @error_count += 1
    { res: '408', res_time: 0, error: e.message }
  rescue StandardError => e
    @error_count += 1
    warn "Error fetching #{url}: #{e.class}: #{e.message}" if $VERBOSE
    { res: 'ERR', res_time: 0, error: e.message }
  end

  private

  def http_get(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: @timeout,
      read_timeout: @timeout,
      verify_mode: @verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    ) do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Ruby-HTTP-Header-Response-Checker/2.0'
      http.request(request)
    end
  end
end
