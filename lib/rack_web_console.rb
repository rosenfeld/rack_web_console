require 'erb'
require 'cgi'
require 'securerandom'
require_relative 'rack_console/version'
require_relative 'rack_console/cookie_script_storage'
require_relative 'rack_console/output_capture'

class RackConsole
  VIEW_TEMPLATE = ::File.join __dir__, 'rack-console-view.erb'

  def initialize(_binding = binding, storage: ->(env){ CookieScriptStorage.new env }, token: nil)
    @storage, @binding = storage, _binding
    @@token ||= token || SecureRandom.base64(32)
  end

  def call(env)
    @_storage = ::Proc === @storage ? @storage[env] : @storage
    env['REQUEST_METHOD'] == 'POST' ? process_script(env) : render_view(env)
  end

  private

  def process_script(env)
    params = CGI.parse env['rack.input'].read
    token = params['token']&.first.to_s
    return [403, {}, []] unless same_origin?(env) && token == @@token
    script = params['script'].first
    @_storage&.script=(script)
    result = []
    (oc = OutputCapture.new).capture do
      begin
        result_eval = eval script, @binding
        result << %Q{<div class="stdout">#{::ERB::Util.h oc.output}</div>}
        result << %Q{<div class="return">#{::ERB::Util.h result_eval.inspect}</div>}
      rescue ::Exception => e
        message = ::ERB::Util.h "#{e.message}\n#{e.backtrace.join "\n"}"
        result << %Q{<div class="stdout">#{::ERB::Util.h oc.output}</div>}
        result << %Q{<div class="error">#{message}</div>}
      end
    end
    headers = { 'Content-Type' => 'text/html; charset=utf-8' }
    @_storage.set_cookie_header! headers
    [ 200, headers, [ result.join("\n") ] ]
  end

  def same_origin?(env)
    env['HTTP_HOST'] == (domain_from(env['HTTP_ORIGIN']) || domain_from(env['HTTP_REFERER']))
  end

  def domain_from(referer)
    referer && referer.gsub(%r{(?:\Ahttps?://|/.*)}, '')
  end

  def render_view(env)
    [ 200, { 'Content-Type' => 'text/html; charset=utf-8' }, [ view_response(env) ] ]
  end

  def view_response(env)
    script = (s = @_storage&.script) ? ::ERB::Util.h(s) : ''
    token = @@token
    ::ERB.new(::File.read view_template).result binding
  end

  def view_template # so that it could be easily subclassed and overriden:
    VIEW_TEMPLATE
  end
end
