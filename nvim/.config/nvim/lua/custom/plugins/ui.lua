return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      require('rose-pine').setup {
        variant = 'auto',
        dark_variant = 'main',
        extend_background_behind_borders = false,
        disable_float_background = true,
        enable = {
          transparency = true,
        },
        styles = {
          italic = false,
          transparency = true,
        },
      }
      local function apply_transparency()
        local groups = {
          'Normal',
          'NormalNC',
          'NormalFloat',
          'NormalFloatNC',

          'SagaNormal',
          'SagaDocNormal',
          'HoverNormal',
          'HoverBorder',
          'SagaBorder',

          'FloatBorder',
          'LineNr',
          'CursorLine',
          'SignColumn',
          'EndOfBuffer',
          'StatusLine',
          'StatusLineNC',
          'WinBar',
          'WinBarNC',
          'CodeiumSuggestion',
          'NoiceCmdline',
          'NoiceCmdlinePopup',
          'NoiceCmdlinePopupBorder',
          'NoiceCmdlineIcon',
        }

        for _, group in ipairs(groups) do
          vim.api.nvim_set_hl(0, group, { bg = 'none', ctermbg = 'none', force = true })
        end

        vim.api.nvim_set_hl(0, 'SagaNormal', { bg = 'none', force = true })
        vim.api.nvim_set_hl(0, 'HoverNormal', { bg = 'none', force = true })

        -- Force borders to be transparent too
        vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#88c0d0', bg = 'none', force = true })
        vim.api.nvim_set_hl(0, 'SagaBorder', { fg = '#88c0d0', bg = 'none', force = true })
        vim.api.nvim_set_hl(0, 'CodeiumSuggestion', { fg = '#808080', bg = 'none', italic = true })

        -- Indent Blankline transparency
        vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#3b4252', bg = 'none' })
        vim.api.nvim_set_hl(0, 'IblScope', { fg = '#88c0d0', bg = 'none' })
      end

      -- Run transparency logic whenever the colorscheme changes
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'rose-pine',
        callback = function()
          apply_transparency()
        end,
      })

      -- Load the colorscheme
      vim.cmd.colorscheme 'rose-pine'

      -- Call once on a slight delay to "catch" plugins that load late
      vim.defer_fn(function()
        apply_transparency()
      end, 100)
    end,
  },

  {
    'nvimdev/lspsaga.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    event = 'LspAttach',
    config = function()
      require('lspsaga').setup {
        ui = {
          winblend = 0,
          border = 'rounded',
          devicon = true,
          title = false,
          expand = '',
          collapse = '',
          code_action = '💡',
          action_fix = ' ',
        },
        hover = {
          border = 'rounded',
          max_width = 0.6,
          open_link = 'gx',
        },
        lightbulb = {
          enable = true,
        },
        symbol_in_winbar = {
          enable = true,
          separator = '  ',
          hide_keyword = true,
          show_file = true,
          folder_level = 2,
        },
        outline = {
          layout = 'float',
          max_height = 0.7,
          left_width = 0.3,
          auto_preview = true,
          close_after_jump = true,
          keys = {
            toggle_or_jump = '<CR>',
            quit = 'q',
            jump = 'o',
          },
        },
        finder = { keys = { quit = { 'q', '<Esc>' } } },
        code_action = { keys = { quit = { 'q', '<Esc>' } } },
        rename = { in_select = true, keys = { quit = '<Esc>', exec = '<CR>' } },
      }

      -- Keymaps
      local map = vim.keymap.set
      map('n', '<leader>co', '<cmd>Lspsaga outline<CR>', { desc = 'Code [O]utline' })
      map('n', '<leader>cB', '<cmd>Lspsaga winbar_toggle<CR>', { desc = 'Toggle [B]readcrumbs' })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'lspsagafinder',
          'lspsagaoutline',
          'sagarename',
          'sagacodeaction',
          'sagahover',
          'safinder',
          'sdefinition',
          'gitsigns-blame',
          'help',
        },
        callback = function()
          map('n', '<Esc>', '<cmd>close<CR>', { buffer = true, silent = true })
          map('i', '<Esc>', '<cmd>close<CR>', { buffer = true, silent = true })
          map('n', 'q', '<cmd>close<CR>', { buffer = true, silent = true })
        end,
      })
    end,
  },

  { 'brenoprata10/nvim-highlight-colors', opts = { enable_tailwind = true } },
  { 'nvim-treesitter/nvim-treesitter-context', opts = { enable = true, max_lines = 3, separator = nil } },
}
