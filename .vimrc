"************************************************
" Basic Settings
"************************************************
set directory=$HOME/.vim/swap
set backupdir=$HOME/.vim/backup
set undodir=$HOME/.vim/undo
set viminfo+=n~/.vim/viminfo

" Encoding
set encoding=utf-8
"set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
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

" Windowsでpythonインターフェイスを有効にする
if has('win32')
  set runtimepath+=$VIM
  set pythonthreedll=$VIM/python3/python35.dll
endif

" Other
set number
set scrolloff=10
set whichwrap=b,s,<,>,[,],~
set ambiwidth=double
set backspace=2 "indent,eol,start



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
  "execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
  execute 'set runtimepath^=' . s:dein_repo_dir
endif

call dein#begin(expand('~/.vim/dein'))
"" -------------------------------
call dein#add('Shougo/dein.vim')

call dein#add('Shougo/vimproc.vim', {'build' : 'make'})
call dein#add('Shougo/unite.vim')
call dein#add('Shougo/neomru.vim')
call dein#add('Shougo/vimfiler')
call dein#add('Shougo/vimshell.vim')
call dein#add('itchyny/lightline.vim')
call dein#add('LeafCage/yankround.vim')
call dein#add('nathanaelkane/vim-indent-guides')
call dein#add('pepo-le/fcitx-mem')

" Session
call dein#add('xolox/vim-misc')
call dein#add('xolox/vim-session')

" Coding
call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neosnippet')
call dein#add('Shougo/neosnippet-snippets')
call dein#add('tpope/vim-surround')
call dein#add('tomtom/tcomment_vim')
call dein#add('junegunn/vim-easy-align')
call dein#add('mattn/emmet-vim')
call dein#add('majutsushi/tagbar')
call dein#add('kana/vim-smartchr')
call dein#add('sgur/vim-editorconfig')

" Markdown
call dein#add('kannokanno/previm')
call dein#add('tyru/open-browser.vim')

" Syntax
call dein#add('scrooloose/syntastic')
call dein#add('othree/html5.vim')
call dein#add('nikvdp/ejs-syntax')
call dein#add('hail2u/vim-css3-syntax')
call dein#add('othree/yajs.vim')
call dein#add('vim-scripts/jQuery')

" Git
call dein#add('tpope/vim-fugitive')
call dein#add('airblade/vim-gitgutter')
"" -------------------------------
call dein#end()

if dein#check_install()
  call dein#install()
endif

filetype plugin indent on     " Required!
syntax on



"************************************************
" FileType
"************************************************
autocmd BufRead,BufNewFile *.ejs setlocal filetype=ejs



"************************************************
" Command
"************************************************
" Encoding -------------------------
:command Sutf set fenc=utf-8
:command Scp set fenc=cp932
:command Seuc set fenc=euc-jp
:command Suni set ff=unix
:command Sdos set ff=dos



"************************************************
" Mapping & Plugin
"************************************************
let mapleader = ","
" ,のデフォルトの機能は、\で使えるように退避
noremap \ ,

" 選択範囲をクリップボードにコピー
vnoremap <C-c> "+y"*y
vnoremap <RightMouse> "+y"*y

" 矢印キーでは表示行単位で行移動する
nnoremap <UP> gk
nnoremap <DOWN> gj
vnoremap <UP> gk
vnoremap <DOWN> gj

" PasteMode
set pastetoggle=<F9>
" PasteModeを自動で抜ける
autocmd InsertLeave * set nopaste

" tabnew
nnoremap <silent> <Leader>t :<C-u>tabnew<CR>

" vim-smartchr
inoremap <buffer><expr> < smartchr#one_of('<', ' < ')
inoremap <buffer><expr> > search('< \%#', 'bcn')? '<bs>> ': smartchr#one_of('>', ' > ')
inoremap <buffer><expr> + smartchr#one_of('+', '++', ' + ')
inoremap <buffer><expr> - smartchr#one_of('-', '--', ' - ')
inoremap <buffer><expr> * smartchr#one_of('*', '**', ' * ')
inoremap <buffer><expr> / smartchr#one_of('/', '// ', ' / ')
inoremap <buffer><expr> & smartchr#one_of('&', ' && ', ' & ')
inoremap <buffer><expr> % smartchr#one_of('%', ' % ')
inoremap <buffer><expr> <Bar> smartchr#one_of('<Bar>', ' <Bar><Bar> ', ' <Bar> ')
" =の場合、単純な代入や比較演算子として入力する場合は前後にスペースをいれる。
" 複合演算代入としての入力の場合は、直前のスペースを削除して=を入力
inoremap <buffer><expr> = search('\(&\<bar><bar>\<bar>+\<bar>-\<bar>*\<bar>/\<bar>>\<bar><\) \%#', 'bcn')? '<bs>= '
                            \ : search('!\%#', 'bcn')? '= '
                            \ : smartchr#one_of('=', ' = ', ' == ',' === ')
inoremap <buffer><expr> , smartchr#one_of(',', ', ')
inoremap <buffer><expr> ? smartchr#one_of('?', '? ')
inoremap <buffer><expr> : smartchr#one_of(':', '::', ': ')
inoremap <buffer><expr> ( smartchr#one_of('(', '()<LEFT>')
inoremap <buffer><expr> ) smartchr#one_of(')', '()', '();<LEFT><LEFT>')
inoremap <buffer><expr> [ smartchr#one_of('[', '[]<LEFT>')
inoremap <buffer><expr> { smartchr#one_of('{', '{}<LEFT>')
inoremap <buffer><expr> " smartchr#one_of('"', '""<LEFT>')
inoremap <buffer><expr> ' smartchr#one_of("'", "''<LEFT>")
inoremap <buffer><expr> . smartchr#loop('.', '->', '=>', '...')

" Unite
nnoremap <silent> <Leader>, :<C-u>Unite<CR>
nnoremap <silent> <Leader>B :<C-u>Unite buffer<CR>
nnoremap <silent> <Leader>o :<C-u>Unite bookmark<CR>
nnoremap <silent> <Leader>r :<C-u>Unite -buffer-name=register register<CR>
nnoremap <silent> <Leader>f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap <silent> <Leader>m :<C-u>Unite file_mru buffer<CR>
nnoremap <silent> <Leader>g :<C-u>Unite grep<CR>
" depend yankround,,
nnoremap <silent> <Leader>y :<C-u>Unite yankround<CR>
let g:unite_enable_start_insert=1
let g:unite_source_history_yank_enable =1
let g:unite_source_file_mru_limit = 100

" VimFiler
nnoremap <silent> <Leader>v :<C-u>VimFilerBufferDir<CR>
nnoremap <silent> <Leader>V :<C-u>tabnew<CR>:<C-u>VimFiler<CR>
nnoremap <silent> <Leader>b :<C-u>VimFiler bookmark:<CR>

" VimShell
nnoremap <silent> <Leader>; :<C-u>VimShell<CR>

" yankround
let g:yankround_dir=$HOME . '/.vim/yankround'
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)

" vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)"

" tagbar
nmap <F8> :TagbarToggle<CR>

" syntastic
let g:syntastic_mode_map = { 'mode': 'passive',
  \ 'active_filetypes': [''],
  \ 'passive_filetypes': [''] }
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_auto_jump = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_php_checkers = ['php']

" emmet
let g:user_emmet_leader_key = '<c-e>'
let g:user_emmet_settings = {
\   'html': {
\       'lang': "ja"
\   }
\ }

" Previm
augroup PrevimSettings
  autocmd!
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
augroup END

" vim-indent-guides
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#555555 ctermbg=2
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#666666 ctermbg=3

" Vim-Session
" 現在のディレクトリ直下の .vimsessions/ を取得
let s:local_session_directory = xolox#misc#path#merge(getcwd(), '.vimsessions')
" 存在すれば
if isdirectory(s:local_session_directory)
  " session保存ディレクトリをそのディレクトリの設定
  let g:session_directory = s:local_session_directory
  " vimを辞める時に自動保存
  let g:session_autosave = 'yes'
  " 引数なしでvimを起動した時にsession保存ディレクトリのdefault.vimを開く
  let g:session_autoload = 'yes'
  " 1分間に1回自動保存
  let g:session_autosave_periodic = 1
else
  let g:session_autosave = 'no'
  let g:session_autoload = 'no'
endif
unlet s:local_session_directory

" neosnippet
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

"************************************************
" neocomplete
"************************************************
"Note: This option must set it in .vimrc(_vimrc).  NOT IN .gvimrc(_gvimrc)!
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase, camelcase, underbar
let g:neocomplete#enable_smart_case = 1
let g:neocomplcache_enable_camel_case_completion = 0
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
" Cache directory
let g:neocomplete#data_directory = $HOME.'/.vim/neocomplete/cache'
" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
\ }
" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'
" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()
" Recommended key-mappings.
" <CR>: close popup and save indent.
"inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#close_popup() . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
"inoremap <expr><C-y>  neocomplete#close_popup()
"inoremap <expr><C-e>  neocomplete#cancel_popup()
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"
" For cursor moving in insert mode(Not recommended)
inoremap <expr><Right> neocomplete#close_popup() . "\<Right>"
" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType php setlocal omnifunc=phpcomplete#CompletePHP
" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
"let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
"let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
