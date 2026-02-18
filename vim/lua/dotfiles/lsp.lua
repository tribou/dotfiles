-- Open LSP docs in a split instead of a hover (like :help)
-- This exists to make lsp docs more usable like an actual manual
local M = {}

function M.open_docs_in_split()
    -- 1. Get position encoding for 0.12
    local client = vim.lsp.get_clients({ bufnr = 0 })[1]
    if not client then return end
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

    -- 2. Request and process
    vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
        if err or not result or not result.contents then return end

        local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

        -- 3. Create scratch buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        -- 4. Set buffer-local options (Modern API)
        local b_opts = { buf = buf }
        vim.api.nvim_set_option_value('filetype', 'markdown', b_opts)
        vim.api.nvim_set_option_value('buftype', 'nofile', b_opts)
        vim.api.nvim_set_option_value('bufhidden', 'wipe', b_opts)
        vim.api.nvim_set_option_value('modifiable', false, b_opts)

        -- 5. Open split and apply Treesitter
        vim.cmd('topleft 15split')
        vim.api.nvim_set_current_buf(buf)
        vim.treesitter.start(buf, 'markdown')

        -- 6. Quick close
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf })
    end)
end

return M
