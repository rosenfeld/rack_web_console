require 'rack_web_console'
require 'rack'
require 'socket'
require 'net/http'
require 'puma'
require 'puma/server'
require 'rails'
require 'action_controller'

class RailsApp < Rails::Application
  config.root = __dir__
  config.eager_load = false

  routes.append do
    match "console" => "console#index", via: [:get, :post]
  end
end

class ConsoleController < ActionController::Base
  skip_forgery_protection

  def index
    abc = 1 # add local variable to binding
    status, headers, body = RackConsole.new(binding).call(request.env)
    response.headers.merge! headers
    render html: body.join("\n").html_safe, status:
  end
end

RailsApp.initialize!

describe RackConsole do
  def simple_app
    abc = 1 # add local variable to binding
    RackConsole.new binding
  end

  def rails_app
    RailsApp
  end

  servers = []
  ports = []

  before(:all) do
    servers << (puma_server = Puma::Server.new simple_app)
    tcp_server = puma_server.add_tcp_listener '127.0.0.1', 0
    ports << tcp_server.addr[1]
    puma_server.run

    servers << (puma_server = Puma::Server.new rails_app)
    tcp_server = puma_server.add_tcp_listener '127.0.0.1', 0
    ports << tcp_server.addr[1]
    puma_server.run
  end

  after(:all) do
    servers.each &:stop
  end

  (0..1).each do |idx|
    server_type = idx == 0 ? 'simple' : 'rails'
    path = idx == 0 ? '/' : '/console/'

    context "with #{server_type} app" do
      let(:port){ ports[idx] }
      before { @path = path }

      it 'renders the template view with GET requests' do
        expect(Net::HTTP.get('127.0.0.1', path, port)).to match %r{<title>Console</title>}
      end

      it 'has basic protection against CSRF' do
        response = Net::HTTP.post_form uri, {'script' => "puts 'abc'\nabc"}
        expect(response.body).to eq ''
        expect(response).to be_an_instance_of Net::HTTPForbidden
      end

      it 'renders output and return value on POST' do
        response = run_script "puts 'abc'\nabc", port
        expect(response.body).to eq [
          '<div class="stdout">abc',
          '</div>',
          '<div class="return">1</div>'
        ].join("\n")
        expect(response['set-cookie']).
          to eq "_rack-console-script=puts+%27abc%27%0Aabc; domain=127.0.0.1; path=#{@path}"
        resp = @http.get @path, {'Cookie' => response['set-cookie'].split(';', 2).first}
        expect(resp.body).
          to match %r{<textarea id="script" rows="10" cols="80">puts &#39;abc&#39;\nabc</textarea>}
      end

      def run_script(script, port)
        content = Net::HTTP.get('127.0.0.1', @path, port) # ensure CSRF token is generated
        @http = Net::HTTP.new uri.host, uri.port
        req = Net::HTTP::Post.new(uri, { 'Referer' => uri.to_s })
        token = /^\s+encodeURIComponent\('(.*?)'\)/m.match(content)[1]
        #token = RackConsole.class_variable_get(:@@token)
        req.set_form_data 'script' => script, 'token' => token
        @http.request req
      end

      it 'renders output and exception details when it happens' do
        response = run_script "puts 'abc'\nraise 'error'", port
        expect(response.body).to match [
          '<div class="stdout">abc',
          '</div>',
          '<div class="error">error'
        ].join("\n")
        expect(response.body).to match /class="error">error.*rack_web_console.rb:.*process_script/m
      end

      def uri
        @uri ||= URI("http://127.0.0.1:#{port}#{@path}")
      end

    end
  end

  # TODO: write those tests
  pending "output of other concurrent threads are not sent to the response"
  pending "output of other concurrent threads are sent to the response if configured so"
end
