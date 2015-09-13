# Vim plugin can't assume that people have bundler, or even a system ruby.
# Vendorise gems and do paths manually
script_dir = File.expand_path(File.dirname(__FILE__))
require File.join(script_dir, '/vendor/eventmachine/lib/em/pure_ruby')
#require File.join(script_dir, '/vendor/eventmachine/lib/eventmachine')
require File.join(script_dir, '/vendor/diffy/lib/diffy')

@socket, @em_socket = Socket.pair(:UNIX, :DGRAM, 0)

def publish_buffer
  VIM::message("Connected to vim-livecoding, publishing buffer...")
  @last_buffer_contents = get_buffer_contents
  @last_compared = Time.now
  if !@ably_process
    puts "starting ably process"
    @ably_process = start_ably_process
  end
  VIM::message("Buffer being published to URL")
end

def update_if_needed()
  # Don't update more than once every 0.1s for performance reasons
  time = Time.now
  if time - @last_compared < 0.1
    return
  end
  @last_compared = time

  buffer_contents = get_buffer_contents
  diff = Diffy::Diff.new(@last_buffer_contents, buffer_contents, {diff: '-e'})
  @last_buffer_contents = buffer_contents

  # Streaming sockets don't guarantee messages won't be lumped together
  #@socket.send(diff.to_s + "\0", 0) unless diff.none?
  sent = @socket.send("a" * 5 + "\0", 0) #unless diff.none?
  sent = @socket.send("a" * 5 + "\0", 0) #unless diff.none?
  sent = @socket.send("a" * 5 + "\0", 0) #unless diff.none?
  sent = @socket.send("a" * 5 + "\0", 0) #unless diff.none?

  # TODO: read from socket till no more messages
  reply = begin
            @socket.recv_nonblock(1000000)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            ""
          end
  messageQueue = reply#.split("\0")
  VIM::message("sent #{sent}, reply: #{messageQueue.inspect}")##{reply.split("\n").join("LF")}, diff is: #{diff.to_s.split("\n").join("LF")}")
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
      EventMachine::handle_existing_unix_socket(@em_socket, ClientHandler)
    end
  end
end

module ClientHandler
  def post_init
    send_data "initialized\0"
  end

  def receive_data(data)
    puts "received #{data}"
    messageQueue = data.split("\0")
    #message = messageQueue.pop
    #send_data "received #{messageQueue.map(&:length)} msg lengths\0"
    send_data "received #{messageQueue.inspect}"
  end

  def unbind
    EM.stop
  end
end

# Uncomment to test out in pry
#class VIM
  #def self.message(msg)
    #puts msg
  #end
  #def self.evaluate(str)
  #end
#end
#require 'pry'
#binding.pry
