" vim -u での起動時もcompatibleモードにしない
if &compatible
  set nocompatible
endif

"************************************************
" Key Mapping
"************************************************
let mapleader = ","
" ,のデフォルトの機能は、\で使えるように退避
noremap \ ,

" 選択範囲をクリップボードにコピー
vnoremap <C-c> "+y
if !has('gui_running')
  vnoremap <RightMouse> "+y
endif
" クリップボードからペースト
noremap <MiddleMouse> "+p
inoremap <C-v> <C-r><C-o>+

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

" ウィンドウ移動
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" tabnew
nnoremap <silent> <Leader>t :<C-u>tabnew<CR>

" shell
if has('nvim')
  nnoremap <silent> <Leader>s :<C-u>terminal<CR>i
else
  nnoremap <silent> <Leader>s :<C-u>terminal ++rows=8<CR>
endif
tnoremap <silent> <ESC> <C-\><C-n>

"************************************************
" vim-plug
"************************************************
if has('nvim')
  let s:plug_base = stdpath('data') . '/site'
  let s:plug_home = stdpath('data') . '/plugged'
elseif has('win32')
  let s:plug_base = expand('~/vimfiles')
  let s:plug_home = expand('~/vimfiles/plugged')
else
  let s:plug_base = expand('~/.vim')
  let s:plug_home = expand('~/.vim/plugged')
endif
let s:plug_vim = s:plug_base . '/autoload/plug.vim'

" plug.vim がなければ自動ダウンロード
if !filereadable(s:plug_vim)
  execute '!curl -fLo ' . shellescape(s:plug_vim)
    \ . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(s:plug_home)

" 見た目
Plug 'itchyny/lightline.vim'
Plug 'nathanaelkane/vim-indent-guides'

" ファイラ・検索
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" 編集
Plug 'LeafCage/yankround.vim'
Plug 'tpope/vim-surround'
Plug 'tomtom/tcomment_vim'
Plug 'junegunn/vim-easy-align'
Plug 'dhruvasagar/vim-table-mode'
Plug 'thinca/vim-qfreplace'
Plug 'simeji/winresizer'

" コーディング（LSP・補完は coc.nvim に集約）
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'liuchengxu/vista.vim'
Plug 'thinca/vim-quickrun'
Plug 'mattn/emmet-vim'

" Markdown
Plug 'previm/previm'
Plug 'tyru/open-browser.vim'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" IME
if has('win32')
  Plug 'pepo-le/win-ime-con.nvim'
elseif has('unix') && !has('mac')
  Plug 'pepo-le/fcitx-mem-re'
endif

call plug#end()

" editorconfig は同梱パッケージを使用（Neovimは組み込み済み）
if !has('nvim')
  packadd! editorconfig
endif

filetype plugin indent on
syntax on

"************************************************
" Plugin Settings
"************************************************
" lightline
if has('win32') && (!has('gui_running') && !has('nvim'))
  let g:lightline = {'colorscheme': 'one'}
else
  let g:lightline = {'colorscheme': 'default'}
endif
if has('nvim')
  let g:lightline = extend(g:lightline, {'enable': {'statusline': 1, 'tabline': 0}})
endif

" fzf
nnoremap <silent> <Leader>f :<C-u>Files<CR>
nnoremap <silent> <Leader>b :<C-u>Buffers<CR>
nnoremap <silent> <Leader>g :<C-u>Rg<CR>
nnoremap <silent> <Leader>R :<C-u>History<CR>

" NERDTree
nnoremap <silent> <Leader>e :<C-u>NERDTreeToggle<CR>
nnoremap <silent> <Leader>E :<C-u>NERDTreeFind<CR>

" yankround
let g:yankround_dir = expand('~/.local/state/vim/yankround')
call mkdir(g:yankround_dir, 'p', 0700)
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)

" vim-indent-guides
let g:indent_guides_auto_colors = 0
augroup IndentGuidesColor
  autocmd!
  autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#555555 ctermbg=2
  autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#666666 ctermbg=3
augroup END

" tcomment
let g:tcomment_opleader1 = '<Leader>c'

" vim-easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" winresizer
let g:winresizer_vert_resize = 1
let g:winresizer_horiz_resize = 1

" vista
let g:vista_default_executive = 'coc'
let g:vista_sidebar_width = 40
let g:vista_echo_cursor = 0
nnoremap <silent> <Leader>o :<C-u>Vista!!<CR>

" quickrun
nnoremap <Leader>q :QuickRun<CR>
let g:quickrun_config = {
  \ 'python': {
  \   'command': 'python3'
  \ },
\ }

" emmet
let g:user_emmet_leader_key = '<c-e>'
let g:user_emmet_settings = {
\   'html': {
\       'lang': "ja"
\   }
\ }

" previm
augroup PrevimSettings
  autocmd!
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
augroup END

"************************************************
" coc.nvim
"************************************************
let g:coc_global_extensions = [
  \ 'coc-json',
  \ 'coc-tsserver',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-pyright',
  \ 'coc-snippets',
\ ]

" Tabで補完候補を移動、Enterで確定
function! s:check_backspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
inoremap <silent><expr> <TAB>
  \ coc#pum#visible() ? coc#pum#next(1) :
  \ <SID>check_backspace() ? "\<Tab>" :
  \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
  \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" 手動で補完を起動
inoremap <silent><expr> <C-f> coc#refresh()

" コードジャンプ
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)

" 診断ジャンプ
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" リネーム・コードアクション
nmap <Leader>rn <Plug>(coc-rename)
nmap <Leader>ca <Plug>(coc-codeaction-cursor)

" Kでドキュメント表示
function! s:show_documentation() abort
  if index(['vim', 'help'], &filetype) >= 0
    execute 'help ' . expand('<cword>')
  elseif CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
nnoremap <silent> K :call <SID>show_documentation()<CR>

" スニペット展開
imap <C-k> <Plug>(coc-snippets-expand-jump)

"************************************************
" Basic Settings
"************************************************
" swap/backup/undo/viminfo はリポジトリ外の ~/.local/state/vim に保存する
" （Neovimは既定で ~/.local/state/nvim を使うため設定不要）
if !has('nvim')
  let s:state_dir = expand('~/.local/state/vim')
  for s:d in ['swap', 'backup', 'undo']
    call mkdir(s:state_dir . '/' . s:d, 'p', 0700)
  endfor
  let &directory = s:state_dir . '/swap//'
  let &backupdir = s:state_dir . '/backup//'
  let &undodir = s:state_dir . '/undo'
  let &viminfofile = s:state_dir . '/viminfo'
endif
set backup
set undofile

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
set shortmess-=S
nnoremap / /\v
if has('nvim')
  set inccommand=split
endif

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

" Color
if has('unix')
  set termguicolors
  colorscheme desert
else
  colorscheme elflord
endif
augroup HighlightColor
  autocmd!
  autocmd VimEnter,ColorScheme * highlight Search ctermbg=3 ctermfg=8
  autocmd VimEnter,ColorScheme * highlight Pmenu ctermbg=5 ctermfg=255 guibg=DarkMagenta
  autocmd VimEnter,ColorScheme * highlight lCursor ctermbg=7 ctermfg=0
augroup END

" Quickfixを自動で閉じる
augroup QfAutoCommands
  autocmd!
  " Auto-close quickfix window
  autocmd WinEnter * if (winnr('$') == 1) && (getbufvar(winbufnr(0), '&buftype')) == 'quickfix' | quit | endif
augroup END

" Windowsでpythonインターフェイスを有効にする
if has('win32')
  if has('nvim')
    let g:python3_host_prog = $PYTHONHOME . '\python.exe'
  else
    set pythonthreedll=$PYTHONDLL
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
augroup FiletypeGroup
  autocmd!
  autocmd FileType vim setlocal sw=2 sts=2 ts=2 et
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact
    \ setlocal shiftwidth=2 tabstop=2
  autocmd FileType html,css,scss,json,yaml setlocal shiftwidth=2 tabstop=2
  autocmd BufRead,BufNewFile *.ejs setlocal shiftwidth=2 tabstop=2 filetype=ejs.html
  autocmd BufRead,BufNewFile *.ctp setlocal filetype=php
  autocmd FileType go setlocal noexpandtab
augroup END

"************************************************
" Command
"************************************************
" Encoding
:command! Sutf set fenc=utf-8
:command! Scp set fenc=cp932
:command! Seuc set fenc=euc-jp
:command! Suni set ff=unix
:command! Sdos set ff=dos

"************************************************
" Coding
"************************************************
" PHP
" $VIMRUNTIME/syntax/php.vim
let g:php_baselib       = 1
let g:php_htmlInStrings = 1
let g:php_noShortTags   = 1
let g:php_sql_query     = 1
"let g:sql_type_default = 'mysql'

"************************************************
" Local Setting
"************************************************
set runtimepath+=$HOME/.vim/
runtime! localrc/vimrc.vim
