# chezmoi-signs.nvim

[:cn: 中文](README.zh-CN.md)

Neovim plugin that shows diff signs in the sign column for chezmoi-managed files compared to their source, similar to the side diff icons in [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim).

- 🟢 `│` added lines
- 🟡 `│` changed lines
- 🔴 `▁` deleted lines

Live refresh while editing (300ms debounce), full refresh on save.

### Installation

**lazy.nvim**

```lua
{
  "W-Rn/chezmoi-signs.nvim",
  opts = {},
}
```

**Manual**

```lua
require("chezmoi-signs").setup()
```

### Configuration

```lua
require("chezmoi-signs").setup({
  debounce_ms = 300,    -- debounce delay in ms
  debug = false,        -- enable debug logging

  -- sign icons (any Unicode char)
  signs = {
    add    = { text = "│", hl = "ChezmoiSignAdd" },
    change = { text = "│", hl = "ChezmoiSignChange" },
    delete = { text = "▁", hl = "ChezmoiSignDelete" },
  },

  -- highlight colors
  highlights = {
    ChezmoiSignAdd    = { fg = "#2da043", bg = "none" },
    ChezmoiSignChange = { fg = "#d9a404", bg = "none" },
    ChezmoiSignDelete = { fg = "#d72e3d", bg = "none" },
  },
})
```

### Commands

| Command | Description |
|---------|-------------|
| `:ChezmoiSignsRefresh` | Refresh signs in current buffer |
| `:ChezmoiSignsToggle`  | Enable / disable the plugin |
| `:ChezmoiSignsClear`   | Clear all signs in current buffer |

### Requirements

- [chezmoi](https://github.com/twpayne/chezmoi)
- Neovim >= 0.8

### License

MIT
