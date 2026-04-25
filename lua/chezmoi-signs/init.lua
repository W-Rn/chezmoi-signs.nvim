local config = require("chezmoi-signs.config")

local M = {}

M._ns = nil
M._enabled = true
M._chezmoi_available = false
M._source_cache = {}   -- source_path -> { lines, mtime }
M._debounce_timers = {} -- buf -> timer_id

local function info(msg)
  vim.notify("[chezmoi-signs] " .. msg, vim.log.levels.INFO)
end

local function debug(msg)
  if config.get("debug") then
    vim.notify("[chezmoi-signs] " .. msg, vim.log.levels.DEBUG)
  end
end

local function warn(msg)
  vim.notify("[chezmoi-signs] " .. msg, vim.log.levels.WARN)
end

local function err(msg)
  vim.notify("[chezmoi-signs] " .. msg, vim.log.levels.ERROR)
end

--- 检查 chezmoi 是否可执行
local function check_chezmoi()
  local bin = config.get("chezmoi_bin")
  local f = io.popen("command -v " .. bin .. " 2>/dev/null")
  if not f then return false end
  local out = f:read("*a")
  f:close()
  return out ~= nil and out ~= ""
end

--- 获取 chezmoi 源文件路径
local function get_source_path(filepath)
  local bin = config.get("chezmoi_bin")
  local result = vim.fn.system({ bin, "source-path", filepath })
  if vim.v.shell_error ~= 0 then return nil end
  return vim.trim(result)
end

--- 直接读取源文件 / 渲染模板
local function read_source_file(source_path)
  local lines
  if source_path:match("%.tmpl$") then
    local bin = config.get("chezmoi_bin")
    local result = vim.fn.system({ bin, "execute-template", source_path })
    if vim.v.shell_error ~= 0 then
      warn("模板渲染失败，直接读取模板文件: " .. source_path)
      local f = io.open(source_path, "r")
      if not f then return nil end
      local content = f:read("*a")
      f:close()
      lines = vim.split(content or "", "\n", { plain = true })
    else
      lines = vim.split(result, "\n", { plain = true })
    end
  else
    local f = io.open(source_path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    lines = vim.split(content or "", "\n", { plain = true })
  end
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

--- 带缓存的源文件内容获取（按 mtime 判断是否过期）
local function get_cached_source(source_path)
  if not source_path then return nil end
  local stat = vim.uv.fs_stat(source_path)
  if not stat then
    M._source_cache[source_path] = nil
    return nil
  end
  local cache = M._source_cache[source_path]
  if cache and cache.mtime == stat.mtime.sec then
    return cache.lines
  end
  local lines = read_source_file(source_path)
  if lines then
    M._source_cache[source_path] = { lines = lines, mtime = stat.mtime.sec }
  end
  return lines
end

--- 清除源文件缓存
local function clear_source_cache(source_path)
  M._source_cache[source_path] = nil
end

--- 解析 unified diff 文本，提取添加/修改/删除的行号
--- @param diff_text string vim.diff 输出的文本
--- @param buf_line_count number 缓冲区总行数
--- @return table { adds = number[], changes = number[], deletes = number[] }
local function parse_diff(diff_text, buf_line_count)
  local result = { adds = {}, changes = {}, deletes = {} }

  if not diff_text or diff_text == "" then
    return result
  end

  local old_lnum = 0
  local new_lnum = 0
  local hunk_adds = {}
  local hunk_dels = {}

  local function flush_hunk()
    if #hunk_adds == 0 and #hunk_dels == 0 then
      return
    end

    local min_n = math.min(#hunk_dels, #hunk_adds)

    -- 前 min_n 对是修改行
    for i = 1, min_n do
      table.insert(result.changes, hunk_adds[i])
    end

    -- 多余的添加行是纯新增
    for i = min_n + 1, #hunk_adds do
      table.insert(result.adds, hunk_adds[i])
    end

    -- 多余的删除行：标记在 hunk 在缓冲区中的起始行
    -- 纯删除时 new_lnum 即 @@ 头中的 new_start，表示删除段后的第一行
    -- 标记放在该行上，表明 "此行之前有内容被删除"
    for i = min_n + 1, #hunk_dels do
      local del_pos
      if #hunk_adds > 0 then
        del_pos = hunk_adds[1]  -- 有添加行时，取第一个添加行作为参照
      else
        del_pos = new_lnum > 0 and new_lnum or 1
      end
      -- 纯删除：标记在 new_start 行（即删除段后的第一个有效行）
      -- 有添加的删除：标记在第一个添加行
      if del_pos < 1 then del_pos = 1 end
      if del_pos <= buf_line_count then
        table.insert(result.deletes, del_pos)
      end
    end

    hunk_adds = {}
    hunk_dels = {}
  end

  for line in diff_text:gmatch("[^\r\n]+") do
    local ohs, ohe, nhs, nhe = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
    if ohs then
      flush_hunk()
      old_lnum = tonumber(ohs)
      new_lnum = tonumber(nhs)
    elseif line:match("^\\") then
      -- 忽略 \ No newline at end of file
    elseif line:match("^%+") then
      table.insert(hunk_adds, new_lnum)
      new_lnum = new_lnum + 1
    elseif line:match("^%-") then
      table.insert(hunk_dels, old_lnum)
      old_lnum = old_lnum + 1
    elseif line:match("^ ") then
      flush_hunk()
      old_lnum = old_lnum + 1
      new_lnum = new_lnum + 1
    end
  end

  flush_hunk()

  -- 去重并排序
  local function uniq_sort(t)
    local seen = {}
    local out = {}
    for _, v in ipairs(t) do
      if not seen[v] then
        seen[v] = true
        table.insert(out, v)
      end
    end
    table.sort(out)
    return out
  end

  result.adds = uniq_sort(result.adds)
  result.changes = uniq_sort(result.changes)
  result.deletes = uniq_sort(result.deletes)

  return result
end

--- 在缓冲区中设置符号列标记
local function apply_signs(buf, diffs)
  local ns = M._ns
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local sign_cfg = config.get("signs")
  if not sign_cfg then return end

  local total = vim.api.nvim_buf_line_count(buf)
  if total == 0 then return end

  -- 记录已有标记的行（避免覆盖）
  local occupied = {}

  local function set_sign(line, text, hl)
    local lnum = line - 1
    if lnum < 0 or lnum >= total then return end
    occupied[line] = true
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, lnum, 0, {
      sign_text = text,
      sign_hl_group = hl,
      priority = 20,
    })
  end

  -- 添加行
  for _, line in ipairs(diffs.adds) do
    set_sign(line, sign_cfg.add.text, sign_cfg.add.hl)
  end

  -- 修改行
  for _, line in ipairs(diffs.changes) do
    set_sign(line, sign_cfg.change.text, sign_cfg.change.hl)
  end

  -- 删除行：避免与已有的添加/修改标记重叠
  for _, line in ipairs(diffs.deletes) do
    local target = line
    -- 如果目标行已被占用，尝试用前一行
    if occupied[target] then
      local alt = target - 1
      if alt >= 1 and not occupied[alt] then
        target = alt
      end
    end
    set_sign(target, sign_cfg.delete.text, sign_cfg.delete.hl)
  end

  debug(string.format("标记: %d 添加, %d 修改, %d 删除",
    #diffs.adds, #diffs.changes, #diffs.deletes))
end

--- 刷新指定缓冲区的 chezmoi 差异标记
--- @param skip_cache boolean 跳过缓存，强制重新读取源文件
function M.refresh(buf, skip_cache)
  buf = buf or vim.api.nvim_get_current_buf()

  if not M._enabled or not M._chezmoi_available then
    pcall(vim.api.nvim_buf_clear_namespace, buf, M._ns, 0, -1)
    return
  end

  local filepath = vim.api.nvim_buf_get_name(buf)
  if filepath == "" then
    pcall(vim.api.nvim_buf_clear_namespace, buf, M._ns, 0, -1)
    return
  end

  local source = get_source_path(filepath)
  if not source then
    pcall(vim.api.nvim_buf_clear_namespace, buf, M._ns, 0, -1)
    debug("文件不受 chezmoi 管理: " .. filepath)
    return
  end

  debug("源路径: " .. source)

  local src_lines
  if skip_cache then
    clear_source_cache(source)
  end
  src_lines = get_cached_source(source)
  if not src_lines then
    err("无法读取源文件: " .. source)
    return
  end

  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #buf_lines > 0 and buf_lines[#buf_lines] == "" then
    table.remove(buf_lines)
  end

  local diff_text = vim.diff(
    table.concat(src_lines, "\n"),
    table.concat(buf_lines, "\n")
  )

  local diffs = parse_diff(diff_text, vim.api.nvim_buf_line_count(buf))
  apply_signs(buf, diffs)
end

--- 防抖刷新（用于实时编辑时的高频触发）
function M.refresh_debounced(buf, delay)
  buf = buf or vim.api.nvim_get_current_buf()
  delay = delay or config.get("debounce_ms") or 300

  -- 取消之前的定时器
  if M._debounce_timers[buf] then
    pcall(vim.uv.timer_stop, M._debounce_timers[buf])
    M._debounce_timers[buf] = nil
  end

  local timer = vim.uv.new_timer()
  timer:start(delay, 0, vim.schedule_wrap(function()
    timer:close()
    M._debounce_timers[buf] = nil
    if vim.api.nvim_buf_is_valid(buf) then
      M.refresh(buf)
    end
  end))
  M._debounce_timers[buf] = timer
end

--- 清除指定缓冲区的标记
function M.clear(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_clear_namespace, buf, M._ns, 0, -1)
end

--- 切换插件的启用状态
function M.toggle()
  M._enabled = not M._enabled
  if M._enabled then
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      M.refresh(b)
    end
    info("已启用")
  else
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      M.clear(b)
    end
    info("已禁用")
  end
end

--- 定义高亮组
--- 使用 `highlight default` 设置颜色，不依赖 gitsigns
local function setup_highlights()
  local defaults = config.get("highlights") or {}
  for hl, colors in pairs(defaults) do
    vim.cmd(string.format("highlight default %s guifg=%s guibg=%s", hl, colors.fg, colors.bg))
  end
end

--- 初始化插件
function M.setup(opts)
  config.setup(opts)

  M._ns = vim.api.nvim_create_namespace("chezmoi-signs")
  M._chezmoi_available = check_chezmoi()

  if not M._chezmoi_available then
    warn("chezmoi 未安装或不可执行，插件已禁用")
    return
  end

  setup_highlights()

  if config.get("auto_refresh") then
    local group = vim.api.nvim_create_augroup("chezmoi_signs", { clear = true })

    -- 打开文件时：完整刷新（读取源文件并缓存）
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = group,
      pattern = "*",
      callback = function(args)
        vim.schedule(function()
          M.refresh(args.buf, true)  -- 跳过缓存，强制重新读取
        end)
      end,
    })

    -- 保存文件时：完整刷新（源文件可能被 chezmoi 更新）
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      pattern = "*",
      callback = function(args)
        vim.schedule(function()
          M.refresh(args.buf, true)
        end)
      end,
    })

    -- 实时编辑时：防抖刷新（仅使用缓存的源文件内容）
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
      group = group,
      pattern = "*",
      callback = function(args)
        M.refresh_debounced(args.buf)
      end,
    })

    -- 清除缓冲区时：清理缓存和定时器
    vim.api.nvim_create_autocmd("BufUnload", {
      group = group,
      pattern = "*",
      callback = function(args)
        if M._debounce_timers[args.buf] then
          pcall(vim.uv.timer_stop, M._debounce_timers[args.buf])
          M._debounce_timers[args.buf] = nil
        end
        M.clear(args.buf)
      end,
    })
  end

  vim.api.nvim_create_user_command("ChezmoiSignsRefresh", function()
    M.refresh()
  end, {})

  vim.api.nvim_create_user_command("ChezmoiSignsToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("ChezmoiSignsClear", function()
    M.clear()
  end, {})
end

return M
