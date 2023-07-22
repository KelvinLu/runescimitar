set nocompatible

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
