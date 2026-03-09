local original_colorscheme = nil

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      sections = {
        { section = 'header' },
        { section = 'keys', gap = 1, padding = 1 },
        { section = 'startup' },
      },
    },
    toggle = {
      map = vim.keymap.set,
      which_key = true, -- Show state in which-key menu
      notify = false, -- Show "Toast" notifications
      icon = {
        enabled = ' ',
        disabled = ' ',
      },
      color = {
        enabled = 'green',
        disabled = 'yellow',
      },
      wk_desc = {
        enabled = 'Disable ',
        disabled = 'Enable ',
      },
    },
    scroll = {
      enabled = false,
      animate = {
        duration = { step = 15, total = 250 },
        easing = 'linear',
      },
      spamming = 10, -- Stops animations if you spam keys to keep it responsive
    },
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024, -- 1.5MB threshold
      -- You can add custom setup logic here
      setup = function(ctx)
        -- Disable expensive UI features
        vim.cmd [[NoMatchParen]] -- Stop highlighting matching brackets
        Snacks.util.wo(0, {
          spell = false,
          wrap = false,
          signcolumn = 'no',
          statuscolumn = '',
          list = false,
        })
        -- Notify the user that Bigfile mode is active
        Snacks.notify.warn 'Bigfile detected: Heavy features disabled for performance'
      end,
    },
    notifier = {
      enabled = true,
      timeout = 3000,
      level = vim.log.levels.ERROR, -- Only shows Errors
      style = 'compact', -- "compact" | "minimal" | "fancy"
    },
    quickfile = { enabled = true },
    words = { enabled = true },
    input = { enabled = true },
    lazygit = {
      configure = true,
      win = { style = 'float', border = 'rounded' },
    },
    picker = {
      enabled = true,
      ui_select = true,
    },

    -- Zen Mode Configuration
    zen = {
      toggles = {
        dim = true,
        git_signs = true,
      },
      win = {
        width = 100,
        backdrop = { transparent = true, blend = 50 },
      },
      on_open = function()
        original_colorscheme = vim.g.colors_name
        pcall(vim.cmd, 'colorscheme tokyonight-moon')
        vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
        vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
      end,
      on_close = function()
        if original_colorscheme then
          pcall(vim.cmd, 'colorscheme ' .. original_colorscheme)
        end
      end,
    },
  },
  keys = {
    -- Picker Keymaps
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = '[S]earch [H]elp',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = '[S]earch [K]eymaps',
    },
    {
      '<leader>sf',
      function()
        Snacks.picker.files()
      end,
      desc = '[S]earch [F]iles',
    },
    {
      '<leader>ss',
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = '[S]earch [S]ymbols',
    },
    {
      '<leader>sw',
      function()
        Snacks.picker.grep_word()
      end,
      desc = '[S]earch current [W]ord',
    },
    {
      '<leader>sg',
      function()
        Snacks.picker.grep()
      end,
      desc = '[S]earch by [G]rep',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = '[S]earch [D]iagnostics',
    },
    {
      '<leader>sr',
      function()
        Snacks.picker.resume()
      end,
      desc = '[S]earch [R]esume',
    },
    {
      '<leader>s.',
      function()
        Snacks.picker.recent()
      end,
      desc = '[S]earch Recent Files',
    },
    {
      '<leader><leader>',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[ ] Find existing buffers',
    },
    {
      '<leader>sm',
      function()
        Snacks.notifier.show_history()
      end,
      desc = '[S]earch [M]essages',
    },
    {
      '<leader>sn',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = '[S]earch [N]eovim files',
    },
    {
      '<leader>st',
      function()
        ---@diagnostic disable-next-line: undefined-field
        Snacks.picker.todo_comments()
      end,
      desc = '[S]earch [T]odos',
    },

    -- Git Keymaps
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'LazyGit',
    },
    {
      '<leader>gl',
      function()
        Snacks.lazygit.log()
      end,
      desc = 'LazyGit Log',
    },
    {
      '<leader>br',
      function()
        Snacks.rename.rename_file()
      end,
      desc = '[B]uffer [R]ename File',
    },
    {
      '<leader>bl',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[B]uffer [L]ist',
    },

    -- Toggle Keymaps
    {
      '<leader>tz',
      function()
        Snacks.zen()
      end,
      desc = 'Toggle [Z]en Mode',
    },
    {
      '<leader>tZ',
      function()
        Snacks.zen.zoom()
      end,
      desc = 'Toggle [Z]oom',
    },
    {
      '<leader>ts',
      function()
        Snacks.toggle.option('spell', { name = 'Spelling' }):toggle()
      end,
      desc = 'Toggle [S]pelling',
    },
    {
      '<leader>tw',
      function()
        Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle()
      end,
      desc = 'Toggle [W]rap',
    },

    {
      '<leader>tn',
      function()
        Snacks.toggle.line_number():toggle()
      end,
      desc = 'Toggle Line [N]umbers',
    },

    {
      '<leader>td',
      function()
        Snacks.toggle.diagnostics():toggle()
      end,
      desc = 'Toggle [D]iagnostics',
    },

    {
      '<leader>th',
      function()
        Snacks.toggle.inlay_hints():toggle()
      end,
      desc = 'Toggle Inlay [H]ints',
    },

    -- The "Fix Word" keymap
    {
      'z=',
      function()
        Snacks.picker.spelling()
      end,
      desc = 'Spelling Suggestions',
    },

    {
      '<leader>gb',
      function()
        Snacks.gitbrowse()
      end,
      desc = '[G]it [B]rowse (Open in Browser)',
    },
    {
      '<leader>gs',
      function()
        Snacks.picker.git_status()
      end,
      desc = '[G]it [S]tatus (Picker)',
    },
    {
      '<leader>gd',
      function()
        Snacks.picker.git_diff()
      end,
      desc = '[G]it [D]iff (Picker)',
    },

    {
      '<leader>tb',
      function()
        Snacks.toggle.line_blame():toggle()
      end,
      desc = '[T]oggle Git [B]lame',
    },

    -- Add this inside your Snacks.nvim 'keys' table
    {
      '<leader>bh',
      function()
        local harpoon = require 'harpoon'
        local items = {}
        -- Harpoon2 stores items in .items
        for _, item in ipairs(harpoon:list().items) do
          table.insert(items, {
            text = item.value,
            file = item.value,
          })
        end

        Snacks.picker {
          title = 'Harpoon',
          items = items,
          format = 'file', -- Uses Snacks' built-in file formatting (icons, colors)
          layout = { preset = 'vscode', preview = true }, -- VSCode style looks great for this
          confirm = function(picker, item)
            picker:close()
            -- Find the index to jump to via Harpoon
            harpoon:list():select(item.idx)
          end,
        }
      end,
      desc = 'Harpoon Picker (Snacks)',
    },
    {
      '<leader>tr',
      function()
        Snacks.toggle.option('conceallevel', { off = 0, on = 2, name = 'Conceal' }):toggle()
      end,
      desc = 'Toggle [R]ender/Conceal',
    },

    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = 'Next Reference',
      mode = { 'n', 't' },
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = 'Prev Reference',
      mode = { 'n', 't' },
    },
  },

  init = function()
    -- [[ Remember Cursor Position ]]
    vim.api.nvim_create_autocmd('BufReadPost', {
      callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
          vim.cmd 'normal! g`"'
        end
      end,
    })

    -- This overrides the default notification behavior
    vim.notify = function(msg, level, opts)
      local severity = level or vim.log.levels.INFO

      -- If it's an ERROR, use the Snacks Floating Notifier
      if severity >= vim.log.levels.ERROR then
        require('snacks').notifier.notify(msg, severity, opts)
      else
        -- For everything else (Info, Warn, Toggles), echo to the bottom
        -- Using schedule ensures it doesn't flicker during heavy UI tasks
        vim.schedule(function()
          -- 'None' uses default text color; 'WarningMsg' would make warnings yellow
          local hl = severity == vim.log.levels.WARN and 'WarningMsg' or 'None'
          vim.api.nvim_echo({ { msg, hl } }, false, {})
        end)
      end
    end
    -- [[ Writing Mode Logic ]]
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'markdown', 'tex', 'txt' },
      callback = function()
        -- Settings
        vim.opt_local.spell = true
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.conceallevel = 2

        -- 1. Movement: Visual line movement for prose
        vim.keymap.set('n', 'j', 'gj', { buffer = true, silent = true })
        vim.keymap.set('n', 'k', 'gk', { buffer = true, silent = true })

        -- 2. Navigation: Jump between spelling errors
        vim.keymap.set('n', ']s', ']s', { buffer = true, desc = 'Next Misspelling' })
        vim.keymap.set('n', '[s', '[s', { buffer = true, desc = 'Prev Misspelling' })

        -- 3. Action: Add word to dictionary (zg) but with a leader key for convenience
        vim.keymap.set('n', '<leader>sa', 'zg', { buffer = true, desc = '[S]pell [A]dd word' })
      end,
    })
  end,
}
