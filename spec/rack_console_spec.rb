require 'rack_web_console'
require 'rack'
require 'socket'
require 'net/http'

describe RackConsole do
  def app
    abc = 1 # add local variable to binding
    RackConsole.new binding
  end

  port = server = nil
  before(:all) do
    server = TCPServer.new 'localhost', 0
    port = server.addr[1]
    server.close
    Thread.start {
      Rack::Handler::WEBrick.run app, BindAddress: '127.0.0.1', Port: port, AccessLog: [],
        Logger: WEBrick::Log.new(nil, 0)
    }
    sleep (ENV['WAIT_FOR_BOOT_TIME'] || 0.1).to_f # give it some time to boot
  end

  after(:all) do
    Rack::Handler::WEBrick.shutdown
  end
  before{ @port = port }

  it 'renders the template view with GET requests' do
    expect(Net::HTTP.get('127.0.0.1', '/', port)).to match %r{<title>Console</title>}
  end

  it 'has basic protection against CSRF' do
    response = Net::HTTP.post_form uri, {'script' => "puts 'abc'\nabc"}
    expect(response.body).to eq ''
    expect(response).to be_an_instance_of Net::HTTPForbidden
  end

  it 'renders output and return value on POST' do
    content = Net::HTTP.get('127.0.0.1', '/', port) # ensure CSRF token is generated
    http = Net::HTTP.new uri.host, uri.port
    req = Net::HTTP::Post.new(uri, { 'Referer' => uri.to_s })
    token = /^\s+encodeURIComponent\('(.*?)'\)/m.match(content)[1]
    #token = RackConsole.class_variable_get(:@@token)
    req.set_form_data 'script' => "puts 'abc'\nabc", 'token' => token
    response = http.request req
    expect(response.body).to eq [
      '<div class="stdout">abc<br>',
      '</div><br>',
      '<div class="return">1</div>'
    ].join("\n")
    expect(response['set-cookie']).
      to eq '_rack-console-script=puts+%27abc%27%0Aabc; domain=127.0.0.1; path=/'
    resp = http.get '/', {'Cookie' => response['set-cookie'].split(';', 2).first}
    expect(resp.body).
      to match %r{<textarea id="script" rows="10" cols="80">puts &#39;abc&#39;\nabc</textarea>}
  end

  def uri
    @uri ||= URI("http://127.0.0.1:#{@port}")
  end

  # TODO: write those tests
  pending "output of other concurrent threads are not sent to the response"
  pending "output of other concurrent threads are sent to the response if configured so"
end
