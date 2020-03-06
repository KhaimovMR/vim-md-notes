
" {{{ FOLDING

nmap <silent> <Leader>mda :call MdArchiveNote('%')<cr>
nmap <silent> <Leader>mdd :call MdDeleteNote('%')<cr>
nmap <silent> <Leader>k :call MdPriorityChange('%', 1, 1, 1)<cr>
nmap <silent> <Leader>j :call MdPriorityChange('%', -1, 1, 1)<cr>


" }}}


" {{{ FOLDING


function! MarkdownCheckListItems()
  redir => markdown_check_replaces
  silent! exec 's/\[ \]/[x]/g'
  redir END
  let l:indentation = ''

  if ( markdown_check_replaces =~ 'Pattern not found')
    silent! exec 's/\[x\]/[ ]/g'
  else
    let l:initial_line_number = line('.')
    if (getline(line('.')) !~ '^\s*- \[x\]')
      return
    endif
    let l:indentation = matchstr(getline(line('.')), '^\s*-')
    let l:indentation = substitute(l:indentation, '-$', '', 'g')

    while (line('.') < line('$'))
      if (getline(line('.') + 1) =~ '^'.l:indentation.'- \[x\]')
        return
      endif

      let l:next_indentation = matchstr(getline(line('.') + 1), '^\s*-')
      let l:next_indentation = substitute(l:next_indentation, '-$', '', 'g')

      if (strlen(l:next_indentation) < strlen(l:indentation))
        return
      endif

      exec "normal! ddp"
      exec "sleep 24m"
    endwhile

    exec "normal! " . l:initial_line_number . "gg"
  endif
endfunction


function! MoveFile(oldspec, newspec)
  let old = expand(a:oldspec)
  let new = expand(a:newspec)

  if (old == new)
    return 0
  endif

  silent! exec ':b ' . old
  exec ':save ' . new
  silent! exec ':bd! ' . old
  silent! call system('rm -f ' . old)
endfunction


function! MdArchiveNote(file)
  let file_name = expand(a:file)
  let result = confirm('Are you sure you want to ARCHIVE the note?', "&Yes\n&No", 1)

  if (result != 1)
    return 0
  endif

  silent! call MoveFile(a:file, 'archive/' . a:file)
  silent! exec ':bd! ' . file_name
  silent! call system('rm -f ' . file_name)
endfunction


function! MdDeleteNote(file)
  let file_name = expand(a:file)
  let result = confirm('Are you sure you want to DELETE the note?', "&Yes\n&No", 1)

  if (result != 1)
    return 0
  endif

  silent! exec ':bd! ' . file_name
  silent! call system('rm -f ' . file_name)
endfunction


function! MdPriorityChange(file, step, current_buffer, swap_priorities)
  let file_name = expand(a:file)
  let separator = '__'

  if (expand('%:p') !~ 'gdrive\/md-notes')
    echo "Not a markdown note file..."
    return 0
  endif

  let file_name_parts = split(file_name, separator)

  if (len(file_name_parts) < 2)
    call insert(file_name_parts, '00', 0)
  endif

  let current_priority = str2nr(file_name_parts[0])
  let new_priority = current_priority + a:step

  if (new_priority < 0)
    echo "Can't change the priority to the negative one"
    return 0
  endif

  let new_priority_fmtd = PrePad(new_priority, 2, '0')
  let new_file_name = new_priority_fmtd . separator . file_name_parts[1]
  let priority_is_busy = systemlist('/bin/ls -1q ' . $PWD . '/' . new_priority_fmtd . '*')
  call MoveFile(file_name, new_file_name)
  let existent_priority_file = substitute(priority_is_busy[0], $PWD . '/' , '', ' g')

  if (priority_is_busy[0] !~ 'No such file or directory')
    if (a:current_buffer == 1 && a:swap_priorities == 1)
      call MdPriorityChange(existent_priority_file, a:step * -1, 0, 1)
    elseif (a:swap_priorities == 0)
      call MdPriorityChange(existent_priority_file, 1, 0, 0)
    endif
  endif

  if (a:current_buffer)
    silent! exec ':b ' . new_file_name
  endif
endfunction


function! Pad(s,amt)
    return a:s . repeat(' ',a:amt - len(a:s))
endfunction


function! PrePad(s,amt,...)
  if a:0 > 0
    let char = a:1
  else
    let char = ' '
  endif

  return repeat(char,a:amt - len(a:s)) . a:s
endfunction


function! MyNewBufferEvent(file)
  if filereadable(expand(a:file))
    return 0
  endif

  call MdPriorityChange(fnamemodify(expand(a:file), ':t'), 0, 1, 0)
  silent! exec ':w ' . a:file
endfunction


" }}}


" {{{ FOLDING


command! -nargs=1 MyNewBufferCmd call MyNewBufferEvent(<f-args>)
autocmd BufNewFile ~/Dropbox/markdown/*/*.md :MyNewBufferCmd %


" }}}
