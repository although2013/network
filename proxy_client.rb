require 'socket'
require 'ipaddr'
require 'byebug'

CONFIG = {
  nodename: 'home mac',
  listen: '0.0.0.0:1080',
  server: ["40.74.116.240", 443]

  role: {
    destination: {

    },
    origin: {
      to: 
    },
    bridge_server: {
      from: "",
      to: ""
    }
  }
}

server = TCPServer.new 1080 # Server bind to port 1080

def select_support_method(client)
  version, nmethods = client.read(2).unpack('CC')

  supported_methods = []
  nmethods.times {
    supported_methods << client.read(1).ord
  }
  supported_methods.first
end

def exchange_loop(client, remote)
  while true
    readable = IO.select([client, remote])
    if rs = readable[0]
      rs.each do |rc|
        begin
          str = rc.read_nonblock(1024)
        rescue EOFError
          puts "closing"
          remote.close
          client.close
          return
        end
        case rc.fileno
        when client.fileno
          remote.write(str)
        when remote.fileno
          client.write(str)
          # puts "client write #{str.length}"
        else
          p "error"
        end
      end        
    end
  end
end

loop do
  client = server.accept    # Wait for a client to connect
  Thread.new {
    method_int = select_support_method(client)
    client.write([5, method_int].pack('CC'))

    ver, cmd, rsv, atyp = client.read(4).unpack('CCCC')
    puts "cmd: #{cmd}" if cmd != 1
    # cmd connect: 1, bind: 2, udp: 3
    if cmd == 1
      # atype ipv4: 1, domainname: 3, ipv6: 4
      if atyp == 3
        domain_length = client.read(1).ord
        host = client.read(domain_length)
        port = client.read(2).unpack('n')[0]

        remote = TCPSocket.new(host, port)
        remote_port = remote.addr[1]
        remote_host = IPAddr.new(remote.addr[2])
        # VER | REP | RSV | ATYP | BND.ADDR | BND.PORT
        # resp = [5,0,0,4].pack('CCCC') + remote_host.hton + [remote_port].pack('n')
        resp = [5,0,0,3].pack('CCCC') + "#{domain_length.chr}#{host}" + [port].pack('n')

        client.write(resp)

        exchange_loop(client, remote)
      elsif atyp == 1
        remote_host = IPAddr.new(client.read(4).unpack('CCCC').join('.'))
        remote_port = client.read(2).unpack('n')[0]

        remote = TCPSocket.new(remote_host.to_s, remote_port)

        resp = [5,0,0,1, remote_host.to_i, remote_port].pack('CCCCNn')

        client.write(resp)

        exchange_loop(client, remote)
      end
    elsif cmd == 2
    end
  }
  
end