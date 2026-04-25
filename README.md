# chezmoi-signs.nvim

Neovim 插件：在符号列显示 chezmoi 主目录文件与源目录之间的差异标记，效果类似 [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)。

- 🟢 `│` 添加的行
- 🟡 `│` 修改的行
- 🔴 `▁` 删除的行（显示在删除位置对应的行）

编辑时实时刷新（300ms 防抖），保存后强制重新读取源文件。

## 安装

### lazy.nvim

```lua
{
  "your-github-username/chezmoi-signs.nvim",
  opts = {},
}
```

### 手动

```lua
-- init.lua
require("chezmoi-signs").setup({
  -- 可选配置
  debounce_ms = 300,    -- 实时刷新的防抖毫秒数
  debug = false,        -- 启用调试日志
})
```

## 命令

| 命令 | 说明 |
|------|------|
| `:ChezmoiSignsRefresh` | 手动刷新当前缓冲区的差异标记 |
| `:ChezmoiSignsToggle`  | 启用 / 禁用插件 |
| `:ChezmoiSignsClear`   | 清除当前缓冲区的所有标记 |

## 依赖

- [chezmoi](https://github.com/twpayne/chezmoi)
- Neovim >= 0.8

## 许可证

MIT
