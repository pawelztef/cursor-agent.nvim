## Cursor Agent Neovim Plugin 

A minimal Neovim plugin to run the Cursor Agent CLI in Neovim. Toggle an interactive side terminal at your project root, or send the current buffer or a visual selection to Cursor Agent.

### Requirements
- **Cursor Agent CLI**: `cursor-agent` available on your `$PATH`

## Installation

### lazy.nvim
```lua
{
  "xTacobaco/cursor-agent.nvim",
  config = function()
    vim.keymap.set("n", "<C-c>", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })
    vim.keymap.set("v", "<C-p>", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })
    vim.keymap.set("n", "<C-b>", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
  end,
}
```

### packer.nvim
```lua
use({
  "xTacobaco/cursor-agent.nvim",
  config = function()
    require("cursor-agent").setup({})
  end,
})
```

### vim-plug
```vim
Plug 'xTacobaco/cursor-agent.nvim'
```
Then in your `init.lua`:
```lua
require("cursor-agent").setup({})
```

Note: The plugin auto-initializes with defaults on load (via `after/plugin/cursor-agent.lua`). Calling `setup()` yourself lets you override defaults.

## Quickstart

- Run `:CursorAgent` to toggle an interactive side terminal in your project root. Type directly into the `cursor-agent` program.
- Visually select code, then use `:CursorAgentSelection` to ask about just that selection.
- Run `:CursorAgentBuffer` to send the entire current buffer (handy for files like `cursor.md`).
- Press `q` in normal mode in the side terminal to close it or run :CursorAgent again to toggle it away.

## Commands

- **:CursorAgent**: Toggle the interactive Cursor Agent terminal (project root).
- **:CursorAgentSelection**: Send the current visual selection (writes to a temp file and opens terminal rendering).
- **:CursorAgentBuffer**: Send the full current buffer (writes to a temp file and opens terminal rendering).

## Configuration

Only set what you need. For typical usage, `cmd` and `args` are enough.
```lua
require("cursor-agent").setup({
  cmd = "cursor-agent",
  args = {},
  keymaps = {
    toggle = {
      mode = "n",
      lhs = "<C-c>",
      desc = "Cursor Agent: Toggle terminal",
    },
    selection = {
      mode = "v",
      lhs = "<C-p>",
      desc = "Cursor Agent: Send selection",
    },
    buffer = {
      mode = "n",
      lhs = "<C-b>",
      desc = "Cursor Agent: Send buffer",
    },
  },
  cursor_window_keys = {
    terminal_mode = {
      help = { "??", "<F1>" },
      toggle_width = { "<C-f>" },
    },
    normal_mode = {
      hide = { "<Esc>", "q" },
    },
  },
})
```

Advanced (for lower-level CLI helpers present in the codebase but not required for terminal mode):
```lua
require("cursor-agent").setup({
  -- Whether to send content via stdin when using non-terminal helpers
  use_stdin = true,
  -- Reserved for future concurrency control
  multi_instance = false,
  -- Timeout for non-streaming helpers (ms)
  timeout_ms = 60000,
  -- Auto-scroll behavior for certain UI helpers
  auto_scroll = true,
})
```

Set `toggle = false` to disable the default mapping and define your own.

### Examples

- Use an absolute path for the CLI:
```lua
require("cursor-agent").setup({ cmd = "/usr/local/bin/cursor-agent" })
```

- Change the toggle mapping:
```lua
require("cursor-agent").setup({
  keymaps = {
    toggle = { lhs = "<leader>c" },
  },
})
```

- Customize terminal window mappings:
```lua
require("cursor-agent").setup({
  cursor_window_keys = {
    terminal_mode = {
      help = { "??", "<F1>" },
      toggle_width = { "<C-f>" },
      hide = { "<Esc>" },
    },
    normal_mode = {
      hide = { "q" },
    },
  },
})
```

`<F1>` must be written with angle brackets. Writing `F1` without brackets will not map correctly.

## Suggested keymaps

```lua
-- Toggle the interactive terminal
vim.keymap.set("n", "<C-c>", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })

-- Ask about the visual selection
vim.keymap.set("v", "<C-p>", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })

-- Ask about the current buffer
vim.keymap.set("n", "<C-b>", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
```

## Programmatic usage

You can call the API directly if you prefer:
```lua
-- Launch a one-off run passing a prompt as argv (opens a side terminal)
require("cursor-agent").ask({ prompt = "How can I refactor this function?" })
```
This opens a side terminal using `termopen`, with the working directory set to the detected project root.

## Troubleshooting

- **CLI not found**: Ensure `cursor-agent` is on your `$PATH`.
- **No output appears**: Verify your CLI installation by running it in a normal terminal.
- **Wrong directory**: The terminal starts in your project root (LSP root if available, otherwise common markers like `.git`).

## How it works

- A side terminal is created with `termopen`, wrapped, and ready for immediate input.
- The terminal starts in the detected project root so Cursor Agent has the right context.
- For selection/buffer commands, the text is written to a temporary file and its path is passed to the CLI as a positional argument.

## Contributing

Contributions are welcome! If you have ideas or improvements, please open an issue or submit a PR.

## Acknowledgements

- Cursor Agent CLI by Cursor - This plugin was build entirely using GPT-5 in Cursor Agent CLI. Development cost: $0.45 with 10m 34s of API time.
