require 'socket'
require 'byebug'

server = UDPSocket.new
server.bind('0.0.0.0', 8080)

nodes = []

loop do
  IO.select([server])
  msg, addr = server.recvfrom_nonblock(10)
  p msg, addr
  client_addr = [addr[3], addr[1]]
  nodes << client_addr
  peer_addr = nodes.reject { |addr| addr == client_addr }.first
  if peer_addr
    server.send "#{peer_addr[0]}:#{peer_addr[1]}", 0, *client_addr
  else
    server.send '\x00', 0, *client_addr
  end
end



# client = server.accept
# puts "accept! #{p client.peeraddr}"
# sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
# nodes << { host: remote_ip, port: remote_port, conn: client }

# Thread.new {
#   command = client.gets
#   if command.strip == 'connect'
#     nodes.each do |node|
#       p node
#       node[:conn].write([1, 1, IPAddr.new(node[:host]).to_i, node[:port]].pack('CCNn'))
#     end
#   end
# }