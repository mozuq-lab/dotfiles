colorscheme desert
set viminfo+=n~/.vim/viminfo
set lines=44
set columns=150

" IMEオンでカーソルの色を変える（Linuxでは不完全）
if has('multi_byte_ime') || has('xim')
  highlight CursorIM guifg=NONE guibg=LightBlue
endif

if has('win32')
  set guifont=MS_Gothic:h11
endif
