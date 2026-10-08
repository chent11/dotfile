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
-- Map lspconfig server names to Mason package names, then install everything
-- in one :MasonInstall, which blocks until done when Neovim is headless.
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

if #missing > 0 then
  step("Installing Mason packages: " .. table.concat(missing, " "))
  local mason_ok, mason_err = pcall(vim.cmd, "MasonInstall " .. table.concat(missing, " "))
  if not mason_ok then
    fail("MasonInstall: " .. tostring(mason_err))
  end
  for _, name in ipairs(missing) do
    if not registry.get_package(name):is_installed() then
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
