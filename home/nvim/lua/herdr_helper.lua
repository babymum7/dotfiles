local M = {}

local function nonempty(v)
  return (v ~= nil and v ~= "") and v or nil
end

local function send_to_agent(pane_id, text)
  -- Ensure text ends with a double newline separator so consecutive sends are cleanly separated
  if not text:match("\n\n$") then
    if text:match("\n$") then
      text = text .. "\n"
    else
      text = text .. "\n\n"
    end
  end
  vim.fn.system({ "herdr", "agent", "send", pane_id, text })
  return vim.v.shell_error == 0
end

function M.get_active_agent_pane_id()
  local workspace_id = nonempty(vim.env.HERDR_WORKSPACE_ID) or nonempty(vim.env.HERDR_ACTIVE_WORKSPACE_ID)
  if not workspace_id then
    local pane_id = nonempty(vim.env.HERDR_PANE_ID) or nonempty(vim.env.HERDR_ACTIVE_PANE_ID)
    if pane_id then
      workspace_id = pane_id:match("^([^:]+)")
    end
  end

  if not workspace_id then
    -- Fallback: find the focused workspace from herdr workspace list
    local handle = io.popen("herdr workspace list 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      local ok, data = pcall(vim.json.decode, result)
      if ok and data and data.result and data.result.workspaces then
        for _, ws in ipairs(data.result.workspaces) do
          if ws.focused then
            workspace_id = ws.workspace_id
            break
          end
        end
      end
    end
  end

  if not workspace_id then
    return nil
  end

  -- Run herdr agent list and parse JSON
  local handle = io.popen("herdr agent list 2>/dev/null")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()

  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data or not data.result or not data.result.agents then
    return nil
  end

  for _, agent in ipairs(data.result.agents) do
    if agent.workspace_id == workspace_id then
      return agent.pane_id
    end
  end
  return nil
end

function M.add_oil_file_to_agent()
  local pane_id = M.get_active_agent_pane_id()
  if not pane_id then
    vim.notify("No active herdr agent found in this workspace.", vim.log.levels.WARN)
    return
  end

  local entry = require("oil").get_cursor_entry()
  if not entry then
    vim.notify("No file under cursor.", vim.log.levels.WARN)
    return
  end

  local dir = require("oil").get_current_dir()
  local abspath = dir .. entry.name

  -- Send path to agent
  if send_to_agent(pane_id, abspath) then
    vim.notify("Sent file path to agent: " .. entry.name, vim.log.levels.INFO)
  else
    vim.notify("Failed to send file path to agent.", vim.log.levels.ERROR)
  end
end

function M.add_visual_selection_to_agent()
  -- Exit Visual mode to ensure '< and '> marks are set to the current selection
  local mode = vim.fn.mode()
  if mode:match("[vV\x16]") then
    vim.cmd('normal! \x1b')
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] == 0 or end_pos[2] == 0 then
    vim.notify("No text selected.", vim.log.levels.WARN)
    return
  end

  local vmode = vim.fn.visualmode()
  if vmode == "" then
    vmode = "v"
  end

  local lines = vim.fn.getregion(start_pos, end_pos, { type = vmode })
  local selection = table.concat(lines, "\n")

  if not selection or selection == "" then
    vim.notify("No text selected.", vim.log.levels.WARN)
    return
  end

  local pane_id = M.get_active_agent_pane_id()
  if not pane_id then
    vim.notify("No active herdr agent found in this workspace.", vim.log.levels.WARN)
    return
  end

  -- Get file path and filetype
  local filepath = vim.api.nvim_buf_get_name(0)
  local filetype = vim.bo.filetype

  -- Format message
  local msg = string.format("[Code Selection from %s]\n```%s\n%s\n```", filepath, filetype, selection)

  -- Send to agent
  if send_to_agent(pane_id, msg) then
    vim.notify("Sent code selection to agent.", vim.log.levels.INFO)
  else
    vim.notify("Failed to send code selection to agent.", vim.log.levels.ERROR)
  end
end

return M
