set nocompatible

call plug#begin()
    Plug 'scrooloose/nerdtree'
    Plug 'jistr/vim-nerdtree-tabs'
    Plug 'Yggdroot/indentLine'
    Plug 'KelvinLu/vim-bbye'
    Plug 'ctrlpvim/ctrlp.vim'
    Plug 'bling/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'flazz/vim-colorschemes'
    Plug 'tpope/vim-sleuth'
call plug#end()

set background=dark
set t_Co=256
colorscheme wombat256mod

highlight Normal ctermbg=none
highlight Nontext ctermbg=none

set number
let &colorcolumn='81,121'
highlight ColorColumn ctermbg=234

set hlsearch

set mouse=a
set backspace=indent,eol,start
set ignorecase smartcase

let g:airline#extensions#tabline#enabled=1
let g:airline_theme='wombat'
let g:airline_powerline_fonts=0
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

let g:airline_symbols.linenr = ' line:'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.colnr = ' col:'

let g:airline_symbols.whitespace = '~'

let g:airline_symbols.branch = 'git branch:'

set laststatus=2

set splitright splitbelow

autocmd BufWritePre * %s/\s\+$//e
autocmd InsertEnter * set cul
autocmd InsertLeave * set nocul

let mapleader=","

function RCifmodbnext()
    if &modifiable | bn! | endif
endfunction

function RCifmodbprevious()
    if &modifiable | bp! | endif
endfunction

function RCifmodbdelete()
    if &modifiable
        if &modified
            let l:choice = confirm("Buffer has unwritten changes, write them before closing buffer?", "&Yes\n&No\n&Cancel", 3)
            if l:choice == 1
                silent w
            elseif l:choice == 3
                return 0
            endif
        endif
        Bdelete!
    endif
endfunction

function RCenewnobuflisted()
    enew!
    setl noswapfile
    setl bufhidden=wipe
    setl buftype=
    setl nobuflisted
endfunction

noremap <PageUp> <C-u>
noremap <PageDown> <C-d>

nmap <Leader>. i
imap <Leader>. <Esc>

nmap <Leader>n <plug>NERDTreeTabsToggle<CR>
nmap <Leader>p :CtrlP<CR>
nmap <Leader>] :call RCifmodbnext()<CR>
nmap <Leader>[ :call RCifmodbprevious()<CR>
nmap <Leader>q :call RCifmodbdelete()<CR>

nmap <silent> <Leader><Up> :wincmd k<CR>
nmap <silent> <Leader><Down> :wincmd j<CR>
nmap <silent> <Leader><Left> :wincmd h<CR>
nmap <silent> <Leader><Right> :wincmd l<CR>

nmap <Leader>h :vnew<CR>:wincmd l<CR>:call RCenewnobuflisted()<CR>
nmap <Leader>v :new<CR>:wincmd j<CR>:call RCenewnobuflisted()<CR>
nmap <Leader>w :resize -5<CR>
nmap <Leader>s :resize +5<CR>
nmap <Leader>a :vertical resize -5<CR>
nmap <Leader>d :vertical resize +5<CR>

nmap <Leader>c :call system("xsel -i -b", @")<CR>
