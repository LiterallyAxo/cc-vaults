--[[
  vaults -- installer / updater for the Vault Network monitor

  Grab this one file, then let it fetch everything else:

    wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vaults.lua
    vaults install

  Commands:
    vaults install [--startup]   download the monitor (and optionally autorun it)
    vaults update                pull the latest version, including this script
    vaults run                   start the monitor
    vaults startup on|off        run the monitor when the computer boots
    vaults version               show the installed and available versions
    vaults uninstall             remove everything this installed
]]

local VERSION = "1.1.0"

local REPO    = "LiterallyAxo/cc-vaults"
local BRANCH  = "main"
local RAW     = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
local FILES   = { "vault_stock.lua", "vaults.lua" }
local MAIN    = "vault_stock.lua"
local STAMP   = ".vaults-version"
local STARTUP = "startup.lua"
local MARKER  = "-- installed by vaults"

--------------------------------------------------------------------- output
local canColor = term and term.isColour and term.isColour()

local function say(text, color)
  if canColor and color then term.setTextColour(color) end
  print(text)
  if canColor and color then term.setTextColour(colours.white) end
end

local function ok(text)   say(text, colours.lime) end
local function warn(text) say(text, colours.yellow) end
local function fail(text) say(text, colours.red) end
local function dim(text)  say(text, colours.lightGrey) end

local function human(bytes)
  if bytes >= 1024 then return string.format("%.1f KB", bytes / 1024) end
  return bytes .. " B"
end

--------------------------------------------------------------------- io
local function fetch(path)
  if not http then
    return nil, "the http API is disabled in this server's CC config"
  end
  -- the raw.githubusercontent CDN caches for a few minutes; bust it
  local url = RAW .. path .. "?cb=" .. tostring(os.epoch and os.epoch("utc") or os.clock())
  local res, err = http.get(url)
  if not res then return nil, err or "request failed" end
  local body = res.readAll()
  res.close()
  if not body or #body == 0 then return nil, "empty response" end
  return body
end

local function readLocal(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "r")
  if not f then return nil end
  local body = f.readAll()
  f.close()
  return body
end

local function writeLocal(path, body)
  local f = fs.open(path, "w")
  if not f then return false, "cannot write " .. path end
  f.write(body)
  f.close()
  return true
end

local function remoteVersion()
  local body = fetch("version.txt")
  return body and body:gsub("%s+$", "") or nil
end

local function localVersion()
  local body = readLocal(STAMP)
  return body and body:gsub("%s+$", "") or nil
end

--------------------------------------------------------------------- actions
-- downloads every file; returns changed, unchanged, error
local function sync()
  local changed, unchanged = {}, {}
  for _, name in ipairs(FILES) do
    local body, err = fetch(name)
    if not body then return nil, nil, name .. ": " .. tostring(err) end
    if readLocal(name) == body then
      unchanged[#unchanged + 1] = name
    else
      local wrote, werr = writeLocal(name, body)
      if not wrote then return nil, nil, werr end
      changed[#changed + 1] = { name = name, size = #body }
    end
  end
  local version = remoteVersion()
  if version then writeLocal(STAMP, version) end
  return changed, unchanged, nil
end

local function setStartup(enabled)
  if enabled then
    writeLocal(STARTUP, MARKER .. "\nshell.run(\"" .. MAIN .. "\")\n")
    ok("startup: the monitor will run when this computer boots")
  else
    local body = readLocal(STARTUP)
    if body and body:find(MARKER, 1, true) then
      fs.delete(STARTUP)
      ok("startup: disabled")
    elseif body then
      warn("startup.lua was not created by vaults - leaving it alone")
    else
      dim("startup: nothing to disable")
    end
  end
end

local function install(flags)
  say("Installing from " .. REPO .. " (" .. BRANCH .. ")")
  local changed, unchanged, err = sync()
  if err then fail("failed: " .. err) return false end

  for _, f in ipairs(changed) do
    ok("  + " .. f.name .. "  " .. human(f.size))
  end
  for _, name in ipairs(unchanged) do
    dim("  = " .. name .. "  already current")
  end
  if flags.startup then setStartup(true) end

  local version = localVersion()
  ok("Installed" .. (version and (" v" .. version) or ""))
  dim("Run it with:  " .. MAIN:gsub("%.lua$", ""))
  return true
end

local function update()
  local before = localVersion()
  say("Checking " .. REPO .. " for updates...")
  local changed, unchanged, err = sync()
  if err then fail("failed: " .. err) return false end

  if #changed == 0 then
    ok("Already up to date" .. (before and (" (v" .. before .. ")") or ""))
    return true
  end

  local selfUpdated = false
  for _, f in ipairs(changed) do
    ok("  ^ " .. f.name .. "  " .. human(f.size))
    if f.name == "vaults.lua" then selfUpdated = true end
  end
  for _, name in ipairs(unchanged) do
    dim("  = " .. name)
  end

  local after = localVersion()
  ok("Updated" .. (before and after and (" " .. before .. " -> " .. after)
                          or (after and (" to v" .. after) or "")))
  if selfUpdated then dim("vaults itself was updated; the new copy is on disk") end
  return true
end

local function version()
  local mine, remote = localVersion(), remoteVersion()
  say("vaults      v" .. VERSION)
  say("installed   " .. (mine or "unknown - run: vaults install"))
  if remote then
    if mine == remote then
      ok("available   " .. remote .. "  (up to date)")
    else
      warn("available   " .. remote .. "  (run: vaults update)")
    end
  else
    warn("available   could not reach GitHub")
  end
  dim("monitor     " .. (fs.exists(MAIN) and "installed" or "missing"))
end

local function uninstall()
  local removed = 0
  for _, name in ipairs(FILES) do
    if name ~= "vaults.lua" and fs.exists(name) then
      fs.delete(name); removed = removed + 1
    end
  end
  if fs.exists(STAMP) then fs.delete(STAMP); removed = removed + 1 end
  setStartup(false)
  ok("Removed " .. removed .. " file" .. (removed == 1 and "" or "s"))
  dim("This installer is still here; delete it with:  rm vaults.lua")
end

local function usage()
  say("vaults v" .. VERSION .. " - Create vault monitor installer")
  say("")
  say("  vaults install [--startup]   download the monitor")
  say("  vaults update                pull the latest version")
  say("  vaults run                   start the monitor")
  say("  vaults startup on|off        run the monitor at boot")
  say("  vaults version               show installed / available versions")
  say("  vaults uninstall             remove what was installed")
end

--------------------------------------------------------------------- main
local args = { ... }
local command = (args[1] or "help"):lower()

local flags = {}
for i = 2, #args do
  local a = args[i]:lower()
  if a == "--startup" or a == "-s" then flags.startup = true end
  flags[#flags + 1] = a
end

if command == "install" then
  install(flags)

elseif command == "update" or command == "upgrade" then
  update()

elseif command == "run" or command == "start" then
  if not fs.exists(MAIN) then
    warn(MAIN .. " is missing - installing it first")
    if not install(flags) then return end
  end
  shell.run(MAIN)

elseif command == "startup" then
  local mode = flags[1]
  if mode == "on" or mode == "enable" then
    setStartup(true)
  elseif mode == "off" or mode == "disable" then
    setStartup(false)
  else
    fail("usage: vaults startup on|off")
  end

elseif command == "version" or command == "--version" or command == "-v" then
  version()

elseif command == "uninstall" or command == "remove" then
  uninstall()

elseif command == "help" or command == "--help" or command == "-h" then
  usage()

else
  fail("unknown command: " .. command)
  usage()
end
