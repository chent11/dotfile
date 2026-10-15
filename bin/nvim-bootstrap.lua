-- Headless Neovim provisioning, run by bootstrap.sh:
--
--   nvim --headless -c "luafile ~/dotfile/bin/nvim-bootstrap.lua"
--
-- Installs all lazy.nvim plugins, every treesitter parser and every Mason
-- package listed in lua/config/tools.lua, then exits. Idempotent: anything
-- already present is skipped. Exit code is non-zero if a step failed.

local tools = require("config.tools")
local failed = false

local function step(msg)
  io.stdout:write("\n==> " .. msg .. "\n")
end

local function fail(msg)
  io.stderr:write("!!  " .. msg .. "\n")
  failed = true
end

-- 1. Plugins ----------------------------------------------------------------
step("Installing lazy.nvim plugins")
require("lazy").install({ wait = true, show = false })

-- 2. Treesitter parsers -----------------------------------------------------
step("Installing treesitter parsers: " .. table.concat(tools.parsers, " "))
require("lazy").load({ plugins = { "nvim-treesitter" } })
local ok, err = pcall(function()
  require("nvim-treesitter").install(tools.parsers):wait(15 * 60 * 1000)
end)
if not ok then
  fail("treesitter install: " .. tostring(err))
end

-- 3. Mason packages ---------------------------------------------------------
-- Map lspconfig server names to Mason package names, then install whatever
-- is missing.
require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim" } })
local registry = require("mason-registry")
registry.refresh()

local to_pkg = require("mason-lspconfig").get_mappings().lspconfig_to_package
local wanted = {}
for _, server in ipairs(tools.servers) do
  table.insert(wanted, to_pkg[server] or server)
end
vim.list_extend(wanted, tools.tools)

local missing = {}
for _, name in ipairs(wanted) do
  local has, pkg = pcall(registry.get_package, name)
  if not has then
    fail("unknown Mason package: " .. name)
  elseif not pkg:is_installed() then
    table.insert(missing, name)
  end
end

-- Install through the package API instead of :MasonInstall. In headless mode
-- :MasonInstall quits nvim with `1cq` on the first failure, before this script
-- can report anything, and its error text is easily lost. Here every package
-- reports its own error, and a failed one gets a second attempt (large
-- downloads such as kotlin-lsp occasionally flake on CI runners).
local function install_all(names)
  local pending, results = #names, {}
  for _, name in ipairs(names) do
    local pkg = registry.get_package(name)
    local handle = pkg:install({}, function(success, err)
      results[name] = { success = success, err = err }
      pending = pending - 1
    end)
    handle:on("stderr", vim.schedule_wrap(function(chunk) io.stderr:write(chunk) end))
  end
  vim.wait(30 * 60 * 1000, function() return pending == 0 end, 200)
  local failed_names = {}
  for _, name in ipairs(names) do
    local r = results[name]
    if not r or not r.success then
      table.insert(failed_names, name)
      io.stderr:write(("!!  Mason package %s failed: %s\n"):format(name, r and tostring(r.err) or "timed out"))
    end
  end
  return failed_names
end

if #missing > 0 then
  step("Installing Mason packages: " .. table.concat(missing, " "))
  local retry = install_all(missing)
  if #retry > 0 then
    step("Retrying Mason packages: " .. table.concat(retry, " "))
    for _, name in ipairs(install_all(retry)) do
      fail("Mason package did not install: " .. name)
    end
  end
else
  step("Mason packages already installed")
end

-- 4. Done -------------------------------------------------------------------
if failed then
  io.stderr:write("\nnvim-bootstrap finished with errors\n")
  vim.cmd("cquit 1")
else
  io.stdout:write("\nnvim-bootstrap complete\n")
  vim.cmd("qall!")
end
