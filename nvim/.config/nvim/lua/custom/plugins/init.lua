-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'Exafunction/codeium.vim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'saghen/blink.cmp',
    },
    event = 'BufEnter',
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ft = { 'markdown', 'codecompanion' },
    opts = {
      code = {
        sign = false,
        width = 'block',
        right_pad = 1,
        highlight = 'NormalFloat',
      },
      heading = {
        sign = false,
      },
    },
  },

  {
    'rachartier/tiny-inline-diagnostic.nvim',
    -- event = 'VeryLazy', -- Load early
    event = 'LspAttach',
    priority = 1000, -- Load before other things
    config = function()
      require('tiny-inline-diagnostic').setup {
        preset = 'modern', -- can be "modern", "classic", "full"
        options = {
          softwrap = 30,
          overflow = {
            mode = 'wrap',
          },
        },
      }

      -- IMPORTANT: Disable the default Neovim virtual text so they don't overlap
      vim.diagnostic.config { virtual_text = false }
    end,
  },

  {
    'echasnovski/mini.files',
    config = function()
      local show_dotfiles = false

      local filter_hide = function(fs_entry) return not vim.startswith(fs_entry.name, '.') end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and require('mini.files').default_filter or filter_hide
        require('mini.files').refresh { content = { filter = new_filter } }
      end

      require('mini.files').setup {
        content = {
          filter = filter_hide,
        },
        windows = {
          max_number = 3,
          width_focus = 30,
          width_nofocus = 15,
          preview = true,
          width_preview = 50,
        },
        options = {
          use_as_default_explorer = true,
        },
      }

      -- Toggle hidden files inside mini.files
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args) vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = args.data.buf_id, desc = 'Toggle Hidden Files' }) end,
      })

      -- Open mini.files (toggles if already open)
      vim.keymap.set('n', '<leader>e', function()
        if not require('mini.files').close() then require('mini.files').open(vim.api.nvim_buf_get_name(0), true) end
      end, { desc = '[E]xplorer (current file)' })

      vim.keymap.set('n', '<leader>E', function()
        if not require('mini.files').close() then require('mini.files').open(vim.uv.cwd(), true) end
      end, { desc = '[E]xplorer (cwd)' })
    end,
  },
}
