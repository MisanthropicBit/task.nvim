<div align="center">
  <br />
  <h1>task.nvim</h1>
  <p><i>Using an event loop and coroutines to build an async/await-free
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

A demonstration of how an event loop[^event_loop] ([`libuv`](https://libuv.org/)
in neovim) and [lua coroutines](https://www.lua.org/pil/9.1.html) can be used to
build an async/await-free
([colorless](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/))
concurrent task library.

- [Requirements](#)
- [Example usage](#example-usage)
- [How does it work?](#how-does-it-work)
- [Contributing](#contributing)
- [References](#references)

## Requirements

* TODO

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

We need two components for the task library. Coroutines which are functions that
can be paused and resumed at a later time[^coroutine] and an event
loop[^event_loop] for asynchronous programming. However, let us first do a brief
review of how asynchronous programming has evolved.

### The evolution of asynchronous programming

Calling an asynchronous function usually returns immediately, firing off the
asynchronous operation (for example waiting for a network request to complete),
and user-supplied callback handles the result of the asynchronous operation when
it completes. This style of programming has led to the "callback hell" where
deeply nested callbacks were necessary to chain asynchronous operations.

```javascript
function asyncFunction1(value, result1 => {
    asyncFunction2(value, result2 => {
        asyncFunction3(value, result3 => {
            // More nested calls
        })
    })
})
```

The solution was the syntactic `async` and `await` keywords which made asynchronous
programming much more readable. Consider the example from above using
`async`/`await`.

```javascript
async function asyncFunction1(value) {
    const result1 = await asyncFunction2(value)
    const result2 = await asyncFunction3(result1)

    // More asynchronous calls
}
```

One critique of this approach is that if you want to `await` something in an
enclosed function, say function A, then it needs to be `async`. If the enclosing
function B of function A also needs to await function A, function B needs to be
`async` as well. This "infectious" behaviour means that a lot of code suddenly
becomes `async`[^colorless_functions]. What if we could design a system without
the need for these viral syntactic elements?

### The task library

When you start a task via e.g. `Task.run`, the function you supply runs in a
coroutine. Since coroutines are a form of cooperative multitasking the coroutine
would normally start and run to completion unless it explicitly yields to
another coroutine which then runs. In contrast, multithreading is a form of
preemptive multitasking where the operating system preempts a thread to allow
another to run . At some later time, the original coroutine might be resumed and
continue where it left off.

This is where coroutines come in and more specifically `Task.wrap`. This
function wraps an asynchronous function by overriding the callback to instead
pass the asynchronous results to `coroutine.resume`. It invokes the asynchronous
function and then calls `coroutine.yield`. Remember that a task is just a
coroutine so the yield suspends the current task. Once the asynchronous
operation completes, the callback is called which does some error handling but
otherwise passes the results to `coroutine.resume` which resumes the suspended
task (coroutine) and passes back the results to the task. So asynchronous
function call are essentially yield points in the coroutine/task where we
explicitly give up control and let the event loop decide which function should
run next.

### The `step` function

Along with `Task.wrap`, the `step` function is the meat of the implementation
described in the above paragraph. Most implementations have chosen this name
because it takes a "step" in a task from one asynchronous call to another.

One very nice benefit of this approach is that when an asynchronous function is
invoked, we can check if it is being called in a coroutine (i.e. in a task) and
run it as described above. Otherwise, we can simply invoke the function as
normal if we do not care about awaiting, enabling us to invoke asynchronous
functions in a non-async environment. This is akin to calling a JavaScript
function returning a `Promise` without awaiting it. Here, there is no
differentiating on the syntax-level between asynchronous and non-asynchronous
code.

Since neovim allows calling asynchronous functions in a synchronous manner if
you omit the callback, we could even allow for calling asynchronous functions
synchronously if the call is not happening inside a coroutine. This has not
been implemented.

One downside to this approach is that existing asynchronous functions will need
to be passed to `Task.wrap` since neovim only provides callback-style
asynchronous functions. If you are interested there is a PR for adding
structured concurrency to neovim.

# Contributing

## References

[^colorless]: https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/
[^coroutine]: https://www.lua.org/pil/9.1.html
[^event_loop]: https://en.wikipedia.org/wiki/Event_loop
[^leafo]: https://leafo.net/posts/itchio-and-coroutines.html
