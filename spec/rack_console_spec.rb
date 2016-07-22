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
    sleep 0.1 # give it some time to boot
  end

  after(:all) do
    Rack::Handler::WEBrick.shutdown
  end
  before{ @port = port }

  it 'renders the template view with GET requests' do
    expect(Net::HTTP.get('127.0.0.1', '/', port)).to match %r{<title>Console</title>}
  end

  it 'renders output and return value on POST' do
    response = Net::HTTP.post_form uri, {'script' => "puts 'abc'\nabc"}
    expect(response.body).to eq [
      '<div class="stdout">abc<br>',
      '</div><br>',
      '<div class="return">1</div>'
    ].join("\n")
    expect(response['set-cookie']).
      to eq '_rack-console-script=puts+%27abc%27%0Aabc; domain=127.0.0.1; path=/'
    http = Net::HTTP.new uri.host, uri.port
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