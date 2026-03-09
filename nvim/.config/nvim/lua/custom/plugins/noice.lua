return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  opts = {
    cmdline = {
      view = 'cmdline_popup', -- This creates the floating box
    },
    presets = {
      command_palette = true, -- This positions it at the TOP CENTER
      long_message_to_split = true,
      lsp_doc_border = true,
    },
    views = {
      cmdline_popup = {
        position = {
          row = '10%', -- Moves it toward the top
          col = '50%', -- Center
        },
        size = {
          width = 60,
          height = 'auto',
        },
      },
    },
  },
}
