local ok, mason = pcall(require, 'mason')
if not ok then
  return
end

-- Suppress texlab exit code 127 errors (common on SMB shares)
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- Filter out texlab exit code 127 messages
  if type(msg) == "string" and msg:match("texlab") and msg:match("exit code 127") then
    return
  end
  original_notify(msg, level, opts)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

mason.setup {
  ui = {
    icons = {
      server_installed = "✓",
      server_pending = "➜",
      server_uninstalled = "✗"
    }
  }
}

-- Servers managed by Mason
local mason_servers = {
  "lua_ls",
  "pyright",
  "denols",
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "bashls",
  "clangd",
  "rust_analyzer",
  "gopls",
  "taplo",
  "dockerls",
  "docker_compose_language_service",
}

-- Servers provided by NixOS (not installed via Mason)
local nixos_servers = {
  "texlab",
  "marksman",
  "ltex",
}

require('mason-lspconfig').setup {
  ensure_installed = mason_servers,
  automatic_installation = true,
}

-- Configure Mason-managed servers
for _, server in ipairs(mason_servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
  })
end

-- Configure NixOS-provided servers
for _, server in ipairs(nixos_servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
  })
end

-- Manually configure R since it's not installed via Mason
vim.lsp.config('r_language_server', {
  cmd = { "R", "--slave", "-e", "languageserver::run()" },
  capabilities = capabilities,
})

-- Configure ltex with custom settings for grammar/spell checking
vim.lsp.config('ltex', {
  capabilities = capabilities,
  filetypes = { "tex", "latex", "markdown", "text", "plaintex" },
  settings = {
    ltex = {
      enabled = { "latex", "tex", "bib", "markdown", "text" },
      language = "en-US",
      diagnosticSeverity = "information",
      setenceCacheSize = 2000,
      additionalRules = {
        enablePickyRules = true,
        motherTongue = "en-US",
      },
      trace = { server = "off" },
      dictionary = {},
      disabledRules = {},
      hiddenFalsePositives = {},
    },
  },
  on_attach = function(client, bufnr)
    -- Keybindings for ltex-specific actions
    local opts = { buffer = bufnr, noremap = true, silent = true }

    vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action,
      vim.tbl_extend('force', opts, { desc = "Grammar: Code actions (add to dict, disable rule)" }))
  end,
})

-- Optimize LSP for network shares
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "/mnt/*/*",
  callback = function()
    -- Reduce LSP file watching on network shares
    local clients = vim.lsp.get_clients({bufnr = 0})
    for _, client in ipairs(clients) do
      if client.server_capabilities.workspace then
        -- Disable file watching for network shares
        client.server_capabilities.workspace.didChangeWatchedFiles = nil
      end
    end
  end,
})
