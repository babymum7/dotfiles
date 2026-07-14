return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      vim.lsp.config['yamlls'] = {
        cmd = { 'yaml-language-server', '--stdio' },
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
            },
          },
        },
      }
      vim.lsp.enable('yamlls')
    end,
  },
}
