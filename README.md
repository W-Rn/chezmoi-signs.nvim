# chezmoi-signs.nvim

Neovim 插件：在符号列显示 chezmoi 主目录文件与源目录之间的差异标记，效果类似 [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)。

_A Neovim plugin that shows diff signs between chezmoi-managed files and their source, similar to [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)._

- 🟢 `│` added / 添加的行
- 🟡 `│` changed / 修改的行
- 🔴 `▁` deleted / 删除的行

编辑时实时刷新（300ms 防抖），保存后强制重新读取源文件。

_Live refresh while editing (300ms debounce), full refresh on save._

## 安装 / Installation

### lazy.nvim

```lua
{
  "W-Rn/chezmoi-signs.nvim",
  opts = {},
}
```

### 手动 / Manual

```lua
require("chezmoi-signs").setup()
```

## 配置 / Configuration

```lua
require("chezmoi-signs").setup({
  debounce_ms = 300,    -- debounce delay in ms / 防抖毫秒数
  debug = false,        -- enable debug logging / 调试日志

  -- sign icons (any Unicode char) / 图标样式
  signs = {
    add    = { text = "│", hl = "ChezmoiSignAdd" },
    change = { text = "│", hl = "ChezmoiSignChange" },
    delete = { text = "▁", hl = "ChezmoiSignDelete" },
  },

  -- highlight colors / 高亮颜色
  highlights = {
    ChezmoiSignAdd    = { fg = "#2da043", bg = "none" },
    ChezmoiSignChange = { fg = "#d9a404", bg = "none" },
    ChezmoiSignDelete = { fg = "#d72e3d", bg = "none" },
  },
})
```

图标示例 / _Icon examples_：

| 风格 / Style | 文本 / Text |
|--------------|-------------|
| 竖线 / bars | `│` `▎` `▌` `┃` |
| ASCII | `+` `~` `-` |
| 底部标记 / bottom | `▁` `▔` `_` |

## 命令 / Commands

| 命令 / Command | 说明 / Description |
|----------------|---------------------|
| `:ChezmoiSignsRefresh` | 手动刷新 / _refresh signs_ |
| `:ChezmoiSignsToggle`  | 启用/禁用 / _toggle enable_ |
| `:ChezmoiSignsClear`   | 清除标记 / _clear signs_ |

## 依赖 / Requirements

- [chezmoi](https://github.com/twpayne/chezmoi)
- Neovim >= 0.8

## 许可证 / License

MIT
