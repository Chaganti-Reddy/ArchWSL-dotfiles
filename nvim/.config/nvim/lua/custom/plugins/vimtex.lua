return {
  {
    'lervag/vimtex',
    lazy = false,
    init = function()
      -- 1. SERVER START (For Inverse Search)
      if vim.v.servername == '' then
        vim.fn.serverstart '/tmp/nvimsocket'
      end

      -- 2. VIEWER SETUP (Fixed for Okular)
      -- Using 'general' method is more stable for Okular on Linux
      vim.g.vimtex_view_method = 'general'
      vim.g.vimtex_view_general_viewer = 'okular'
      vim.g.vimtex_view_general_options = '--unique file:@pdf#src:@line@tex'

      -- 3. COMPILER SETUP
      vim.g.vimtex_compiler_latexmk = {
        options = {
          '-shell-escape',
          '-verbose',
          '-file-line-error',
          '-synctex=1',
          '-interaction=nonstopmode',
        },
      }

      -- 4. MISC SETTINGS
      vim.g.vimtex_mappings_enabled = 0
      vim.g.vimtex_quickfix_mode = 0
      vim.g.vimtex_syntax_conceal = {
        additions = 1,
        greek = 1,
        math_bounds = 1,
        math_delimiters = 1,
        math_fracs = 1,
        math_symbols = 1,
        sections = 1,
        styles = 1,
      }

      vim.g.vimtex_syntax_conceal_cchar_pre = ' '
    end,

    config = function()
      -- WHICH-KEY (Buffer-local for LaTeX only)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'tex',
        callback = function()
          local wk = require 'which-key'
          wk.add {
            { '<leader>l', group = '[L]aTeX', buffer = true, icon = '󰈙 ' },
            { '<leader>lc', '<cmd>VimtexClean<CR>', desc = 'Clean Aux Files', buffer = true },
            { '<leader>le', '<cmd>VimtexErrors<CR>', desc = 'Show Errors', buffer = true },
            { '<leader>ll', '<cmd>VimtexCompile<CR>', desc = 'Toggle Compile', buffer = true },
            { '<leader>lt', '<cmd>VimtexTocToggle<CR>', desc = 'Toggle TOC', buffer = true },
            { '<leader>lv', '<cmd>VimtexView<CR>', desc = 'View PDF (Okular)', buffer = true },
          }

          -- UNIVERSAL K (LaTeX Edition)
          vim.keymap.set('n', 'K', function()
            -- 1. Try Lspsaga Hover (Floating Window)
            -- This will show citations, labels, and command previews in a float.
            local ok, _ = pcall(vim.cmd, 'Lspsaga hover_doc')

            -- 2. Fallback to standard LSP hover
            if not ok then
              vim.lsp.buf.hover()
            end

            -- Note: We REMOVED VimtexDoc from here so it stops opening the browser.
          end, { desc = 'LaTeX: Hover Documentation (Floating)', buffer = true })

          -- 3. Dedicated key for the "Big PDF Manuals"
          -- Only press this when you actually want to read the 50-page browser/PDF docs.
          vim.keymap.set('n', '<leader>ld', '<cmd>VimtexDoc<CR>', { desc = 'LaTeX: Open PDF/Browser Manual', buffer = true })
        end,
      })

      -- Ensure snippets are available for plaintex
      require('luasnip').filetype_extend('plaintex', { 'tex' })
    end,
  },
}
