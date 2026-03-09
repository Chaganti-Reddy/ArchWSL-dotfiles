return {
  'mrcjkb/rustaceanvim',
  version = '^6',
  lazy = false,
  init = function()
    -- 1. Debugger Path Logic (Keep as is)
    local mason_path = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/'
    local extension_path = mason_path .. 'extension/'
    local codelldb_path = extension_path .. 'adapter/codelldb'
    local liblldb_path = extension_path .. 'lldb/lib/liblldb'

    local sysname = vim.uv.os_uname().sysname
    if sysname:find 'Windows' then
      codelldb_path = extension_path .. 'adapter\\codelldb.exe'
      liblldb_path = extension_path .. 'bin\\liblldb.dll'
    elseif sysname:find 'Darwin' then
      liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
    else
      liblldb_path = extension_path .. 'lldb/lib/liblldb.so'
    end

    -- 2. Configuration
    vim.g.rustaceanvim = {
      server = {
        -- It silences the popups when Cargo fails (standalone mode),
        -- allowing us to keep the check enabled for projects.
        status_notify_level = false,

        on_attach = function(client, bufnr)
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

          local ok, wk = pcall(require, 'which-key')
          if ok then
            wk.add { { '<leader>cr', group = '[R]ust Actions', mode = 'n' } }
          end

          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
          end

          -- Submap Keybinds
          map('<leader>crr', '<cmd>RustLsp runnables<CR>', '[R]un')
          map('<leader>crd', '<cmd>RustLsp debuggables<CR>', '[D]ebug')
          map('<leader>crt', '<cmd>RustLsp testables<CR>', '[T]est')
          map('<leader>cre', '<cmd>RustLsp expandMacro<CR>', '[E]xpand Macro')
          map('<leader>crh', '<cmd>RustLsp explainError<CR>', '[H]elp (Explain)')
          map('<leader>crg', '<cmd>RustLsp crateGraph<CR>', '[G]raph View')
          map('<leader>crn', vim.lsp.buf.rename, '[N]ame (Rename)')
          map('<leader>ca', '<cmd>RustLsp codeAction<CR>', '[A]ction (Rust)')
        end,

        default_settings = {
          ['rust-analyzer'] = {
            -- ENABLE checkOnSave globally.
            checkOnSave = {
              command = 'clippy',
              enable = true,
            },
            -- Ensure diagnostics are fully enabled
            diagnostics = {
              enable = true,
              refreshSupport = false, -- Sometimes helps with diagnostic flickering
            },
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              runBuildScripts = true,
            },
            procMacro = {
              enable = true,
              ignored = {
                ['async-trait'] = { 'async_trait' },
                ['napi-derive'] = { 'napi' },
                ['async-recursion'] = { 'async_recursion' },
              },
            },
            inlayHints = {
              bindingModeHints = { enable = true },
              chainingHints = { enable = true },
              closingBraceHints = { enable = true, minLines = 25 },
              closureReturnTypeHints = { enable = 'always' },
              lifetimeElisionHints = { enable = 'always' },
              parameterHints = { enable = true },
              typeHints = { enable = true },
            },
          },
        },
      },
      dap = (vim.uv.fs_stat(codelldb_path) ~= nil) and {
        adapter = require('rustaceanvim.config').get_codelldb_adapter(codelldb_path, liblldb_path),
      } or nil,
    }
  end,
}
