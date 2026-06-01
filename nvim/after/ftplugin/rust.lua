local bufnr = vim.api.nvim_get_current_buf()

-- The generic UserLspConfig LspAttach autocmd (init.lua) re-binds K/<leader>a on
-- every attach, which races with (and clobbers) buffer-local maps set here at
-- FileType time. Register our overrides on LspAttach too: since this ftplugin is
-- sourced after init.lua, our handler runs *after* the generic one and wins.
vim.api.nvim_create_autocmd("LspAttach", {
  buffer = bufnr,
  callback = function(ev)
    local opts = { silent = true, buffer = ev.buf }

    -- codeAction with rust-analyzer's grouping
    vim.keymap.set("n", "<leader>a", function()
      vim.cmd.RustLsp("codeAction")
    end, opts)

    -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
    vim.keymap.set("n", "K", function()
      vim.cmd.RustLsp({ "hover", "actions" })
    end, opts)
  end,
})

vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) -- always inlay
