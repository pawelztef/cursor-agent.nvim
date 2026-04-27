local M = {}

local default_config = {
  -- Executable or argv table. Example: "cursor-agent" or {"cursor-agent", "cli"}
  cmd = "cursor-agent",
  -- Additional arguments always passed to the CLI
  args = {},
  -- Send request content via stdin. If false, content is appended to args via --input
  use_stdin = true,
  -- When true, multiple requests can run concurrently. Default false per spec.
  multi_instance = false,
  -- Maximum time to wait for a non-streaming request (ms)
  timeout_ms = 60000,
  -- Auto-scroll output buffer to the end as new content arrives
  auto_scroll = true,
  -- Default mappings provided by the plugin
  keymaps = {
    toggle = {
      mode = "n",
      lhs = "<A-c>",
      desc = "Cursor Agent: Toggle terminal",
    },
    selection = {
      mode = "v",
      lhs = "<A-p>",
      desc = "Cursor Agent: Send selection",
    },
    buffer = {
      mode = "n",
      lhs = "<A-b>",
      desc = "Cursor Agent: Send buffer",
    },
  },
  cursor_window_keys = {
    terminal_mode = {
      help = { "??", "<F1>" },
      toggle_width = { "<C-f>" },
    },
    normal_mode = {
      hide = { "q" },
    },
  },
}

local active_config = vim.deepcopy(default_config)

function M.setup(user_config)
  active_config = vim.tbl_deep_extend("force", active_config, user_config or {})
end

function M.get()
  return active_config
end

function M.reset_to_defaults()
  active_config = vim.deepcopy(default_config)
end

return M
