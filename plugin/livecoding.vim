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

" Not sure why rubyfile doesn't work when just given a relative paths
execute "rubyfile " . expand("<sfile>:p:h:h") . "/ruby/livecoding.rb"
