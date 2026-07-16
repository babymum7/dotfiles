return {
  {
    'williamboman/mason.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
    config = function(_, opts)
      require('mason').setup(opts)
      -- Prepend Mason bin directory to PATH for Neovim runtime
      local mason_bin = vim.fn.stdpath('data') .. '/mason/bin'
      if vim.fn.isdirectory(mason_bin) == 1 then
        vim.env.PATH = mason_bin .. ':' .. vim.env.PATH
      end

      -- Ensure non-LSP tools (like tree-sitter-cli) are installed via Mason
      local mr = require('mason-registry')
      mr.refresh(function()
        for _, tool in ipairs({ 'tree-sitter-cli' }) do
          if mr.has_package(tool) then
            local p = mr.get_package(tool)
            if not p:is_installed() then
              p:install()
            end
          end
        end
      end)
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'neovim/nvim-lspconfig',
    },
    opts = {
      ensure_installed = {
        'yamlls',
        'gopls',
        'rust_analyzer',
      },
    },
    config = function(_, opts)
      vim.lsp.config('yamlls', {
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
            },
          },
        },
      })

      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
            },
            checkOnSave = {
              command = 'clippy',
            },
          },
        },
      })

      require('mason-lspconfig').setup(opts)
    end,
  },
}
