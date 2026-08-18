--[[
  rail  --  UK style train information displays for CC: Tweaked        v0.1.0

  Part of the cc-vaults package; install it with `vaults install rail`.

  Turns Create train stations into the boards you get on the real railway:
  the concourse departure and arrival summaries, the big platform board with
  its scrolling calling points, the little dot matrix over a doorway, the
  in-carriage passenger information screen and route diagram, a station clock,
  and Create flap displays / nixie tubes through CC:C Bridge.

    rail                    departures board (the default)
    rail arrivals           arrivals board
    rail platform [n]       platform board for platform n
    rail summary [n]        one line "next train" dot matrix
    rail onboard            in-carriage passenger information
    rail route              in-carriage route diagram
    rail concourse          station clock over the next departures
    rail flap               push the next departure onto Create displays
    rail hub                headless: read the stations, serve them by rednet
    rail setup              write a starter rail.cfg you can edit
    rail help               this list

  Every mode reads rail.cfg if it is there.  With no config and nothing wired
  up it runs on a demo timetable, so a fresh computer still shows you a board.

  Wiring:
    computer -> wired modem -> networking cable -> modem on each Train Station
    right-click each modem until it says "peripheral attached", then a monitor
]]

local VERSION = "0.1.0"
local CONFIG  = "rail.cfg"

--------------------------------------------------------------------- config
local config = {
  mode      = nil,              -- what to show when `rail` is run with no mode
  station   = "Create Central", -- the station this display belongs to
  code      = "CRC",            -- three letter code, as on the real thing
  operator  = "Create Rail",    -- train operator, named on onboard displays
  theme     = "dot",            -- "dot" amber dot matrix, "lcd" colour screen
  clock     = "mc",             -- "mc" in-game time, "real" the system clock
  textScale = 0.5,              -- monitor text scale
  refresh   = 5,                -- seconds between peripheral scans
  scroll    = 0.4,              -- seconds per column of scrolling text
  rotate    = 6,                -- seconds a rotating message stays up
  rows      = 0,                -- departures to list (0 = as many as fit)
  platform  = nil,              -- platform this display serves
  dwell     = 1,                -- minutes a train is booked to stand
  legRun    = 6,                -- minutes assumed between calling points
  train     = nil,              -- onboard/route: the Create train name
  coach     = nil,              -- onboard: coach letter, shown in the corner
  route     = nil,              -- onboard/route: station names, in order
  platforms = {},               -- station peripheral or name -> platform
  timetable = {},               -- booked services; see `rail setup`
  demo      = true,             -- invent a timetable when nothing is wired up
  logo      = true,             -- draw the double arrow where there is room
  messages  = {
    "See it. Say it. Sorted. Text the British Transport Police on 61016.",
    "Please keep your personal belongings with you at all times.",
    "Smoking is not permitted anywhere on this station.",
  },
}

local function loadConfig()
  if not (fs and fs.exists and fs.exists(CONFIG)) then return false end
  local handle = fs.open(CONFIG, "r")
  if not handle then return false end
  local src = handle.readAll()
  handle.close()
  local chunk, err = load(src, CONFIG, "t", {})
  if not chunk then return false, err end
  local ok, result = pcall(chunk)
  if not ok then return false, result end
  if type(result) ~= "table" then return false, CONFIG .. " must return a table" end
  for key, value in pairs(result) do config[key] = value end
  return true
end

local configOk, configErr = loadConfig()

--------------------------------------------------------------------- device
local mon = peripheral.find("monitor")
local dev = mon or term.current()
if mon and mon.setTextScale then mon.setTextScale(config.textScale) end

local isColor = dev.isColour and dev.isColour() or false

-- Two looks: the amber dot matrix everyone pictures when you say "departure
-- board", and the navy and white screens that have been replacing them.
local PALETTES = {
  dot = {
    [colors.black]     = 0x04060a,
    [colors.gray]      = 0x0c1017,
    [colors.lightGray] = 0x1d2431,
    [colors.brown]     = 0x8a5510,   -- dim amber, for rules and small print
    [colors.orange]    = 0xff9d1c,   -- the amber
    [colors.yellow]    = 0xffc95c,   -- bright amber, for headlines
    [colors.white]     = 0xfff2dc,
    [colors.red]       = 0xff5f52,
    [colors.lime]      = 0x74d47f,
    [colors.green]     = 0x2f7a44,
    [colors.cyan]      = 0x4fc3f7,
    [colors.lightBlue] = 0x2f6fd0,
    [colors.blue]      = 0x12295c,
    [colors.magenta]   = 0xc792ea,
    [colors.pink]      = 0xff7ab6,
    [colors.purple]    = 0x6b4bb8,
  },
  lcd = {
    [colors.black]     = 0x070b14,
    [colors.gray]      = 0x101a2e,
    [colors.lightGray] = 0x24344f,
    [colors.brown]     = 0x8fa3c4,
    [colors.orange]    = 0xf5a623,
    [colors.yellow]    = 0xffd166,
    [colors.white]     = 0xf7fbff,
    [colors.red]       = 0xff6b6b,
    [colors.lime]      = 0x3ddc84,
    [colors.green]     = 0x1f8a53,
    [colors.cyan]      = 0x5ec8f5,
    [colors.lightBlue] = 0x2f6fd0,
    [colors.blue]      = 0x0e3a86,
    [colors.magenta]   = 0xc792ea,
    [colors.pink]      = 0xff7ab6,
    [colors.purple]    = 0x6b4bb8,
  },
}

local theme
if isColor then
  local looks = {
    dot = {
      base   = colors.black,  panel  = colors.gray,    rule = colors.lightGray,
      band   = colors.gray,   text   = colors.orange,  head = colors.yellow,
      dim    = colors.brown,  bright = colors.white,   good = colors.orange,
      bad    = colors.red,    late   = colors.yellow,  mark = colors.orange,
      logo   = colors.yellow, bandText = colors.yellow,
    },
    lcd = {
      base   = colors.black,  panel  = colors.gray,    rule = colors.lightGray,
      band   = colors.blue,   text   = colors.white,   head = colors.white,
      dim    = colors.brown,  bright = colors.white,   good = colors.lime,
      bad    = colors.red,    late   = colors.orange,  mark = colors.cyan,
      logo   = colors.white,  bandText = colors.white,
    },
  }
  theme = looks[config.theme] or looks.dot
else
  -- a basic monitor only has black and white; keep everything legible
  local w, b, l = colors.white, colors.black, colors.lightGray
  theme = {
    base = b, panel = b, rule = l, band = w, bandText = b, text = w,
    head = w, dim = l, bright = w, good = w, bad = w, late = w, mark = w,
    logo = w,
  }
end

local savedPalette = {}
local function applyPalette()
  local palette = PALETTES[config.theme] or PALETTES.dot
  if not (isColor and dev.setPaletteColour) then return end
  for slot, rgb in pairs(palette) do
    savedPalette[slot] = { dev.getPaletteColour(slot) }
    dev.setPaletteColour(slot, rgb)
  end
end

local function restorePalette()
  if not dev.setPaletteColour then return end
  for slot, rgb in pairs(savedPalette) do
    dev.setPaletteColour(slot, rgb[1], rgb[2], rgb[3])
  end
end

--------------------------------------------------------------------- canvas
-- Double buffered character canvas: everything draws into per-cell tables and
-- flush() blits only the rows that changed, so the board does not flicker
-- while the calling points scroll past.
local HEX = "0123456789abcdef"
local blitOf = {}
for i = 0, 15 do blitOf[2 ^ i] = HEX:sub(i + 1, i + 1) end

local Canvas = {}
Canvas.__index = Canvas

function Canvas.new(device)
  local self = setmetatable({ dev = device }, Canvas)
  self:resize()
  return self
end

function Canvas:resize()
  self.w, self.h = self.dev.getSize()
  self.ch, self.fg, self.bg, self.last = {}, {}, {}, {}
  for y = 1, self.h do
    self.ch[y], self.fg[y], self.bg[y], self.last[y] = {}, {}, {}, false
  end
  self:clear(theme.base)
end

function Canvas:clear(bg)
  local f, b = blitOf[theme.text], blitOf[bg or theme.base]
  for y = 1, self.h do
    local ch, fg, bgr = self.ch[y], self.fg[y], self.bg[y]
    for x = 1, self.w do ch[x], fg[x], bgr[x] = " ", f, b end
  end
end

function Canvas:set(x, y, char, fg, bg)
  if x < 1 or y < 1 or x > self.w or y > self.h then return end
  self.ch[y][x] = char
  if fg then self.fg[y][x] = blitOf[fg] end
  if bg then self.bg[y][x] = blitOf[bg] end
end

function Canvas:rect(x, y, w, h, bg)
  local b = blitOf[bg]
  for yy = y, y + h - 1 do
    if yy >= 1 and yy <= self.h then
      local ch, bgr = self.ch[yy], self.bg[yy]
      for xx = math.max(1, x), math.min(self.w, x + w - 1) do
        ch[xx], bgr[xx] = " ", b
      end
    end
  end
end

function Canvas:text(x, y, str, fg, bg)
  if y < 1 or y > self.h then return end
  str = tostring(str)
  for i = 1, #str do
    local xx = x + i - 1
    if xx > self.w then break end
    if xx >= 1 then
      self.ch[y][xx] = str:sub(i, i)
      if fg then self.fg[y][xx] = blitOf[fg] end
      if bg then self.bg[y][xx] = blitOf[bg] end
    end
  end
end

function Canvas:right(x2, y, str, fg, bg)
  self:text(x2 - #tostring(str) + 1, y, str, fg, bg)
end

function Canvas:centre(y, str, fg, bg, x1, x2)
  x1, x2 = x1 or 1, x2 or self.w
  str = tostring(str)
  self:text(x1 + math.floor(((x2 - x1 + 1) - #str) / 2), y, str, fg, bg)
end

-- a thin rule: \140 is the middle row of the 2x3 drawing block
function Canvas:rule(x, y, width, fg, bg)
  self:text(x, y, string.rep("\140", math.max(0, width)), fg, bg)
end

-- Pixel art at 2x3 per character with the drawing glyphs at 128-159.  The six
-- pixels of a cell are bits 1, 2, 4, 8, 16, 32 reading left to right and top
-- to bottom; the glyphs only cover the first five, so when the bottom right
-- pixel is set the mask is inverted and the two colours swap.
function Canvas:sprite(x, y, rows, fg, bg)
  for cy = 0, math.ceil(#rows / 3) - 1 do
    for cx = 0, math.ceil(#(rows[1] or "") / 2) - 1 do
      local mask, bit = 0, 1
      for py = 1, 3 do
        for px = 1, 2 do
          local row = rows[cy * 3 + py]
          local cell = row and row:sub(cx * 2 + px, cx * 2 + px) or " "
          if cell ~= " " and cell ~= "." and cell ~= "" then mask = mask + bit end
          bit = bit * 2
        end
      end
      local f, b = fg, bg
      if mask >= 32 then
        mask, f, b = 31 - (mask - 32), bg, fg
      end
      self:set(x + cx, y + cy, mask == 0 and " " or string.char(128 + mask), f, b)
    end
  end
end

function Canvas:flush()
  for y = 1, self.h do
    local line = table.concat(self.ch[y])
    local f = table.concat(self.fg[y])
    local b = table.concat(self.bg[y])
    local key = line .. f .. b
    if self.last[y] ~= key then
      self.last[y] = key
      self.dev.setCursorPos(1, y)
      self.dev.blit(line, f, b)
    end
  end
end

local canvas = Canvas.new(dev)

-- The double arrow, 12x9 pixels, which comes out as 6x3 characters.  Two bars
-- kinked in opposite directions, and rotationally symmetric, like the real one.
local DOUBLE_ARROW = {
  "..........##",
  "....########",
  ".###########",
  "##..........",
  "............",
  "..........##",
  "###########.",
  "########....",
  "##..........",
}

-- 3x5 digits for the concourse clock
local BIG = {
  ["0"] = { "###", "# #", "# #", "# #", "###" },
  ["1"] = { "  #", "  #", "  #", "  #", "  #" },
  ["2"] = { "###", "  #", "###", "#  ", "###" },
  ["3"] = { "###", "  #", "###", "  #", "###" },
  ["4"] = { "# #", "# #", "###", "  #", "  #" },
  ["5"] = { "###", "#  ", "###", "  #", "###" },
  ["6"] = { "###", "#  ", "###", "# #", "###" },
  ["7"] = { "###", "  #", "  #", "  #", "  #" },
  ["8"] = { "###", "# #", "###", "# #", "###" },
  ["9"] = { "###", "# #", "###", "  #", "###" },
  [":"] = { "   ", " # ", "   ", " # ", "   " },
  [" "] = { "   ", "   ", "   ", "   ", "   " },
}

local function bigWidth(text, scale)
  return #text * 4 * scale - scale
end

local function drawBig(x, y, text, scale, fg)
  local cx = x
  for i = 1, #text do
    local glyph = BIG[text:sub(i, i)] or BIG[" "]
    for row = 1, 5 do
      for col = 1, 3 do
        if glyph[row]:sub(col, col) == "#" then
          canvas:rect(cx + (col - 1) * scale, y + (row - 1) * scale,
                      scale, scale, fg)
        end
      end
    end
    cx = cx + 4 * scale
  end
end

--------------------------------------------------------------------- format
local function trim(str, width)
  str = tostring(str)
  if width < 1 then return "" end
  if #str <= width then return str end
  if width <= 2 then return str:sub(1, width) end
  return str:sub(1, width - 1) .. "."
end

local function upper(str)
  return tostring(str):upper()
end

local function ordinal(n)
  local suffix = "th"
  if n % 100 < 11 or n % 100 > 13 then
    suffix = ({ "st", "nd", "rd" })[n % 10] or "th"
  end
  return n .. suffix
end

-- the visible slice of a line of text that scrolls right to left forever
local function marquee(text, width, tick)
  text = tostring(text)
  if #text <= width then return text end
  local loop = text .. "        \7        "
  local offset = math.floor(tick) % #loop
  return (loop:sub(offset + 1) .. loop):sub(1, width)
end

local function joinCalls(calls)
  if #calls == 0 then return "" end
  if #calls == 1 then return calls[1] .. " only" end
  local head = {}
  for i = 1, #calls - 1 do head[i] = calls[i] end
  return table.concat(head, ", ") .. " and " .. calls[#calls]
end

--------------------------------------------------------------------- clock
-- Minecraft time is a float in hours; the real clock is there for anyone who
-- would rather their railway ran to the wall clock.
local function nowMinutes()
  if config.clock == "real" then
    local t = os.date("*t")
    return t.hour * 60 + t.min
  end
  return math.floor((os.time() or 0) * 60 + 0.5) % 1440
end

local function hhmm(minutes)
  minutes = math.floor(minutes + 0.5) % 1440
  return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end

local function clockText()
  if config.clock == "real" then return os.date("%H:%M") end
  return hhmm(nowMinutes())
end

local function parseTime(text)
  if type(text) == "number" then return text end
  local h, m = tostring(text):match("^(%d+)[:%.](%d+)")
  if not h then return nil end
  return (tonumber(h) * 60 + tonumber(m)) % 1440
end

--------------------------------------------------------------------- state
local MODES = {
  "departures", "arrivals", "platform", "summary",
  "onboard", "route", "concourse",
}

local state = {
  mode     = "departures",
  services = {},   -- everything leaving here, soonest first
  arrivals = {},   -- and everything coming in
  stations = {},   -- live Create station records
  trains   = {},   -- train name -> where it was last seen
  known    = {},   -- platform -> the last calling pattern seen there
  source   = "demo",
  tick     = 0,
  lastScan = 0,
  hubSeen  = 0,
}

--------------------------------------------------------------------- live
local function callMethod(p, method, ...)
  if type(p[method]) ~= "function" then return nil end
  local ok, value = pcall(p[method], ...)
  if ok then return value end
  return nil
end

local function stationNames()
  local found = {}
  for _, name in ipairs(peripheral.getNames()) do
    for _, kind in ipairs({ peripheral.getType(name) }) do
      if type(kind) == "string" and kind:lower():find("station", 1, true) then
        found[#found + 1] = name
        break
      end
    end
  end
  table.sort(found)
  return found
end

-- Create schedule destinations are filters, so "Kings Cross *" matches every
-- platform at Kings Cross
local function stopMatches(filter, name)
  filter = tostring(filter):gsub("^%s+", ""):gsub("%s+$", "")
  name = tostring(name)
  if filter == name then return true end
  local pattern = "^" .. filter:gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0")
                              :gsub("%*", ".*") .. "$"
  return name:match(pattern) ~= nil
end

local function cleanStop(text)
  return (tostring(text):gsub("%*", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function platformOf(station)
  local set = config.platforms or {}
  local given = set[station.peripheral] or set[station.name]
  if given then return tostring(given) end
  local fromName = tostring(station.name):match("[Pp]latform%s*(%w+)")
  if fromName then return fromName end
  local fromPeripheral = tostring(station.peripheral):match("(%d+)$")
  return fromPeripheral or "-"
end

local function ownStation(station)
  local set = config.platforms or {}
  if set[station.peripheral] or set[station.name] then return true end
  return tostring(station.name):lower():find(tostring(config.station):lower(), 1, true) ~= nil
end

local function scheduleStops(schedule)
  local stops = {}
  if type(schedule) ~= "table" then return stops end
  local entries = schedule.entries or schedule.Entries
  if type(entries) ~= "table" then return stops end
  for _, entry in ipairs(entries) do
    local instruction = type(entry) == "table" and (entry.instruction or entry.Instruction)
    if type(instruction) == "table" then
      local id = tostring(instruction.id or instruction.Id or "")
      local data = instruction.data or instruction.Data
      if id:find("destination", 1, true) and type(data) == "table" then
        local text = data.text or data.Text
        if text then stops[#stops + 1] = tostring(text) end
      end
    end
  end
  return stops
end

-- everywhere the train calls after here, in order, stopping if it comes back
local function onwardCalls(stops, here)
  local start
  for i, stop in ipairs(stops) do
    if stopMatches(stop, here) then start = i break end
  end
  local calls = {}
  if not start then
    for i, stop in ipairs(stops) do calls[i] = cleanStop(stop) end
    return calls
  end
  for step = 1, #stops - 1 do
    local stop = stops[((start - 1 + step) % #stops) + 1]
    if stopMatches(stop, here) then break end
    calls[#calls + 1] = cleanStop(stop)
  end
  return calls
end

local function previousCall(stops, here)
  for i, stop in ipairs(stops) do
    if stopMatches(stop, here) then
      return cleanStop(stops[((i - 2) % #stops) + 1])
    end
  end
  return nil
end

local function readStation(name)
  local p = peripheral.wrap(name)
  if type(p) ~= "table" then return nil end
  local station = {
    peripheral = name,
    name       = callMethod(p, "getStationName") or name,
    present    = callMethod(p, "isTrainPresent") or false,
    imminent   = callMethod(p, "isTrainImminent") or false,
    enroute    = callMethod(p, "isTrainEnroute") or false,
    train      = callMethod(p, "getTrainName"),
  }
  if station.present then station.schedule = callMethod(p, "getSchedule") end
  station.platform = platformOf(station)
  return station
end

local function trackTrains(stations, now)
  for _, station in ipairs(stations) do
    local train = station.train
    if train and station.present then
      state.trains[train] = { at = station.name, standing = true, since = now }
    end
  end
  -- a train that was standing here and is not any more has left
  for _, station in ipairs(stations) do
    if not station.present then
      for name, where in pairs(state.trains) do
        if where.at == station.name and where.standing and station.train ~= name then
          state.trains[name] = { at = station.name, standing = false, since = now }
        end
      end
    end
  end
end

-- Departures we can see for ourselves.  A schedule can only be read while the
-- train is standing at the station, so the calling pattern each platform last
-- served is remembered and reused for the trains that are still on their way.
local function liveServices(now)
  local stations = {}
  for _, name in ipairs(stationNames()) do
    local station = readStation(name)
    if station then stations[#stations + 1] = station end
  end
  state.stations = stations
  trackTrains(stations, now)

  local mine = {}
  for _, station in ipairs(stations) do
    if ownStation(station) then mine[#mine + 1] = station end
  end
  if #mine == 0 then mine = stations end

  local services = {}
  for _, station in ipairs(mine) do
    local key = station.platform
    if station.present then
      local stops = scheduleStops(station.schedule)
      local calls = onwardCalls(stops, station.name)
      if #calls > 0 then
        state.known[key] = {
          calls  = calls,
          dest   = calls[#calls],
          origin = previousCall(stops, station.name),
        }
      end
    end
    local known = state.known[key]
    if known and (station.present or station.imminent or station.enroute) then
      local wait = config.legRun
      if station.present then wait = config.dwell
      elseif station.imminent then wait = math.max(1, math.floor(config.dwell)) end
      services[#services + 1] = {
        platform = key,
        dest     = known.dest,
        calls    = known.calls,
        origin   = known.origin,
        train    = station.train,
        depart   = now + wait,
        arrive   = now + (station.present and 0 or wait),
        present  = station.present,
        imminent = station.imminent,
        enroute  = station.enroute,
        operator = config.operator,
        live     = true,
      }
    end
  end
  return services
end

--------------------------------------------------------------------- booked
local function bookedServices(now)
  local services = {}
  for _, row in ipairs(config.timetable or {}) do
    local depart = parseTime(row.depart or row.time)
    if depart then
      local wait = (depart - now) % 1440
      if wait > 1435 then wait = wait - 1440 end   -- keep one just gone at the top
      local calls = row.calls or {}
      services[#services + 1] = {
        platform  = tostring(row.platform or "-"),
        dest      = row.dest or calls[#calls] or "?",
        origin    = row.origin,
        calls     = calls,
        via       = row.via,
        coaches   = row.coaches,
        operator  = row.operator or config.operator,
        train     = row.train,
        depart    = depart,
        arrive    = parseTime(row.arrive) or depart,
        delay     = row.delay,
        cancelled = row.cancelled,
        wait      = wait,
        booked    = true,
      }
    end
  end
  table.sort(services, function(a, b) return a.wait < b.wait end)
  return services
end

--------------------------------------------------------------------- demo
-- A plausible hour at a busy station, so a computer with nothing wired to it
-- still shows you what the board is meant to look like.
local DEMO = {
  { after = 4,  plat = "3",  coaches = 9, operator = "Create West Coast",
    from = "Wolverhampton", via = "Coventry",
    calls = { "Coventry", "Rugby", "Milton Keynes Central", "London Euston" } },
  { after = 9,  plat = "5",  coaches = 5, operator = "CrossCreate", delay = 7,
    from = "Bournville",
    calls = { "Wolverhampton", "Stafford", "Crewe", "Stockport", "Manchester Piccadilly" } },
  { after = 13, plat = "10", coaches = 4, operator = "Transport for Create",
    cancelled = true, from = "Nuneaton",
    calls = { "Smethwick Galton Bridge", "Worcester Shrub Hill", "Newport", "Cardiff Central" } },
  { after = 18, plat = "8",  coaches = 3, operator = "East Create Railway",
    from = "Redditch",
    calls = { "Water Orton", "Tamworth", "Burton-on-Trent", "Derby", "Nottingham" } },
  { after = 22, plat = "2",  coaches = 4, operator = "Chiltern Creations",
    from = "Kidderminster", via = "Solihull",
    calls = { "Solihull", "Dorridge", "Warwick", "Leamington Spa" } },
  { after = 27, plat = "4",  coaches = 8, operator = "Create West Coast",
    from = "Coventry", delay = 3,
    calls = { "Sandwell & Dudley", "Wolverhampton", "Crewe", "Liverpool Lime Street" } },
  { after = 31, plat = "1",  coaches = 2, operator = "Create Rail",
    from = "Lichfield Trent Valley",
    calls = { "Five Ways", "University", "Selly Oak", "Longbridge", "Redditch" } },
  { after = 36, plat = "6",  coaches = 10, operator = "Create West Coast",
    from = "Shrewsbury", via = "Stoke-on-Trent",
    calls = { "Stoke-on-Trent", "Macclesfield", "Stockport", "Manchester Piccadilly" } },
}

local function demoServices(now)
  local services = {}
  for i, row in ipairs(DEMO) do
    local depart = now + row.after
    services[#services + 1] = {
      platform  = row.plat,
      dest      = row.calls[#row.calls],
      origin    = row.from,
      calls     = row.calls,
      via       = row.via,
      coaches   = row.coaches,
      operator  = row.operator,
      train     = string.format("%dC%02d", 1 + (i % 9), i * 7 % 90),
      depart    = depart,
      arrive    = depart - config.dwell,
      delay     = row.delay,
      cancelled = row.cancelled,
      wait      = row.after,
      demo      = true,
    }
  end
  return services
end

--------------------------------------------------------------------- merge
local function matchLive(booked, live)
  for _, row in ipairs(live) do
    if row.platform == booked.platform then return row end
  end
  for _, row in ipairs(live) do
    if row.dest == booked.dest then return row end
  end
  return nil
end

-- Booked times are the skeleton; what the stations report is the flesh.  A
-- booked service whose train has not turned up starts running late by itself,
-- which is the whole point of an "Expected" column.
local function applyLive(services, live, now)
  for _, service in ipairs(services) do
    local match = matchLive(service, live)
    if match then
      service.train    = match.train or service.train
      service.present  = match.present
      service.imminent = match.imminent
      service.enroute  = match.enroute
      if #(match.calls or {}) > 0 and #(service.calls or {}) == 0 then
        service.calls = match.calls
        service.dest = match.dest or service.dest
      end
      if match.present and service.depart < now then
        service.delay = math.max(service.delay or 0, now - service.depart)
      end
    elseif not service.cancelled and service.depart < now - 1 then
      service.delay = math.max(service.delay or 0, math.floor(now - service.depart))
    end
  end
end

local function sortByTime(services, field)
  table.sort(services, function(a, b)
    local aw = a.wait or (a[field] or 0)
    local bw = b.wait or (b[field] or 0)
    if aw == bw then return (a.platform or "") < (b.platform or "") end
    return aw < bw
  end)
end

local function expectedOf(service)
  local delay = service.delay
  if type(delay) == "number" and delay > 0 then return service.depart + delay end
  return service.depart
end

-- what goes in the Expected column, and the colour it goes in
local function statusOf(service)
  if service.cancelled then return "Cancelled", theme.bad end
  if service.delay == "unknown" then return "Delayed", theme.late end
  if type(service.delay) == "number" and service.delay > 0 then
    return hhmm(expectedOf(service)), theme.late
  end
  return "On time", theme.good
end

local function refresh()
  local now = nowMinutes()
  local live = liveServices(now)
  local services = bookedServices(now)

  if #services > 0 then
    state.source = "timetable"
    applyLive(services, live, now)
  elseif #live > 0 then
    state.source = "live"
    for _, service in ipairs(live) do service.wait = service.depart - now end
    services = live
  elseif config.demo then
    state.source = "demo"
    services = demoServices(now)
  else
    state.source = "none"
    services = {}
  end

  sortByTime(services, "depart")
  state.services = services

  local arrivals = {}
  for _, service in ipairs(services) do
    if service.origin then
      local copy = {}
      for key, value in pairs(service) do copy[key] = value end
      copy.wait = (copy.arrive or copy.depart) - now
      arrivals[#arrivals + 1] = copy
    end
  end
  sortByTime(arrivals, "arrive")
  state.arrivals = arrivals
  state.lastScan = now
end

--------------------------------------------------------------------- rednet
-- A hub reads the stations and shouts what it sees; displays that cannot see
-- a station of their own listen in.  Everything works without this, it just
-- saves running networking cable to the far end of the layout.
local link = { open = false }

function link.start()
  if not rednet then return false end
  local modem = peripheral.find("modem")
  if not modem then return false end
  local ok = pcall(rednet.open, peripheral.getName(modem))
  link.open = ok and true or false
  return link.open
end

function link.publish()
  if not link.open then return end
  pcall(rednet.broadcast, {
    station  = config.station,
    services = state.services,
    trains   = state.trains,
    at       = nowMinutes(),
  }, "rail")
end

function link.accept(message)
  if type(message) ~= "table" then return false end
  if message.station and message.station ~= config.station then return false end
  if type(message.services) == "table" and #message.services > 0 then
    state.services = message.services
    state.source = "hub"
    local arrivals = {}
    for _, service in ipairs(message.services) do
      if service.origin then arrivals[#arrivals + 1] = service end
    end
    state.arrivals = arrivals
  end
  if type(message.trains) == "table" then state.trains = message.trains end
  state.hubSeen = nowMinutes()
  return true
end

--------------------------------------------------------------------- chrome
local function rotation(count)
  if count < 1 then return 1 end
  local seconds = state.tick * config.scroll
  return (math.floor(seconds / config.rotate) % count) + 1
end

local function tickerText()
  local parts = {}
  for _, message in ipairs(config.messages or {}) do parts[#parts + 1] = message end
  if state.source == "demo" then
    parts[#parts + 1] = "Demonstration timetable - run `rail setup` to write your own."
  end
  return table.concat(parts, "        \7        ")
end

-- the header band every board wears: logo, station, what the board is, clock
local function drawHeader(title, w, h)
  local tall = h >= 14 and w >= 44
  local rows = tall and 3 or 1
  canvas:rect(1, 1, w, rows, theme.band)
  local left = 2
  if tall and config.logo and isColor then
    canvas:sprite(2, 1, DOUBLE_ARROW, theme.logo, theme.band)
    left = 10
  end
  local clock = clockText()
  local row = tall and 2 or 1
  -- a narrow board falls back to the three letter code, like the small signs
  local room = w - left - #clock - #title - 4
  local name = upper(config.station)
  if #name > room and config.code then name = upper(config.code) end
  canvas:text(left, row, trim(name, room), theme.bandText, theme.band)
  canvas:right(w - 1, row, clock, theme.bandText, theme.band)
  if #title > 0 then
    canvas:centre(row, title, theme.bandText, theme.band, left, w - #clock - 3)
  end
  return rows + 1
end

local function drawTicker(w, h)
  canvas:rect(1, h, w, 1, theme.panel)
  canvas:text(2, h, marquee(tickerText(), w - 2, state.tick), theme.dim, theme.panel)
  canvas:rule(1, h - 1, w, theme.rule, theme.base)
  return h - 2
end

--------------------------------------------------------------------- boards
-- Time / Destination / Plat / Expected, the summary board on the concourse
local function drawSummaryBoard(w, h, list, label, timeField)
  local top = drawHeader(label, w, h)
  local bottom = drawTicker(w, h)

  local timeX = 2
  local expW = 9
  local expX = w >= 34 and (w - expW) or nil
  local platX = (w >= 46 and expX) and (expX - 5) or nil
  local destX = timeX + 6
  local destEnd = (platX or expX or (w + 1)) - 2

  canvas:rect(1, top, w, 1, theme.base)
  canvas:text(timeX, top, "Time", theme.dim)
  canvas:text(destX, top, label == "Arrivals" and "Origin" or "Destination", theme.dim)
  if platX then canvas:text(platX, top, "Plat", theme.dim) end
  if expX then canvas:right(w - 1, top, "Expected", theme.dim) end
  canvas:rule(1, top + 1, w, theme.rule)

  local first = top + 2
  local room = bottom - first + 1
  local limit = config.rows > 0 and math.min(config.rows, room) or room
  -- the "and more" line needs a row of its own, or it lands on a service
  if #list > limit then limit = limit - 1 end

  if #list == 0 then
    canvas:centre(first + math.floor(room / 2) - 1,
                  "There are no departures from this station.", theme.dim)
    return
  end

  for i = 1, math.min(limit, #list) do
    local service = list[i]
    local y = first + i - 1
    local status, colour = statusOf(service)
    local name = service.dest
    if label == "Arrivals" then name = service.origin or service.dest end
    canvas:text(timeX, y, hhmm(service[timeField] or service.depart), theme.text)
    canvas:text(destX, y, trim(name, destEnd - destX + 1),
                service.cancelled and theme.dim or theme.bright)
    -- "via" rides along in small print, the way it does on the real boards
    if service.via and label ~= "Arrivals"
       and destX + #name + 6 + #service.via <= destEnd then
      canvas:text(destX + #name + 2, y, "via " .. service.via, theme.dim)
    end
    if platX then
      canvas:text(platX, y, service.cancelled and "-" or tostring(service.platform), theme.text)
    end
    if expX then canvas:right(w - 1, y, status, colour) end
  end

  if #list > limit then
    canvas:right(w - 1, first + limit,
                 "+" .. (#list - limit) .. " later services", theme.dim)
  end
end

local function drawDepartures(w, h) drawSummaryBoard(w, h, state.services, "Departures", "depart") end
local function drawArrivals(w, h)   drawSummaryBoard(w, h, state.arrivals, "Arrivals", "arrive") end

--------------------------------------------------------------------- platform
local function servicesForPlatform()
  local wanted = config.platform and tostring(config.platform)
  if not wanted then return state.services end
  local list = {}
  for _, service in ipairs(state.services) do
    if tostring(service.platform) == wanted then list[#list + 1] = service end
  end
  return #list > 0 and list or state.services
end

-- The big board at the end of the platform: one train in detail, its calling
-- points scrolling underneath, then the two after it.
local function drawPlatform(w, h)
  local list = servicesForPlatform()
  local title = config.platform and ("Platform " .. config.platform) or "Departures"
  local top = drawHeader(title, w, h)
  local bottom = drawTicker(w, h)
  local service = list[1]

  if not service then
    canvas:centre(math.floor((top + bottom) / 2), "No advertised departures", theme.dim)
    return
  end

  local status, colour = statusOf(service)
  local y = top + 1
  canvas:text(2, y, "1st", theme.dim)
  canvas:text(6, y, hhmm(service.depart), theme.head)
  canvas:text(12, y, trim(service.dest, w - 12 - #status - 2), theme.bright)
  canvas:right(w - 1, y, status, colour)

  y = y + 1
  local notes = {}
  if service.cancelled then
    notes[#notes + 1] = "This service has been cancelled"
  elseif service.present then
    notes[#notes + 1] = "At platform"
  elseif service.imminent then
    notes[#notes + 1] = "Approaching - please stand back from the platform edge"
  elseif type(service.delay) == "number" and service.delay > 0 then
    notes[#notes + 1] = "Delayed by " .. math.floor(service.delay) .. " min"
  end
  if service.via then notes[#notes + 1] = "via " .. service.via end
  if service.coaches then
    notes[#notes + 1] = "formed of " .. service.coaches .. " coaches"
  end
  if service.operator then notes[#notes + 1] = service.operator end
  canvas:text(12, y, trim(table.concat(notes, "  \7  "), w - 13), theme.dim)

  y = y + 2
  if y <= bottom then
    canvas:text(2, y, "Calling at:", theme.dim)
    local calls = joinCalls(service.calls or {})
    if #calls == 0 then calls = "this train does not stop before " .. service.dest end
    canvas:text(14, y, marquee(calls, w - 15, state.tick), theme.text)
  end

  y = y + 1
  if y + 1 <= bottom and #list > 1 then
    canvas:rule(2, y, w - 2, theme.rule)
    y = y + 1
    -- the real thing lists the next few and leaves the rest to the concourse
    for i = 2, math.min(#list, 5, 2 + (bottom - y)) do
      local later = list[i]
      local laterStatus, laterColour = statusOf(later)
      canvas:text(2, y, ordinal(i), theme.dim)
      canvas:text(6, y, hhmm(later.depart), theme.text)
      canvas:text(12, y, trim(later.dest, w - 12 - #laterStatus - 8),
                  later.cancelled and theme.dim or theme.text)
      if w >= 46 then canvas:right(w - 12, y, "Plat " .. later.platform, theme.dim) end
      canvas:right(w - 1, y, laterStatus, laterColour)
      y = y + 1
    end
  end
end

--------------------------------------------------------------------- summary
-- The little dot matrix over a doorway or on a platform post.  One to four
-- rows, so it says one thing at a time and rotates.
local function drawNextTrain(w, h)
  local list = servicesForPlatform()
  local service = list[1]
  canvas:clear(theme.base)
  if not service then
    canvas:centre(1, trim("No departures", w), theme.dim)
    return
  end
  local status, colour = statusOf(service)
  local calls = joinCalls(service.calls or {})

  if h == 1 then
    local pages = {
      hhmm(service.depart) .. "  " .. service.dest .. "  " .. status,
      "Calling at: " .. calls,
      service.coaches and ("Formed of " .. service.coaches .. " coaches") or nil,
    }
    local page = pages[rotation(#pages)] or pages[1]
    canvas:text(1, 1, marquee(page, w, state.tick), theme.text)
    return
  end

  canvas:text(1, 1, hhmm(service.depart), theme.head)
  canvas:text(7, 1, trim(service.dest, w - 7 - #status - 1), theme.bright)
  canvas:right(w, 1, status, colour)
  if h >= 2 then
    canvas:text(1, 2, marquee("Calling at: " .. calls, w, state.tick), theme.text)
  end
  if h >= 3 then
    local extras = {}
    if config.platform then extras[#extras + 1] = "Platform " .. config.platform end
    if service.coaches then extras[#extras + 1] = service.coaches .. " coaches" end
    if service.operator then extras[#extras + 1] = service.operator end
    canvas:text(1, 3, trim(table.concat(extras, "  \7  "), w), theme.dim)
  end
  if h >= 5 and list[2] then
    canvas:rule(1, 4, w, theme.rule)
    for i = 2, math.min(#list, h - 3) do
      local later = list[i]
      local laterStatus, laterColour = statusOf(later)
      local y = 3 + i
      canvas:text(1, y, hhmm(later.depart), theme.text)
      canvas:text(7, y, trim(later.dest, w - 7 - #laterStatus - 1), theme.text)
      canvas:right(w, y, laterStatus, laterColour)
    end
  end
end

--------------------------------------------------------------------- onboard
-- Which service this carriage is running, and how far along it is.  A hub
-- tells us where the train was last seen; failing that the route is walked on
-- the clock so the display still shows something sensible.
local function journey()
  local route = config.route
  if type(route) ~= "table" or #route < 2 then
    local service = state.services[1]
    if not service then return nil end
    route = { config.station }
    for _, stop in ipairs(service.calls or {}) do route[#route + 1] = stop end
    if #route < 2 then return nil end
  end

  local index, standing = 1, true
  local where = config.train and state.trains[config.train]
  if where then
    for i, stop in ipairs(route) do
      if stopMatches(where.at, stop) or stopMatches(stop, where.at) then index = i break end
    end
    standing = where.standing
  else
    -- nothing is reporting; creep along the route so the screen stays alive
    local step = math.floor(state.tick * config.scroll / 20)
    index = (step % #route) + 1
    standing = (step % 2) == 0
  end

  local now = nowMinutes()
  local times = {}
  for i = 1, #route do
    times[i] = now + (i - index) * config.legRun
  end
  return {
    route    = route,
    index    = math.min(index, #route),
    standing = standing,
    times    = times,
    dest     = route[#route],
    origin   = route[1],
    next     = route[math.min(index + (standing and 0 or 1), #route)],
  }
end

local function drawOnboard(w, h)
  local trip = journey()
  canvas:clear(theme.base)
  canvas:rect(1, 1, w, 1, theme.band)
  canvas:text(2, 1, trim(config.operator, w - 20), theme.bandText, theme.band)
  if config.coach then
    canvas:centre(1, "Coach " .. config.coach, theme.bandText, theme.band)
  end
  canvas:right(w - 1, 1, clockText(), theme.bandText, theme.band)

  if not trip then
    canvas:centre(math.floor(h / 2), "No service information available", theme.dim)
    return
  end

  local bottom = drawTicker(w, h)
  local mid = math.floor((2 + bottom) / 2)

  canvas:centre(mid - 3, "This train is for", theme.dim)
  canvas:centre(mid - 2, trim(upper(trip.dest), w - 2), theme.head)
  canvas:rule(math.floor(w / 4), mid - 1, math.ceil(w / 2), theme.rule)

  local arriving = trip.standing and "This station is" or "The next station is"
  local page = rotation(3)
  if page == 2 and #trip.route > trip.index then
    canvas:centre(mid + 1, "Calling at", theme.dim)
    local rest = {}
    for i = trip.index + 1, #trip.route do rest[#rest + 1] = trip.route[i] end
    canvas:centre(mid + 2, trim(joinCalls(rest), w - 2), theme.bright)
  elseif page == 3 then
    canvas:centre(mid + 1, "Welcome aboard this " .. config.operator .. " service", theme.dim)
    canvas:centre(mid + 2, "to " .. trip.dest, theme.bright)
  else
    canvas:centre(mid + 1, arriving, theme.dim)
    canvas:centre(mid + 2, trim(upper(trip.next), w - 2), theme.bright)
    if not trip.standing then
      local eta = trip.times[math.min(trip.index + 1, #trip.times)]
      canvas:centre(mid + 3, "We should arrive at " .. hhmm(eta), theme.text)
    else
      canvas:centre(mid + 3, "Please mind the gap between the train and the platform", theme.text)
    end
  end
end

--------------------------------------------------------------------- route
-- The strip of dots in the vestibule: where the train has been, where it is,
-- and everywhere it still has to go.
local function drawRoute(w, h)
  local trip = journey()
  local top = drawHeader(trip and ("to " .. trip.dest) or "Route", w, h)
  local bottom = drawTicker(w, h)
  if not trip then
    canvas:centre(math.floor((top + bottom) / 2), "No route information", theme.dim)
    return
  end

  local y = top + 1
  local stops = #trip.route
  if w >= stops * 4 and y + 1 <= bottom then
    local gap = math.floor((w - 4) / math.max(1, stops - 1))
    for i = 1, stops do
      local x = 3 + (i - 1) * gap
      if i < stops then canvas:rule(x + 1, y, gap - 1, i < trip.index and theme.dim or theme.rule) end
      local colour = theme.dim
      if i == trip.index then colour = theme.head elseif i > trip.index then colour = theme.text end
      canvas:set(x, y, "\7", colour, theme.base)
    end
    -- the marker owns its column; the end labels only appear if they clear it
    local markX = 3 + (trip.index - 1) * gap
    local from = trim(trip.route[1], math.floor(w / 3))
    local to = trim(trip.route[stops], math.floor(w / 3))
    canvas:set(markX, y + 1, "\30", theme.head, theme.base)
    if markX > 2 + #from then canvas:text(2, y + 1, from, theme.dim) end
    if markX < w - 1 - #to then canvas:right(w - 1, y + 1, to, theme.text) end
    y = y + 3
  end

  -- one row per stop when the list is long, two when there is room for the
  -- little bit of track between them
  local step = (bottom - y + 1) >= stops * 2 and 2 or 1
  for i = 1, stops do
    if y > bottom then break end
    local passed = i < trip.index
    local hereNow = i == trip.index
    local colour = passed and theme.dim or (hereNow and theme.head or theme.text)
    canvas:set(3, y, "\7", colour, theme.base)
    if i < stops and step == 2 then canvas:set(3, y + 1, "\149", theme.rule, theme.base) end
    canvas:text(5, y, trim(trip.route[i], w - 24), colour)
    canvas:right(w - 12, y, hhmm(trip.times[i]), passed and theme.dim or theme.text)
    if hereNow then
      canvas:right(w - 1, y, trip.standing and "this stop" or "departed", theme.head)
    elseif i == trip.index + 1 and not trip.standing then
      canvas:right(w - 1, y, "next stop", theme.bright)
    elseif passed then
      canvas:right(w - 1, y, "called", theme.dim)
    end
    y = y + step
  end
end

--------------------------------------------------------------------- clock
local function drawConcourse(w, h)
  canvas:clear(theme.base)
  local bottom = drawTicker(w, h)
  local y = 2

  if config.logo and isColor and w >= 30 then
    canvas:sprite(2, y, DOUBLE_ARROW, theme.logo, theme.base)
    canvas:text(10, y + 1, trim("Welcome to " .. config.station, w - 12), theme.bright)
    y = y + 4
  else
    canvas:centre(y, trim("Welcome to " .. config.station, w - 2), theme.bright)
    y = y + 2
  end

  local time = clockText()
  local scale = (w >= bigWidth(time, 2) + 4 and bottom - y >= 11) and 2 or 1
  if bottom - y >= 5 then
    drawBig(math.floor((w - bigWidth(time, scale)) / 2) + 1, y, time, scale, theme.head)
    y = y + 5 * scale + 1
  end

  if y + 1 <= bottom then
    canvas:rule(2, y, w - 2, theme.rule)
    y = y + 1
    canvas:text(2, y, "Time", theme.dim)
    canvas:text(8, y, "Destination", theme.dim)
    canvas:right(w - 1, y, "Plat", theme.dim)
    y = y + 1
    for i = 1, #state.services do
      if y > bottom then break end
      local service = state.services[i]
      local status, colour = statusOf(service)
      canvas:text(2, y, hhmm(service.depart), theme.text)
      canvas:text(8, y, trim(service.dest, w - 8 - #status - 8), theme.bright)
      canvas:right(w - 8, y, status, colour)
      canvas:right(w - 1, y, tostring(service.platform), theme.text)
      y = y + 1
    end
  end
end

--------------------------------------------------------------------- flap
-- CC:C Bridge Source Blocks push plain text onto Create flap displays, nixie
-- tubes and signs.  They are small, so pick what fits.
local function flapLines(width, height)
  local service = servicesForPlatform()[1]
  if not service then return { "No departures" } end
  local status = statusOf(service)
  local lines = {}
  if width <= 10 then
    lines[1] = hhmm(service.depart)
    if height >= 2 then lines[2] = trim(service.dest, width) end
    return lines
  end
  local dest = trim(upper(service.dest), width - 6 - #status - 1)
  lines[1] = hhmm(service.depart) .. " " .. dest ..
             string.rep(" ", width - 6 - #dest - #status) .. status
  if height >= 2 then
    lines[2] = trim("Plat " .. service.platform .. "  " ..
                    joinCalls(service.calls or {}), width)
  end
  if height >= 3 then
    lines[3] = trim(config.station .. "  " .. clockText(), width)
  end
  return lines
end

local function pushFlaps()
  local sources = {}
  for _, name in ipairs(peripheral.getNames()) do
    for _, kind in ipairs({ peripheral.getType(name) }) do
      if kind == "create_source" then sources[#sources + 1] = peripheral.wrap(name) end
    end
  end
  for _, source in ipairs(sources) do
    local ok, width, height = pcall(source.getSize)
    if ok then
      pcall(source.clear)
      for i, line in ipairs(flapLines(width, height)) do
        if i <= height then
          pcall(source.setCursorPos, 1, i)
          pcall(source.write, line)
        end
      end
    end
  end
  return #sources
end

--------------------------------------------------------------------- setup
local TEMPLATE = [==[
-- rail.cfg -- edit to taste, then restart the display.
-- Anything you leave out keeps its default.
return {
  mode     = nil,         -- the mode to show when `rail` is run with no
                          -- arguments, so the board comes back after a reboot:
                          -- "departures", "platform", "onboard", ...
  station  = "Birmingham New Street",  -- what this station is called
  code     = "BHM",
  operator = "Create Rail",
  theme    = "dot",       -- "dot" amber dot matrix, "lcd" modern screen
  clock    = "mc",        -- "mc" in-game time, "real" your own clock
  platform = nil,         -- set on platform and summary displays, e.g. 3

  -- Which Create station block is which platform.  The key is either the
  -- peripheral name (see `rail hub`) or the name you gave the station in game.
  platforms = {
    -- ["create:track_station_0"] = 1,
    -- ["New Street Platform 3"]  = 3,
  },

  -- The booked timetable.  Leave it empty to run purely on what the station
  -- blocks report.  `calls` ends with the final destination.
  timetable = {
    -- { depart = "15:26", platform = 3, coaches = 9, via = "Coventry",
    --   origin = "Wolverhampton", operator = "Create West Coast",
    --   calls = { "Coventry", "Rugby", "Milton Keynes Central", "London Euston" } },
    -- { depart = "15:41", platform = 5, coaches = 4, cancelled = true,
    --   calls = { "Stafford", "Crewe", "Manchester Piccadilly" } },
  },

  -- Onboard and route displays: the Create train name this carriage belongs
  -- to, and the stations it works through.
  train = nil,
  route = nil,
  -- route = { "Birmingham New Street", "Coventry", "Rugby", "London Euston" },

  messages = {
    "See it. Say it. Sorted. Text the British Transport Police on 61016.",
    "Please keep your personal belongings with you at all times.",
  },
}
]==]

local function writeTemplate(force)
  if fs.exists(CONFIG) and not force then
    print(CONFIG .. " already exists; `rail setup -f` overwrites it")
    return
  end
  local handle = fs.open(CONFIG, "w")
  handle.write(TEMPLATE)
  handle.close()
  print("wrote " .. CONFIG .. " -- edit it, then start a display")
end

--------------------------------------------------------------------- draw
local DRAW = {
  departures = drawDepartures,
  arrivals   = drawArrivals,
  platform   = drawPlatform,
  summary    = drawNextTrain,
  onboard    = drawOnboard,
  route      = drawRoute,
  concourse  = drawConcourse,
}

local function draw()
  local w, h = canvas.w, canvas.h
  canvas:clear(theme.base)
  local drawer = DRAW[state.mode] or drawDepartures
  if h < 3 then
    drawNextTrain(w, h)
  else
    drawer(w, h)
  end
  canvas:flush()
end

--------------------------------------------------------------------- main
local args = { ... }
-- a board that boots straight into its mode needs it in the config, because
-- `vaults startup rail on` cannot pass arguments
local mode = tostring(args[1] or config.mode or "departures"):lower()

local ALIASES = {
  dep = "departures", departure = "departures", board = "departures",
  arr = "arrivals", arrival = "arrivals",
  plat = "platform", next = "summary", matrix = "summary",
  pis = "onboard", train = "onboard", carriage = "onboard",
  diagram = "route", line = "route",
  clock = "concourse", station = "concourse",
  display = "flap", create = "flap",
}
mode = ALIASES[mode] or mode

if mode == "help" or mode == "-h" or mode == "--help" then
  print("rail " .. VERSION .. " -- train information displays")
  print("modes: departures arrivals platform summary onboard route")
  print("       concourse flap hub setup help")
  print("run `rail setup` to write rail.cfg, then `rail <mode>`")
  return
end

if mode == "setup" then
  writeTemplate(args[2] == "-f" or args[2] == "--force")
  return
end

if mode == "version" then
  print("rail " .. VERSION)
  return
end

if args[2] and tonumber(args[2]) and (mode == "platform" or mode == "summary") then
  config.platform = args[2]
end

state.mode = MODES[1]
for _, name in ipairs(MODES) do
  if name == mode then state.mode = mode end
end

-- test hook: inert in game, lets tests/ reach the internals of this script
if _G.__VAULT_TEST then
  _G.__VAULT_TEST.internals = {
    config = config, theme = theme, state = state, canvas = canvas,
    refresh = refresh, draw = draw, link = link, journey = journey,
    liveServices = liveServices, bookedServices = bookedServices,
    demoServices = demoServices, scheduleStops = scheduleStops,
    onwardCalls = onwardCalls, previousCall = previousCall,
    stopMatches = stopMatches, platformOf = platformOf, statusOf = statusOf,
    marquee = marquee, joinCalls = joinCalls, hhmm = hhmm,
    parseTime = parseTime, nowMinutes = nowMinutes, ordinal = ordinal,
    flapLines = flapLines, pushFlaps = pushFlaps, palette = PALETTES.dot,
    template = TEMPLATE, version = VERSION,
    setMode = function(name) state.mode = name end,
  }
end

term.clear()
term.setCursorPos(1, 1)
print("rail " .. VERSION .. " -- " .. mode)
print("station: " .. config.station)
if configErr then printError(CONFIG .. ": " .. tostring(configErr)) end
if not configOk then print("no " .. CONFIG .. "; run `rail setup` to write one") end
print(mon and ("display: " .. peripheral.getName(mon) .. " " ..
               canvas.w .. "x" .. canvas.h .. " chars")
          or  ("display: terminal " .. canvas.w .. "x" .. canvas.h))
print("keys: [q]uit  [r]efresh  [tab] next mode")

link.start()
-- the headless modes leave the terminal colours alone; they only print
if mode ~= "hub" and mode ~= "flap" then applyPalette() end

local ok, err = pcall(function()
  refresh()
  if mode == "hub" then
    print("hub: serving " .. #state.services .. " services on rednet")
  elseif mode == "flap" then
    print("flap: " .. pushFlaps() .. " Create display sources")
  else
    draw()
  end

  local scanTimer = os.startTimer(config.refresh)
  local tickTimer = os.startTimer(config.scroll)

  while true do
    local event = { os.pullEvent() }
    local name = event[1]

    if name == "timer" then
      if event[2] == scanTimer then
        -- a hub that is still talking to us knows more than our own scan does
        if state.source ~= "hub" or (nowMinutes() - state.hubSeen) > 3 then
          refresh()
        end
        if mode == "hub" then
          link.publish()
        elseif mode == "flap" then
          pushFlaps()
        else
          draw()
        end
        scanTimer = os.startTimer(config.refresh)
      elseif event[2] == tickTimer then
        state.tick = state.tick + 1
        if mode ~= "hub" and mode ~= "flap" then draw() end
        tickTimer = os.startTimer(config.scroll)
      end

    elseif name == "rednet_message" then
      if event[4] == "rail" and mode ~= "hub" and link.accept(event[3]) then
        if mode == "flap" then pushFlaps() else draw() end
      end

    elseif name == "monitor_touch" or name == "mouse_click" then
      refresh()
      if mode ~= "hub" and mode ~= "flap" then draw() end

    elseif name == "key" then
      local key = event[2]
      if key == keys.q then break
      elseif key == keys.r then
        refresh()
        if mode ~= "hub" and mode ~= "flap" then draw() end
      elseif key == keys.tab and mode ~= "hub" and mode ~= "flap" then
        for i, entry in ipairs(MODES) do
          if entry == state.mode then
            state.mode = MODES[i % #MODES + 1]
            break
          end
        end
        draw()
      end

    elseif name == "monitor_resize" or name == "term_resize" then
      canvas:resize()
      if mode ~= "hub" and mode ~= "flap" then draw() end

    elseif name == "peripheral" or name == "peripheral_detach" then
      refresh()
      if mode ~= "hub" and mode ~= "flap" then draw() end
    end
  end
end)

restorePalette()
for _, screen in ipairs({ dev, term }) do
  screen.setBackgroundColor(colors.black)
  screen.setTextColor(colors.white)
  screen.clear()
  screen.setCursorPos(1, 1)
end
if not ok then error(err, 0) end
print("rail stopped.")
