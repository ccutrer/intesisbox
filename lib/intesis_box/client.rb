require 'socket'

module IntesisBox
  class Client
    attr_reader :ip, :model, :mac, :version, :rssi
    attr_reader :limits
    attr_reader :devicename
    attr_reader :onoff, :mode, :fansp, :vaneud, :vanelr, :setptemp, :ambtemp, :errstatus, :errcode

    def initialize(ip, port = 3310)
      @limits = {}
      @ip = ip
      @io = TCPSocket.new(ip, port)

      @io.puts("LIMITS:*")
      poll(1)
      @io.puts("CFG:DEVICENAME")
      poll(1)
      @io.puts("GET,1:*")
      poll(1)
      # this is purposely last, since mac is what we check for it being ready
      @io.puts("ID")
      poll(1)
    end

    def poll(timeout = 30)
      return false if @io.wait_readable(timeout).nil?

      loop do
        line = @io.readline.strip
        cmd, args = line.split(':', 2)
        case cmd
        when "ID"
          @model, @mac, _ip, _protocol, @version, @rssi = args.split(',')
        when "LIMITS"
          function, limits = args.split(",",2)
          limits = limits[1...-1].split(",")
          next if function == 'ONOFF'
          limits.map! { |l| l.to_f / 10 } if %w{SETPTEMP AMBTEMP}.include?(function)
          @limits[function.downcase.to_sym] = limits
        when "CHN,1"
          function, value = args.split(",")
          value = value == 'ON' if function == 'ONOFF'
          value = value.to_f / 10 if %w{SETPTEMP AMBTEMP}.include?(function)
          value = value.to_i if function == 'ERRCODE'
          value = nil if value == -3276.8
          instance_variable_set(:"@#{function.downcase}", value)
        when "CFG"
          function, value = args.split(",", 2)
          @devicename = value if function == 'DEVICENAME'
        end
        break unless @io.ready?
      end
      true
    end

    def ping
      @io.puts("PING")
    end

    def onoff=(value)
      @io.puts("SET,1:ONOFF,#{value ? 'ON' : 'OFF'}")
    end

    %w{mode fansp vaneud vanelr}.each do |function|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{function}=(value)
          return if limits[:#{function}] && !limits[:#{function}].include?(value.to_s)
          @io.puts("SET,1:#{function.upcase},\#{value}")
        end
      RUBY
    end

    def setptemp=(value)
      value = value.round
      return if limits[:setptemp] && (value < limits[:setptemp].first || value > limits[:setptemp].last)
      @io.puts("SET,1:SETPTEMP,#{value * 10}")
    end
  end
end
