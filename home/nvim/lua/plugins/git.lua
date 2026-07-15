return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Git Diff View' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'File Git History' },
      { '<leader>gq', '<cmd>DiffviewClose<CR>', desc = 'Close Git Diff' },
    },
  },
}
