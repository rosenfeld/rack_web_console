require 'cgi'
require 'rack/utils'

class RackConsole
  class CookieScriptStorage
    attr_accessor :script

    def initialize(env, cookie_key: '_rack-console-script', max_length: 4000)
      @env, @cookie_key, @max_length = env, cookie_key, max_length
      @script = ::CGI::Cookie.parse(env['HTTP_COOKIE'].to_s)[cookie_key]&.first || ''
    end

    WARNING_LIMIT_MSG = ->(max){ 'WARNING: stored script was limited to the first ' +
      "#{max} chars to avoid issues with cookie overflow\n" }
    def set_cookie_header!(headers = {})
      script = @script.to_s
      puts WARNING_LIMIT_MSG[@max_length] if script.size > @max_length
      cookie = { value: script[0...@max_length], path: @env['REQUEST_PATH'],
        domain: @env['SERVER_NAME'] }
      ::Rack::Utils.set_cookie_header! headers, @cookie_key, cookie
      headers
    end
  end
end
