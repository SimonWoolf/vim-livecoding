# Vim plugin can't assume that people have bundler, or even a system ruby.
# Vendorise gems and do paths manually
script_dir = File.expand_path(File.dirname(__FILE__))
require File.join(script_dir, '/vendor/eventmachine/lib/em/pure_ruby')
#require File.join(script_dir, '/vendor/eventmachine/lib/eventmachine')
require File.join(script_dir, '/vendor/diffy/lib/diffy')
require File.join(script_dir, 'mailbox')
require File.join(script_dir, 'em_ably_handler')


def publish_buffer
  VIM::message("Connected to vim-livecoding, publishing buffer...")
  @last_buffer_contents = get_buffer_contents
  @last_compared = Time.now
  if !@ably_process
    parent_socket, @child_socket = Socket.pair(:UNIX, :DGRAM, 0)
    puts "starting ably process"
    @ably_process = start_ably_process
    @mailbox = Mailbox.new parent_socket
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

  @mailbox.send([:diff, [buffer_id, diff.to_s]]) unless diff.none?

  while message = @mailbox.receive
    process_message(*message)
    #VIM::message("reply: #{message.split("\n").join("LF")}, diff was: #{diff.to_s.split("\n").join("LF")}")
  end
end

def process_message(action, data)
  case action
  when :message
    VIM::message("reply: #{data}")
    nil
  when :error
    VIM::message("ERROR: #{data.inspect}. Publishing has stopped, process closed")
  end
end

def stop_publishing_this_buffer()
end

def stop_all_publishing()
  @mailbox.send [:close, nil]
  VIM::message("Ceased all publishing and disconnected from vim-livecoding")
end

def get_buffer_contents()
  VIM::evaluate "join(getline(1, '$'), '\n')"
end

def buffer_id()
  VIM::Buffer.current.number
end

def start_ably_process()
  fork do
    # Inside this process @last_buffer_contents is the state of the buffer at the time the process was forked,
    # @parent_socket is the server end of the socket
    EventMachine.run do
      EventMachine::handle_existing_unix_socket(@child_socket, EmAblyHandler)
    end
    # clean up after eventloop stops.  this also lets the main process know
    # something's wrong, it'll get an EPIPE if it tries to write to the socket
    @child_socket.close
  end
end

# Uncomment to test out in pry

#module VIM
  #def self.message(msg)
    #puts msg
  #end
  #def self.evaluate(code)
    #rand(36**8).to_s(36)
  #end
#end
#require 'pry'
#binding.pry
