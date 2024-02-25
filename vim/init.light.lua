-- remind, ':helptags ALL' after adding any package

vim.g.mapleader = " " -- XXX "<Space>" don't work

-- as soon as possible
vim.cmd(":packadd syntastic")

-- [[[ mason

vim.cmd(":packadd nvim-lspconfig")
vim.cmd(":packadd mason")
vim.cmd(":packadd mason-lspconfig")

require("mason").setup({})
require("mason-lspconfig").setup({})

-- ]]]
-- [[[ neo-tree

-- need plenary dependency
require("nvim-web-devicons").setup()
require("neo-tree").setup({
    popup_border_style = "rounded",
    buffers = {
        -- When working with sessions, for example, restored but unfocused buffers
        -- are mark as "unloaded". Turn this on to view these unloaded buffer.
        show_unloaded = true,
    },
})
-- shortcuts
-- XXX why not? vim.api.nvim_set_keymap("n", "\", ":Neotree toggle current reveal_force_cwd<CR>", { noremap = true})
vim.cmd([[:nnoremap \ :Neotree toggle current reveal_force_cwd<CR>]])
vim.cmd([[:nnoremap \| :Neotree toggle reveal<CR>]])
-- vim.cmd([[:nnoremap gd :Neotree float reveal_file=<cfile> reveal_force_cwd<CR>]])
vim.cmd([[:nnoremap <Leader>b :Neotree toggle show buffers<CR>]])
vim.cmd([[:nnoremap <Leader>s :Neotree toggle git_status<CR>]])

-- ]]]
-- [[[ dap

vim.cmd(":packadd nvim-dap")
vim.cmd(":packadd nvim-dap-ui")
require("dapui").setup()

-- ]]]
-- [[[ treesitter

-- treesitter: always call TSUpdate after update
vim.cmd(":packadd nvim-treesitter")

-- treesitter xit
vim.cmd(":packadd tree-sitter-xit")
require("nvim-treesitter.install").compilers = {
  "{{env_var "HOME"}}/utils/gcc_install/bin/gcc",
  vim.fn.getenv('CC'),
  "gcc",
  "clang"
}
require("nvim-treesitter.parsers").get_parser_configs().xit = {
  install_info = {
    url = "~/.dotfiles/vim/pack/parser/opt/tree-sitter-xit",
    files = { "src/parser.c" },
    generate_requires_npm = false, -- if stand-alone parser without npm dependencies
    requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
  },
  filetype = "xit", -- if filetype does not match the parser name
}

vim.cmd(":packadd nvim-ts-rainbow")

-- " :lua vim.opt.runtimepath:append("~/.config/nvim/parsers")

require('nvim-treesitter.configs').setup {
  ensure_installed = { "bash", "c", "comment", "cpp", "cmake",
                       "fish", "json", "latex", "lua", "markdown",
                       "python", "rust", "toml", "xit" },
  sync_install = false,
  auto_install = false,
  ignore_install = { "help", "javascript" },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  highlight = {
    enable = true,
    is_supported = function()
        if vim.fn.getfsize(vim.fn.expand('%')) > 512 * 1024 then
            vim.api.nvim_echo({ { vim.fn.expand('%') .. ": disable tree-sitter due to size" } }, true, {})
            return false
        end
        return true
    end,
    -- list of language that will be disabled
    disable = { "help", },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = false,
  },
  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
    -- colors = {}, -- table of hex strings
    -- termcolors = {} -- table of colour name strings
  },
}

vim.cmd(":packadd xit")
require('xit').setup {
  disable_default_highlights = true, -- broken, defined at end of this file
  disable_default_mappings = false,
  default_jump_group = "all", -- possible values: all, open_and_ongoing
  wrap_jumps = true,
}

-- to debug treesitter
-- vim.cmd(":packadd nvim-treesitter-playground")

require("nvim-treesitter.configs").setup {
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = 'o',
      toggle_hl_groups = 'i',
      toggle_injected_languages = 't',
      toggle_anonymous_nodes = 'a',
      toggle_language_display = 'I',
      focus_language = 'f',
      unfocus_language = 'F',
      update = 'R',
      goto_node = '<cr>',
      show_help = '?',
    },
  }
}

-- ]]]
-- [[[ main settings

-- fish shell might break some features
if vim.go.shell:match('fish$') then
    -- as PS1 isn't defined, we don't need NOFISH
    vim.go.shell = '/bin/bash'
end

-- allow bash aliases in :! commands
vim.env.BASH_ENV = "~/.config/nvim/bash_env"

-- technically unrequired by neovim as hardcoded
vim.opt.compatible = false
vim.opt.encoding = 'utf-8'
-- technically unrequired by neovim as default ones now
vim.opt.backspace = 'indent,eol,start'
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.hidden = true
vim.opt.backup = false
vim.opt.timeout = true
vim.opt.ttimeout = true
vim.opt.magic = true
vim.opt.modeline = true
vim.opt.modelines = 5
vim.opt.joinspaces = false
vim.opt.showmatch = false -- was true
vim.opt.showmode = false
vim.opt_local.textwidth = 0
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.wildchar = ('\t'):byte() -- funny way to type <Tab>
vim.opt.wildmenu = true

-- own
vim.opt.writebackup = false
vim.opt.backupcopy = 'auto,breakhardlink'
vim.opt.timeoutlen = 300 -- 300ms after typing for keymap
vim.opt.ttimeoutlen = 300 -- 300ms after ESC (was 10
vim.opt_local.list = true -- show tabs
vim.opt.listchars = 'tab:>-,trail:-,extends:>,precedes:<'
vim.opt.lazyredraw = true
vim.opt.report = 0
vim.opt_local.shiftwidth = 4
vim.opt.scrolloff = 2 -- give context/margin
vim.opt.suffixes = '.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.cmi,.cmo,.blk.c'
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.colorcolumn = '+1'
vim.opt.title = true
vim.opt.shada = "'1000,/1000,:1000,<1000,@1000,h"
vim.opt.ignorecase = true
vim.opt.smartcase = true -- case sensitive when search contains capital
vim.opt.iskeyword = vim.opt.iskeyword + '-' -- consider - as part of word
vim.opt.whichwrap = '' -- was "<,>,[,]" so left and right but I unmap them
vim.opt.wildmode = 'longest,list,full'
vim.opt_local.foldmethod = 'marker'
vim.opt.foldlevelstart = 2 -- was 20
vim.opt.tildeop = true
-- default statuline
vim.opt.cinoptions = ''
vim.opt.cinoptions = vim.opt.cinoptions + 'L0.5s'          -- align labels at 0.5 shiftwidth
vim.opt.cinoptions = vim.opt.cinoptions + ':0.5s,=0.5s'    -- same for case labels and code following a label
vim.opt.cinoptions = vim.opt.cinoptions + 'g0.5s,h0.5s'    -- same for c++ stuff
vim.opt.cinoptions = vim.opt.cinoptions + 't0'             -- type on the line before the functions is not idented
vim.opt.cinoptions = vim.opt.cinoptions + '(0,Ws'          -- indent in functions ( ... ) when it breaks
vim.opt.cinoptions = vim.opt.cinoptions + 'm1'             -- aligh the closing ) properly
vim.opt.cinoptions = vim.opt.cinoptions + 'j1'             -- java/javscript -> fixes blocks
-- vim.opt.cinoptions = vim.opt.cinoptions + 'l0.5s' -- align code after label ignoring braces.
vim.opt.wrapscan = false -- stop search at end of buffer
vim.opt.virtualedit = 'onemore' -- allow to be on \n
vim.opt.spelllang = 'en_us,fr'
-- make <enter> work in popup
vim.cmd([[:inoremap <cr> <C-R>=pumvisible() ? "\<lt>C-Y>" : "\<lt>cr>"<cr>]])

-- ]]]
-- [[[ external tools: diff, make, grep, path…

vim.opt.diffopt = 'internal,filler,closeoff,context:5,iwhite,vertical,algorithm:histogram'
vim.opt.makeprg = 'LC_ALL=C make MONOCHROME=1 L=1'
vim.opt.grepprg = 'rg --no-heading --vimgrep'
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.path = '.,./include,./../include'

--- ]]]
--- [[[ FIXME XXX NOT defaults but will be modified by init.vim

vim.opt.laststatus = 0 -- no statusline
vim.opt.ruler = false -- no cursor position
vim.opt.showcmd = false -- no command in lower right
vim.opt.shadafile = 'NONE' -- no history load/store
vim.opt_local.wrapmargin = 1

-- XXX restore correct pre 0.10 swapfile behavior with E325 (tmux own-patched)
-- 1:remove silent-but-one-warning-line (displayed even if appropriate callback is defined!)
vim.cmd([[:autocmd! nvim_swapfile]])
-- 2:force ATTENTION message when swap detected
vim.cmd([[:autocmd SwapExists * :let v:swapchoice = '']])

-- ]]]
-- [[[ clipboard

vim.opt.clipboard = 'unnamedplus'

-- share clipboard via terminal
require('osc52').setup {
  max_length = 0,      -- Maximum length of selection (0 for no limit)
  silent     = false,  -- Disable message on successful copy
  trim       = false,  -- Trim surrounding whitespaces before copy
}
-- TODO test tmux.nvim plugin
vim.g.clipboard = {
  name = 'tmuxClipboard',
  copy = {
    ['+'] = {'tmux', 'load-buffer', '-w', '-'},
    ['*'] = {'tmux', 'load-buffer', '-w', '-'},
  },
  paste = {
    ['+'] = {'tmux', 'save-buffer', '-'},
    ['*'] = {'tmux', 'save-buffer', '-'},
  },
  cache_enabled = true,
}

-- ]]]
-- [[[ fugitive

vim.keymap.set('n', '<Leader>gv', '<CMD>Gvdiffsplit!<CR>')
vim.keymap.set('n', '<Leader>gh', '<CMD>Gvdiff HEAD<CR>')
vim.keymap.set('n', '<Leader>go', '<CMD>Gvdiff origin/master<CR>')
vim.keymap.set('n', '<Leader>ga', '<CMD>Git difftool -y<CR>')

-- ]]]


-- dotter/handlebars+fold incompatibility: temporary [ instead of {
-- vim: foldmarker=[[[,]]]
-- vim: filetype=lua
