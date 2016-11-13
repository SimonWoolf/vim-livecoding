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
  autocmd TextChanged,TextChangedI * call UpdateIfNeeded()
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
" :p = absolute path, :h = remove last section from path
"execute "rubyfile " . expand("<sfile>:p:h:h") . "/ruby/livecoding.rb"

"autocmd CursorMoved,CursorMovedI,InsertLeave * call UpdateIfNeeded()
function! Close(channel)
  echon "\nclosed"
  " Read the output from the command into the quickfix window
  "execute "cfile! " . g:backgroundCommandOutput
  " Open the quickfix window
  "copen
  "unlet g:backgroundCommandOutput
endfunction

echohl ErrorMsg
function! Close(channel)
  echon "\nclosed"
endfunction

function! Callback(channel)
  echon "\ncallback"
endfunction

function! Outcb(channel, msg)
  echon " outcb: "
  echon a:msg
endfunction

function! Errcb(channel, msg)
  echon "\nerrcb\n"
  echon a:msg
endfunction

function! Exitcb(job, exit_status)
  echon "\nexitcb\n"
  echon a:exit_status
endfunction

function! Timeout(channel)
  echon "\ntimeout"
endfunction

"call job_start(["ruby", "test.rb"], {'close_cb': 'BackgroundCommandClose', 'out_io': 'file', 'out_name': g:backgroundCommandOutput})
let g:job = job_start(["ruby", expand("<sfile>:p:h:h") . "/ruby/test.rb"], {'close_cb': 'Close', 'out_cb': 'Outcb', 'err_cb': 'Errcb', 'timeout': 'Timeout', 'exit_cb': 'Exitcb'})

function! RunBackgroundCommand(command)
  " Make sure we're running VIM version 8 or higher.
  if v:version < 800
    echoerr 'RunBackgroundCommand requires VIM version 8 or higher'
    return
  endif

  if exists('g:backgroundCommandOutput')
    echo 'Already running task in background'
  else
    echo 'Running task in background'
    " Launch the job.
    " Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
    " will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or?
    let g:backgroundCommandOutput = tempname()
    call job_start([], {'close_cb': 'BackgroundCommandClose', 'out_io': 'file', 'out_name': g:backgroundCommandOutput})
  endif
endfunction
