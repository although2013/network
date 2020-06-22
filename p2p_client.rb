require 'socket'

discover_node = ['40.74.116.240', 8080]
# discover_node = ['127.0.0.1', 8080]

socket = TCPSocket.new(*discover_node)

Thread.new {
  while true
    readable = IO.select([socket])

    if rs = readable[0]
      rs.each do |rc|
        begin
          str = rc.read_nonblock(1024)
        rescue EOFError
          socket.close
          break
        end
        cmd, atype, remote_host, remote_port = str.unpack('CCNn')
        next if cmd != 1

        punch = UDPSocket.new
        punch.bind('', 8888)
        punch.send('', 0, remote_host, remote_port)
        punch.close

        udp_in = UDPSocket.new
        udp_in.bind('0.0.0.0', 8888)
        puts "Binding to local port 6311"

        loop do
          # Receive data or time out after 5 seconds
          if IO.select([udp_in], nil, nil, rand(4))
            data = udp_in.recvfrom(1024)
            receive_remote_port = data[1][1]
            receive_remote_host = data[1][3]
            puts "Response from #{receive_remote_host}:#{receive_remote_port} is #{data[0]}"
          else
            puts "Sending a little something.. #{Time.now} #{`uname -a`}"
            udp_in.send(Time.now.to_s, 0, remote_host, remote_port)
          end
        end

      end
    end
  end

}


while cmd = STDIN.gets()
  if cmd.strip == 'start'
    puts "start connect"
    socket.write("connect\n")
  end
end

# socket.close