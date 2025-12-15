-- vimtex.lua
-- VimTeX configuration for LaTeX editing

local g = vim.g

-- Basic VimTeX settings
g.vimtex_enabled = 1

-- Compiler settings
g.vimtex_compiler_method = 'latexmk'
g.vimtex_compiler_latexmk = {
  build_dir = '',
  callback = 1,
  continuous = 1,
  executable = 'latexmk',
  hooks = {},
  options = {
    '-verbose',
    '-file-line-error',
    '-synctex=1',
    '-interaction=nonstopmode',
  },
}

-- PDF viewer settings (platform-specific)
local is_darwin = vim.fn.has('mac') == 1 or vim.fn.has('macunix') == 1

if is_darwin then
  -- macOS - Use Skim
  g.vimtex_view_method = 'skim'
  g.vimtex_view_skim_sync = 1
  g.vimtex_view_skim_activate = 1
else
  -- Linux - Use Okular
  g.vimtex_view_method = 'general'
  g.vimtex_view_general_viewer = 'okular'
  g.vimtex_view_general_options = '--unique file:@pdf\\#src:@line@tex'
end

-- Enable quickfix mode (error window)
g.vimtex_quickfix_mode = 1
g.vimtex_quickfix_open_on_warning = 0
g.vimtex_quickfix_autoclose_after_keystrokes = 3

-- LaTeX Concealment Settings
-- Enable concealment for a cleaner editing experience
g.vimtex_syntax_conceal = {
  accents = 1,
  cites = 1,
  fancy = 1,
  greek = 1,
  math_bounds = 0,
  math_delimiters = 1,
  math_fracs = 1,
  math_super_sub = 1,
  math_symbols = 1,
  sections = 0,
  styles = 1,
}

-- Set conceal level for LaTeX files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nc' -- conceal in normal and command mode, not in insert
  end,
})

-- Syntax highlighting
g.vimtex_syntax_enabled = 1
g.vimtex_syntax_conceal_disable = 0

-- Text objects and motions
g.vimtex_motion_enabled = 1
g.vimtex_text_obj_enabled = 1

-- Folding (optional - set to 0 if you don't want folding)
g.vimtex_fold_enabled = 0

-- TOC settings
g.vimtex_toc_config = {
  name = 'TOC',
  layers = {'content', 'todo', 'include'},
  split_width = 30,
  todo_sorted = 0,
  show_help = 1,
  show_numbers = 1,
}

-- Indent settings
g.vimtex_indent_enabled = 1
g.vimtex_indent_bib_enabled = 1

-- Format settings
g.vimtex_format_enabled = 1

-- Disable overfull/underfull warnings
g.vimtex_quickfix_ignore_filters = {
  'Underfull',
  'Overfull',
  'specifier changed to',
  'Token not allowed in a PDF string',
}

-- Enhanced keymaps for LaTeX editing
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    local opts = { buffer = true, noremap = true, silent = true }

    -- Compilation
    vim.keymap.set('n', '<localleader>ll', '<cmd>VimtexCompile<CR>', vim.tbl_extend('force', opts, { desc = "Toggle compilation" }))
    vim.keymap.set('n', '<localleader>lv', '<cmd>VimtexView<CR>', vim.tbl_extend('force', opts, { desc = "View PDF" }))
    vim.keymap.set('n', '<localleader>lc', '<cmd>VimtexClean<CR>', vim.tbl_extend('force', opts, { desc = "Clean auxiliary files" }))
    vim.keymap.set('n', '<localleader>lC', '<cmd>VimtexClean!<CR>', vim.tbl_extend('force', opts, { desc = "Clean all files" }))

    -- Navigation
    vim.keymap.set('n', '<localleader>lt', '<cmd>VimtexTocOpen<CR>', vim.tbl_extend('force', opts, { desc = "Open TOC" }))
    vim.keymap.set('n', '<localleader>lT', '<cmd>VimtexTocToggle<CR>', vim.tbl_extend('force', opts, { desc = "Toggle TOC" }))

    -- Info and errors
    vim.keymap.set('n', '<localleader>li', '<cmd>VimtexInfo<CR>', vim.tbl_extend('force', opts, { desc = "Show info" }))
    vim.keymap.set('n', '<localleader>le', '<cmd>VimtexErrors<CR>', vim.tbl_extend('force', opts, { desc = "Show errors" }))

    -- Word count
    vim.keymap.set('n', '<localleader>lw', '<cmd>VimtexCountWords<CR>', vim.tbl_extend('force', opts, { desc = "Count words" }))

    -- Context menu (useful for citations, references, etc.)
    vim.keymap.set('n', '<localleader>lm', '<cmd>VimtexContextMenu<CR>', vim.tbl_extend('force', opts, { desc = "Context menu" }))
  end,
})

-- Set localleader for LaTeX-specific commands
vim.g.maplocalleader = ','
