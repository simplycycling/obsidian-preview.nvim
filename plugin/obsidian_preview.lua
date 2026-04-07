-- User-facing commands. Plugin authors should call require("obsidian_preview").setup()
-- in their config; these commands are available immediately after the plugin loads.

vim.api.nvim_create_user_command("ObsidianPreviewStart", function()
  require("obsidian_preview").start()
end, { desc = "Start Obsidian preview for the current buffer" })

vim.api.nvim_create_user_command("ObsidianPreviewStop", function()
  require("obsidian_preview").stop()
end, { desc = "Stop Obsidian preview and clean up temp files" })

vim.api.nvim_create_user_command("ObsidianPreviewToggle", function()
  require("obsidian_preview").toggle()
end, { desc = "Toggle Obsidian preview on/off" })
