require 'eventmachine'
require 'diffy'

@child_socket, @parent_socket = Socket.pair(:UNIX, :DGRAM, 0)

def publish_buffer
  VIM::message("Connected to vim-livecoding, publishing buffer...")
  VIM::message("Buffer being published to URL")
  @last_buffer_contents = get_buffer_contents
  @last_compared = Time.now
  if !@ably_process
    puts "starting ably process"
    @ably_process = start_ably_process
  end
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
    message = begin
      @parent_socket.recv_nonblock(100)
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      ""
    end
    VIM::message("update_if_needed called, message is: #{message}, diff is: #{diff.to_s}")
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
    # Inside this process @last_buffer_contents is the state of the buffer at the time the process was forked
    EventMachine.run do
      EM.add_periodic_timer(1) do
        #@count += 1
        @child_socket.send "last buffer contents: " + @last_buffer_contents.inspect, 0
      end

      EM.add_timer(10) do
        @child_socket.send "I waited 10 seconds", 0
        EM.stop_event_loop
      end
    end
  end
end

require 'pry'
