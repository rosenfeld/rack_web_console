require 'erb'
require 'cgi'
require_relative 'rack_console/version'
require_relative 'rack_console/cookie_script_storage'
require_relative 'rack_console/output_capture'

class RackConsole
  VIEW_TEMPLATE = ::File.join __dir__, 'rack-console-view.erb'

  def initialize(_binding = binding, storage: ->(env){ CookieScriptStorage.new env })
    @storage, @binding = storage, _binding
  end

  def call(env)
    @_storage = ::Proc === @storage ? @storage[env] : @storage
    env['REQUEST_METHOD'] == 'POST' ? process_script(env) : render_view(env)
  end

  private


  def process_script(env)
    script = CGI.unescape env['rack.input'].read.sub(/\Ascript=/, '')
    @_storage&.script=(script)
    result = []
    (oc = OutputCapture.new).capture do
      begin
        result_eval = eval script, @binding
        result << %Q{<div class="stdout">#{::ERB::Util.h oc.output}</div>}
        result << %Q{<div class="return">#{::ERB::Util.h result_eval.inspect}</div>}
      rescue ::Exception => e
        result << e.message << "\n" << e.backtrace.join("\n")
      end
    end
    headers = { 'Content-Type' => 'text/html; charset=utf-8' }
    @_storage.set_cookie_header! headers
    [ 200, headers, [ result.join("\n").gsub("\n", "<br>\n") ] ]
  end

  def render_view(env)
    [ 200, { 'Content-Type' => 'text/html; charset=utf-8' }, [ view_response(env) ] ]
  end

  def view_response(env)
    script = (s = @_storage&.script) ? ::ERB::Util.h(s) : ''
    ::ERB.new(::File.read view_template).result binding
  end

  def view_template # so that it could be easily subclassed and overriden:
    VIEW_TEMPLATE
  end
end