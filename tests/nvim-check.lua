-- Headless verification of the Neovim setup, run by tests/check.sh:
--
--   nvim --headless -c "luafile ~/dotfile/tests/nvim-check.lua"
--
-- Goes beyond "it starts": every plugin, parser and Mason package from
-- lua/config/tools.lua must be present, LSP servers must attach and report
-- diagnostics, conform must format, nvim-lint must lint, and the autocmds in
-- lua/config/autocmds.lua must do what they claim. Exit code is non-zero when
-- any check fails.

local tools = require("config.tools")
local uv = vim.uv or vim.loop
local passed, failed = 0, 0

local function ok(msg)
  passed = passed + 1
  io.stdout:write("    ok    " .. msg .. "\n")
end

local function fail(msg, detail)
  failed = failed + 1
  io.stdout:write("    FAIL  " .. msg .. (detail and (": " .. tostring(detail)) or "") .. "\n")
end

local function check(cond, msg, detail)
  if cond then ok(msg) else fail(msg, detail) end
end

local function section(msg)
  io.stdout:write("\n  " .. msg .. "\n")
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")

local function write(path, lines)
  vim.fn.writefile(type(lines) == "table" and lines or vim.split(lines, "\n"), path)
  return path
end

-- 1. Core ---------------------------------------------------------------------
section("core")
check(vim.fn.has("nvim-0.11") == 1, "Neovim >= 0.11 (running " .. tostring(vim.version()) .. ")")
check(vim.g.mapleader == " ", "mapleader is <Space>")
check(vim.o.undofile and vim.fn.isdirectory(vim.o.undodir) == 1, "undofile on and undodir exists (" .. vim.o.undodir .. ")")
check(vim.o.spell, "spell checking enabled by default")
local spell_add = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
check(vim.fn.filereadable(spell_add) == 1, "spell submodule checked out (spell/en.utf-8.add)")
for _, bin in ipairs({ "fd", "rg", "git", "node", "cc" }) do
  check(vim.fn.executable(bin) == 1, "external tool on PATH: " .. bin)
end

-- 2. lazy.nvim plugins ----------------------------------------------------------
section("plugins")
local lazy_cfg = require("lazy.core.config")
local count, missing = 0, {}
for name, plugin in pairs(lazy_cfg.plugins) do
  count = count + 1
  if not uv.fs_stat(plugin.dir) then table.insert(missing, name) end
end
check(count > 0 and #missing == 0, count .. " lazy.nvim plugins installed", table.concat(missing, ", "))

local ts_spec = lazy_cfg.plugins["nvim-treesitter"]
check(ts_spec and ts_spec.url:find("chent11/nvim%-treesitter") and ts_spec.branch == "spell-checking-for-string",
  "nvim-treesitter spec points at the chent11 fork, branch spell-checking-for-string")
if ts_spec and uv.fs_stat(ts_spec.dir) then
  local branch = vim.trim(vim.fn.system({ "git", "-C", ts_spec.dir, "rev-parse", "--abbrev-ref", "HEAD" }))
  check(branch == "spell-checking-for-string", "nvim-treesitter checkout is on the fork branch", branch)
end

for _, mod in ipairs({ "snacks", "lazy", "mason", "conform", "lint" }) do
  local loaded = pcall(require, mod)
  check(loaded, "require('" .. mod .. "')")
end
check(lazy_cfg.plugins["vim-fugitive"] ~= nil, "vim-fugitive is configured (the commit template autocmd loads it on demand)")

-- 3. Treesitter parsers ------------------------------------------------------------
section("treesitter parsers")
require("lazy").load({ plugins = { "nvim-treesitter" } })
local samples = {
  c = "int x;", cpp = "int x;", go = "package main", lua = "local x = 1", python = "x = 1",
  rust = "fn main() {}", typescript = "let x = 1;", vim = "set nu", query = "(x)", comment = "TODO",
  regex = "a+", kotlin = "val x = 1", json = "{}", yaml = "a: 1", bash = "x=1", markdown = "# t",
  markdown_inline = "*t*",
}
local bad_parsers = {}
for _, lang in ipairs(tools.parsers) do
  local added, res = pcall(vim.treesitter.language.add, lang)
  local parsed = false
  if added and res ~= false then
    parsed = pcall(function()
      local parser = vim.treesitter.get_string_parser(samples[lang] or "", lang)
      assert(#parser:parse() > 0, "no tree")
    end)
  end
  if not parsed then table.insert(bad_parsers, lang) end
end
check(#bad_parsers == 0, #tools.parsers .. " parsers load and parse", table.concat(bad_parsers, ", "))

-- treesitter highlighting actually starts on a buffer
local py = write(tmp .. "/hl.py", "x = 1")
vim.cmd.edit(py)
vim.wait(2000, function() return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil end)
check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "treesitter highlighter active on a python buffer")

-- 4. Mason packages ----------------------------------------------------------------
section("mason packages")
require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim" } })
local registry = require("mason-registry")
local to_pkg = require("mason-lspconfig").get_mappings().lspconfig_to_package
local wanted = {}
for _, server in ipairs(tools.servers) do table.insert(wanted, to_pkg[server] or server) end
vim.list_extend(wanted, tools.tools)

-- Mason package name -> executable it must provide (default: same name)
local binaries = {
  ["pyright"] = "pyright-langserver",
  ["kotlin-lsp"] = "intellij-server",
}
for _, name in ipairs(wanted) do
  local has, pkg = pcall(registry.get_package, name)
  if not has then
    fail("Mason package unknown: " .. name)
  else
    check(pkg:is_installed(), "Mason package installed: " .. name)
    local bin = binaries[name] or name
    check(vim.fn.executable(bin) == 1, "executable provided by " .. name .. ": " .. bin)
  end
end

-- 5. LSP ------------------------------------------------------------------------
section("lsp")
for _, server in ipairs(tools.servers) do
  check(vim.lsp.config[server] ~= nil and vim.lsp.config[server].cmd ~= nil, "vim.lsp.config('" .. server .. "') has a cmd")
end
check(vim.lsp.is_enabled("pyright") and vim.lsp.is_enabled("clangd") and vim.lsp.is_enabled("lua_ls"),
  "pyright, clangd and lua_ls are enabled")

-- open a file, wait for the server to attach, then for a diagnostic matching `pattern`
local function lsp_roundtrip(path, server, pattern, timeout)
  vim.cmd.edit(path)
  local buf = vim.api.nvim_get_current_buf()
  local attached = vim.wait(timeout or 60000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = server }) > 0
  end, 200)
  check(attached, server .. " attaches to " .. vim.fn.fnamemodify(path, ":t"))
  if not attached or not pattern then return end
  local found
  vim.wait(timeout or 60000, function()
    for _, d in ipairs(vim.diagnostic.get(buf)) do
      if d.message:find(pattern) then found = d.message return true end
    end
    return false
  end, 200)
  check(found ~= nil, server .. " reports the expected diagnostic", "wanted /" .. pattern .. "/, got " .. vim.inspect(vim.tbl_map(function(d) return d.message end, vim.diagnostic.get(buf))))
end

lsp_roundtrip(write(tmp .. "/bad.py", 'x: int = "a"'), "pyright", "not assignable")
lsp_roundtrip(write(tmp .. "/bad.c", "int main(void) { return y; }"), "clangd", "ndeclared identifier")
vim.fn.mkdir(tmp .. "/luaproj", "p")
write(tmp .. "/luaproj/.luarc.json", "{}")
lsp_roundtrip(write(tmp .. "/luaproj/init.lua", "local x = 1\nreturn x"), "lua_ls", nil, 90000)

-- nvim-cmp loads and has the configured sources
require("lazy").load({ plugins = { "nvim-cmp" } })
local cmp_ok, cmp = pcall(require, "cmp")
if cmp_ok then
  local names = vim.tbl_map(function(s) return s.name end, cmp.get_config().sources)
  check(vim.tbl_contains(names, "nvim_lsp") and vim.tbl_contains(names, "buffer") and vim.tbl_contains(names, "path"),
    "nvim-cmp sources: nvim_lsp, buffer, path", vim.inspect(names))
else
  fail("require('cmp')")
end

-- 6. Formatting and linting ------------------------------------------------------------------
section("conform / nvim-lint")
require("lazy").load({ plugins = { "conform.nvim", "nvim-lint" } })
local json = write(tmp .. "/t.json", '{"a":1,\n"b":[1,2]}')
vim.cmd.edit(json)
local jbuf = vim.api.nvim_get_current_buf()
check(vim.bo[jbuf].filetype == "jsonc", "*.json opens as jsonc (autocmd)", vim.bo[jbuf].filetype)
local formatters = require("conform").list_formatters(jbuf)
check(#formatters > 0 and formatters[1].name == "prettier" and formatters[1].available,
  "conform resolves prettier for jsonc and it is available", vim.inspect(formatters))
local formatted = require("conform").format({ bufnr = jbuf, timeout_ms = 30000, quiet = true })
local text = table.concat(vim.api.nvim_buf_get_lines(jbuf, 0, -1, false), "\n")
check(formatted and text == '{ "a": 1, "b": [1, 2] }', "conform formats a jsonc buffer with prettier", vim.inspect(text))

local dockerfile = write(tmp .. "/Dockerfile", "FROM ubuntu:latest\nRUN apt-get install curl\n")
vim.cmd.edit(dockerfile)
local dbuf = vim.api.nvim_get_current_buf()
check(vim.bo[dbuf].filetype == "dockerfile", "Dockerfile filetype detected", vim.bo[dbuf].filetype)
require("lint").try_lint()
local linted = vim.wait(30000, function() return #vim.diagnostic.get(dbuf, { namespace = nil }) > 0 end, 200)
check(linted, "nvim-lint runs hadolint on a Dockerfile and reports findings",
  vim.inspect(vim.tbl_map(function(d) return d.message end, vim.diagnostic.get(dbuf))))

-- 7. Autocmds --------------------------------------------------------------------
section("autocmds")
local lua_file = write(tmp .. "/indent.lua", "")
vim.cmd.edit(lua_file)
check(vim.bo.shiftwidth == 2 and vim.bo.tabstop == 2, "lua buffers use 2-space indent", vim.bo.shiftwidth)
local py_file = write(tmp .. "/indent.py", "")
vim.cmd.edit(py_file)
check(vim.bo.shiftwidth == 4, "python buffers keep the 4-space default", vim.bo.shiftwidth)

local ws = write(tmp .. "/ws.txt", { "trailing   ", "clean" })
vim.cmd.edit(ws)
vim.api.nvim_buf_set_lines(0, 0, 1, false, { "trailing  \t " })
vim.cmd("silent write")
check(vim.deep_equal(vim.fn.readfile(ws), { "trailing", "clean" }), "trailing whitespace trimmed on save", vim.inspect(vim.fn.readfile(ws)))

local md = write(tmp .. "/t.md", "# title")
vim.cmd.edit(md)
check(vim.wo.wrap and vim.wo.linebreak and vim.wo.conceallevel == 2, "markdown: wrap, linebreak, conceallevel 2")

-- commit template: staged diff + guidelines injected as comments
vim.notify = function() end -- the autocmd notifies; keep the report clean
local repo = tmp .. "/repo"
vim.fn.mkdir(repo, "p")
local function git(...) return vim.fn.system({ "git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@example.com", ... }) end
git("init", "-q")
write(repo .. "/hello.txt", "hello")
git("add", "hello.txt")
vim.cmd.edit(repo .. "/.git/COMMIT_EDITMSG")
vim.wait(500)
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local body = table.concat(lines, "\n")
check(vim.bo.filetype == "gitcommit", "COMMIT_EDITMSG detected as gitcommit", vim.bo.filetype)
check(body:find("# ##Here is the diff of changes:", 1, true) ~= nil, "commit template: staged diff header injected")
check(body:find("# +hello", 1, true) ~= nil, "commit template: staged diff content injected")
check(body:find("Commit Message Guidelines", 1, true) ~= nil, "commit template: guidelines injected")
check(vim.bo.textwidth == 72, "COMMIT_EDITMSG textwidth 72", vim.bo.textwidth)

-- 8. checkhealth -------------------------------------------------------------------
section("checkhealth")
vim.cmd("silent checkhealth lazy mason nvim-treesitter vim.lsp")
local errors = {}
for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if line:match("^%s*%- ERROR") then table.insert(errors, vim.trim(line)) end
end
check(#errors == 0, "checkhealth lazy/mason/nvim-treesitter/vim.lsp has no ERROR", "\n" .. table.concat(errors, "\n"))

-- Done --------------------------------------------------------------------------
io.stdout:write(string.format("\n  nvim-check: %d passed, %d failed\n", passed, failed))
vim.fn.delete(tmp, "rf")
if failed > 0 then vim.cmd("cquit 1") else vim.cmd("qall!") end
