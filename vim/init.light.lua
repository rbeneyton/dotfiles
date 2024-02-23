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
vim.api.nvim_set_option('compatible', false)
vim.api.nvim_set_option('encoding', 'utf-8')
-- technically unrequired by neovim as default ones
vim.api.nvim_set_option('backspace', 'indent,eol,start')
vim.api.nvim_set_option('autoindent', true)
vim.api.nvim_set_option('autoread', true)
vim.api.nvim_set_option('hidden', true)
vim.api.nvim_set_option('backup', false)
vim.api.nvim_set_option('timeout', true)
vim.api.nvim_set_option('ttimeout', true)
vim.api.nvim_set_option('magic', true)
vim.api.nvim_set_option('modeline', true)
vim.api.nvim_set_option('modelines', 5)
vim.api.nvim_set_option('joinspaces', false)
vim.api.nvim_set_option('showmatch', false) -- (was true)
vim.api.nvim_set_option('showmode', false)
vim.api.nvim_set_option_value('textwidth', 0, {buf = 0})

-- own
vim.api.nvim_set_option('writebackup', false)
vim.api.nvim_set_option('backupcopy', 'auto,breakhardlink')
vim.api.nvim_set_option('timeoutlen', 300) -- 300ms after typing for keymap
vim.api.nvim_set_option('ttimeoutlen', 300) -- 300ms after ESC (was 10)
vim.api.nvim_set_option_value('list', true, {win = 0}) -- show tabs
vim.api.nvim_set_option('listchars', 'tab:>-,trail:-,extends:>,precedes:<')
vim.api.nvim_set_option('lazyredraw', true)
vim.api.nvim_set_option('report', 0)
vim.api.nvim_set_option_value('shiftwidth', 4, {buf = 0})
vim.api.nvim_set_option('scrolloff', 2) -- give context/margin
vim.api.nvim_set_option('suffixes', '.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.cmi,.cmo,.blk.c')
vim.api.nvim_set_option_value('tabstop', 4, {buf = 0})
vim.api.nvim_set_option_value('softtabstop', 4, {buf = 0})
vim.api.nvim_set_option_value('expandtab', true, {buf = 0})
vim.api.nvim_set_option_value('colorcolumn', '+1', {win = 0})
vim.api.nvim_set_option('title', true)

-- XXX NOT defaults but will be modified by init.vim
vim.api.nvim_set_option('laststatus', 0) -- no statusline
vim.api.nvim_set_option('ruler', false) -- no cursor position
vim.api.nvim_set_option('showcmd', false) -- no command in lower right

-- XXX restore correct pre 0.10 swapfile behavior with E325 (tmux own-patched)
-- 1:remove silent-but-one-warning-line (displayed even if appropriate callback is defined!)
vim.cmd(":autocmd! nvim_swapfile")
-- 2:force ATTENTION message when swap detected
vim.cmd(":autocmd SwapExists * :let v:swapchoice = ''")

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

-- dotter/handlebars+fold incompatibility: temporary [ instead of {
-- vim: foldmarker=[[[,]]]
-- vim: filetype=lua
