def publish_buffer
   VIM::message("Connected to vim-livecoding, publishing buffer...")
   VIM::message("Buffer being published to URL")
end

def update_if_needed()
  # :h if_ruby for help with this stuff
  buffer_contents = VIM::evaluate "join(getline(1, '$'), '\n')"
  # Diff against previous
  # If a change: push change
  VIM::message("update_if_needed called")
end

def stop_publishing_this_buffer()
   VIM::message("Stopped publishing this buffer")
end

def stop_all_publishing()
   VIM::message("Ceased all publishing and disconnected from vim-livecoding")
end
