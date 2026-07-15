return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Git Diff View' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'File Git History' },
      { '<leader>gq', '<cmd>DiffviewClose<CR>', desc = 'Close Git Diff' },
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    keys = {
      { '<leader>g', function() require('neogit').open() end, desc = 'Neogit' },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    opts = { current_line_blame = true },  -- who last touched this line
    keys = {
      { '<leader>gs', '<cmd>Gitsigns diffthis<CR>', desc = 'Git Diff current file' },
    },
  },
}
