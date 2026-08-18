-- Tests for vaults, the package manager
local mock = require("cc_mock")
local H = require("harness")
local describe, it, eq = H.describe, H.it, H.eq

local SCRIPT = (_G.ROOT or "") .. "vaults.lua"
local RAW = "https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/"

local STOCK_BODY  = "-- pretend stock dashboard\nprint('hi')\n"
local VAULTS_BODY = "-- pretend manager\n"

local MANIFEST = [[
# vaults package manifest
# name | file | version | description

vaults | vaults.lua        | 2.0.0 | Installer and launcher for these scripts
stock  | scripts/stock.lua | 1.2.0 | Live Create vault stock dashboard
]]

local function remote(opts)
  opts = opts or {}
  return {
    [RAW .. "manifest.txt"] = opts.manifest or MANIFEST,
    [RAW .. "vaults.lua"] = opts.vaults or VAULTS_BODY,
    [RAW .. "scripts/stock.lua"] = opts.stock or STOCK_BODY,
  }
end

local function newEnv(opts)
  opts = opts or {}
  opts.urls = opts.urls or remote()
  return mock.newEnv(opts)
end

-- a computer that already has both scripts at the manifest versions
local function installed(extra)
  local files = {
    ["vaults.lua"] = VAULTS_BODY,
    ["stock.lua"] = STOCK_BODY,
    [".vaults-state"] = "stock|1.2.0\nvaults|2.0.0\n",
  }
  for k, v in pairs(extra or {}) do files[k] = v end
  return files
end

describe("vaults: install", function()
  it("installs every script in the manifest to the computer root", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install")
    eq(env.files["stock.lua"], STOCK_BODY, "installed as stock.lua, not scripts/stock.lua")
    eq(env.files["vaults.lua"], VAULTS_BODY)
    H.contains(env.printed(), "+ stock.lua")
    H.contains(env.printed(), "Installed 2 scripts")
    H.contains(env.printed(), "Run:  stock")
  end)

  it("records the installed versions", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install")
    H.contains(env.files[".vaults-state"], "stock|1.2.0")
    H.contains(env.files[".vaults-state"], "vaults|2.0.0")
  end)

  it("installs just the named script", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install", "stock")
    eq(env.files["stock.lua"], STOCK_BODY)
    eq(env.files["vaults.lua"], nil, "the manager was not asked for")
    H.contains(env.printed(), "Installed 1 script")
  end)

  it("rejects a name that is not in the manifest", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install", "reactor")
    H.contains(env.printed(), "unknown script: reactor")
    H.contains(env.printed(), "available: vaults, stock")
    eq(env.files["reactor.lua"], nil)
  end)

  it("picks up a script added to the manifest with no code change", function()
    local later = MANIFEST .. "reactor | scripts/reactor.lua | 0.1.0 | Reactor babysitter\n"
    local urls = remote({ manifest = later })
    urls[RAW .. "scripts/reactor.lua"] = "-- reactor\n"
    local env = newEnv({ urls = urls })
    H.runOk(env, SCRIPT, "install")
    eq(env.files["reactor.lua"], "-- reactor\n")
    H.contains(env.printed(), "Installed 3 scripts")
    H.contains(env.printed(), "Run:  stock  |  reactor")
  end)

  it("busts the GitHub CDN cache on every request", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install")
    H.truthy(#env.httpLog > 0)
    for _, url in ipairs(env.httpLog) do
      H.contains(url, "?cb=", "each request should carry a cache buster")
    end
  end)

  it("skips files that already match", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "= stock.lua")
    H.contains(env.printed(), "nothing changed")
  end)

  it("explains when the http API is turned off", function()
    local env = newEnv({ noHttp = true })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "http API is disabled")
    eq(env.files["stock.lua"], nil)
  end)

  it("stops instead of writing half an install", function()
    local urls = remote()
    urls[RAW .. "scripts/stock.lua"] = nil
    local env = newEnv({ urls = urls })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "failed: stock")
    eq(env.files[".vaults-state"], nil, "no state written for a failed install")
  end)

  it("rejects a malformed manifest", function()
    local env = newEnv({ urls = remote({ manifest = "# nothing but a comment\n" }) })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "manifest is empty or malformed")
  end)
end)

describe("vaults: update", function()
  it("says nothing to do when everything matches", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "update")
    H.contains(env.printed(), "Already up to date")
  end)

  it("replaces changed scripts and bumps the recorded version", function()
    local newManifest = MANIFEST:gsub("1%.2%.0", "1.3.0")
    local env = newEnv({
      urls = remote({ manifest = newManifest, stock = "-- v2 dashboard\n" }),
      files = installed(),
    })
    H.runOk(env, SCRIPT, "update")
    eq(env.files["stock.lua"], "-- v2 dashboard\n")
    H.contains(env.files[".vaults-state"], "stock|1.3.0")
    H.contains(env.printed(), "^ stock.lua")
    H.contains(env.printed(), "Updated stock 1.2.0 -> 1.3.0")
  end)

  it("updates the manager itself", function()
    local env = newEnv({
      urls = remote({ vaults = "-- newer manager\n" }),
      files = installed(),
    })
    H.runOk(env, SCRIPT, "update")
    eq(env.files["vaults.lua"], "-- newer manager\n")
    H.contains(env.printed(), "vaults itself was updated")
  end)

  it("leaves scripts alone that were never installed", function()
    local later = MANIFEST .. "reactor | scripts/reactor.lua | 0.1.0 | Reactor babysitter\n"
    local urls = remote({ manifest = later })
    urls[RAW .. "scripts/reactor.lua"] = "-- reactor\n"
    local env = newEnv({ urls = urls, files = installed() })
    H.runOk(env, SCRIPT, "update")
    eq(env.files["reactor.lua"], nil, "update should not install new scripts")
    H.contains(env.printed(), "New in the manifest: reactor")
  end)

  it("can update a single named script", function()
    local env = newEnv({
      urls = remote({ stock = "-- v2\n", vaults = "-- newer manager\n" }),
      files = installed(),
    })
    H.runOk(env, SCRIPT, "update", "stock")
    eq(env.files["stock.lua"], "-- v2\n")
    eq(env.files["vaults.lua"], VAULTS_BODY, "the manager was not in the target list")
  end)
end)

describe("vaults: list", function()
  it("shows availability, versions and descriptions", function()
    local env = newEnv({ files = { ["stock.lua"] = STOCK_BODY,
                                   [".vaults-state"] = "stock|1.2.0\n" } })
    H.runOk(env, SCRIPT, "list")
    local out = env.printed()
    H.contains(out, "NAME")
    H.contains(out, "stock")
    H.contains(out, "1.2.0")
    H.contains(out, "installed")
    H.contains(out, "Live Create vault stock dashboard")
    H.contains(out, "not installed", "the manager itself is not on disk here")
  end)

  it("flags a script whose manifest version moved on", function()
    local env = newEnv({
      urls = remote({ manifest = MANIFEST:gsub("1%.2%.0", "1.4.0") }),
      files = installed(),
    })
    H.runOk(env, SCRIPT, "list")
    H.contains(env.printed(), "update available (1.2.0 -> 1.4.0)")
  end)
end)

describe("vaults: run, remove, startup", function()
  it("runs an installed script without touching the network", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "run", "stock")
    eq(#env.httpLog, 0, "no downloads needed")
    eq(env.shellRuns[1], "stock.lua")
  end)

  it("installs a missing script before running it", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "run", "stock")
    H.contains(env.printed(), "not installed - fetching it first")
    eq(env.files["stock.lua"], STOCK_BODY)
    eq(env.shellRuns[1], "stock.lua")
  end)

  it("passes arguments through to the script", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "run", "stock", "--debug", "7")
    eq(env.shellRuns[1], "stock.lua --debug 7")
  end)

  it("removes one script and forgets its version", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "remove", "stock")
    eq(env.files["stock.lua"], nil)
    eq(env.files["vaults.lua"], VAULTS_BODY)
    H.falsy(env.files[".vaults-state"]:find("stock", 1, true))
    H.contains(env.printed(), "Removed stock.lua")
  end)

  it("will not remove itself by accident", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "remove", "vaults")
    eq(env.files["vaults.lua"], VAULTS_BODY)
    H.contains(env.printed(), "vaults uninstall")
  end)

  it("wires a named script into startup", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "startup", "stock", "on")
    H.contains(env.files["startup.lua"], "shell.run(\"stock.lua\")")
    H.contains(env.files["startup.lua"], "-- installed by vaults")
    H.contains(env.printed(), "stock will run when this computer boots")
  end)

  it("refuses to autorun something that is not installed", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "startup", "stock", "on")
    eq(env.files["startup.lua"], nil)
    H.contains(env.printed(), "not installed")
  end)

  it("clears its own startup entry", function()
    local env = newEnv({ files = installed({
      ["startup.lua"] = "-- installed by vaults\nshell.run(\"stock.lua\")\n" }) })
    H.runOk(env, SCRIPT, "startup", "off")
    eq(env.files["startup.lua"], nil)
    H.contains(env.printed(), "startup: cleared")
  end)

  it("refuses to delete somebody else's startup.lua", function()
    local env = newEnv({ files = installed({
      ["startup.lua"] = "print('my own boot script')" }) })
    H.runOk(env, SCRIPT, "startup", "off")
    eq(env.files["startup.lua"], "print('my own boot script')")
    H.contains(env.printed(), "not created by vaults")
  end)
end)

describe("vaults: version and uninstall", function()
  it("reports the manager version against the manifest", function()
    local env = newEnv({ files = installed() })
    H.runOk(env, SCRIPT, "version")
    H.contains(env.printed(), "vaults      v2.0.0")
    H.contains(env.printed(), "installed   1 script")
    H.contains(env.printed(), "(up to date)")
  end)

  it("flags a newer manager in the manifest", function()
    local env = newEnv({
      urls = remote({ manifest = MANIFEST:gsub("2%.0%.0", "2.1.0") }),
      files = installed(),
    })
    H.runOk(env, SCRIPT, "version")
    H.contains(env.printed(), "manifest    v2.1.0  (run: vaults update)")
  end)

  it("uninstalls the scripts but keeps the manager", function()
    local env = newEnv({ files = installed({
      ["startup.lua"] = "-- installed by vaults\nshell.run(\"stock.lua\")\n" }) })
    H.runOk(env, SCRIPT, "uninstall")
    eq(env.files["stock.lua"], nil)
    eq(env.files[".vaults-state"], nil)
    eq(env.files["startup.lua"], nil)
    eq(env.files["vaults.lua"], VAULTS_BODY, "the manager stays put")
    H.contains(env.printed(), "Removed 1 script")
    H.contains(env.printed(), "rm vaults.lua")
  end)

  it("prints usage for no command and for nonsense", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.contains(env.printed(), "vaults install")

    local env2 = newEnv()
    H.runOk(env2, SCRIPT, "frobnicate")
    H.contains(env2.printed(), "unknown command: frobnicate")
    H.contains(env2.printed(), "vaults update")
  end)
end)
