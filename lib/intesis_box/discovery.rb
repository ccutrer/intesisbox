require 'socket'

module IntesisBox
  class Discovery
    class << self
      def discover(timeout: 1, expected_count: nil, expect: nil)
        wmps = {}
        discovery = new(timeout: timeout) do |wmp|
          wmps[wmp[:mac]] = wmp
          next false if wmps.length == expected_count
          next false if expect && wmp[:mac] == expect
          true
        end
        wmps
      ensure
        discovery&.close
      end
    end

    def initialize(timeout: nil)
      @socket = UDPSocket.new
      @socket.bind("0.0.0.0", 3310)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      @found = []

      receive_lambda = -> do
        loop do
          if IO.select([@socket], nil, nil, timeout)
            @socket.wait_readable
            msg, _ = @socket.recvfrom(128)
            next unless msg.start_with?("DISCOVER:")
            msg = msg[9..-1]

            model, mac, ip, protocol, version, rssi, name, _, _ = msg.split(",")
            wmp = { mac: mac, model: model, ip: ip, protocol: protocol, version: version, rssi: rssi, name: name }
            if block_given?
              break unless yield wmp
            else
              @found << wmp
            end
          else
            break
          end
        end
      end

      if timeout
        discover
        receive_lambda.call
      else
        @receive_thread = Thread.new(&receive_lambda)
      end
    end

    def close
      @receive_thread&.kill
      @socket.close
    end

    def discover
      @socket.sendmsg("DISCOVER\r\n", 0, Socket.sockaddr_in(3310, '255.255.255.255'))
    end

    def pending_discoveries
      result, @found = @found, []
      result
    end
  end
end
