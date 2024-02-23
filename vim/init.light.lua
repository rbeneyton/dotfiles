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

-- dotter/handlebars+fold incompatibility: temporary [ instead of {
-- vim: foldmarker=[[[,]]]
-- vim: filetype=lua
