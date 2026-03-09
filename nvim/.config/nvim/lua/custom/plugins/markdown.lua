return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ft = { 'markdown', 'codecompanion' },
    opts = {
      code = {
        sign = false,
        width = 'block',
        right_pad = 1,
        highlight = 'NormalFloat',
      },
      heading = {
        sign = false,
      },
    },
  },
}
