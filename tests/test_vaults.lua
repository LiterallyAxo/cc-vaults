-- Tests for the vaults installer / updater
local mock = require("cc_mock")
local H = require("harness")
local describe, it, eq = H.describe, H.it, H.eq

local SCRIPT = (_G.ROOT or "") .. "vaults.lua"
local RAW = "https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/"

local MONITOR_BODY = "-- pretend monitor script\nprint('hi')\n"
local INSTALLER_BODY = "-- pretend installer\n"

local function remote(opts)
  opts = opts or {}
  return {
    [RAW .. "vault_stock.lua"] = opts.monitor or MONITOR_BODY,
    [RAW .. "vaults.lua"] = opts.installer or INSTALLER_BODY,
    [RAW .. "version.txt"] = opts.version or "1.1.0\n",
  }
end

local function newEnv(opts)
  opts = opts or {}
  opts.urls = opts.urls or remote()
  return mock.newEnv(opts)
end

describe("vaults: install", function()
  it("downloads the monitor, the installer and the version stamp", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install")
    eq(env.files["vault_stock.lua"], MONITOR_BODY)
    eq(env.files["vaults.lua"], INSTALLER_BODY)
    eq(env.files[".vaults-version"], "1.1.0")
    H.contains(env.printed(), "+ vault_stock.lua")
    H.contains(env.printed(), "Installed v1.1.0")
  end)

  it("busts the GitHub CDN cache on every request", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install")
    for _, url in ipairs(env.httpLog) do
      H.contains(url, "?cb=", "each request should carry a cache buster")
    end
  end)

  it("skips files that already match", function()
    local env = newEnv({ files = { ["vault_stock.lua"] = MONITOR_BODY } })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "= vault_stock.lua  already current")
    H.contains(env.printed(), "+ vaults.lua")
  end)

  it("wires up autorun with --startup", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "install", "--startup")
    H.contains(env.files["startup.lua"], "shell.run(\"vault_stock.lua\")")
    H.contains(env.files["startup.lua"], "-- installed by vaults")
    H.contains(env.printed(), "will run when this computer boots")
  end)

  it("reports a missing file instead of writing half an install", function()
    local urls = remote()
    urls[RAW .. "vaults.lua"] = nil
    local env = newEnv({ urls = urls })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "failed: vaults.lua")
    eq(env.files[".vaults-version"], nil, "no version stamp on a failed install")
  end)

  it("explains when the http API is turned off", function()
    local env = newEnv({ noHttp = true })
    H.runOk(env, SCRIPT, "install")
    H.contains(env.printed(), "http API is disabled")
  end)
end)

describe("vaults: update", function()
  it("says nothing to do when everything matches", function()
    local env = newEnv({ files = {
      ["vault_stock.lua"] = MONITOR_BODY,
      ["vaults.lua"] = INSTALLER_BODY,
      [".vaults-version"] = "1.1.0",
    } })
    H.runOk(env, SCRIPT, "update")
    H.contains(env.printed(), "Already up to date (v1.1.0)")
  end)

  it("replaces changed files and bumps the stamp", function()
    local env = newEnv({
      urls = remote({ monitor = "-- v2 monitor\n", version = "1.2.0" }),
      files = {
        ["vault_stock.lua"] = MONITOR_BODY,
        ["vaults.lua"] = INSTALLER_BODY,
        [".vaults-version"] = "1.1.0",
      },
    })
    H.runOk(env, SCRIPT, "update")
    eq(env.files["vault_stock.lua"], "-- v2 monitor\n")
    eq(env.files[".vaults-version"], "1.2.0")
    H.contains(env.printed(), "^ vault_stock.lua")
    H.contains(env.printed(), "Updated 1.1.0 -> 1.2.0")
  end)

  it("can replace itself", function()
    local env = newEnv({
      urls = remote({ installer = "-- newer installer\n" }),
      files = {
        ["vault_stock.lua"] = MONITOR_BODY,
        ["vaults.lua"] = INSTALLER_BODY,
        [".vaults-version"] = "1.1.0",
      },
    })
    H.runOk(env, SCRIPT, "update")
    eq(env.files["vaults.lua"], "-- newer installer\n")
    H.contains(env.printed(), "vaults itself was updated")
  end)
end)

describe("vaults: other commands", function()
  it("runs the monitor, installing it first if needed", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "run")
    H.contains(env.printed(), "is missing - installing it first")
    eq(env.shellRuns[1], "vault_stock.lua")
  end)

  it("runs an already installed monitor without touching the network", function()
    local env = newEnv({ files = { ["vault_stock.lua"] = MONITOR_BODY } })
    H.runOk(env, SCRIPT, "run")
    eq(#env.httpLog, 0, "no downloads needed")
    eq(env.shellRuns[1], "vault_stock.lua")
  end)

  it("toggles startup on and off", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "startup", "on")
    H.truthy(env.files["startup.lua"])
    local env2 = mock.newEnv({
      urls = remote(),
      files = { ["startup.lua"] = "-- installed by vaults\nshell.run(\"vault_stock.lua\")\n" },
    })
    H.runOk(env2, SCRIPT, "startup", "off")
    eq(env2.files["startup.lua"], nil)
    H.contains(env2.printed(), "startup: disabled")
  end)

  it("refuses to delete somebody else's startup.lua", function()
    local env = newEnv({ files = { ["startup.lua"] = "print('my own boot script')" } })
    H.runOk(env, SCRIPT, "startup", "off")
    eq(env.files["startup.lua"], "print('my own boot script')")
    H.contains(env.printed(), "not created by vaults")
  end)

  it("compares installed and available versions", function()
    local env = newEnv({ files = { [".vaults-version"] = "1.0.0" } })
    H.runOk(env, SCRIPT, "version")
    H.contains(env.printed(), "installed   1.0.0")
    H.contains(env.printed(), "available   1.1.0  (run: vaults update)")
  end)

  it("reports being up to date", function()
    local env = newEnv({ files = { [".vaults-version"] = "1.1.0" } })
    H.runOk(env, SCRIPT, "version")
    H.contains(env.printed(), "(up to date)")
  end)

  it("uninstalls the monitor but keeps itself", function()
    local env = newEnv({ files = {
      ["vault_stock.lua"] = MONITOR_BODY,
      ["vaults.lua"] = INSTALLER_BODY,
      [".vaults-version"] = "1.1.0",
      ["startup.lua"] = "-- installed by vaults\nshell.run(\"vault_stock.lua\")\n",
    } })
    H.runOk(env, SCRIPT, "uninstall")
    eq(env.files["vault_stock.lua"], nil)
    eq(env.files[".vaults-version"], nil)
    eq(env.files["startup.lua"], nil)
    eq(env.files["vaults.lua"], INSTALLER_BODY, "the installer stays put")
    H.contains(env.printed(), "Removed 2 files")
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
