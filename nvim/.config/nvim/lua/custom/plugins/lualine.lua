return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'theprimeagen/harpoon',
  },
  config = function()
    local lualine = require 'lualine'

    -- 1. Macro Recording (Same as before)
    local function macro_recording()
      local reg = vim.fn.reg_recording()
      if reg == '' then
        return ''
      end
      return '󰑋  REC @' .. reg
    end

    -- 2. Harpoon 2 Status (Same as before)
    local function harpoon_status()
      local harpoon = require 'harpoon'
      local list = harpoon:list()
      local current_file = vim.api.nvim_buf_get_name(0)
      local root = list.config:get_root_dir()
      for i, item in ipairs(list.items) do
        local full_path = root .. '/' .. item.value
        if full_path == current_file then
          return '󰀱 ' .. i
        end
      end
      return ''
    end

    -- 3. Treesitter Status
    local function treesitter_status()
      local b = vim.api.nvim_get_current_buf()
      if vim.treesitter.highlighter.active[b] then
        return ' TS'
      end
      return ''
    end

    -- 4. Mini.nvim Style Diagnostics Statistics
    -- Mimics the "E1 W2" format, only showing non-zero counts
    local function diagnostic_stats()
      -- Use modern Neovim API for efficiency
      local count = vim.diagnostic.count and vim.diagnostic.count(0) or {}
      local res = {}
      local levels = {
        { id = vim.diagnostic.severity.ERROR, sym = 'E' },
        { id = vim.diagnostic.severity.WARN, sym = 'W' },
        { id = vim.diagnostic.severity.INFO, sym = 'I' },
        { id = vim.diagnostic.severity.HINT, sym = 'H' },
      }
      for _, level in ipairs(levels) do
        local n = count[level.id] or 0
        if n > 0 then
          table.insert(res, level.sym .. n)
        end
      end
      return table.concat(res, ' ')
    end

    lualine.setup {
      options = {
        theme = 'rose-pine',
        -- ROUNDED PILL LOOK
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        globalstatus = true,
        disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'snacks_dashboard' } },
      },
      sections = {
        -- LEFT: Mode and Git
        lualine_a = {
          { 'mode', separator = { left = '' }, right_padding = 2 },
        },
        lualine_b = {
          'branch',
          { 'diff', symbols = { added = '+', modified = '~', removed = '-' } },
        },
        lualine_c = {
          { 'filename', path = 1, file_status = true },
          { harpoon_status, color = { fg = '#7aa2f7' } },
        },

        -- RIGHT: Macros, TS, Mini-style Diagnostics, and Tech Specs
        lualine_x = {
          { macro_recording, color = { fg = '#ff9e64', gui = 'bold' } },
          { treesitter_status, color = { fg = '#9ece6a' } },
          -- The new mini-style diagnostics section
          { diagnostic_stats, color = { fg = '#bb9af7', gui = 'bold' } },
        },
        lualine_y = {
          'filetype',
          'encoding',
          'fileformat',
        },
        lualine_z = {
          { 'location', separator = { right = '' }, left_padding = 2 },
        },
      },
    }

    -- Auto-refresh logic for macros
    vim.api.nvim_create_autocmd('RecordingEnter', {
      callback = function()
        lualine.refresh()
      end,
    })
    vim.api.nvim_create_autocmd('RecordingLeave', {
      callback = function()
        vim.defer_fn(function()
          lualine.refresh()
        end, 50)
      end,
    })
  end,
}
