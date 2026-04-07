local M = {}

M.defaults = {
  vault_path = nil, -- auto-detected from obsidian.nvim if not set
  debounce_ms = 300,
}

M.options = {}

--- Attempt to read vault path from obsidian.nvim client config.
--- Supports both v1 (dir) and v2+ (workspaces).
local function detect_vault_from_obsidian_nvim()
  local ok, obsidian = pcall(require, "obsidian")
  if not ok then
    return nil
  end

  -- v2+: exposes get_client()
  if obsidian.get_client then
    local client_ok, client = pcall(obsidian.get_client)
    if client_ok and client then
      local ws = client.opts and client.opts.workspaces
      if ws and ws[1] then
        return tostring(ws[1].path)
      end
      local dir = client.opts and client.opts.dir
      if dir then
        return tostring(dir)
      end
    end
  end

  -- v1 fallback: opts exposed directly on module
  if obsidian.opts then
    local ws = obsidian.opts.workspaces
    if ws and ws[1] then
      return tostring(ws[1].path)
    end
    if obsidian.opts.dir then
      return tostring(obsidian.opts.dir)
    end
  end

  return nil
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  if not M.options.vault_path then
    M.options.vault_path = detect_vault_from_obsidian_nvim()
  end

  if M.options.vault_path then
    M.options.vault_path = vim.fn.expand(M.options.vault_path)
  end
end

return M
