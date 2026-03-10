return {
  'stevearc/aerial.nvim',
  lazy = true, -- Corrected from lazy_load
  -- Use 'keys' to trigger loading. This prevents the "nil" error
  -- because the plugin will definitely be loaded when you toggle it.
  keys = {
    { '<leader>ta', '<cmd>AerialToggle!<CR>', desc = 'Aerial (Side)' },
    { '<leader>tA', '<cmd>AerialNavToggle<CR>', desc = 'Aerial (Float)' },
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    -- Priority of backends. Treesitter is usually best for most files.
    backends = { 'treesitter', 'lsp', 'markdown', 'man' },

    layout = {
      min_width = 30,
      default_direction = 'right',
    },

    -- Set keymaps only when aerial is active in a buffer
    on_attach = function(bufnr)
      -- Jump forwards/backwards with '{' and '}'
      vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', { buffer = bufnr, desc = 'Aerial Prev' })
      vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', { buffer = bufnr, desc = 'Aerial Next' })
    end,
  },
}
