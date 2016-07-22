require 'stringio'

class RackConsole
  class OutputCapture
    def initialize
      @old = $stdout
      @io = ::StringIO.new
      @main_thread = ::Thread.current
    end

    def write(value)
      io.write(value)
    end

    def capture
      $stdout = self
      yield
    ensure
      $stdout = @old
    end

    def output
      @io.rewind
      @io.read
    end

    private

    def io
      ::Thread.current == @main_thread || @main_thread[:rack_console_capture_all] ? @io : @old
    end
  end
end
