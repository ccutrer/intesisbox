# frozen_string_literal: true

require "socket"

module IntesisBox
  class Client
    attr_reader :ip, :model, :mac, :version, :rssi, :limits, :devicename, :onoff, :mode, :fansp, :vaneud, :vanelr,
                :setptemp, :ambtemp, :errstatus, :errcode

    def initialize(ip, port = 3310)
      @limits = {}
      @ip = ip
      @io = TCPSocket.new(ip, port)

      puts("LIMITS:*")
      poll(0.25)
      puts("CFG:DEVICENAME")
      poll(0.25)
      puts("GET,1:*")
      # keep consuming messages while they're still coming
      loop while poll(0.5)
      # this is purposely last, since mac is what we check for it being ready
      puts("ID")
      poll(0.25)
    end

    TEMP_ATTRS = %w[SETPTEMP AMBTEMP].freeze
    private_constant :TEMP_ATTRS

    def poll(timeout = 30)
      return false if @io.wait_readable(timeout).nil?

      loop do
        line = @io.readline.strip
        IntesisBox.logger&.debug("Read #{line.inspect} from #{mac || ip}")
        cmd, args = line.split(":", 2)
        case cmd
        when "ID"
          @model, @mac, _ip, _protocol, @version, @rssi = args.split(",")
        when "LIMITS"
          function, limits = args.split(",", 2)
          limits = limits[1...-1].split(",")
          next if function == "ONOFF"

          limits.map! { |l| l.to_f / 10 } if TEMP_ATTRS.include?(function)
          @limits[function.downcase.to_sym] = limits
        when "CHN,1"
          function, value = args.split(",")
          value = value == "ON" if function == "ONOFF"
          value = nil if value == "-32768"
          value = value.to_f / 10 if value && TEMP_ATTRS.include?(function)
          value = value.to_i if function == "ERRCODE"
          instance_variable_set(:"@#{function.downcase}", value)
        when "CFG"
          function, value = args.split(",", 2)
          @devicename = value if function == "DEVICENAME"
        when "PONG"
          @rssi = args.to_i
        end
        break unless @io.ready?
      end
      true
    end

    def ping
      puts("PING")
    end

    def onoff=(value)
      puts("SET,1:ONOFF,#{value ? "ON" : "OFF"}")
    end

    %w[mode fansp vaneud vanelr].each do |function|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{function}=(value)
          return if limits[:#{function}] && !limits[:#{function}].include?(value.to_s)
          puts("SET,1:#{function.upcase},\#{value}")
        end
      RUBY
    end

    def setptemp=(value)
      value = value.round
      return if limits[:setptemp] && (value < limits[:setptemp].first || value > limits[:setptemp].last)

      puts("SET,1:SETPTEMP,#{value * 10}")
    end

    def devicename=(value)
      puts("CFG:DEVICENAME,#{value}")
      # have to re-query to ensure it got the new value
      puts("CFG:DEVICENAME")
    end

    private

    def puts(line)
      IntesisBox.logger&.debug("Writing #{line.inspect} to #{mac || ip}")
      @io.puts(line)
    end
  end
end
