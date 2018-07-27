"************************************************
" Key Mapping
"************************************************
let mapleader = ","
" ,のデフォルトの機能は、\で使えるように退避
noremap \ ,

" 選択範囲をクリップボードにコピー
vnoremap <C-c> "+y
if has('!gui_running')
  vnoremap <RightMouse> "+y
endif
" クリップボードからペースト
noremap <MiddleMouse> "+p
inoremap <C-v> <C-r>+

" 矢印キーでは表示行単位で行移動する
nnoremap <UP> gk
nnoremap <DOWN> gj
vnoremap <UP> gk
vnoremap <DOWN> gj

" 検索ハイライトをESC2度押しで消す
nnoremap <ESC><ESC> :nohlsearch<CR>

" インデントを連続で変更
vnoremap < <gv
vnoremap > >gv

" タブ移動
nnoremap <C-LEFT> gT
nnoremap <C-RIGHT> gt

" PasteMode
set pastetoggle=<F9>
" PasteModeを自動で抜ける
autocmd InsertLeave * set nopaste

" tabnew
nnoremap <silent> <Leader>t :<C-u>tabnew<CR>

" shell
nnoremap <silent> <Leader>s :<C-u>terminal ++close ++rows=8<CR>
tnoremap <silent> <ESC> <C-\><C-n>

"************************************************
" dain
"************************************************
filetype off                   " Required!

" dein dir
let s:dein_dir = expand('~/.vim/dein')
" dein.vim
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" clone dein
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . s:dein_repo_dir
endif

if dein#load_state(s:dein_dir)
  call dein#begin(expand('~/.vim/dein'))
  call dein#add('Shougo/dein.vim')
  "" -------------------------------
  call dein#load_toml(expand('~/.vim') . '/dein.toml')
  "" -------------------------------
  call dein#end()
endif

if dein#check_install()
  call dein#install()
endif

filetype plugin indent on     " Required!
syntax on

"************************************************
" Basic Settings
"************************************************
set directory=$HOME/.vim/swap
set backupdir=$HOME/.vim/backup
set undodir=$HOME/.vim/undo
if has('nvim')
  set viminfo+=n~/.vim/nviminfo
else
  set viminfo+=n~/.vim/viminfo
endif

" Encoding
set encoding=utf-8
set fileencodings=utf-8,sjis,euc-jp,iso-2022-jp
set fileformats=unix,dos,mac
"set noeol nofixeol
scriptencoding utf-8

" Tab
set expandtab
set tabstop=4
set softtabstop=0
set shiftwidth=4

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase
set imsearch=0
nnoremap / /\v

" Tab & Trailing Space
set list
set listchars=tab:^\ ,trail:_,extends:>,precedes:<

" 全角スペースをハイライト
highlight IdeographicSpace term=underline ctermbg=DarkGreen guibg=DarkGreen
augroup highlightIdegraphicSpace
  autocmd!
  autocmd Colorscheme * highlight IdeographicSpace term=underline ctermbg=DarkGreen guibg=DarkGreen
  autocmd VimEnter,WinEnter * match IdeographicSpace /　/
augroup END

" StatusLine
set laststatus=2

" Mouse
set mouse=a

" マッピング待ちとキーコード待ちの時間
set timeout timeoutlen=3000 ttimeoutlen=100

" IME
set iminsert=0
if has('multi_byte_ime') || has('xim')
  " 挿入モードのIME状態を記憶しないようにする
  "inoremap <silent> <ESC> <ESC>:set iminsert=0<CR>
endif

" Color
colorscheme elflord
set t_Co=256
highlight Search ctermbg=3 ctermfg=255
highlight Pmenu ctermbg=5 ctermfg=255
highlight lCursor ctermbg=7 ctermfg=0

" Windowsでpythonインターフェイスを有効にする
if has('win32')
  if has('nvim')
    let g:python3_host_prog = 'python.exe'
  else
    set runtimepath+=$VIM
    set pythonthreedll=$VIM/python3/python35.dll
  endif
endif

" Others
set number
set scrolloff=10
set whichwrap=b,s,<,>,[,],~
set ambiwidth=double
set backspace=2 "indent,eol,start
set clipboard=

"************************************************
" FileType
"************************************************
autocmd BufRead,BufNewFile *.js setlocal shiftwidth=2 tabstop=2
autocmd BufRead,BufNewFile *.jsx setlocal shiftwidth=2 tabstop=2
autocmd BufRead,BufNewFile *.ts setlocal shiftwidth=2 tabstop=2
autocmd BufRead,BufNewFile *.tsx setlocal shiftwidth=2 tabstop=2
autocmd BufRead,BufNewFile *.ejs setlocal filetype=ejs
autocmd BufRead,BufNewFile *.ctp setlocal filetype=php
autocmd BufRead,BufNewFile *.go setlocal filetype=go noexpandtab

"************************************************
" Command
"************************************************
" Encoding
:command Sutf set fenc=utf-8
:command Scp set fenc=cp932
:command Seuc set fenc=euc-jp
:command Suni set ff=unix
:command Sdos set ff=dos

"************************************************
" Local Setting
"************************************************
set runtimepath+=$HOME/.vim/
runtime! localrc/vimrc.vim
