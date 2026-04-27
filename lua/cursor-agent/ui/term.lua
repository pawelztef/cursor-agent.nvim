local M = {}
local config = require("cursor-agent.config")

local function resolve_size(value, total)
  if type(value) == "number" then
    if value > 0 and value < 1 then
      return math.floor(total * value)
    end
    return math.floor(value)
  end
  return math.floor(total * 0.6)
end

local function resolve_cwd(cwd)
  if type(cwd) ~= "string" or cwd == "" then return vim.fn.getcwd() end
  local uv = vim.uv or vim.loop
  local stat = uv.fs_stat(cwd)
  if stat and stat.type == "directory" then return cwd end
  return vim.fn.getcwd()
end

local function normalize_keys(value)
  if type(value) == "string" then
    value = { value }
  end
  if type(value) ~= "table" then
    return {}
  end
  local keys = {}
  for _, lhs in ipairs(value) do
    if type(lhs) == "string" and lhs ~= "" then
      if lhs:match("^F%d+$") then
        table.insert(keys, ("<%s>"):format(lhs))
      else
        table.insert(keys, lhs)
      end
    end
  end
  return keys
end

local function map_keys(bufnr, mode, keys, rhs)
  for _, lhs in ipairs(keys) do
    pcall(vim.keymap.set, mode, lhs, rhs, { buffer = bufnr, nowait = true, silent = true })
  end
end

local function apply_window_keys(bufnr, win, opts)
  local cfg = config.get()
  local window_keys = opts.cursor_window_keys or cfg.cursor_window_keys or {}
  local normal_mode = window_keys.normal_mode or {}
  local terminal_mode = window_keys.terminal_mode or {}

  local normal_hide = normalize_keys(normal_mode.hide)
  if #normal_hide == 0 then
    normal_hide = { "q" }
  end

  local base_width = resolve_size(opts.width or 0.4, vim.o.columns)
  local expanded_width = resolve_size(opts.expanded_width or 0.8, vim.o.columns)
  local is_expanded = false

  local function hide()
    M.close(win)
  end

  local function toggle_width()
    if not (win and vim.api.nvim_win_is_valid(win)) then
      return
    end
    local target = is_expanded and base_width or expanded_width
    pcall(vim.api.nvim_win_set_width, win, math.max(target, 20))
    is_expanded = not is_expanded
  end

  local function show_help()
    local hide_keys = table.concat(normal_hide, ", ")
    local toggle_keys = table.concat(normalize_keys(terminal_mode.toggle_width), ", ")
    if toggle_keys == "" then
      toggle_keys = "none"
    end
    vim.notify(("Cursor Agent window keys | hide: %s | toggle width: %s"):format(hide_keys, toggle_keys))
  end

  map_keys(bufnr, "n", normal_hide, hide)
  map_keys(bufnr, "t", normalize_keys(terminal_mode.hide), hide)
  map_keys(bufnr, "t", normalize_keys(terminal_mode.toggle_width), toggle_width)
  map_keys(bufnr, "t", normalize_keys(terminal_mode.help), show_help)
end

---Open a floating terminal window and run the provided argv command
---@param opts table
---@field argv string[]|string Command to execute (argv table preferred)
---@field title string|nil Window title
---@field title_pos string|nil Title position (e.g. "center")
---@field border string|nil Border style (e.g. "rounded")
---@field width number|nil Width in columns or 0-1 float for percentage
---@field height number|nil Height in rows or 0-1 float for percentage
---@field on_exit fun(code: integer)|nil Optional on-exit callback
---@field cwd string|nil Working directory for the terminal process
---@return integer bufnr, integer win, integer job_id
function M.open_float_term(opts)
  opts = opts or {}
  local width = resolve_size(opts.width or 0.6, vim.o.columns)
  local height = resolve_size(opts.height or 0.6, vim.o.lines - vim.o.cmdheight)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  -- Keep the terminal buffer around when the window closes so it can be reused
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")

  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title or "Cursor Agent",
    title_pos = opts.title_pos or "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  local argv = opts.argv

  local job_id = vim.fn.termopen(argv, {
    cwd = resolve_cwd(opts.cwd),
    on_exit = function(_, code)
      if type(opts.on_exit) == "function" then
        pcall(opts.on_exit, code)
      end
    end,
  })

  apply_window_keys(bufnr, win, opts)

  -- Jump to bottom and enter terminal-mode for immediate typing
  local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
  vim.schedule(function()
    pcall(vim.cmd, 'startinsert')
  end)

  return bufnr, win, job_id
end

---Open a floating window for an existing buffer (no new job is started)
---@param bufnr integer Existing buffer number (e.g. a terminal buffer)
---@param opts table|nil Same window options as open_float_term (title/border/size)
---@return integer win
function M.open_float_win_for_buf(bufnr, opts)
  opts = opts or {}
  local width = resolve_size(opts.width or 0.6, vim.o.columns)
  local height = resolve_size(opts.height or 0.6, vim.o.lines - vim.o.cmdheight)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title or "Cursor Agent",
    title_pos = opts.title_pos or "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  apply_window_keys(bufnr, win, opts)

  -- Jump to bottom and enter terminal-mode for immediate typing
  local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
  vim.schedule(function()
    pcall(vim.cmd, 'startinsert')
  end)

  return win
end

function M.open_side_term(opts)
  opts = opts or {}
  local width = resolve_size(opts.width or 0.4, vim.o.columns)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")

  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
  pcall(vim.api.nvim_win_set_width, win, math.max(width, 20))

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  local job_id = vim.fn.termopen(opts.argv, {
    cwd = resolve_cwd(opts.cwd),
    on_exit = function(_, code)
      if type(opts.on_exit) == "function" then
        pcall(opts.on_exit, code)
      end
    end,
  })

  apply_window_keys(bufnr, win, opts)

  local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
  vim.schedule(function()
    pcall(vim.cmd, "startinsert")
  end)

  return bufnr, win, job_id
end

function M.open_side_win_for_buf(bufnr, opts)
  opts = opts or {}
  local width = resolve_size(opts.width or 0.4, vim.o.columns)

  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
  pcall(vim.api.nvim_win_set_width, win, math.max(width, 20))

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  apply_window_keys(bufnr, win, opts)

  local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
  vim.schedule(function()
    pcall(vim.cmd, "startinsert")
  end)

  return win
end

function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
