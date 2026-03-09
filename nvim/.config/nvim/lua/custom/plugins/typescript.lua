return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      settings = {
        -- Extraordinary: Automatically add missing imports and remove unused ones
        expose_as_code_action = 'all',
        complete_function_calls = true,
      },
    },
  },
  -- Auto-close and auto-rename HTML tags
  {
    'windwp/nvim-ts-autotag',
    opts = {},
  },
}
