require 'eventmachine'

@child_socket, @parent_socket = Socket.pair(:UNIX, :DGRAM, 0)

def publish_buffer
   VIM::message("Connected to vim-livecoding, publishing buffer...")
   VIM::message("Buffer being published to URL")
end

def update_if_needed()
  # :h if_ruby for help with this stuff
  #buffer_contents = VIM::evaluate "join(getline(1, '$'), '\n')"
  # Diff against previous
  # If a change: push change
  message = begin
    @parent_socket.recv_nonblock(100)
  rescue Errno::EAGAIN, Errno::EWOULDBLOCK
    ""
  end
  VIM::message("update_if_needed called, message: #{message}")
end

def stop_publishing_this_buffer()
   VIM::message("Stopped publishing this buffer")
end

def stop_all_publishing()
   VIM::message("Ceased all publishing and disconnected from vim-livecoding")
end


fork do
  @count = 0
  EventMachine.run do
      EM.add_periodic_timer(1) do
        @child_socket.send @count.to_s, 0
        @count += 1
      end

      EM.add_timer(10) do
          @child_socket.send "I waited 10 seconds", 0
          EM.stop_event_loop
      end
  end
end
