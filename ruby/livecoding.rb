# Vim plugin can't assume that people have bundler, or even a system ruby.
# Vendorise gems and do paths manually
script_dir = File.expand_path(File.dirname(__FILE__))
require File.join(script_dir, '/vendor/eventmachine/lib/eventmachine')
require File.join(script_dir, '/vendor/diffy/lib/diffy')

#@child_socket, @parent_socket = Socket.pair(:UNIX, :DGRAM, 0)
@socket = UNIXServer.new("/tmp/vim-livecoding-#{rand(36**8).to_s(36)}")

def publish_buffer
  VIM::message("Connected to vim-livecoding, publishing buffer...")
  @last_buffer_contents = get_buffer_contents
  @last_compared = Time.now
  if !@ably_process
    puts "starting ably process"
    @ably_process = start_ably_process
  end
  @socket = @socket.accept
  VIM::message("Buffer being published to URL")
end

def update_if_needed()
  # Don't update more than once every 0.3s for performance reasons
  time = Time.now
  if time - @last_compared < 0.3
    return
  end
  @last_compared = time

  buffer_contents = get_buffer_contents
  diff = Diffy::Diff.new(@last_buffer_contents, buffer_contents)
  @last_buffer_contents = buffer_contents

  if diff.none?
    VIM::message("update_if_needed called, but buffer unchanged (is: #{@last_buffer_contents})")
    return
  else
    @socket.send diff.to_s.split.first, 0
    reply = begin
      @socket.recv_nonblock(100)
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      ""
    end
    VIM::message("update_if_needed called, reply is: #{reply}, diff is: #{diff.to_s}")
  end
end

def stop_publishing_this_buffer()
   VIM::message("Stopped publishing this buffer")
end

def stop_all_publishing()
   VIM::message("Ceased all publishing and disconnected from vim-livecoding")
end

def get_buffer_contents()
  VIM::evaluate "join(getline(1, '$'), '\n')"
end

def start_ably_process()
  fork do
    # Inside this process @last_buffer_contents is the state of the buffer at the time the process was forked,
    # @socket is the server end of the socket
    EventMachine.run do
      EventMachine::connect_unix_domain(@socket.path, ClientHandler)
    end
  end
end

module ClientHandler
  def post_init
    send_data "initialized"
  end

  def receive_data(data)
    send_data("received: #{data}")
  end

  def unbind
    EM.stop
  end
end
