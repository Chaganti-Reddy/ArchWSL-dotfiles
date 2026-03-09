-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  { 'wakatime/vim-wakatime', lazy = false },
  {
    'mg979/vim-visual-multi',
    init = function()
      -- Map Ctrl-d to match VS Code
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Subword Under'] = '<C-d>',
      }
    end,
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
    'kkoomen/vim-doge',
    -- Build step ensures the generator is ready
    build = ':call doge#install()',
    event = 'BufReadPost', -- Load when you open a file
    config = function()
      -- 1. Basic Settings
      vim.g.doge_doc_standard_python = 'google' -- Options: 'google', 'numpy', 'reST'
      vim.g.doge_doc_standard_javascript = 'jsdoc'
      vim.g.doge_doc_standard_typescript = 'tsdoc'

      -- 2. Mapping Workflow
      -- This makes it so you can Tab/S-Tab through the placeholders in the docstring
      vim.g.doge_mapping_workflow = 1

      -- 3. Keybindings
      -- Generate documentation
      vim.keymap.set('n', '<leader>gD', '<Plug>(doge-generate)', { desc = '[G]enerate [D]ocumentation' })

      -- These allow you to jump between the empty parts of the comment to fill them in
      -- vim.keymap.set('n', '<Tab>', '<Plug>(doge-next-placeholder)', { desc = 'Next placeholder' })
      -- vim.keymap.set('n', '<S-Tab>', '<Plug>(doge-prev-placeholder)', { desc = 'Previous placeholder' })
      -- vim.keymap.set('i', '<Tab>', '<Plug>(doge-next-placeholder)', { desc = 'Next placeholder' })
      -- vim.keymap.set('i', '<S-Tab>', '<Plug>(doge-prev-placeholder)', { desc = 'Previous placeholder' })
    end,
  },
}
