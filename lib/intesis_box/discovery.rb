require 'socket'

module IntesisBox
  class Discovery
    class << self
      def discover(timeout: 1, expected_count: nil)
        socket = UDPSocket.new
        socket.bind("0.0.0.0", 3310)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
        socket.sendmsg("DISCOVER\r\n", 0, Socket.sockaddr_in(3310, '255.255.255.255'))
        wmps = {}
        loop do
          if IO.select([socket], nil, nil, timeout)
            msg, _ = socket.recvfrom(128)
            next unless msg.start_with?("DISCOVER:")
            msg = msg[9..-1]

            model, mac, ip, protocol, version, rssi, name, _, _ = msg.split(",")
            wmps[mac] = { model: model, ip: ip, protocol: protocol, version: version, rssi: rssi, name: name }
            break if wmps.length == expected_count
          else
            break
          end
        end
        wmps
      ensure
        socket.close
      end
    end
  end
end
