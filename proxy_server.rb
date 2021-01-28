MAX_ID = 18446744073709551616

class BridgeServer
  def initialize
    @server = TCPServer.new("0.0.0.0", 443)
    @data_conns = []
    @dest_conns = []
  end

  def listen_forever
    loop do
      client = @server.accept

      conn_type = client.read(1).ord
      case conn_type
      when 0
        # destination, wait until data
        @dest_conns = [client]
      when 1
        #from origin, need transfer
        conn_id = client.read(8).unpack('Q')[0]
        conn = @data_conns.select { |obj| obj[:id] == conn_id }
        if conn
          # new initialized conn should not existed
          # exception
          raise 'new initialized conn should not existed'
        else
          conn = {
            id: conn_id,
            origin: client,
            dest: nil
          }
          @data_conns << conn

          if @dest_conns.any?
            dest = @dest_conns.first
            dest.write([10, conn_id].pack('CQ'))
          else
            raise 'no destination node connected'
          end
        when 2
          conn_id = client.read(8).unpack('Q')[0]
          conn = @data_conns.select { |obj| obj[:id] == conn_id }

          if conn
            conn[:dest] = client
          else
            raise 'no conn which destnation needed'
          end
        end

      end

    end
  end
  
      # Wait for a client to connect
  Thread.new {

end


