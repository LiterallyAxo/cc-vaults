--[[
  vaults -- package manager for the cc-vaults scripts

  Grab this one file, then let it fetch everything else:

    wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vaults.lua
    vaults install

  Every script listed in the repo's manifest.txt is installed to the computer
  root as <name>.lua, so you just type its name to run it (`stock`).  vaults
  itself is in that manifest, so `vaults update` also updates the manager.

  Commands:
    vaults install [name ...]     install everything, or only the named scripts
    vaults update  [name ...]     update what is installed (vaults included)
    vaults list                   what is available, what is installed
    vaults run <name> [args ...]  run a script, installing it first if needed
    vaults remove <name>          delete one script
    vaults startup <name> on|off  run a script when the computer boots
    vaults startup off            clear the boot script
    vaults version                versions of this manager and the manifest
    vaults uninstall              remove every installed script
]]

local VERSION = "2.0.0"
local SELF    = "vaults"

local REPO     = "LiterallyAxo/cc-vaults"
local BRANCH   = "main"
local RAW      = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
local MANIFEST = "manifest.txt"
local STATE    = ".vaults-state"
local STARTUP  = "startup.lua"
local MARKER   = "-- installed by vaults"

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

local function pad(text, width)
  text = tostring(text)
  if #text >= width then return text end
  return text .. string.rep(" ", width - #text)
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

--------------------------------------------------------------------- manifest
-- lines look like:  name | path/in/repo.lua | version | description
local function parseManifest(body)
  local entries, order = {}, {}
  for line in body:gmatch("[^\r\n]+") do
    if line:match("%S") and not line:match("^%s*#") then
      local name, file, version, desc =
        line:match("^%s*([^|]-)%s*|%s*([^|]-)%s*|%s*([^|]-)%s*|%s*(.-)%s*$")
      if name and file and name ~= "" then
        entries[name] = { name = name, file = file, version = version, desc = desc }
        order[#order + 1] = name
      end
    end
  end
  return entries, order
end

local function getManifest()
  local body, err = fetch(MANIFEST)
  if not body then return nil, nil, err end
  local entries, order = parseManifest(body)
  if #order == 0 then return nil, nil, "the manifest is empty or malformed" end
  return entries, order, nil
end

--------------------------------------------------------------------- state
local function readState()
  local installed = {}
  for line in (readLocal(STATE) or ""):gmatch("[^\r\n]+") do
    local name, version = line:match("^(%S+)|(%S*)$")
    if name then installed[name] = version end
  end
  return installed
end

local function writeState(installed)
  local names = {}
  for name in pairs(installed) do names[#names + 1] = name end
  table.sort(names)
  local lines = {}
  for _, name in ipairs(names) do
    lines[#lines + 1] = name .. "|" .. (installed[name] or "")
  end
  writeLocal(STATE, table.concat(lines, "\n") .. "\n")
end

local function scriptFile(name) return name .. ".lua" end

--------------------------------------------------------------------- actions
-- returns "new" | "same" | "updated", or nil plus an error
local function installOne(entry, installed)
  local body, err = fetch(entry.file)
  if not body then return nil, entry.name .. ": " .. tostring(err) end

  local target = scriptFile(entry.name)
  local existing = readLocal(target)
  local status = (existing == body) and "same" or (existing and "updated" or "new")

  if status ~= "same" then
    local wrote, werr = writeLocal(target, body)
    if not wrote then return nil, werr end
  end
  installed[entry.name] = entry.version
  return status, nil, #body
end

local function report(name, status, size)
  local file = scriptFile(name)
  if status == "new" then
    ok("  + " .. pad(file, 16) .. human(size))
  elseif status == "updated" then
    ok("  ^ " .. pad(file, 16) .. human(size))
  else
    dim("  = " .. pad(file, 16) .. "already current")
  end
end

local function resolve(names, entries, order)
  if #names == 0 then return order end
  local wanted = {}
  for _, name in ipairs(names) do
    if not entries[name] then
      fail("unknown script: " .. name)
      dim("available: " .. table.concat(order, ", "))
      return nil
    end
    wanted[#wanted + 1] = name
  end
  return wanted
end

local function install(names)
  local entries, order, err = getManifest()
  if not entries then fail("failed: " .. err) return false end

  local targets = resolve(names, entries, order)
  if not targets then return false end

  say("Installing from " .. REPO)
  local installed = readState()
  local changed = 0
  for _, name in ipairs(targets) do
    local status, ierr, size = installOne(entries[name], installed)
    if not status then fail("failed: " .. ierr) return false end
    if status ~= "same" then changed = changed + 1 end
    report(name, status, size)
  end
  writeState(installed)

  local runnable = {}
  for _, name in ipairs(targets) do
    if name ~= SELF then runnable[#runnable + 1] = name end
  end
  ok("Installed " .. #targets .. " script" .. (#targets == 1 and "" or "s") ..
     (changed == 0 and " (nothing changed)" or ""))
  if #runnable > 0 then
    dim("Run:  " .. table.concat(runnable, "  |  "))
  end
  return true
end

local function update(names)
  local entries, order, err = getManifest()
  if not entries then fail("failed: " .. err) return false end

  local installed = readState()
  local targets = names
  if #targets == 0 then
    -- everything already on disk, plus the manager itself
    for _, name in ipairs(order) do
      if installed[name] or name == SELF or fs.exists(scriptFile(name)) then
        targets[#targets + 1] = name
      end
    end
  end
  targets = resolve(targets, entries, order)
  if not targets then return false end

  say("Checking " .. REPO .. " for updates...")
  local changed, selfUpdated = {}, false
  for _, name in ipairs(targets) do
    local before = installed[name]
    local status, uerr, size = installOne(entries[name], installed)
    if not status then fail("failed: " .. uerr) return false end
    report(name, status, size)
    if status ~= "same" then
      changed[#changed + 1] = { name = name, from = before, to = entries[name].version }
      if name == SELF then selfUpdated = true end
    end
  end
  writeState(installed)

  if #changed == 0 then
    ok("Already up to date")
  else
    for _, c in ipairs(changed) do
      ok("Updated " .. c.name .. " " ..
         (c.from and (c.from .. " -> " .. (c.to or "?")) or ("to v" .. (c.to or "?"))))
    end
    if selfUpdated then dim("vaults itself was updated; the new copy is on disk") end
  end

  -- anything new in the manifest that has never been installed
  local news = {}
  for _, name in ipairs(order) do
    if not installed[name] then news[#news + 1] = name end
  end
  if #news > 0 then
    dim("New in the manifest: " .. table.concat(news, ", ") ..
        "  (vaults install " .. news[1] .. ")")
  end
  return true
end

local function list()
  local entries, order, err = getManifest()
  if not entries then fail("failed: " .. err) return false end
  local installed = readState()

  say(pad("NAME", 10) .. pad("VERSION", 9) .. "STATUS")
  for _, name in ipairs(order) do
    local e = entries[name]
    local have = installed[name]
    local row = pad(e.name, 10) .. pad(e.version or "?", 9)
    if not have and not fs.exists(scriptFile(name)) then
      dim(row .. "not installed")
    elseif have == e.version then
      ok(row .. "installed")
    else
      warn(row .. "update available (" .. (have or "?") .. " -> " .. (e.version or "?") .. ")")
    end
    if e.desc and e.desc ~= "" then dim("          " .. e.desc) end
  end
  return true
end

local function setStartup(name, enabled)
  if enabled then
    writeLocal(STARTUP, MARKER .. "\nshell.run(\"" .. scriptFile(name) .. "\")\n")
    ok("startup: " .. name .. " will run when this computer boots")
  else
    local body = readLocal(STARTUP)
    if body and body:find(MARKER, 1, true) then
      fs.delete(STARTUP)
      ok("startup: cleared")
    elseif body then
      warn("startup.lua was not created by vaults - leaving it alone")
    else
      dim("startup: nothing to clear")
    end
  end
end

local function run(name, args)
  if not name then
    fail("usage: vaults run <name>")
    return false
  end
  if not fs.exists(scriptFile(name)) then
    warn(name .. " is not installed - fetching it first")
    if not install({ name }) then return false end
  end
  return shell.run(scriptFile(name), table.unpack(args))
end

local function remove(name)
  if not name then fail("usage: vaults remove <name>") return false end
  if name == SELF then
    warn("use 'vaults uninstall' to remove everything, then: rm vaults.lua")
    return false
  end
  local installed = readState()
  if not fs.exists(scriptFile(name)) then
    dim(name .. " is not installed")
    return true
  end
  fs.delete(scriptFile(name))
  installed[name] = nil
  writeState(installed)
  ok("Removed " .. scriptFile(name))
  return true
end

local function uninstall()
  local installed = readState()
  local removed = 0
  for name in pairs(installed) do
    if name ~= SELF and fs.exists(scriptFile(name)) then
      fs.delete(scriptFile(name))
      removed = removed + 1
    end
  end
  if fs.exists(STATE) then fs.delete(STATE) end
  setStartup(nil, false)
  ok("Removed " .. removed .. " script" .. (removed == 1 and "" or "s"))
  dim("This manager is still here; delete it with:  rm vaults.lua")
  return true
end

local function version()
  say("vaults      v" .. VERSION)
  local installed = readState()
  local entries = getManifest()
  local count = 0
  for name in pairs(installed) do
    if name ~= SELF then count = count + 1 end
  end
  say("installed   " .. count .. " script" .. (count == 1 and "" or "s") ..
      (installed[SELF] and (", manager v" .. installed[SELF]) or ""))
  if entries and entries[SELF] then
    if entries[SELF].version == VERSION then
      ok("manifest    v" .. entries[SELF].version .. "  (up to date)")
    else
      warn("manifest    v" .. entries[SELF].version .. "  (run: vaults update)")
    end
  else
    warn("manifest    could not reach GitHub")
  end
end

local function usage()
  say("vaults v" .. VERSION .. " - package manager for " .. REPO)
  say("")
  say("  vaults install [name ...]     install everything, or just these")
  say("  vaults update  [name ...]     update what is installed")
  say("  vaults list                   available and installed scripts")
  say("  vaults run <name> [args ...]  run a script")
  say("  vaults remove <name>          delete one script")
  say("  vaults startup <name> on|off  run a script at boot")
  say("  vaults version                version info")
  say("  vaults uninstall              remove every installed script")
end

--------------------------------------------------------------------- main
local argv = { ... }
local command = (argv[1] or "help"):lower()

local rest = {}
for i = 2, #argv do rest[#rest + 1] = argv[i] end

if command == "install" or command == "add" then
  install(rest)

elseif command == "update" or command == "upgrade" then
  update(rest)

elseif command == "list" or command == "ls" then
  list()

elseif command == "run" or command == "start" then
  local name = table.remove(rest, 1)
  run(name, rest)

elseif command == "remove" or command == "rm" then
  remove(rest[1])

elseif command == "startup" then
  local name, mode = rest[1], rest[2]
  if name == "off" or name == "disable" or name == "clear" then
    setStartup(nil, false)
  elseif not name or not mode then
    fail("usage: vaults startup <name> on|off   (or: vaults startup off)")
  elseif mode == "on" or mode == "enable" then
    if not fs.exists(scriptFile(name)) then
      warn(name .. " is not installed")
    else
      setStartup(name, true)
    end
  elseif mode == "off" or mode == "disable" then
    setStartup(name, false)
  else
    fail("usage: vaults startup <name> on|off")
  end

elseif command == "version" or command == "--version" or command == "-v" then
  version()

elseif command == "uninstall" then
  uninstall()

elseif command == "help" or command == "--help" or command == "-h" then
  usage()

else
  fail("unknown command: " .. command)
  usage()
end
