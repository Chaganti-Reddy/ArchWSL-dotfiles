-- utils: current buffer dir (detects where your file is)
local function get_buf_dir(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name == '' or name:match '^term://' then
    return vim.uv.cwd()
  end
  return vim.fn.fnamemodify(name, ':p:h')
end

-- tiny helpers
local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_json(path)
  local ok, decoded = pcall(function()
    local f = io.open(path, 'r')
    if not f then
      return nil
    end
    local s = f:read '*a'
    f:close()
    return vim.json.decode(s)
  end)
  return ok and decoded or nil
end

-- Project Command Resolvers
local function npm_script(script, dir)
  local pkg = dir .. '/package.json'
  if exists(pkg) then
    local j = read_json(pkg)
    if j and j.scripts and j.scripts[script] then
      return 'npm run ' .. script
    end
  end
  return nil
end

local function cmake_build_cmd(dir)
  if exists(dir .. '/CMakeLists.txt') then
    return 'cmake -S . -B build && cmake --build build'
  end
  return nil
end

local function make_cmd(target, dir)
  if exists(dir .. '/Makefile') or exists(dir .. '/makefile') then
    return target and ('make ' .. target) or 'make'
  end
  return nil
end

local function cargo_cmd(sub, dir)
  local root = vim.fn.findfile('Cargo.toml', dir .. ';')
  if root ~= '' then
    return 'cargo ' .. (sub or 'run')
  end
  return nil
end

-- Language Runners Table
local runners = {
  python = {
    run = function(path)
      return 'python3 ' .. vim.fn.shellescape(path)
    end,
  },
  javascript = {
    run = function(path, dir)
      return npm_script('start', dir) or ('node ' .. vim.fn.shellescape(path))
    end,
  },
  typescript = {
    run = function(path, dir)
      return npm_script('start', dir) or (exists(dir .. '/tsconfig.json') and 'ts-node ' .. vim.fn.shellescape(path)) or 'tsx ' .. vim.fn.shellescape(path)
    end,
  },
  lua = {
    run = function(path)
      return 'lua ' .. vim.fn.shellescape(path)
    end,
  },
  c = {
    run = function(path, dir)
      local out = vim.fn.fnamemodify(path, ':r')
      return make_cmd(nil, dir)
        or cmake_build_cmd(dir)
        or (string.format('cc %s -O2 -Wall -o %s && %s', vim.fn.shellescape(path), vim.fn.shellescape(out), vim.fn.shellescape(out)))
    end,
  },
  cpp = {
    run = function(path, dir)
      local out = vim.fn.fnamemodify(path, ':r')
      return make_cmd(nil, dir)
        or cmake_build_cmd(dir)
        or (string.format('c++ %s -std=c++20 -O2 -Wall -o %s && %s', vim.fn.shellescape(path), vim.fn.shellescape(out), vim.fn.shellescape(out)))
    end,
  },
  rust = {
    run = function(path, dir)
      local cmd = cargo_cmd('run', dir)
      if cmd then
        return cmd
      end
      local out = vim.fn.fnamemodify(path, ':r')
      local is_win = vim.uv.os_uname().sysname:find 'Windows' ~= nil
      local out_file = is_win and (out .. '.exe') or out
      return string.format('rustc %s -o %s && %s', vim.fn.shellescape(path), vim.fn.shellescape(out_file), vim.fn.shellescape(out_file))
    end,
  },
}

-- Isolated Runner Logic
local runner_terminal = nil

local function run_in_term(cmd, dir)
  if not cmd or #cmd == 0 then
    vim.notify('No command for this filetype', vim.log.levels.WARN)
    return
  end

  if runner_terminal then
    runner_terminal:shutdown()
  end

  local Terminal = require('toggleterm.terminal').Terminal
  runner_terminal = Terminal:new {
    cmd = cmd,
    dir = dir,
    direction = 'float',
    close_on_exit = false,
    -- Force insert mode every time it opens
    on_open = function(term)
      vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc><Esc>', [[<C-\><C-n>:hide<CR>]], { noremap = true, silent = true })

      vim.schedule(function()
        vim.cmd 'startinsert'
      end)
    end,
    on_close = function()
      runner_terminal = nil
    end,
  }
  runner_terminal:toggle()
end

local last_source_buf = nil

return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      size = 20,
      open_mapping = [[<c-\>]], -- Standard toggleterm behavior for default terminals
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
      direction = 'float',
      float_opts = { border = 'curved' },
    }

    local map = vim.keymap.set

    -- 1. Smart Run (Alt-r)
    map({ 'n', 't' }, '<A-r>', function()
      local current_buf = vim.api.nvim_get_current_buf()

      -- Only update source if we aren't currently in a terminal
      if vim.bo[current_buf].buftype ~= 'terminal' then
        last_source_buf = current_buf
      end

      local source_buf = last_source_buf
      if not source_buf or not vim.api.nvim_buf_is_valid(source_buf) then
        vim.notify('No valid source file to run', vim.log.levels.ERROR)
        return
      end

      -- Auto-save before running
      vim.api.nvim_buf_call(source_buf, function()
        vim.cmd 'silent! w'
      end)

      local path = vim.api.nvim_buf_get_name(source_buf)
      local dir = get_buf_dir(source_buf)
      local ft = vim.bo[source_buf].filetype

      local cmd = (runners[ft] and runners[ft].run) and runners[ft].run(path, dir) or make_cmd(nil, dir) or cargo_cmd('run', dir)

      run_in_term(cmd, dir)
    end, { desc = 'Smart Run: Always Restart' })

    -- 2. Standard Floating/Horizontal Terms (Alt-f / Alt-h)
    -- These will use the default Toggleterm logic and NOT the special Runner Esc mappings
    map({ 'n', 't' }, '<A-f>', function()
      local buf = last_source_buf or vim.api.nvim_get_current_buf()
      require('toggleterm').toggle(1, 0, get_buf_dir(buf), 'float')
    end, { desc = 'Standard Float Term' })

    map({ 'n', 't' }, '<A-h>', function()
      local buf = last_source_buf or vim.api.nvim_get_current_buf()
      require('toggleterm').toggle(2, 15, get_buf_dir(buf), 'horizontal')
    end, { desc = 'Standard Horizontal Term' })
  end,
}
