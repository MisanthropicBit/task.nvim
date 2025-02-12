rockspec_format = "3.0"
package = "task.nvim"
version = "scm-1"

description = {
    summary = "Using an event loop and corountines to build an async/await-free concurrent task library",
    detailed = [[]],
    labels = {
        "neovim",
        "plugin",
        "task",
        "concurrency",
        "async",
    },
    homepage = "https://github.com/MisanthropicBit/task.nvim",
    issues_url = "https://github.com/MisanthropicBit/task.nvim/issues",
    license = "BSD 3-Clause",
}

dependencies = {
    "lua == 5.1",
}

test_dependencies = {
    "busted >= 2.2.0",
    "neotest-busted >= 0.4.0",
    "neotest >= 5.8.0",
    "nvim-nio >= 1.10.1",
}

source = {
    url = "git://github.com/MisanthropicBit/task.nvim",
}

build = {
    type = "builtin",
}

test = {
    type = "command",
    command = "nvim -l ./run-tests.lua",
}
