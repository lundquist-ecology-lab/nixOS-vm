fn = vim.fn
api = vim.api
cmd = vim.cmd
opt = vim.opt
g = vim.g

_G.theme = "paradise"

local modules = {
  'options',
  'mappings',
  'statusline',
  'plugins',
  'colors',
}

for _, a in ipairs(modules) do
  local ok, err = pcall(require, a)
  if not ok then
    error("Error calling " .. a .. err)
  end
end

-- Configure nvim-treesitter (installed via Nix)
pcall(function()
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
  vim.o.foldmethod = "expr"
  vim.o.foldexpr = "nvim_treesitter#foldexpr()"
  vim.o.foldenable = false
end)

-- Auto commands
api.nvim_create_autocmd({"TermOpen", "TermEnter"}, {
  pattern = "term://*",
  command = "setlocal nonumber norelativenumber signcolumn=no | setfiletype term",
})

api.nvim_create_autocmd("BufEnter", {
  pattern = "term://*",
  command = "startinsert"
})

api.nvim_create_autocmd("VimLeave", {
  command = "set guicursor=a:ver20",
})

vim.cmd("hi StatusLine gui=NONE")
vim.cmd("hi StatusLineNC gui=NONE")

-- Optimize neovim for SMB/network shares
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "/mnt/*/*",  -- Match all network mounts
    callback = function()
        -- Disable swap files to avoid network lag
        vim.opt_local.swapfile = false
        -- Disable backup files that can cause conflicts
        vim.opt_local.backup = false
        vim.opt_local.writebackup = false
        -- Disable undo file for network shares (major slowdown)
        vim.opt_local.undofile = false
        -- Reduce file change check frequency (5 seconds instead of default)
        vim.opt_local.updatetime = 5000
        -- Enable autoread for ClaudeCode changes, but only check when window focused
        vim.opt_local.autoread = true
        -- Reduce syntax sync for large files
        vim.opt_local.synmaxcol = 200
    end,
})

-- Check for external file changes when focusing nvim (for ClaudeCode edits)
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold"}, {
    pattern = "/mnt/*/*",  -- Match all network mounts
    callback = function()
        -- Only check if buffer is valid and not modified
        if vim.bo.buftype == "" and not vim.bo.modified then
            vim.cmd("checktime")
        end
    end,
})

vim.opt.clipboard:append("unnamedplus")


vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    require("osc52").copy_register('"')
  end,
})

vim.g.mkdp_browser = "firefox"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "telekasten",
  callback = function()
    vim.bo.filetype = "markdown"
    vim.defer_fn(function()
      pcall(function()
        vim.treesitter.start(0, "markdown")
      end)
    end, 200)
  end
})


-- Treat all vimwiki buffers as markdown for Treesitter
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vimwiki",
  callback = function()
    vim.bo.filetype = "markdown"
    vim.bo.syntax = "markdown"
    -- vim.b.vimwiki_tag_format = {["pre"] = "#", ["sep"] = "\\>"}
    vim.g.vimwiki_tag_start = ":tag:"  -- This makes tags start with :tag instead of #tag
    vim.g.vimwiki_tag_format = {
        pre = ":tag:",  -- Prefix for recognizing tags 
        sep = " "   -- Separator after tag
    }
    vim.defer_fn(function()
      pcall(function()
        vim.treesitter.start(0, "markdown")
      end)
    end, 300)
  end
})

-- Ensure all .md files trigger markdown parser too
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.md",
  callback = function()
    vim.bo.filetype = "markdown"
    vim.defer_fn(function()
      pcall(function()
        vim.treesitter.start(0, "markdown")
      end)
    end, 300)
  end,
})

-- Add protection for Zotcite and Treesitter interaction
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = {"*.md"},
  callback = function()
    -- Make sure the buffer exists before trying to access it
    if vim.api.nvim_buf_is_valid(vim.api.nvim_get_current_buf()) then
      pcall(function()
        vim.treesitter.get_parser(0, "markdown")
      end)
    end
  end
})

-- Fix for Zotcite and Treesitter conflicts
vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"vimwiki", "markdown"},
  callback = function()
    -- Additional vimwiki/markdown configuration can go here
  end
})

-- Add this to your init.lua
vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"vimwiki"},
  callback = function()
    -- Use a different key for VimWiki navigation
    vim.keymap.set('n', '<C-j>', '<Plug>VimwikiNextLink', {buffer = true})
  end
})

-- Enable spell checking only for specific file types
vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"markdown", "text", "vimwiki", "tex"},
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = {"en_us"}
    -- Additional spell check configurations
    vim.opt.spellsuggest = {"best,10"}  -- Show only 10 suggestions
    vim.opt.spelloptions = {"camel"}    -- Recognize camelCase words
  end
})

-- Re-map your buffer navigation explicitly
vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"vimwiki"},
  callback = function()
    vim.keymap.set('n', '<Tab>', ':bnext<CR>', {buffer = true, noremap = true})
    vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', {buffer = true, noremap = true})
  end
})


-- Disable VimWiki's Tab mappings and restore your buffer navigation
vim.g.vimwiki_key_mappings = {
  table_mappings = 0,  -- Disable table mappings
  table_format = 0,    -- Disable table formatting
  all_maps = 1,        -- Keep other mappings
  links = 0,           -- Disable links mappings (including Tab)
  global = 1,
  headers = 1,
  text_objs = 1,
}


-- Use different keys for VimWiki link navigation
vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"vimwiki"},
  callback = function()
    vim.keymap.set('n', '<C-n>', '<Plug>VimwikiNextLink', {buffer = true})
    vim.keymap.set('n', '<C-p>', '<Plug>VimwikiPrevLink', {buffer = true})
  end
})

-- Check if we're likely using an exit node (high latency)
local function is_high_latency()
  -- Only enable high latency mode when actually on network shares
  local bufname = vim.api.nvim_buf_get_name(0)
  return bufname:match("^/mnt/") ~= nil
end

if is_high_latency() then
  vim.opt.updatetime = 2000
  vim.opt.timeoutlen = 1500
  
  -- FIRST: Clear existing problematic autocommands
  vim.api.nvim_clear_autocmds({event = "CursorMoved"})
  vim.api.nvim_clear_autocmds({event = "CursorMovedI"})
  
  -- Disable matchparen completely (this needs to be early)
  vim.g.loaded_matchparen = 1
  
  -- If matchparen is already loaded, disable it
  vim.cmd("silent! NoMatchParen")
  
  -- Then create your safer autocommands
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    callback = function()
      -- Safe cursor handling with pcall
      pcall(function()
        -- Any cursor-related logic here
      end)
    end,
    desc = "Network-tolerant cursor handling"
  })
end
