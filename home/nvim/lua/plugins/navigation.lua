return {
  {
    'stevearc/oil.nvim',
    dependencies = {
      'malewicz1337/oil-git.nvim',
    },
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ["<C-p>"] = {
          "actions.preview",
          opts = {
            vertical = true,
            split = "belowright",
          },
        },
        ["yp"] = "actions.yank_entry",
      },
    },
    cmd = { "Oil" },
    keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File Browser' } },
    config = function(_, opts)
      require('oil').setup(opts)
      require('oil-git').setup()
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },
      { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    },
  },
}
