-- Test runner.  From the repo root:   lua tests/run.lua
-- Requires a normal Lua 5.4 interpreter; CC: Tweaked itself is emulated by
-- tests/cc_mock.lua, so nothing here needs Minecraft running.
local here = (arg and arg[0] or "tests/run.lua"):gsub("[^/\\]+$", "")
if here == "" then here = "./" end
_G.ROOT = here .. "../"

package.path = here .. "?.lua;" .. package.path

local H = require("harness")

local suites = { "test_rail", "test_stock", "test_vaults" }
for _, suite in ipairs(suites) do
  io.write("\n", suite, "\n")
  require(suite)
end

os.exit(H.report() and 0 or 1)
