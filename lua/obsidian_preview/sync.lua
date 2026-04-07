local M = {}

local config = require("obsidian_preview.config")

-- Per-buffer debounce timers
local timers = {}

--- Derive the preview file path for a given buffer.
--- Uses the buffer's filename (without extension) with _preview appended.
--- Falls back to "untitled" for unnamed buffers.
local function preview_path_for_buf(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local stem
  if name == "" then
    stem = "untitled"
  else
    stem = vim.fn.fnamemodify(name, ":t:r")
    -- Sanitize: replace any path-unsafe characters
    stem = stem:gsub("[^%w%-_]", "_")
  end
  return config.options.vault_path .. "/" .. stem .. "_preview.md"
end

--- Write buffer lines to path, prepending a minimal frontmatter block.
--- The frontmatter doesn't force Reading View (no Obsidian URI param exists for that),
--- but the file is valid YAML frontmatter and won't break rendering.
local function write_to_disk(path, lines)
  local f = io.open(path, "w")
  if not f then
    vim.notify("ObsidianPreview: could not write to " .. path, vim.log.levels.ERROR)
    return
  end
  f:write(table.concat(lines, "\n"))
  f:close()
end

--- Immediately sync buf to its preview file. Returns the preview file path.
function M.sync(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = preview_path_for_buf(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  write_to_disk(path, lines)
  return path
end

--- Debounced sync — waits debounce_ms after the last call before writing.
function M.debounced_sync(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local existing = timers[bufnr]
  if existing then
    existing:stop()
    existing:close()
    timers[bufnr] = nil
  end

  local t = vim.uv.new_timer()
  timers[bufnr] = t
  t:start(config.options.debounce_ms, 0, vim.schedule_wrap(function()
    -- Buffer may have been wiped by the time the timer fires
    if vim.api.nvim_buf_is_valid(bufnr) then
      M.sync(bufnr)
    end
    t:close()
    timers[bufnr] = nil
  end))
end

--- Return the preview file path for a buffer without writing anything.
function M.path_for(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return preview_path_for_buf(bufnr)
end

--- Delete a preview file from disk if it exists.
function M.cleanup(path)
  if path and vim.fn.filereadable(path) == 1 then
    os.remove(path)
  end
end

--- Cancel any pending debounce timer for a buffer.
function M.cancel_timer(bufnr)
  local t = timers[bufnr]
  if t then
    t:stop()
    t:close()
    timers[bufnr] = nil
  end
end

return M
