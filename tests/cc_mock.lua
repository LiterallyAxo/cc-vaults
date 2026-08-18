--[[
  A small ComputerCraft (CC: Tweaked) emulator, just complete enough to run
  the scripts in this repo headlessly under a normal Lua 5.4 interpreter.

  Provides: peripheral, term, monitors, colors/colours, keys, parallel,
  textutils, fs, http, shell and the os event queue, plus a screen capture
  so tests can assert on what was actually drawn.
]]

local mock = {}

--------------------------------------------------------------------- colours
local COLORS = {
  white = 0x1, orange = 0x2, magenta = 0x4, lightBlue = 0x8,
  yellow = 0x10, lime = 0x20, pink = 0x40, gray = 0x80,
  lightGray = 0x100, cyan = 0x200, purple = 0x400, blue = 0x800,
  brown = 0x1000, green = 0x2000, red = 0x4000, black = 0x8000,
}

local KEYS = {}
do
  local i = 1
  for letter in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    KEYS[letter] = i; i = i + 1
  end
  KEYS.up, KEYS.down, KEYS.left, KEYS.right = 100, 101, 102, 103
  KEYS.pageUp, KEYS.pageDown, KEYS.tab, KEYS.escape = 104, 105, 106, 107
  KEYS.enter, KEYS.space = 108, 109
end

--------------------------------------------------------------------- screen
local Screen = {}
Screen.__index = Screen

function Screen.new(w, h, color)
  local self = setmetatable({ w = w, h = h, color = color, palette = {} }, Screen)
  self.cx, self.cy = 1, 1
  self.textScale = 1
  self.blits = 0
  self:reset()
  return self
end

-- keep the last painted frame around: programs clear the screen on the way
-- out, and tests still want to assert on what the user actually saw
function Screen:snap()
  local copy = setmetatable({
    w = self.w, h = self.h, color = self.color, palette = self.palette,
    ch = {}, fg = {}, bg = {}, blits = self.blits,
  }, Screen)
  for y = 1, self.h do
    copy.ch[y], copy.fg[y], copy.bg[y] = {}, {}, {}
    for x = 1, self.w do
      copy.ch[y][x] = self.ch[y][x]
      copy.fg[y][x] = self.fg[y][x]
      copy.bg[y][x] = self.bg[y][x]
    end
  end
  return copy
end

function Screen:isBlank()
  for y = 1, self.h do
    for x = 1, self.w do
      if self.ch[y][x] ~= " " then return false end
    end
  end
  return true
end

-- the frame tests should look at: the live one, or the last non-blank one
function Screen:view()
  if not self:isBlank() then return self end
  return self.snapshot or self
end

function Screen:reset()
  if self.ch and not self:isBlank() then self.snapshot = self:snap() end
  self.ch, self.fg, self.bg = {}, {}, {}
  for y = 1, self.h do
    self.ch[y], self.fg[y], self.bg[y] = {}, {}, {}
    for x = 1, self.w do
      self.ch[y][x], self.fg[y][x], self.bg[y][x] = " ", "0", "f"
    end
  end
end

function Screen:row(y)
  return table.concat(self.ch[y] or {})
end

function Screen:lines()
  local out = {}
  for y = 1, self.h do out[y] = self:row(y) end
  return out
end

function Screen:dump()
  return table.concat(self:lines(), "\n")
end

function Screen:contains(needle)
  for y = 1, self.h do
    if self:row(y):find(needle, 1, true) then return true, y end
  end
  return false
end

-- returns the blit colour char of the foreground at a position of some text
function Screen:fgOf(needle)
  for y = 1, self.h do
    local sx = self:row(y):find(needle, 1, true)
    if sx then return self.fg[y][sx], y, sx end
  end
  return nil
end

function Screen:api()
  local s = self
  local api
  api = {
    getSize = function() return s.w, s.h end,
    setCursorPos = function(x, y) s.cx, s.cy = math.floor(x), math.floor(y) end,
    getCursorPos = function() return s.cx, s.cy end,
    setCursorBlink = function() end,
    isColor = function() return s.color end,
    isColour = function() return s.color end,
    setTextScale = function(v) s.textScale = v end,
    setTextColor = function(c) s.text = c end,
    setTextColour = function(c) s.text = c end,
    setBackgroundColor = function(c) s.back = c end,
    setBackgroundColour = function(c) s.back = c end,
    setPaletteColour = function(slot, r, g, b) s.palette[slot] = { r, g, b } end,
    setPaletteColor = function(slot, r, g, b) s.palette[slot] = { r, g, b } end,
    getPaletteColour = function(slot)
      local p = s.palette[slot]
      if p then return p[1], p[2], p[3] end
      return 0, 0, 0
    end,
    getPaletteColor = function(slot) return api.getPaletteColour(slot) end,
    clear = function() s:reset() end,
    clearLine = function() end,
    write = function(text)
      text = tostring(text)
      for i = 1, #text do
        local x = s.cx + i - 1
        if s.cy >= 1 and s.cy <= s.h and x >= 1 and x <= s.w then
          s.ch[s.cy][x] = text:sub(i, i)
        end
      end
      s.cx = s.cx + #text
    end,
    blit = function(text, fg, bg)
      assert(#text == #fg and #text == #bg,
        "blit length mismatch: " .. #text .. "/" .. #fg .. "/" .. #bg)
      s.blits = s.blits + 1
      for i = 1, #text do
        local x = s.cx + i - 1
        if s.cy >= 1 and s.cy <= s.h and x >= 1 and x <= s.w then
          s.ch[s.cy][x] = text:sub(i, i)
          s.fg[s.cy][x] = fg:sub(i, i)
          s.bg[s.cy][x] = bg:sub(i, i)
        end
      end
      s.cx = s.cx + #text
    end,
    scroll = function() end,
  }
  return api
end

--------------------------------------------------------------------- fs mock
local function newFs(files)
  local data = {}
  for k, v in pairs(files or {}) do data[k] = v end

  local fs = {}
  local function norm(path)
    return (tostring(path):gsub("^%./", ""):gsub("^/", ""))
  end

  function fs.exists(path) return data[norm(path)] ~= nil end
  function fs.isDir(path)
    local p = norm(path) .. "/"
    if norm(path) == "" then return true end
    for k in pairs(data) do if k:sub(1, #p) == p then return true end end
    return false
  end
  function fs.delete(path) data[norm(path)] = nil end
  function fs.makeDir() end
  function fs.getDir(path) return (norm(path):match("^(.*)/[^/]*$")) or "" end
  function fs.getName(path) return (norm(path):match("([^/]+)$")) or norm(path) end
  function fs.combine(a, b)
    a, b = norm(a), norm(b)
    if a == "" then return b end
    return a .. "/" .. b
  end
  function fs.list(path)
    local out, seen = {}, {}
    local prefix = norm(path)
    prefix = prefix == "" and "" or prefix .. "/"
    for k in pairs(data) do
      if k:sub(1, #prefix) == prefix then
        local rest = k:sub(#prefix + 1):match("^[^/]+")
        if rest and not seen[rest] then seen[rest] = true; out[#out + 1] = rest end
      end
    end
    table.sort(out)
    return out
  end
  function fs.open(path, mode)
    path = norm(path)
    if mode:find("r") then
      local content = data[path]
      if not content then return nil, "No such file" end
      local pos = 1
      return {
        readAll = function() return content end,
        readLine = function()
          if pos > #content then return nil end
          local nl = content:find("\n", pos, true) or (#content + 1)
          local line = content:sub(pos, nl - 1)
          pos = nl + 1
          return line
        end,
        close = function() end,
      }
    end
    local buffer = mode:find("a") and (data[path] or "") or ""
    return {
      write = function(text) buffer = buffer .. tostring(text) end,
      writeLine = function(text) buffer = buffer .. tostring(text) .. "\n" end,
      flush = function() data[path] = buffer end,
      close = function() data[path] = buffer end,
    }
  end

  return fs, data
end

--------------------------------------------------------------------- env
-- opts:
--   vaults   = { ["create:item_vault_0"] = { {name=..., count=...}, ... } }
--   sizes    = { ["create:item_vault_0"] = 27 }
--   broken   = { ["create:item_vault_3"] = true }   -- list() throws
--   extras   = { ["monitor_1"] = "monitor" }        -- other peripherals
--   stations = { ["create:track_station_0"] = { name=, present=, train=,
--                                               imminent=, enroute=, schedule= } }
--   sources  = { ["create_source_0"] = { width = 24, height = 3 } }
--   modem    = "modem_0"                            -- makes rednet work
--   time     = 15.5                                 -- os.time(), in hours
--   width/height/color, events, files, urls
function mock.newEnv(opts)
  opts = opts or {}
  local env = {}

  local width  = opts.width or 82
  local height = opts.height or 26
  local screen = Screen.new(width, height, opts.color ~= false)
  local termScreen = Screen.new(51, 19, true)

  env.screen = screen
  env.term = termScreen
  env.output = {}
  env.timers = {}
  env.httpLog = {}
  env.shellRuns = {}

  ---- peripherals ---------------------------------------------------------
  local vaults = {}
  local sizes  = opts.sizes or {}
  local broken = opts.broken or {}
  for name, items in pairs(opts.vaults or {}) do vaults[name] = items end

  env.setVault = function(name, items) vaults[name] = items end
  env.removeVault = function(name) vaults[name] = nil end
  env.breakVault = function(name, isBroken) broken[name] = isBroken end

  -- Create train stations and CC:C Bridge display sources
  local stations, sources = {}, {}
  for name, data in pairs(opts.stations or {}) do stations[name] = data end
  for name, data in pairs(opts.sources or {}) do
    sources[name] = { width = data.width or 24, height = data.height or 3, lines = {} }
  end
  env.stations = stations
  env.sources = sources
  env.setStation = function(name, data) stations[name] = data end
  env.sourceText = function(name)
    local source = sources[name]
    if not source then return nil end
    return table.concat(source.lines, "\n")
  end

  local modemName = opts.modem
  local monitorName = opts.monitorName
  if monitorName == nil then monitorName = "monitor_0" end

  local function peripheralNames()
    local names = {}
    for name in pairs(vaults) do names[#names + 1] = name end
    for name in pairs(stations) do names[#names + 1] = name end
    for name in pairs(sources) do names[#names + 1] = name end
    for name in pairs(opts.extras or {}) do names[#names + 1] = name end
    if modemName then names[#names + 1] = modemName end
    if monitorName then names[#names + 1] = monitorName end
    table.sort(names)
    return names
  end

  local function typeOf(name)
    if vaults[name] then return "create:item_vault", "inventory" end
    if stations[name] then return "Create_Station" end
    if sources[name] then return "create_source" end
    if name == modemName then return "modem" end
    if name == monitorName then return "monitor" end
    local extra = (opts.extras or {})[name]
    if extra then return extra end
    return nil
  end

  local monitorApi
  local wrapped = {}          -- so peripheral.getName can recognise a wrapper
  local build
  local function wrap(name)
    if typeOf(name) == nil then
      wrapped[name] = nil
      return nil
    end
    if not wrapped[name] then wrapped[name] = build(name) end
    return wrapped[name]
  end

  function build(name)
    if vaults[name] then
      return {
        list = function()
          if broken[name] then error("peripheral is not responding", 0) end
          local slots = {}
          for i, item in ipairs(vaults[name]) do
            slots[i] = { name = item.name, count = item.count, nbt = item.nbt }
          end
          return slots
        end,
        size = function()
          if broken[name] then error("peripheral is not responding", 0) end
          return sizes[name] or 27
        end,
        getItemDetail = function(slot)
          if broken[name] then error("peripheral is not responding", 0) end
          local item = vaults[name][slot]
          if not item then return nil end
          return {
            name = item.name,
            count = item.count,
            displayName = item.displayName or item.name,
            maxCount = item.maxCount or 64,
          }
        end,
      }
    end
    if stations[name] then
      local function field(key, fallback)
        local value = stations[name][key]
        if value == nil then return fallback end
        return value
      end
      return {
        getStationName  = function() return field("name", name) end,
        setStationName  = function(value) stations[name].name = value end,
        isTrainPresent  = function() return field("present", false) end,
        isTrainImminent = function() return field("imminent", false) end,
        isTrainEnroute  = function() return field("enroute", false) end,
        getTrainName    = function() return field("train", nil) end,
        hasSchedule     = function() return stations[name].schedule ~= nil end,
        getSchedule     = function()
          if not stations[name].present then error("there is no train here", 0) end
          return stations[name].schedule
        end,
      }
    end
    if sources[name] then
      local source = sources[name]
      local cy = 1
      return {
        getSize = function() return source.width, source.height end,
        clear = function() source.lines = {} end,
        clearLine = function() source.lines[cy] = "" end,
        setCursorPos = function(_, y) cy = math.floor(y) end,
        getCursorPos = function() return 1, cy end,
        setTextColour = function() end,
        setBackgroundColour = function() end,
        write = function(text) source.lines[cy] = (source.lines[cy] or "") .. tostring(text) end,
        getLine = function(y) return source.lines[y] or "" end,
      }
    end
    if name == modemName then
      return { isWireless = function() return false end }
    end
    if name == monitorName then return monitorApi end
    return nil
  end

  local peripheral = {
    getNames = peripheralNames,
    getType = typeOf,
    hasType = function(name, want)
      for _, t in ipairs({ typeOf(name) }) do
        if t == want then return true end
      end
      return false
    end,
    isPresent = function(name) return typeOf(name) ~= nil end,
    wrap = wrap,
    getName = function(obj)
      if obj == monitorApi then return monitorName end
      for _, name in ipairs(peripheralNames()) do
        if wrap(name) == obj then return name end
      end
      return "unknown"
    end,
    call = function(name, method, ...)
      local p = wrap(name)
      if not p then error("no such peripheral " .. tostring(name), 0) end
      return p[method](...)
    end,
    find = function(kind)
      for _, name in ipairs(peripheralNames()) do
        for _, t in ipairs({ typeOf(name) }) do
          if t == kind then return wrap(name) end
        end
      end
      return nil
    end,
  }

  monitorApi = screen:api()
  if monitorName then
    monitorApi.getName = function() return monitorName end
  end

  ---- events / os ---------------------------------------------------------
  local queue = {}
  for i, e in ipairs(opts.events or {}) do queue[i] = e end
  env.queue = queue
  env.push = function(e) queue[#queue + 1] = e end
  env.pushNext = function(e) table.insert(queue, 1, e) end

  local exhausted = false
  local clock = 0
  local timerId = 0

  local worldTime = opts.time or 6.0
  env.setTime = function(hours) worldTime = hours end

  local osApi = {
    clock = function() clock = clock + 0.05 return clock end,
    time = function() return worldTime end,
    day = function() return 1 end,
    epoch = function() return 1700000000000 end,
    sleep = function() end,
    startTimer = function(delay)
      timerId = timerId + 1
      env.timers[#env.timers + 1] = { id = timerId, delay = delay }
      return timerId
    end,
    cancelTimer = function() end,
    queueEvent = function(...) queue[#queue + 1] = { ... } end,
    getComputerLabel = function() return "test" end,
    date = os.date,
    pullEvent = function()
      while true do
        local e = table.remove(queue, 1)
        if e == nil then
          if exhausted then error("mock: event queue exhausted", 0) end
          exhausted = true
          return "key", KEYS.q          -- always terminate the loop
        end
        if type(e) == "function" then
          e(env)                        -- lets a test mutate state mid-run
        else
          return table.unpack(e)
        end
      end
    end,
  }
  osApi.pullEventRaw = osApi.pullEvent

  ---- misc APIs -----------------------------------------------------------
  local parallel = {
    waitForAll = function(...)
      for _, fn in ipairs({ ... }) do fn() end
    end,
    waitForAny = function(...)
      local fns = { ... }
      if fns[1] then fns[1]() end
    end,
  }

  env.rednetSent = {}
  local rednet = {
    open = function(side) env.rednetOpen = side end,
    close = function() env.rednetOpen = nil end,
    isOpen = function() return env.rednetOpen ~= nil end,
    broadcast = function(message, protocol)
      env.rednetSent[#env.rednetSent + 1] = { message = message, protocol = protocol }
    end,
    send = function(id, message, protocol)
      env.rednetSent[#env.rednetSent + 1] = { to = id, message = message, protocol = protocol }
    end,
    receive = function() return nil end,
  }

  local textutils = {
    formatTime = function() return "06:00" end,
    serialize = function(t) return tostring(t) end,
    serializeJSON = function(t) return tostring(t) end,
    tabulate = function() end,
  }

  local fsApi, files = newFs(opts.files)
  env.files = files

  local urls = opts.urls or {}
  local http = {
    get = function(url)
      env.httpLog[#env.httpLog + 1] = url
      local base = url:gsub("%?.*$", "")
      local body = urls[base] or urls[url]
      if body == nil then return nil, "404: Not Found" end
      local pos = 1
      return {
        readAll = function() return body end,
        readLine = function()
          if pos > #body then return nil end
          local nl = body:find("\n", pos, true) or (#body + 1)
          local line = body:sub(pos, nl - 1)
          pos = nl + 1
          return line
        end,
        getResponseCode = function() return 200 end,
        close = function() end,
      }
    end,
    checkURL = function() return true end,
  }

  local termApi = termScreen:api()
  termApi.current = function() return termApi end
  termApi.native = function() return termApi end
  termApi.redirect = function() return termApi end

  local shell = {
    run = function(...)
      env.shellRuns[#env.shellRuns + 1] = table.concat({ ... }, " ")
      return true
    end,
    getRunningProgram = function() return opts.program or "vaults.lua" end,
    dir = function() return "" end,
    resolve = function(p) return p end,
  }

  ---- sandbox globals -----------------------------------------------------
  local G = {
    -- stock lua
    assert = assert, error = error, ipairs = ipairs, pairs = pairs,
    pcall = pcall, xpcall = xpcall, select = select, next = next,
    setmetatable = setmetatable, getmetatable = getmetatable,
    rawget = rawget, rawset = rawset, rawequal = rawequal, rawlen = rawlen,
    tonumber = tonumber, tostring = tostring, type = type, unpack = table.unpack,
    math = math, string = string, table = table, coroutine = coroutine,
    load = load,
    -- cc apis
    colors = COLORS, colours = COLORS, keys = KEYS, rednet = rednet,
    peripheral = peripheral, parallel = parallel, textutils = textutils,
    fs = fsApi, http = http, shell = shell, term = termApi, os = osApi,
    sleep = function() end,
    read = function() return opts.readInput or "" end,
    write = function(text) termApi.write(text) end,
    print = function(...)
      local parts = {}
      for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
      env.output[#env.output + 1] = table.concat(parts, "\t")
    end,
    printError = function(...)
      local parts = {}
      for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
      env.output[#env.output + 1] = "ERROR: " .. table.concat(parts, "\t")
    end,
  }
  if opts.noHttp then G.http = nil end   -- server with the http API turned off
  G._G = G
  G._ENV = G
  G.__VAULT_TEST = {}
  env.globals = G
  env.colors = COLORS
  env.keys = KEYS

  --- run a script inside the sandbox; returns ok, err
  function env.run(path, ...)
    local chunk, loadErr = loadfile(path, "t", G)
    if not chunk then return false, loadErr end
    local args = { ... }
    local ok, err = pcall(function() return chunk(table.unpack(args)) end)
    env.internals = G.__VAULT_TEST.internals
    env.frame = screen:view()
    env.termFrame = termScreen:view()
    return ok, err
  end

  function env.printed()
    return table.concat(env.output, "\n")
  end

  return env
end

mock.COLORS = COLORS
mock.KEYS = KEYS
return mock
