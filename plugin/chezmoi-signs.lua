if vim.g.loaded_chezmoi_signs then
  return
end
vim.g.loaded_chezmoi_signs = true

local ok, err = pcall(function()
  require("chezmoi-signs").setup()
end)

if not ok then
  vim.notify("[chezmoi-signs] 加载失败: " .. tostring(err), vim.log.levels.ERROR)
end
