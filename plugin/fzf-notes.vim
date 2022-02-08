" Copyright (c) 2022 Elijah Danko
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

if exists('g:loaded_fzf_notes')
  finish
endif
let g:loaded_fzf_notes = 1

let s:cpo_save = &cpo
set cpo&vim

if len($FZF_NOTES_DIR) == 0
  echom "FZF_NOTES_DIR env is required."
  finish
endif

function s:sys_copy_cmd() abort
  if len($FZF_NOTES_COPY_COMMAND) > 0
    return $FZF_NOTES_COPY_COMMAND
  endif
  if has("win32") || !has("unix")
    echom "The operation system is not supported."
    return "<undefind>"
  endif
  if system("uname") =~ "Darwin"
    echom "The operation system is not supported."
    return "<undefind>"
  endif
  if $XDG_SESSION_TYPE =~ "wayland"
    return "wl-copy"
  endif
  return "xclip -selection c"
endfunction

let s:collection_bin = len($FZF_COLLECTION_BIN) ? $FZF_COLLECTION_BIN : $HOME . "/.bin/fzf-notes-bin"
if empty(glob(s:collection_bin))
  echom "fzf-notes-bin is not found"
  finish
endif
let s:copy_cmd = <SID>sys_copy_cmd()
if s:copy_cmd == "<undefind>"
  echom "undetected clipboard engine"
  finish
endif
let s:copy_key = len($FZF_NOTES_COPY_KEY) ? $FZF_NOTES_COPY_KEY : "alt-w"
let s:new_note_key = len($FZF_NOTES_NEW_NOTE_KEY) ? $FZF_NOTES_NEW_NOTE_KEY : "ctrl-o"
let s:preview_window = len($FZF_NOTES_PREVIEW_WINDOW) ? $FZF_NOTES_PREVIEW_WINDOW : "nohidden"
let s:rg_cmd = len($FZF_NOTES_RG_COMMAND) ? $FZF_NOTES_RG_COMMAND :
      \ "rg --no-column --line-number --no-heading --color=always --smart-case -- '\\S'"

let s:preview_cmd = s:collection_bin . " -np " . $FZF_NOTES_DIR . " {1} {2} 40"

command! -nargs=* -bang FzfNotes call fzf#run(
      \ fzf#wrap({"sink*": function("<SID>handler"),
      \ "source": join([s:rg_cmd, " ", $FZF_NOTES_DIR, ' | ', s:collection_bin, " -ns ", $FZF_NOTES_DIR]),
      \ "options": [
        \ "--print-query",
        \ "--ansi",
        \ "--delimiter=:",
        \ "--multi",
        \ "--query=" . <q-args>,
        \ "--expect=" . s:new_note_key,
        \ "--bind=". s:copy_key . ":execute-silent(echo {3..} | " . s:copy_cmd . ")",
        \ "--header=" . s:copy_key . ":copy, " . s:new_note_key . ":new",
        \ "--preview=" . s:preview_cmd,
        \ "--preview-window=" . s:preview_window,
        \ ] }, <bang>0)
      \ )

function s:handler(lines) abort
  if a:lines[1] == s:new_note_key
    call s:new_entry(a:lines[0])
    return
  endif
  call s:jump(a:lines[2])
endfunction

function s:new_entry(file) abort
  let path = $FZF_NOTES_DIR . "/" . a:file
  call mkdir(fnamemodify(path, ":h"), "p", 0700)
  exec "edit " . path
endfunction

function s:jump(fileinfo) abort
  let parties = split(a:fileinfo, ":")
  let linenum = "+" . parties[1]
  let name = $FZF_NOTES_DIR . "/" . parties[0]
  exec "edit " . linenum . " " . name
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
