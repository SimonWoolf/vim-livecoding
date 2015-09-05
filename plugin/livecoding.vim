if exists("g:livecoding")
  finish
endif

if !has("ruby")
  echohl ErrorMsg
  echon "Sorry, vim-livecoding requires ruby support, as there is currently no vimscript ably client library"
  finish
endif

let g:loaded_livecoding = "true"

function PublishBuffer()
  command! -buffer StopPublishingThisBuffer call StopPublishingThisBuffer()
  command! -buffer StopAllPublishing call StopAllPublishing()
  autocmd BufUnload * call StopPublishingThisBuffer()
  autocmd InsertLeave * call UpdateIfNeeded()
  :ruby publish_buffer
endfunction

function UpdateIfNeeded()
  :ruby update_if_needed()
endfunction

function StopPublishingThisBuffer()
  :ruby stop_publishing_this_buffer()
endfunction

function StopAllPublishing()
  :ruby stop_all_publishing()
endfunction

command! PublishBuffer call PublishBuffer()

ruby << EOF

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

EOF
