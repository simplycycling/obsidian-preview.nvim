local M = {}

local config = require("obsidian_preview.config")
local sync = require("obsidian_preview.sync")

-- Augroup for active-preview autocmds (cleared on stop)
local preview_augroup = vim.api.nvim_create_augroup("ObsidianPreview", { clear = true })

-- Separate augroup for VimLeavePre — persists even after stop() so temp files
-- are always cleaned up if the user quits without calling stop first.
local cleanup_augroup = vim.api.nvim_create_augroup("ObsidianPreviewCleanup", { clear = true })

local active = false

-- Set of preview file paths currently on disk, keyed by bufnr
local preview_files = {}

local function is_markdown(bufnr)
  return vim.api.nvim_get_option_value("filetype", { buf = bufnr }) == "markdown"
end

local function open_in_obsidian(path)
  -- macOS: use `open`; on Linux swap for `xdg-open`
  local opener = vim.fn.has("mac") == 1 and "open" or "xdg-open"
  vim.fn.jobstart({ opener, "obsidian://open?path=" .. path }, { detach = true })
end

--- Set up the VimLeavePre handler once at setup time so it survives stop().
local function register_exit_cleanup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = cleanup_augroup,
    callback = function()
      for _, path in pairs(preview_files) do
        sync.cleanup(path)
      end
    end,
  })
end

function M.setup(opts)
  config.setup(opts)
  register_exit_cleanup()
end

function M.start()
  if not config.options.vault_path then
    vim.notify(
      "ObsidianPreview: vault_path is not set and could not be auto-detected from obsidian.nvim.\n"
        .. "Add `vault_path = '/path/to/your/vault'` to your setup() call.",
      vim.log.levels.ERROR
    )
    return
  end

  if active then
    vim.notify("ObsidianPreview: already running", vim.log.levels.WARN)
    return
  end

  active = true

  -- Sync current buffer immediately, then open Obsidian after a short delay.
  -- The delay gives Obsidian time to index a newly created file before the URI fires.
  local bufnr = vim.api.nvim_get_current_buf()
  local path = sync.sync(bufnr)
  preview_files[bufnr] = path
  vim.defer_fn(function()
    open_in_obsidian(path)
  end, config.options.open_delay_ms)

  -- Debounced sync on every text change.
  -- Only sync buffers that have an active preview — this handles non-.md files
  -- and unnamed buffers that the user explicitly started a preview on.
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = preview_augroup,
    callback = function()
      local cur = vim.api.nvim_get_current_buf()
      if preview_files[cur] then
        sync.debounced_sync(cur)
      end
    end,
  })

  -- Follow the active buffer: sync + navigate Obsidian when entering a new markdown buffer
  vim.api.nvim_create_autocmd("BufEnter", {
    group = preview_augroup,
    callback = function()
      local cur = vim.api.nvim_get_current_buf()
      if is_markdown(cur) then
        local p = sync.sync(cur)
        preview_files[cur] = p
        open_in_obsidian(p)
      end
    end,
  })

  -- Remove stale preview files when a buffer is wiped
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = preview_augroup,
    callback = function()
      local cur = vim.api.nvim_get_current_buf()
      local p = preview_files[cur]
      if p then
        sync.cancel_timer(cur)
        sync.cleanup(p)
        preview_files[cur] = nil
      end
    end,
  })

  vim.notify("ObsidianPreview: started", vim.log.levels.INFO)
end

function M.stop()
  if not active then
    vim.notify("ObsidianPreview: not running", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_clear_autocmds({ group = preview_augroup })

  for bufnr, path in pairs(preview_files) do
    sync.cancel_timer(bufnr)
    sync.cleanup(path)
  end
  preview_files = {}
  active = false

  vim.notify("ObsidianPreview: stopped", vim.log.levels.INFO)
end

function M.toggle()
  if active then
    M.stop()
  else
    M.start()
  end
end

return M
