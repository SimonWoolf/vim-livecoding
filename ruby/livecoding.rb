require 'eventmachine'
require 'diffy'

@child_socket, @parent_socket = Socket.pair(:UNIX, :DGRAM, 0)

def publish_buffer
  VIM::message("Connected to vim-livecoding, publishing buffer...")
  VIM::message("Buffer being published to URL")
  @last_buffer_contents = get_buffer_contents
  @last_compared = Time.now
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
    #message = begin
      #@parent_socket.recv_nonblock(100)
    #rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      #""
    #end
    VIM::message("update_if_needed called, diff is: #{diff.to_s}")
    VIM::Buffer.current.append(1, "OMG")
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


#fork do
  #@count = 0
  #EventMachine.run do
      #EM.add_periodic_timer(1) do
        #@child_socket.send @count.to_s, 0
        #@count += 1
      #end

      #EM.add_timer(10) do
          #@child_socket.send "I waited 10 seconds", 0
          #EM.stop_event_loop
      #end
  #end
#end
require 'pry'
