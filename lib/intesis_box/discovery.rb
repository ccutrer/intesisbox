require 'socket'

module IntesisBox
  class Discovery
    class << self
      def discover(timeout = 5, exhaustive = false)
        socket = UDPSocket.new
        socket.bind("0.0.0.0", 0)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
        socket.sendmsg("DISCOVER", 0, Socket.sockaddr_in(3310, '255.255.255.255'))
        wmps = {}
        puts "updated3"
        loop do
          if IO.select([socket], nil, nil, timeout)
            msg, ip = socket.recvfrom(128)
            puts "got #{msg}"
            ip = ip[2]

            name, mac = msg.split(",")
            name.strip!
            break unless exhaustive
          else
            break
          end
        end
        wmps
      end
    end
  end
end
