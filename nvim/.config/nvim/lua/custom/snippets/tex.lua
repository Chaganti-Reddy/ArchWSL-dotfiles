local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local rep = require('luasnip.extras').rep
local d = ls.dynamic_node
local sn = ls.snippet_node

-- Advanced: Context-aware math detection
local function in_math()
  return vim.fn['vimtex#syntax#in_mathzone']() == 1
end

-- Helper for Visual selection wrapping
local get_visual = function(args, parent)
  if #parent.snippet.env.LS_SELECT_RAW > 0 then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else
    return sn(nil, i(1))
  end
end

return {
  -- ==========================================
  -- 1. TEMPLATES & STRUCTURE
  -- ==========================================
  s({ trig = 'template', priority = 2000 }, {
    t { '\\documentclass[12pt]{article}', '' },
    t { '\\usepackage[utf8]{inputenc}', '\\usepackage{amsmath, amssymb, amsthm}', '' },
    t { '\\usepackage{geometry}', '\\geometry{margin=1in}', '' },
    t { '', '\\begin{document}', '' },
    i(0),
    t { '', '\\end{document}' },
  }),

  -- Fast Section
  s('sec', { t '\\section{', i(1), t '}', i(0) }),

  -- ==========================================
  -- 2. VISUAL WRAPPERS (Select text + hit Tab)
  -- ==========================================
  -- Wrap selection in Bold
  s('tbf', { t '\\textbf{', d(1, get_visual), t '}' }),
  -- Wrap selection in Italics
  s('tit', { t '\\textit{', d(1, get_visual), t '}' }),
  -- Wrap selection in Inline Math
  s('mkk', { t '$', d(1, get_visual), t '$' }),

  -- ==========================================
  -- 3. AUTO-EXPANDING MATH (God-Tier Speed)
  -- ==========================================
  -- Quick Inline Math: type 'mk' -> $ $
  s({ trig = 'mk', snippetType = 'autosnippet' }, {
    t '$',
    i(1),
    t '$',
    i(0),
  }),

  -- Quick Display Math: type 'dm' -> \[ \]
  s({ trig = 'dm', snippetType = 'autosnippet' }, {
    t { '\\[', '\t' },
    i(1),
    t { '', '\\]' },
    i(0),
  }),

  -- Powers/Subscripts (only in math)
  s({ trig = 'sr', snippetType = 'autosnippet' }, { t '^2' }, { condition = in_math }),
  s({ trig = 'cb', snippetType = 'autosnippet' }, { t '^3' }, { condition = in_math }),
  s({ trig = 'rd', snippetType = 'autosnippet' }, { t '^{', i(1), t '}' }, { condition = in_math }),
  s({ trig = '__', snippetType = 'autosnippet' }, { t '_{', i(1), t '}' }, { condition = in_math }),

  -- Symbols (Type ; + key for instant Greek)
  s({ trig = ';a', snippetType = 'autosnippet' }, { t '\\alpha' }, { condition = in_math }),
  s({ trig = ';b', snippetType = 'autosnippet' }, { t '\\beta' }, { condition = in_math }),
  s({ trig = ';g', snippetType = 'autosnippet' }, { t '\\gamma' }, { condition = in_math }),
  s({ trig = ';p', snippetType = 'autosnippet' }, { t '\\pi' }, { condition = in_math }),
  s({ trig = ';o', snippetType = 'autosnippet' }, { t '\\omega' }, { condition = in_math }),
  s({ trig = '->', snippetType = 'autosnippet' }, { t '\\rightarrow ' }, { condition = in_math }),
  s({ trig = '=>', snippetType = 'autosnippet' }, { t '\\implies ' }, { condition = in_math }),

  -- Complex Structures
  s({ trig = 'sum', snippetType = 'autosnippet' }, {
    t '\\sum_{',
    i(1, 'n=1'),
    t '}^{',
    i(2, '\\infty'),
    t '} ',
    i(0),
  }, { condition = in_math }),

  s({ trig = 'lim', snippetType = 'autosnippet' }, {
    t '\\lim_{',
    i(1, 'n'),
    t ' \\to ',
    i(2, '\\infty'),
    t '} ',
    i(0),
  }, { condition = in_math }),

  -- ==========================================
  -- 4. SMART LISTS
  -- ==========================================
  s('enum', {
    t { '\\begin{enumerate}', '\t\\item ' },
    i(1),
    t { '', '\\end{enumerate}' },
  }),

  s('item', {
    t { '\\begin{itemize}', '\t\\item ' },
    i(1),
    t { '', '\\end{itemize}' },
  }),

  s({ trig = 'ali', snippetType = 'autosnippet' }, {
    t { '\\begin{align}', '\t' },
    i(1),
    t ' &= ',
    i(2),
    t { ' \\\\', '\t' },
    i(3),
    t ' &= ',
    i(4),
    t { '', '\\end{align}' },
    i(0),
  }, { condition = in_math }),

  -- 2. Cases (For piecewise functions)
  s({ trig = 'cas', snippetType = 'autosnippet' }, {
    t { '\\begin{cases}', '\t' },
    i(1),
    t ' & ',
    i(2),
    t { ' \\\\', '\t' },
    i(3),
    t ' & ',
    i(4),
    t { '', '\\end{cases}' },
  }, { condition = in_math }),

  -- 3. Matrices (Standard 2x2)
  s({ trig = 'pmat', snippetType = 'autosnippet' }, {
    t { '\\begin{pmatrix}', '\t' },
    i(1),
    t ' & ',
    i(2),
    t { ' \\\\', '\t' },
    i(3),
    t ' & ',
    i(4),
    t { '', '\\end{pmatrix}' },
  }, { condition = in_math }),

  -- Quick add item: type '--' -> \item
  s({ trig = '--', snippetType = 'autosnippet' }, { t '\\item ' }),
  s({ trig = '"', snippetType = 'autosnippet' }, {
    t '``',
    i(1),
    t "''",
  }),
}
