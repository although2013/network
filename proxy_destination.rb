module Destination
  def initialize(server)
    remote = TCPSocket.new(*server)
    remote_port = remote.addr[1]
    remote_host = IPAddr.new(remote.addr[2])

  end







end


class CommunicateConn
  def initialize(server_host, server_port)
    node_name = 'company_pc'
    @server = TCPSocket.new(server_host, server_port)
    # node_type: destination: 5, node_name: length(1) + name(1-255)
    first_msg = [5,node_name.length].pack('CC') + node_name
    @server.write(first_msg)
  end

  def listen()
    loop do
      cmd, conn_id = @server.read(9).unpack('CQ')
      case cmd
      when 10
        
      end
    end
  end



end