# chezmoi-signs.nvim

[中文](#中文) | [English](#english)

---

<a id="中文"></a>

## 中文

Neovim 插件：在符号列显示 chezmoi 主目录文件与源目录之间的差异标记，效果类似 [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) 的侧边差异图标。

- 🟢 `│` 添加的行
- 🟡 `│` 修改的行
- 🔴 `▁` 删除的行

编辑时实时刷新（300ms 防抖），保存后强制重新读取源文件。

### 安装

**lazy.nvim**

```lua
{
  "W-Rn/chezmoi-signs.nvim",
  opts = {},
}
```

**手动**

```lua
require("chezmoi-signs").setup()
```

### 配置

```lua
require("chezmoi-signs").setup({
  debounce_ms = 300,    -- 防抖毫秒数
  debug = false,        -- 调试日志

  -- 图标样式（支持任意 Unicode 字符）
  signs = {
    add    = { text = "│", hl = "ChezmoiSignAdd" },
    change = { text = "│", hl = "ChezmoiSignChange" },
    delete = { text = "▁", hl = "ChezmoiSignDelete" },
  },

  -- 高亮颜色
  highlights = {
    ChezmoiSignAdd    = { fg = "#2da043", bg = "none" },
    ChezmoiSignChange = { fg = "#d9a404", bg = "none" },
    ChezmoiSignDelete = { fg = "#d72e3d", bg = "none" },
  },
})
```

### 命令

| 命令 | 说明 |
|------|------|
| `:ChezmoiSignsRefresh` | 手动刷新 |
| `:ChezmoiSignsToggle`  | 启用/禁用 |
| `:ChezmoiSignsClear`   | 清除标记 |

### 依赖

- [chezmoi](https://github.com/twpayne/chezmoi)
- Neovim >= 0.8

### 许可证

MIT

---

<a id="english"></a>

## English

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
