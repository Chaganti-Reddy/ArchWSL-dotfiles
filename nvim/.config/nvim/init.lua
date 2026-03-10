-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winblend = 0
vim.o.pumblend = 0
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- [[ Basic Keymaps ]]

-- Clear highlights and close floats on <Esc>
vim.keymap.set('n', '<Esc>', function()
  vim.cmd 'nohlsearch'
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= '' then vim.api.nvim_win_close(win, false) end
    end
  end
end, { desc = 'Clear highlights and close floats' })

-- [[ Visual Mode Smart Escape ]]
vim.keymap.set('v', '<Esc>', function()
  local mark = vim.api.nvim_buf_get_mark(0, 'z')
  if mark[1] > 0 then
    vim.api.nvim_buf_set_mark(0, 'z', 0, 0, {})
    return '<Esc>`z'
  end
  return '<Esc>'
end, { expr = true })

vim.keymap.set('n', 'yY', ':%y+<CR>', { desc = 'Yank [A]ll to clipboard' })
vim.keymap.set('n', '<C-a>', ':normal! mzggVG<CR>', { desc = 'Select [A]ll' })

-- Return to cursor after yanking in Visual Mode
vim.keymap.set('v', 'y', 'y`z', { desc = 'Yank and return to mark' })
vim.keymap.set('v', 'Y', 'Y`z', { desc = 'Yank line and return to mark' })

-- Move lines
local opts = {}
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', opts)
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', opts)
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', opts)
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', opts)
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", opts)
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", opts)
vim.keymap.set('v', '<A-Down>', ":m '>+1<CR>gv=gv", opts)
vim.keymap.set('v', '<A-Up>', ":m '<-2<CR>gv=gv", opts)

-- Save file
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })

-- Fix [A]ll [I]ndent
vim.keymap.set('n', '<leader>cI', function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd 'normal! gg=G'
  vim.api.nvim_win_set_cursor(0, pos)
  print 'File auto-indented!'
end, { desc = '[I]ndent File' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Stay in visual mode after indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('n', '<', '<<')
vim.keymap.set('n', '>', '>>')

-- Search for selected text in visual mode
vim.keymap.set('v', '*', [[y/\V<C-R>=escape(@", '/\')<CR><CR>]])
vim.keymap.set('v', '#', [[y?\V<C-R>=escape(@", '?\')<CR><CR>]])

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Delete/Change without yanking into clipboard
vim.keymap.set({ 'n', 'v' }, 'x', '"_x')
vim.keymap.set({ 'n', 'v' }, 'X', '"_X')
vim.keymap.set('v', '<Del>', '"_d')
vim.keymap.set({ 'n', 'v' }, '<leader>cd', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set({ 'n', 'v' }, '<leader>cc', '"_c', { desc = 'Change without yanking' })

-- Paste over selected text WITHOUT losing clipboard
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste over without overwriting clipboard' })

-- CTRL-BACKSPACE / CTRL-DELETE
vim.keymap.set('n', '<C-BS>', '"_db')
vim.keymap.set('n', '<C-Del>', '"_dw')
vim.keymap.set('i', '<C-BS>', '<C-o>"_db')
vim.keymap.set('i', '<C-Del>', '<C-o>"_dw')
vim.keymap.set('i', '<C-H>', '<C-o>"_db')

-- Smart dd: don't yank empty lines
vim.keymap.set('n', 'dd', function()
  if vim.api.nvim_get_current_line():match '^%s*$' then
    return '"_dd'
  else
    return 'dd'
  end
end, { expr = true, desc = "Smart dd: don't yank empty lines" })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- [[ Smart Commenting ]]
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-_>', 'gc', { remap = true, desc = 'Toggle comment' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- Buffer Navigation
vim.keymap.set('n', '[b', '<cmd>bprev<CR>', { desc = 'Previous Buffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { desc = 'Next Buffer' })

-- Buffer management
vim.keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = '[B]uffer [D]elete' })
vim.keymap.set('n', '<leader>bD', function() require('mini.bufremove').delete(0, true) end, { desc = '[B]uffer [D]elete Force' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<CR>', { desc = '[B]uffer [N]ext' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprev<CR>', { desc = '[B]uffer [P]revious' })
vim.keymap.set('n', '<leader>bb', '<cmd>e #<CR>', { desc = '[B]uffer [S]witch to Last' })
vim.keymap.set('n', '<leader>bl', '<leader><leader>', { desc = '[B]uffer [L]ist', remap = true })

-- [[ Split Management ]]
vim.keymap.set('n', '<leader>\\', '<cmd>vsplit<CR>', { desc = 'Split Vertical' })
vim.keymap.set('n', '<leader>\\-', '<cmd>split<CR>', { desc = 'Split Horizontal' })
vim.keymap.set('n', '<leader>\\=', '<C-w>=', { desc = 'Equalize Splits' })
vim.keymap.set('n', '<leader>\\x', '<cmd>close<CR>', { desc = 'Close Split' })
vim.keymap.set('n', '<leader>\\o', '<cmd>only<CR>', { desc = 'Close Other Splits' })
vim.keymap.set('n', '<leader>\\h', '<cmd>vertical resize -2<CR>', { desc = 'Shrink Width' })
vim.keymap.set('n', '<leader>\\l', '<cmd>vertical resize +2<CR>', { desc = 'Grow Width' })
vim.keymap.set('n', '<leader>\\k', '<cmd>resize +2<CR>', { desc = 'Grow Height' })
vim.keymap.set('n', '<leader>\\j', '<cmd>resize -2<CR>', { desc = 'Shrink Height' })

-- File operations
vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files { cwd = vim.fn.expand '%:p:h' } end, { desc = '[F]ind [F]iles (file dir)' })
vim.keymap.set('n', '<leader>fp', function() Snacks.picker.files { cwd = Snacks.git.get_root() } end, { desc = '[F]ind [F]iles (project)' })
vim.keymap.set('n', '<leader>fr', function() Snacks.picker.recent() end, { desc = '[F]ind [R]ecent' })
vim.keymap.set('n', '<leader>fF', function() Snacks.picker.files() end, { desc = '[F]ind [F]iles (cwd)' })
vim.keymap.set('n', '<leader>fg', function() Snacks.picker.grep { cwd = vim.fn.expand '%:p:h' } end, { desc = '[F]ind by [G]rep (file dir)' })
vim.keymap.set('n', '<leader>fw', function() Snacks.picker.grep_word() end, { desc = '[F]ind current [W]ord' })
vim.keymap.set('n', '<leader>fn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = '[F]ind [N]eovim files' })

-- [[ Basic Autocommands ]]

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
require('lazy').setup({
  { 'NMAC427/guess-indent.nvim', opts = {} },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      delay = 0,
      preset = 'helix',
      win = {
        border = 'rounded',
        padding = { 1, 2 },
      },
      icons = {
        mappings = vim.g.have_nerd_font,
        breadcrumb = '»',
        separator = '➜',
        group = '+',
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>s', group = '[S]earch', icon = ' ' },
        { '<leader>t', group = '[T]oggles', icon = ' ' },
        { '<leader>g', group = '[G]it', icon = '󰊢 ' },
        { '<leader>gh', group = 'Git [H]unk', mode = { 'n', 'v' }, icon = '󰊠 ' },
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' }, icon = ' ' },
        { '<leader>f', group = '[F]ile', icon = '󰈔 ' },
        { '<leader>b', group = '[B]uffer', icon = '󰓩 ' },
        { '<leader>d', group = '[D]ebug', icon = '󰃤 ' },
        { '<leader>e', desc = '[E]xplorer (current file)', icon = '󰙅 ' },
        { '<leader>E', desc = '[E]xplorer (cwd)', icon = '󰙅 ' },
        { '<leader>\\', group = '[\\]Splits', icon = '󱂬 ' },
        { '<leader>h', group = '[H]arpoon', icon = '󱡀 ' },
      },
    },
  },

  -- LSP Plugins
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim', ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
      'SmiteshP/nvim-navic',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>cr', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'v' })
          map('grd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
          map('grr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
          map('gri', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', function() Snacks.picker.lsp_symbols() end, 'Open Document Symbols')
          map('gW', function() Snacks.picker.lsp_workspace_symbols() end, 'Open Workspace Symbols')
          map('grt', function() Snacks.picker.lsp_type_definitions() end, '[G]oto [T]ype Definition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then require('nvim-navic').attach(client, event.buf) end
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many', header = '', prefix = '' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      ---@type table<string, vim.lsp.Config>
      local servers = {
        clangd = {
          capabilities = { offsetEncoding = { 'utf-16' } },
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        stylua = {},
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                  '${3rd}/luv/library',
                  '${3rd}/busted/library',
                }),
              },
            })
          end,
          settings = { Lua = {} },
        },
        jsonls = {},
        yamlls = {},
        bashls = {},
        dockerls = {},
        docker_compose_language_service = {},
        -- texlab = {
        --   settings = {
        --     texlab = {
        --       build = {
        --         onSave = true, -- Auto build on save
        --         forwardSearchAfter = true,
        --       },
        --       forwardSearch = {
        --         executable = 'okular',
        --         args = { '--unique', 'file:%p#src:%l%f' },
        --       },
        --       chktex = { onOpenAndSave = true, onEdit = true },
        --       diagnosticsDelay = 200,
        --       diagnostics = {
        --         ignoredPatterns = {}, -- Add patterns here to ignore specific warnings
        --         showExactlyOnce = true,
        --       },
        --       latexformatter = 'latexindent',
        --       formatterLineLength = 80,
        --       bibtexFormatter = 'texlab',
        --       -- Add completion for references and citations
        --       completion = {
        --         matcher = 'fuzzy',
        --         executable = 'latexmk',
        --         args = { '-pdf', '-ln', '-f', '%f' },
        --         onSave = true,
        --       },
        --       -- This allows texlab to suggest packages you haven't even typed yet
        --       experimental = {
        --         citationCommands = { 'cite', 'parencite' },
        --         labelReferenceCommands = { 'ref', 'eqref' },
        --       },
        --     },
        --   },
        -- },
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua',
        'ruff',
        'eslint_d',
        'stylelint',
        'htmlhint',
        'markdownlint',
        'codelldb',
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>cf',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return { timeout_ms = 500, lsp_format = 'fallback' }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        rust = { 'rustfmt' },
        python = { 'ruff_format', 'ruff_organize_imports' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        css = { 'prettierd' },
        html = { 'prettierd' },
        markdown = { 'prettierd' },
        tex = { 'latexindent' },
        bib = { 'bibtex-tidy' },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_lua').lazy_load {
                paths = { vim.fn.stdpath 'config' .. '/lua/custom/snippets' },
              }
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
        opts = {},
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        list = {
          selection = { preselect = true, auto_insert = false },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
          window = { border = 'rounded', max_width = 60, max_height = 20 },
        },
        ghost_text = { enabled = true },
        menu = {
          scrollbar = false,
          draw = {
            columns = {
              { 'kind_icon' },
              { 'label', 'label_description', gap = 1 },
              { 'kind' },
            },
            components = {
              kind = { highlight = 'Comment' },
            },
          },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev', 'buffer' },
        providers = {
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      enabled = function() return true end,
      signature = { enabled = true, window = { border = 'rounded' } },
    },
  },

  { -- Colorscheme
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      local transparent = true

      require('tokyonight').setup {
        transparent = transparent,
        styles = {
          comments = { italic = false },
          sidebars = 'transparent',
          floats = 'transparent',
        },
      }

      vim.cmd.colorscheme 'tokyonight-night'

      vim.keymap.set('n', '<leader>tt', function()
        transparent = not transparent
        require('tokyonight').setup {
          transparent = transparent,
          styles = {
            comments = { italic = true },
            sidebars = transparent and 'transparent' or 'dark',
            floats = transparent and 'transparent' or 'dark',
          },
        }
        vim.cmd.colorscheme 'tokyonight-night'
      end, { desc = '[T]oggle [T]ransparency' })
    end,
  },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  { -- mini.nvim collection
    'nvim-mini/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()
      require('mini.pairs').setup {
        modes = { insert = true, command = false, terminal = false },
        mappings = {
          ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
          ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
          ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
          [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
          [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
          ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
          ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
          ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
          ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
        },
      }

      -- Rust: disable ' pairing entirely (lifetimes: 'a, 'static, 'b: 'a)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        callback = function()
          vim.b.minipairs_disable = false -- keep pairs active
          -- Override ' to just insert a single quote in rust
          vim.keymap.set('i', "'", "'", { buffer = true, noremap = true })
        end,
      })

      require('mini.bufremove').setup()

      require('mini.tabline').setup {
        show_icons = true,
        format = nil,
        -- Where to show tabpage section in case of multiple vim tabpages.
        -- One of 'left', 'right', 'none'.
        tabpage_section = 'left',
      }

      local sl = require 'mini.statusline'

      sl.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = sl.section_mode { trunc_width = 120 }
            local git = sl.section_git { trunc_width = 90 }
            local diff = sl.section_diff { trunc_width = 90 }
            local diagnostics = sl.section_diagnostics { trunc_width = 90 }
            local lsp = sl.section_lsp { trunc_width = 100 }
            local filename = sl.section_filename { trunc_width = 140 }
            local fileinfo = sl.section_fileinfo { trunc_width = 120 }

            return sl.combine_groups {
              { hl = mode_hl, strings = { mode } },
              { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=',
              { hl = 'MiniStatuslineFileinfo', strings = { lsp, fileinfo } },
              { hl = mode_hl, strings = { '%2l:%-2v', '%3p%%' } },
            }
          end,
          inactive = function()
            local filename = sl.section_filename { trunc_width = 140 }
            return sl.combine_groups {
              { hl = 'MiniStatuslineFilename', strings = { filename } },
            }
          end,
        },
      }

      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved' }, {
        callback = function()
          if vim.api.nvim_win_get_config(0).relative ~= '' then return end
          local ft = vim.bo.filetype
          if ft == 'snacks_dashboard' or ft == '' then
            vim.wo.winbar = ''
          elseif require('nvim-navic').is_available() then
            vim.wo.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
          else
            vim.wo.winbar = ''
          end
        end,
      })

      require('nvim-navic').setup {
        icons = {
          File = ' ',
          Module = ' ',
          Namespace = ' ',
          Package = ' ',
          Class = ' ',
          Method = ' ',
          Property = ' ',
          Field = ' ',
          Constructor = ' ',
          Enum = ' ',
          Interface = ' ',
          Function = ' ',
          Variable = ' ',
          Constant = ' ',
          String = ' ',
          Number = ' ',
          Boolean = ' ',
          Array = ' ',
          Object = ' ',
          Key = ' ',
          Null = ' ',
          EnumMember = ' ',
          Struct = ' ',
          Event = ' ',
          Operator = ' ',
          TypeParameter = ' ',
        },
        lsp = {
          auto_attach = false,
          preference = nil,
        },
        highlight = false,
        separator = ' > ',
        depth_limit = 0,
        depth_limit_indicator = '..',
        safe_output = true,
        lazy_update_context = false,
        click = false,
        format_text = function(text) return text end,
      }
    end,
  },

  { -- Multi Edit like VSCode ctrl+d
    'mg979/vim-visual-multi',
    branch = 'master',
    init = function()
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Subword Under'] = '<C-d>',
      }
    end,
  },

  {
    'mrcjkb/rustaceanvim',
    version = '^6',
    lazy = false,
    ft = { 'rust' },
    init = function()
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

      vim.g.rustaceanvim = {
        server = {
          status_notify_level = false,
          on_attach = function(_, bufnr)
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

            require('which-key').add {
              { '<leader>r', group = '[R]ust', icon = '󱘗 ', buffer = bufnr },
              { '<leader>rm', group = '[R]ust [M]ove', icon = ' ', buffer = bufnr },
            }

            local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc }) end

            map('<leader>rr', '<cmd>RustLsp runnables<CR>', '[R]unnables')
            map('<leader>rd', '<cmd>RustLsp debuggables<CR>', '[D]ebuggables')
            map('<leader>rt', '<cmd>RustLsp testables<CR>', '[T]estables')
            map('<leader>re', '<cmd>RustLsp expandMacro<CR>', '[E]xpand Macro')
            map('<leader>rh', '<cmd>RustLsp hover actions<CR>', '[H]over Actions')
            map('<leader>ra', '<cmd>RustLsp codeAction<CR>', '[A]ction')
            map('<leader>rx', '<cmd>RustLsp explainError<CR>', 'E[x]plain Error')
            map('<leader>rg', '<cmd>RustLsp crateGraph<CR>', '[G]raph Crates')
            map('<leader>rn', vim.lsp.buf.rename, '[N]ame Rename')
            map('<leader>rmu', function() vim.cmd.RustLsp { 'moveItem', 'up' } end, '[M]ove Item [U]p')
            map('<leader>rmd', function() vim.cmd.RustLsp { 'moveItem', 'down' } end, '[M]ove Item [D]own')
          end,
          default_settings = {
            ['rust-analyzer'] = {
              checkOnSave = { command = 'clippy', enable = true },
              diagnostics = { enable = true, refreshSupport = false },
              cargo = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
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
  },

  { -- Treesitter
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    config = function()
      local parsers = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'rust',
        'json',
        'javascript',
        'java',
        'javadoc',
        'python',
        'typescript',
        'tsx',
        'yaml',
      }
      require('nvim-treesitter').install(parsers)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end
          if not vim.treesitter.language.add(language) then return end
          vim.treesitter.start(buf, language)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  require 'kickstart.plugins.gitsigns',
  require 'custom.plugins.terminal',
  require 'custom.plugins.aerial',
  require 'custom.plugins.snacks',
  require 'custom.plugins.init',
  -- require 'kickstart.plugins.debug',
  -- require 'custom.plugins.vimtex',
}, { ---@diagnostic disable-line: missing-fields
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.keymap.set('n', '<leader>co', '<cmd>AerialToggle!<CR>', { desc = 'Code [O]utline' })

-- vim: ts=2 sts=2 sw=2 et
