" ~/.vimrc - minimal defaults (common)

set nocompatible

" UI
syntax on
set number
set relativenumber
set cursorline
set showcmd
set ruler

" Indentation
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Files
set hidden
set undofile
set undodir=~/.vim/undo
set backupdir=~/.vim/backup
set directory=~/.vim/swap

" Colors
set termguicolors

" Mappings (default <leader> is \)
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
inoremap jk <Esc>
