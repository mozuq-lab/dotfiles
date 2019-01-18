colorscheme desert
if has('nvim')
  set viminfo+=n~/.vim/nviminfo
else
  set viminfo+=n~/.vim/viminfo
endif
set lines=44
set columns=150
set cursorline
set mousemodel=popup
set guioptions=egimrLtT

" IMEオンでカーソルの色を変える（Linuxでは不完全）
if has('multi_byte_ime') || has('xim')
  highlight CursorIM guifg=NONE guibg=LightBlue
endif

if has('win32') && ! has('nvim')
  set guifont=MS_Gothic:h11
endif

if has('unix')
  set guifont=Monospace\ 11
endif

"************************************************
" Local Setting
"************************************************
set runtimepath+=$HOME/.vim/
runtime! localrc/gvimrc.vim
