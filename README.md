# obsidian-preview.nvim

Preview the current Neovim buffer in Obsidian's Reading View, live as you type.

Inspired by `markdown-preview.nvim` but targets Obsidian instead of a browser — useful when you want Obsidian's wiki-link rendering, callouts, dataview output, or theme. Or, like me, you're only writing markdown files for Obsidian, not the internet, and it's more relevant than a browser.

## How it works

1. On `:ObsidianPreviewStart`, the current buffer is written to a temp `.md` file inside your vault (e.g. `my-notes_preview.md`).
2. Obsidian opens that file via its URI scheme (`obsidian://open?path=...`).
3. `TextChanged`/`TextChangedI` autocmds keep the file in sync as you type (debounced).
4. When you switch to a different markdown buffer, the preview follows.
5. On `:ObsidianPreviewStop` or Neovim exit, the temp file is deleted.

## Requirements

- Neovim 0.9+ (uses `vim.uv`)
- Obsidian installed and registered as a URI handler
- macOS or Linux

## Installation

### lazy.nvim

```lua
{
  "simplycycling/obsidian-preview.nvim",
  config = function()
    require("obsidian_preview").setup({
      -- vault_path is auto-detected from obsidian.nvim if you use it
      -- vault_path = "~/Documents/MyVault" or whatever,
      debounce_ms = 300,
    })
  end,
}
```

### vim-plug

```vim
Plug 'simplycycling/obsidian-preview.nvim'
```

Then in your init.lua:

```lua
require("obsidian_preview").setup()
```

### vim.pack (built-in)

Clone the repo into Neovim's pack directory:

```sh
git clone https://github.com/simplycycling/obsidian-preview.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/obsidian-preview.nvim
```

Then add the setup call to your `init.lua`:

```lua
require("obsidian_preview").setup({
  -- vault_path is auto-detected from obsidian.nvim if you use it
  -- vault_path = "~/Documents/MyVault" or, you know, wherever you keep it,
})
```

The `start/` directory means the plugin loads automatically. No extra `packadd` call needed.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `vault_path` | `string\|nil` | `nil` | Path to your Obsidian vault. Auto-detected from obsidian.nvim if not set. |
| `debounce_ms` | `number` | `300` | Milliseconds to wait after the last keystroke before writing to disk. |
| `open_delay_ms` | `number` | `500` | Milliseconds to wait after writing the preview file before opening Obsidian. Increase if Obsidian reports it cannot find the file on startup. |

## Commands

| Command | Description |
|---|---|
| `:ObsidianPreviewStart` | Start preview for the current buffer |
| `:ObsidianPreviewStop` | Stop preview and delete temp files |
| `:ObsidianPreviewToggle` | Toggle preview on/off |

## Getting Reading View

Obsidian has no URI parameter to force a file open in Reading View. Set this once in Obsidian:

**Settings → Editor → Default view for new tabs → Reading View**

After that, every file opened by this plugin will render in Reading View automatically.

## Known behaviour

- **Focus shift on start**: On macOS, `:ObsidianPreviewStart` will bring Obsidian to the foreground. This is a side effect of how macOS handles the `open` command and is not currently avoidable. Click back on your terminal or use your window manager to return focus to Neovim after starting the preview. Subsequent buffer switches update the Obsidian view silently without stealing focus.

## Platform notes

- **macOS**: uses the `open` command (detected automatically)
- **Linux**: uses `xdg-open` (detected automatically); requires Obsidian to handle `obsidian://` URIs
- **Windows**: not currently supported 😭
