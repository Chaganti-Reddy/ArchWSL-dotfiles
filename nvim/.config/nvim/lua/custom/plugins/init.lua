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

  { 'wakatime/vim-wakatime', lazy = false },

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
      local diag_mode = 1 -- 1 = tiny-inline, 2 = virtual text, 3 = off

      vim.keymap.set('n', '<leader>td', function()
        diag_mode = diag_mode % 3 + 1
        if diag_mode == 1 then
          require('tiny-inline-diagnostic').enable()
          vim.diagnostic.config { virtual_text = false }
          print 'Diagnostics: tiny-inline'
        -- elseif diag_mode == 2 then
        --   require('tiny-inline-diagnostic').disable()
        --   vim.diagnostic.config { virtual_text = true }
        --   print 'Diagnostics: virtual text'
        else
          require('tiny-inline-diagnostic').disable()
          vim.diagnostic.config { virtual_text = false }
          print 'Diagnostics: off'
        end
      end, { desc = '[T]oggle [D]iagnostics' })
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
        mappings = {
          close = 'q',
          go_in = 'l',
          go_in_plus = 'L',
          go_out = 'h',
          go_out_plus = 'H',
          mark_goto = "'",
          mark_set = 'm',
          reset = '<BS>',
          reveal_cwd = '@',
          show_help = 'g?',
          synchronize = '=',
          trim_left = '<',
          trim_right = '>',
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
          permanent_delete = false,
        },
      }

      -- Toggle hidden files inside mini.files
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf = args.data.buf_id

          vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = buf, desc = 'Toggle Hidden Files' })

          -- Split open
          local open_split = function(cmd)
            local entry = require('mini.files').get_fs_entry()
            if not entry or entry.fs_type ~= 'file' then return end
            require('mini.files').close()
            vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(entry.path))
          end

          vim.keymap.set('n', '<C-h>', function() open_split 'split' end, { buffer = buf, desc = 'Open in horizontal split', nowait = true })
          vim.keymap.set('n', '<C-x>', function() open_split 'vsplit' end, { buffer = buf, desc = 'Open in vertical split', nowait = true })
          vim.keymap.set('n', '<C-t>', function() open_split 'tabedit' end, { buffer = buf, desc = 'Open in new tab', nowait = true })
        end,
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

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {},
    keys = {
      { '<leader>ha', function() require('harpoon'):list():add() end, desc = '[H]arpoon [A]dd' },
      { '<leader>hh', function() require('harpoon').ui:toggle_quick_menu(require('harpoon'):list()) end, desc = '[H]arpoon [M]enu' },
      { '<leader>h1', function() require('harpoon'):list():select(1) end, desc = '[H]arpoon [1]' },
      { '<leader>h2', function() require('harpoon'):list():select(2) end, desc = '[H]arpoon [2]' },
      { '<leader>h3', function() require('harpoon'):list():select(3) end, desc = '[H]arpoon [3]' },
      { '<leader>h4', function() require('harpoon'):list():select(4) end, desc = '[H]arpoon [4]' },
    },
  },
}
