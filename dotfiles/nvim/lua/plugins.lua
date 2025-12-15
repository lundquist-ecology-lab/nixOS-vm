-- plugins.lua
local fn = vim.fn
local opt = vim.opt
local g = vim.g

-- Bootstrap lazy.nvim
local lazypath = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
opt.rtp:prepend(lazypath)

g.mapleader = " "

require("lazy").setup({
  {
    'norcalli/nvim-colorizer.lua',
    event = "BufReadPost",
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main = "ibl",
    opts = {},
    config = function()
      require('plugins.indent_blankline')
    end,
  },
  -- nvim-treesitter is installed via Nix home-manager (see home/mlundquist.nix)
  -- This ensures all parsers are available from the system
  -- We still need to configure it here
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = false,  -- Disabled because it's managed by Nix
  },
  'RRethy/nvim-base16',
  {
    'kyazdani42/nvim-tree.lua',
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
    },
    config = function()
      require('plugins.nvim-tree')
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = "BufReadPost",
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('plugins.gitsigns')
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help Tags" },
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('plugins.telescope')
      -- Add custom telescope commands for notes
      local telescope = require('telescope.builtin')
      vim.keymap.set("n", "<leader>fn", function()
        telescope.find_files({
          cwd = "/mnt/onyx/notes",
          prompt_title = "Find Notes",
        })
      end, { desc = "Find Notes" })

      vim.keymap.set("n", "<leader>fg", function()
        telescope.live_grep({
          cwd = "/mnt/onyx/notes",
          prompt_title = "Search Notes Content",
        })
      end, { desc = "Search Notes Content" })

      vim.keymap.set("n", "<leader>ft", function()
        telescope.grep_string({
          cwd = "/mnt/onyx/notes",
          prompt_title = "Find Tags",
          search = ":tag:",
        })
      end, { desc = "Find Tags" })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = "VeryLazy",
    config = function()
      require('plugins.bufferline')
    end,
  },

  -- Completion & LSP
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require('nvim-autopairs').setup()
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        snippet = { expand = function(args) end },
        mapping = cmp.mapping.preset.insert({
          ['<CR>']      = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end,
  },
  {
    'numToStr/Comment.nvim',
    keys = {
      { "gc", mode = { "n", "v" }, desc = "Comment toggle" },
      { "gb", mode = { "n", "v" }, desc = "Comment toggle blockwise" },
    },
    config = function()
      require('Comment').setup()
    end,
  },
  {
    'williamboman/mason.nvim',
    event = "BufReadPre",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'neovim/nvim-lspconfig',
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
      require('plugins.lsp')
    end,
  },
  {
    'goolord/alpha-nvim',
    config = function()
      require('alpha').setup(require('alpha.themes.dashboard').config)
    end,
  },

  -- Claude Code
  {
    "greggh/claude-code.nvim",
    cmd = { "ClaudeCode" },
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup()
    end
  },
  -- LaTeX Support
  {
    'lervag/vimtex',
    ft = { "tex", "latex", "bib" },
    config = function()
      require('plugins.vimtex')
    end,
  },

  -- Snippets
  {
    'L3MON4D3/LuaSnip',
    event = "InsertEnter",
    dependencies = {
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      require('plugins.luasnip')
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  {
    'jpmcb/nvim-llama',
    cmd = { "Llama" },
  },

  {
    'ojroques/nvim-osc52',
    event = "VeryLazy",
    config = function()
      require('osc52').setup({ max_length = 0, trim = false, silent = false })
      vim.keymap.set('n', '<leader>y', function() require('osc52').copy_register('"') end)
      vim.keymap.set('v', '<leader>y', function() require('osc52').copy_register('"') end)
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown", "vimwiki" },
    build = "cd app && yarn install",
    config = function()
      vim.g.mkdp_auto_start = 0
    end,
  },
  
  -- Enhanced VimWiki setup for better notebook experience
 {
  "vimwiki/vimwiki",
  ft = { "vimwiki", "markdown" },
  cmd = { "VimwikiIndex", "VimwikiDiaryIndex", "VimwikiMakeDiaryNote" },
  keys = {
    { "<leader>ww", "<cmd>VimwikiIndex<cr>", desc = "Open Wiki Index" },
    { "<leader>wd", "<cmd>VimwikiDiaryIndex<cr>", desc = "Open Diary Index" },
    { "<leader>wn", "<cmd>VimwikiMakeDiaryNote<cr>", desc = "New Diary Entry" },
  },
  init = function()
    vim.g.vimwiki_list = {
      {
        path = '/mnt/onyx/notes',
        syntax = 'markdown',
        ext = '.md',
        auto_diary_index = 1,
        auto_generate_links = 1,
        auto_tags = 1,
      }
    }
    
    -- Important settings for better usability
    vim.g.vimwiki_global_ext = 0  -- Don't treat all .md files as wiki
    vim.g.vimwiki_markdown_link_ext = 1  -- Use .md extension in links
    vim.g.vimwiki_links_space_char = '-'  -- Use hyphens in filenames
    vim.g.vimwiki_dir_link = 'index'  -- When following directory, open index
    vim.g.vimwiki_auto_header = 1  -- Auto-create header
    vim.g.vimwiki_list_margin = 0  -- No extra margin in lists
    vim.g.vimwiki_use_calendar = 1  -- Enable calendar integration if available
    
    -- Add explicit Treesitter compatibility
    vim.g.vimwiki_ext2syntax = {['.md'] = 'markdown'}
    
    -- Key mappings for common notebook tasks
    vim.keymap.set("n", "<leader>ww", "<cmd>VimwikiIndex<cr>", { desc = "Open Wiki Index" })
    vim.keymap.set("n", "<leader>wd", "<cmd>VimwikiDiaryIndex<cr>", { desc = "Open Diary Index" })
    vim.keymap.set("n", "<leader>wn", "<cmd>VimwikiMakeDiaryNote<cr>", { desc = "New Diary Entry" })
    vim.keymap.set("n", "<leader>w<space>", "<cmd>VimwikiToggleListItem<cr>", { desc = "Toggle Checkbox" })
    vim.keymap.set("n", "<leader>wt", "<cmd>VimwikiRebuildTags<cr>", { desc = "Rebuild Tags" })
    vim.keymap.set("n", "<leader>ws", "<cmd>VimwikiSearchTags<cr>", { desc = "Search Tags" })
    vim.keymap.set("n", "<leader>wh", "<cmd>Vimwiki2HTML<cr>", { desc = "Convert to HTML" })
    
    -- Quick capture function
    vim.api.nvim_create_user_command('WikiCapture', function()
      local title = vim.fn.input("Quick note title: ")
      if title ~= "" then
        vim.cmd('VimwikiGoto ' .. title:gsub(" ", "-"))
      end
    end, {})
    
    vim.keymap.set("n", "<leader>wc", "<cmd>WikiCapture<cr>", { desc = "Quick Capture Note" })
  end,
},
-- Enhanced note-taking with telekasten
  {
    "renerocksai/telekasten.nvim",
    ft = { "markdown", "vimwiki" },
    cmd = { "Telekasten" },
    keys = {
      { "<leader>tf", "<cmd>Telekasten find_notes<CR>", desc = "Telekasten Find Notes" },
      { "<leader>tg", "<cmd>Telekasten search_notes<CR>", desc = "Telekasten Search Notes" },
      { "<leader>tt", "<cmd>Telekasten goto_today<CR>", desc = "Telekasten Today's Note" },
      { "<leader>tn", "<cmd>Telekasten new_note<CR>", desc = "Telekasten New Note" },
    },
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require('telekasten').setup({
        home = vim.fn.expand("/mnt/onyx/notes"),
        dailies_create_nonexisting = true,
        templates_subdir = "templates",
        template_new_note = "templates/new_note.md",
        template_new_daily = "templates/daily.md",
        image_subdir = "images",
        extension = ".md",
        follow_creates_nonexisting = true,
        dailies_dateformat = "%Y-%m-%d",
        -- Telekasten-specific keybindings
        mappings = {
          -- Create new note at cursor or selection
          note_create_from_cursor = "<leader>z",
        },
        auto_set_filetype = false,
      })
      
      -- Telekasten keybindings
      vim.keymap.set("n", "<leader>tf", "<cmd>Telekasten find_notes<CR>", { desc = "Telekasten Find Notes" })
      vim.keymap.set("n", "<leader>tg", "<cmd>Telekasten search_notes<CR>", { desc = "Telekasten Search Notes" })
      vim.keymap.set("n", "<leader>tt", "<cmd>Telekasten goto_today<CR>", { desc = "Telekasten Today's Note" })
      vim.keymap.set("n", "<leader>tn", "<cmd>Telekasten new_note<CR>", { desc = "Telekasten New Note" })
      vim.keymap.set("n", "<leader>tb", "<cmd>Telekasten show_backlinks<CR>", { desc = "Telekasten Show Backlinks" })
      vim.keymap.set("n", "<leader>tz", "<cmd>Telekasten follow_link<CR>", { desc = "Telekasten Follow Link" })
      vim.keymap.set("n", "<leader>t#", "<cmd>Telekasten show_tags<CR>", { desc = "Telekasten Show Tags" })
    end,
  },
  
  -- Focused writing environment
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
    },
    config = function()
      require("zen-mode").setup({
        window = {
          backdrop = 1,
          width = 90,
          options = {
            signcolumn = "no",
            number = false,
            relativenumber = false,
            cursorline = false,
            cursorcolumn = false,
          },
        },
        plugins = {
          options = {
            enabled = true,
            ruler = false,
            showcmd = false,
          },
          twilight = { enabled = false },
          gitsigns = { enabled = false },
          kitty = {
            enabled = true,
            font = "+4",
          },
        },
        on_open = function()
          vim.fn.system("kitty @ set-background-opacity 0.85")
          vim.cmd("highlight ZenBg guibg=NONE ctermbg=NONE")
        end,
        on_close = function()
          vim.fn.system("kitty @ set-background-opacity 0.85")
        end,
      })
      
      vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "Toggle Zen Mode" })
    end,
  },
  
  -- Use glow for markdown and wiki preview
  {
    "ellisonleao/glow.nvim",
    ft = { "markdown", "vimwiki" },
    cmd = "Glow",
    config = function()
      require('glow').setup({
        -- Support both markdown and wiki files
        filetype = {"markdown", "wiki"},
        -- Style options
        width = 120,
        height = 100,
        border = "rounded",
      })
    end,
  },

  -- Add telescope-frecency for better note navigation (optional, but useful)
  {
    "nvim-telescope/telescope-frecency.nvim",
    keys = {
      { "<leader>fr", desc = "Recent Notes" },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "kkharji/sqlite.lua",
    },
    config = function()
      require("telescope").load_extension("frecency")

      -- For frequent note access
      vim.keymap.set("n", "<leader>fr", function()
        require("telescope").extensions.frecency.frecency({
          workspace = "notes",
          path_display = { "tail" },
        })
      end, { desc = "Recent Notes" })
    end,
  },
}, {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
