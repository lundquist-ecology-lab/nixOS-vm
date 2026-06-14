g.mapleader = ' '

-- basic
opt.scrolloff = 3
opt.mouse = 'a'
opt.title = true
opt.titlestring = '%f'
opt.swapfile = false
opt.undofile = true
-- opt.cmdheight = 0
opt.termguicolors = true
opt.showmode = false
opt.cul = true

-- timeout stuff
opt.updatetime = 300
opt.timeout = true
opt.timeoutlen = 1000
opt.ttimeoutlen = 10

-- status, tab, number, sign line
opt.ruler = false
opt.laststatus = 3
opt.showtabline = 2
opt.number = true
opt.numberwidth = 1
opt.relativenumber = false
opt.signcolumn = "yes"

-- window, buffer, tabs
opt.switchbuf = "newtab"
opt.splitbelow = true
opt.splitright = true
opt.hidden = true
opt.fillchars = {
  eob = " ",
  diff = " ",
  msgsep = " "
}

-- text formatting
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.showmatch = true
opt.smartcase = true
opt.whichwrap:append "<>[]hl"

-- remove intro
opt.shortmess:append "sI"

-- disable inbuilt vim plugins
local built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
}

for _, plugin in pairs(built_ins) do
  g["loaded_" .. plugin] = 1
end

local has_wayland_clipboard =
  vim.env.WAYLAND_DISPLAY and vim.env.WAYLAND_DISPLAY ~= "" and
  vim.fn.executable("wl-copy") == 1

local has_x11_clipboard =
  vim.env.DISPLAY and vim.env.DISPLAY ~= "" and
  (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1)

local has_macos_clipboard = vim.fn.executable("pbcopy") == 1

local has_clipboard_provider =
  has_wayland_clipboard or
  has_x11_clipboard or
  has_macos_clipboard

if vim.env.SSH_TTY and vim.env.SSH_TTY ~= "" then
  local function osc52_copy(lines, _)
    local ok, osc52 = pcall(require, "osc52")
    if ok then
      osc52.copy(table.concat(lines, "\n"))
    end
  end

  local function osc52_paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = osc52_copy,
      ["*"] = osc52_copy,
    },
    paste = {
      ["+"] = osc52_paste,
      ["*"] = osc52_paste,
    },
  }

  opt.clipboard = 'unnamedplus'
elseif has_clipboard_provider then
  opt.clipboard = 'unnamedplus'
else
  opt.clipboard = ''
end
