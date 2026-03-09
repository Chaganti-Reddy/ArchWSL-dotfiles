local show_dotfiles = false
local filter_show = function(entry)
  return true
end
local filter_hide = function(entry)
  -- Hides files starting with '.' and common heavy folders
  return not vim.startswith(entry.name, '.') and entry.name ~= 'node_modules' and entry.name ~= 'venv' and entry.name ~= '.git'
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and filter_show or filter_hide
  require('mini.files').refresh { content = { filter = new_filter } }
end

return {
  {
    'akinsho/bufferline.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('bufferline').setup {
        options = {
          mode = 'buffers',
          themable = true,
          buffer_close_icon = '✗',
          close_icon = '',
          path_components = 1,
          modified_icon = '●',
          separator_style = { '│', '│' },
          enforce_regular_tabs = true,
          -- UPDATED: Hides the bar if only one file is open
          always_show_bufferline = false,
          indicator = { style = 'none' },
          sort_by = 'insert_at_end',
          close_command = function(n)
            Snacks.bufdelete(n)
          end,
          right_mouse_command = function(n)
            Snacks.bufdelete(n)
          end,
        },
      }

      local opts = { silent = true }
      -- VS Code style cycling
      vim.keymap.set('n', '<C-Tab>', '<Cmd>BufferLineCycleNext<CR>', opts)
      vim.keymap.set('n', '<C-S-Tab>', '<Cmd>BufferLineCyclePrev<CR>', opts)

      -- Quick jump (Leader + Number)
      for i = 1, 9 do
        vim.keymap.set('n', '<leader>b' .. i, function()
          require('bufferline').go_to_buffer(i)
        end, { desc = 'Go to Buffer ' .. i })
      end

      -- Buffer Actions
      vim.keymap.set('n', '<leader>bd', function()
        Snacks.bufdelete()
      end, { desc = '[B]uffer [D]elete' })
      vim.keymap.set('n', '<leader>bl', function()
        Snacks.picker.buffers()
      end, { desc = '[B]uffer [L]ist' })
    end,
  },

  {
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup {
        keymaps = {
          ['q'] = 'actions.close', -- Press q to exit
          ['<C-c>'] = 'actions.close',
        },
      }
      -- Standard shortcuts
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
      vim.keymap.set('n', '<leader>fo', '<CMD>Oil<CR>', { desc = '[F]ile [O]pen (Oil)' })
    end,
  },

  {
    'echasnovski/mini.files',
    config = function()
      require('mini.files').setup {
        content = {
          filter = filter_hide, -- Hide hidden files by default
        },
        windows = {
          max_number = 3,
          width_focus = 30,
          width_nofocus = 15,
          preview = false,
        },
        options = {
          use_as_default_explorer = true,
        },
      }

      -- Create local keymap 'g.' to toggle hidden files inside mini.files
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = args.data.buf_id, desc = 'Toggle Hidden Files' })
        end,
      })

      -- Global keymap to open mini.files
      vim.keymap.set('n', '<leader>ff', function()
        if not require('mini.files').close() then
          require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
        end
      end, { desc = '[F]ile [F]inder (mini.files)' })
    end,
  },

  {
    'theprimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- Harpoon doesn't need to load until you press a key
    keys = {
      {
        '<leader>ba',
        function()
          require('harpoon'):list():add()
        end,
        desc = 'Harpoon Add File',
      },
      -- Quick Jump keys (Improved navigation)
      {
        '<leader>1',
        function()
          require('harpoon'):list():select(1)
        end,
        desc = 'Harpoon Jump 1',
      },
      {
        '<leader>2',
        function()
          require('harpoon'):list():select(2)
        end,
        desc = 'Harpoon Jump 2',
      },
      {
        '<leader>3',
        function()
          require('harpoon'):list():select(3)
        end,
        desc = 'Harpoon Jump 3',
      },
      {
        '<leader>4',
        function()
          require('harpoon'):list():select(4)
        end,
        desc = 'Harpoon Jump 4',
      },
    },
    config = function()
      require('harpoon'):setup()
    end,
  },
}
