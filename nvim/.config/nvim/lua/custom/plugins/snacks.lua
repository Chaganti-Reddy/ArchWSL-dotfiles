local original_colorscheme = nil

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      sections = {
        { section = 'header', padding = 1 },
        { section = 'keys', gap = 1, padding = 1 },
        { icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, height = 5, padding = 1 },
        { icon = ' ', title = 'Projects', section = 'projects', indent = 2, height = 5, padding = 1 },
        { section = 'startup', padding = 1 },
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
      spamming = 10,
    },
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024,
      setup = function(ctx)
        vim.cmd [[NoMatchParen]]
        Snacks.util.wo(0, {
          spell = false,
          wrap = false,
          signcolumn = 'no',
          statuscolumn = '',
          list = false,
        })
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
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
      },
    },
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
        if original_colorscheme then pcall(vim.cmd, 'colorscheme ' .. original_colorscheme) end
      end,
    },
  },
  keys = {
    -- Picker
    {
      '<leader>st',
      function() ---@diagnostic disable-next-line: undefined-field
        Snacks.picker.todo_comments()
      end,
      desc = '[S]earch [T]odos',
    },
    { '<leader>sf', function() Snacks.picker.files { cwd = Snacks.git.get_root() } end, desc = '[S]earch [F]iles (project)' },
    { '<leader>sg', function() Snacks.picker.grep { cwd = Snacks.git.get_root() } end, desc = '[S]earch [G]rep (project)' },
    { '<leader>sw', function() Snacks.picker.grep_word { cwd = Snacks.git.get_root() } end, desc = '[S]earch current [W]ord (project)' },
    { '<leader>s/', function() Snacks.picker.grep { buf = true } end, desc = '[S]earch in Open Files' },
    { '<leader>sF', function() Snacks.picker.files() end, desc = '[S]earch [F]iles' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = '[S]earch [S]ymbols' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>sm', function() Snacks.notifier.show_history() end, desc = '[S]earch [M]essages' },
    { '<leader>sW', function() Snacks.picker.grep_word() end, desc = '[S]earch current [W]ord' },
    { '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
    { '<leader>sG', function() Snacks.picker.grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>st', function() Snacks.picker.todo_comments() end, desc = '[S]earch [T]odos' },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files' },
    { '<leader><leader>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },

    -- Git
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'LazyGit' },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'LazyGit Log' },
    { '<leader>gb', function() Snacks.gitbrowse() end, desc = '[G]it [B]rowse (Open in Browser)' },
    { '<leader>gs', function() Snacks.picker.git_status() end, desc = '[G]it [S]tatus (Picker)' },
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = '[G]it [D]iff (Picker)' },

    -- Buffer
    { '<leader>br', function() Snacks.rename.rename_file() end, desc = '[B]uffer [R]ename File' },
    { '<leader>bl', function() Snacks.picker.buffers() end, desc = '[B]uffer [L]ist' },
    {
      '<leader>bh',
      function()
        local ok, harpoon = pcall(require, 'harpoon')
        if not ok then
          vim.notify('Harpoon not installed', vim.log.levels.WARN)
          return
        end
        local items = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(items, { text = item.value, file = item.value })
        end
        Snacks.picker {
          title = 'Harpoon',
          items = items,
          format = 'file',
          layout = { preset = 'vscode', preview = true },
          confirm = function(picker, item)
            picker:close()
            harpoon:list():select(item.idx)
          end,
        }
      end,
      desc = 'Harpoon Picker',
    },

    -- Toggles
    { '<leader>tz', function() Snacks.zen() end, desc = 'Toggle [Z]en Mode' },
    { '<leader>tZ', function() Snacks.zen.zoom() end, desc = 'Toggle [Z]oom' },
    { '<leader>ts', function() Snacks.toggle.option('spell', { name = 'Spelling' }):toggle() end, desc = 'Toggle [S]pelling' },
    { '<leader>tw', function() Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle() end, desc = 'Toggle [W]rap' },
    { '<leader>tn', function() Snacks.toggle.line_number():toggle() end, desc = 'Toggle Line [N]umbers' },
    { '<leader>th', function() Snacks.toggle.inlay_hints():toggle() end, desc = 'Toggle Inlay [H]ints' },
    { '<leader>tb', function() Snacks.toggle.line_blame():toggle() end, desc = '[T]oggle Git [B]lame' },
    { '<leader>tr', function() Snacks.toggle.option('conceallevel', { off = 0, on = 2, name = 'Conceal' }):toggle() end, desc = 'Toggle [R]ender/Conceal' },

    -- Spelling suggestions
    { 'z=', function() Snacks.picker.spelling() end, desc = 'Spelling Suggestions' },

    -- Word reference jumps
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = { 'n', 't' } },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = { 'n', 't' } },
  },

  init = function()
    -- Remember cursor position on file open
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = vim.api.nvim_create_augroup('restore-cursor', { clear = true }),
      callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then vim.cmd 'normal! g`"' end
      end,
    })

    -- Custom notify: errors float, everything else echoes to cmdline
    vim.notify = function(msg, level, opts)
      local severity = level or vim.log.levels.INFO
      if severity >= vim.log.levels.ERROR then
        require('snacks').notifier.notify(msg, severity, opts)
      else
        vim.schedule(function()
          local hl = severity == vim.log.levels.WARN and 'WarningMsg' or 'None'
          vim.api.nvim_echo({ { msg, hl } }, false, {})
        end)
      end
    end

    -- Writing mode: markdown, tex, txt
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'markdown', 'tex', 'txt' },
      callback = function()
        vim.opt_local.spell = true
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.conceallevel = 2

        vim.keymap.set('n', 'j', 'gj', { buffer = true, silent = true })
        vim.keymap.set('n', 'k', 'gk', { buffer = true, silent = true })
        vim.keymap.set('n', ']s', ']s', { buffer = true, desc = 'Next Misspelling' })
        vim.keymap.set('n', '[s', '[s', { buffer = true, desc = 'Prev Misspelling' })
        vim.keymap.set('n', '<leader>sa', 'zg', { buffer = true, desc = '[S]pell [A]dd word' })
      end,
    })
  end,
}
