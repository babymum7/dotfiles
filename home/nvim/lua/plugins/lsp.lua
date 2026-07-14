return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lspconfig = require('lspconfig')
      lspconfig.yamlls.setup({
        cmd = { 'yaml-language-server', '--stdio' },
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
            },
          },
        },
      })
    end,
  },
}
