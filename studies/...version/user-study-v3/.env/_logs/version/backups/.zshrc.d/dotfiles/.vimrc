" Auto-pairs
set nocompatible
filetype plugin indent on
syntax enable
set termguicolors
set hidden
set clipboard=unnamedplus

"  Display & navigation
set number
set relativenumber
set cursorline
set showmatch
set incsearch
set hlsearch
set ignorecase
set smartcase
set scrolloff=8
set sidescrolloff=8
set wrap
set linebreak
set showcmd
set ruler
set laststatus=2
set wildmenu
set wildmode=longest:full,full
set lazyredraw
set updatetime=300
set timeoutlen=500

" Tabs, indent, and formatting
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
set autoindent
set smartindent
set cindent
set copyindent

" Splits, mouse, undo, backups
set splitbelow
set splitright
set mouse=a
set backspace=indent,eol,start
set undofile
set undodir=~/.vim/undodir
set backupdir=~/.vim/backupdir
set directory=~/.vim/swapdir
set backup
set writebackup
set swapfile

" Plugin manager
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'
Plug 'jiangmiao/auto-pairs'
Plug 'Yggdroot/indentLine'
call plug#end()

" Plugin configuration
let NERDTreeShowHidden=1
let NERDTreeMinimalUI=1
autocmd VimEnter * NERDTree

let g:ale_linters_explicit=1
let g:ale_fix_on_save=1
let g:ale_fixers = {'*': ['remove_trailing_lines','trim_whitespace']}

let g:airline#extensions#tabline#enabled=1
let g:airline_theme='dark'

let g:AutoPairsMapBS=1
let g:AutoPairsMapCR=1

let g:fzf_layout = { 'down': '40%' }

" Key mappings
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :GFiles<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>t :TagbarToggle<CR>
