# Vim plugin can't assume that people have bundler, or even a system ruby.
# Vendorise gems and do paths manually
script_dir = File.expand_path(File.dirname(__FILE__))
require File.join(script_dir, '/vendor/eventmachine/lib/em/pure_ruby')
#require File.join(script_dir, '/vendor/eventmachine/lib/eventmachine')
require File.join(script_dir, '/vendor/diffy/lib/diffy')
require File.join(script_dir, 'mailbox')
require File.join(script_dir, 'em_ably_handler')

def publish_buffer
  ensure_healthy_ably_process_running

  if(bp = current_buffer_publisher)
    # get a clean slate
    bp.stop_publishing
  end

  @publishers[buffer_id] = BufferPublisher.new(@mailbox)
end

def update_if_needed
  receive_messages
  current_buffer_publisher.update_if_needed
end

def ensure_healthy_ably_process_running
  if !@ably_process
    VIM::message "Starting ably process"
    start_ably_process
  elsif @mailbox.defunct?
    VIM::message "Mailbox status was defunct, restarting ably process (was pid ##{@ably_process})"
    # Process probably already exited and closed the socket after the event
    # loop finished. If not, force it to
    # TODO: dispose of publishers
    Process.kill :TERM, @ably_process
    start_ably_process
  end
end

def start_ably_process
  parent_socket, @child_socket = Socket.pair(:UNIX, :DGRAM, 0)
  @ably_process = fork_em_process;
  @mailbox = Mailbox.new parent_socket
  @publishers = {}
end

def fork_em_process
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

def buffer_id
  VIM::Buffer.current.number
end

def current_buffer_publisher
  @publishers[buffer_id]
end

def receive_messages
  while message = @mailbox.receive
    process_message(*message)
  end
end

def stop_publishing_this_buffer
  current_buffer_publisher.stop
end

def stop_all_publishing
  mailbox.sendmsg [:close, nil]
end

# currently all messages are global rather than buffer-specific.
# if buffer-specific, dispatch to the right bufferPublisher
def process_message(action, data)
  case action
  when :message
    #VIM::message("reply: #{message.split("\n").join("LF")}, diff was: #{diff.to_s.split("\n").join("LF")}")
    VIM::message("reply: #{data}")
  when :error
    VIM::message("ERROR: #{data.inspect}. Publishing has stopped, process closed")
  end
end


# one livecoder
class BufferPublisher
  attr_reader :mailbox

  def initialize(mailbox)
    VIM::message("publishing buffer...")
    @mailbox = mailbox
    @last_buffer_contents = get_buffer_contents
    @last_compared = Time.now
    # TODO write to file and send that as initial?
    VIM::message("Buffer being published to URL")
    self
  end

  def update_if_needed
    # Don't update more than once every 0.1s for performance reasons
    time = Time.now
    if time - @last_compared < 0.1
      return
    end
    @last_compared = time

    buffer_contents = get_buffer_contents
    diff = Diffy::Diff.new(@last_buffer_contents, buffer_contents, {diff: '-e'})
    @last_buffer_contents = buffer_contents

    mailbox.sendmsg([:diff, [buffer_id, diff.to_s]]) unless diff.none?
  end

  def stop
  end

  def get_buffer_contents
    VIM::evaluate "join(getline(1, '$'), '\n')"
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
