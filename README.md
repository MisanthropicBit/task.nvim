<div align="center">
  <br />
  <h1>task.nvim</h1>
  <p><i>Using an event loop and corountines to build an async/await-free
  concurrent task library</i></p>
  <p>
    <img src="https://img.shields.io/badge/version-0.1.0-blue?style=for-the-badge" />
    <a href="https://luarocks.org/modules/misanthropicbit/task.nvim">
        <img src="https://img.shields.io/luarocks/v/misanthropicbit/task.nvim?logo=lua&color=purple&style=for-the-badge" />
    </a>
    <a href="/.github/workflows/tests.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/MisanthropicBit/task.nvim/tests.yml?branch=master&style=for-the-badge" />
    </a>
    <a href="/LICENSE">
        <img src="https://img.shields.io/github/license/MisanthropicBit/task.nvim?style=for-the-badge" />
    </a>
  </p>
  <br />
</div>

A demonstration of how an event loop ([`libuv`](https://libuv.org/) in neovim)
and [lua coroutines](https://www.lua.org/pil/9.1.html) can be used to build an
async/await-free
([colorless](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/))
concurrent task library.

## Example usage

### Wait for a task

```lua
local task = Task.run(function()
    Task.sleep(500)
end)

task:wait()

vim.print(task:failed()) -- false
vim.print(task:cancelled()) -- false
vim.print(task:started()) -- false
vim.print(task:done()) -- true
vim.print(task:running()) -- false
vim.print(task:elapsed_ms() >= 100) -- true
```

### Wait for multiple tasks to finish

```lua
local times = { 500, 1000, 600, 350 }
local tasks = vim.tbl_map(function(time)
    return Task.run(function()
        Task.sleep(time)
    end)
end)

-- Limit to two concurrent tasks at a time and cancel remaining tasks if timeout is exceeded
task:wait_all(tasks, { concurrency = 2, timeout = 3000 })
```

## How does it work?

We need two components for the task library. Coroutines which are functions that can
be paused and resumed at a later time and an event loop ...
