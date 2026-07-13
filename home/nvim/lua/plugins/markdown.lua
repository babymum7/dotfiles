return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    opts = {
      ensure_installed = { 'markdown', 'markdown_inline' },
    },
    config = function(_, opts)
      require('nvim-treesitter').setup(opts)
      if opts.ensure_installed then
        local res = require('nvim-treesitter').install(opts.ensure_installed)
        if res and res.wait then
          res:wait(30000)
        end
      end
    end,
  },
  {
    'echasnovski/mini.icons',
    opts = {},
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    ft = { 'markdown' },
    opts = {},
  },
}
