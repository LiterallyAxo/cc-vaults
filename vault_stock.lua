--[[
  VAULT NETWORK  --  Create Item Vault stock monitor for CC: Tweaked

  Scans every Create Item Vault on the computer's peripheral network and
  renders a live dashboard on an attached monitor.

    * custom colour palette (advanced monitors) instead of the default 16
    * double buffered term.blit renderer, so no flicker on refresh
    * three touch views: STOCK, MOVERS (what changed) and VAULTS
    * tap any item for a per-vault breakdown

  Wiring:
    computer -> wired modem -> networking cable -> modem on every vault
    right-click each modem until it turns red / says "peripheral attached"
]]

--------------------------------------------------------------------- config
local config = {
  refresh      = 5,       -- seconds between rescans
  textScale    = 0.5,     -- monitor text scale (0.5 = most rows)
  vaultPattern = "vault", -- peripheral type must contain this...
  includeAll   = false,   -- ...unless true, then every inventory counts
  detailBudget = 40,      -- getItemDetail lookups per scan (server-tick cost)
  colWidth     = 40,      -- target width of one item column
  usePalette   = true,    -- recolour the 16 palette slots (advanced only)
}

--------------------------------------------------------------------- device
local mon = peripheral.find("monitor")
local dev = mon or term.current()
if mon then mon.setTextScale(config.textScale) end

local isColor = dev.isColour and dev.isColour() or false

local theme
if isColor then
  theme = {
    base = colors.black,  panel = colors.gray,   alt   = colors.lightGray,
    text = colors.white,  muted = colors.brown,  band  = colors.blue,
    bandText = colors.white,
    accent = colors.cyan, accent2 = colors.lightBlue,
    pos  = colors.lime,   neg  = colors.red,     qty = colors.yellow,
    warn = colors.orange, sel  = colors.magenta,
    tags = { colors.cyan, colors.lightBlue, colors.magenta, colors.lime,
             colors.orange, colors.pink, colors.green, colors.purple },
  }
else
  local w, b, g, l = colors.white, colors.black, colors.gray, colors.lightGray
  theme = {
    base = b, panel = b, alt = b, text = w, muted = l, band = w, bandText = b,
    accent = w, accent2 = l, pos = w, neg = l, qty = w, warn = w, sel = g,
    tags = { w },
  }
end

-- a calmer palette than vanilla; only touched on advanced displays
local PALETTE = {
  [colors.black]     = 0x0e1117,
  [colors.gray]      = 0x1a2030,
  [colors.lightGray] = 0x2b3346,
  [colors.white]     = 0xe6ecf5,
  [colors.brown]     = 0x8791a5,
  [colors.blue]      = 0x1f4f8f,
  [colors.lightBlue] = 0x4aa3ff,
  [colors.cyan]      = 0x46d5c8,
  [colors.lime]      = 0x4ade80,
  [colors.green]     = 0x2f9e5f,
  [colors.yellow]    = 0xf0b429,
  [colors.orange]    = 0xff9f45,
  [colors.red]       = 0xf76c6c,
  [colors.magenta]   = 0xc792ea,
  [colors.pink]      = 0xff7ab6,
  [colors.purple]    = 0x7a4fd0,
}

local savedPalette = {}
local function applyPalette()
  if not (isColor and config.usePalette and dev.setPaletteColour) then return end
  for slot, rgb in pairs(PALETTE) do
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
-- A double buffered character canvas. Everything draws into per-cell tables,
-- then flush() blits only the rows that actually changed.
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
      local ch, fgr, bgr = self.ch[yy], self.fg[yy], self.bg[yy]
      for xx = math.max(1, x), math.min(self.w, x + w - 1) do
        ch[xx], bgr[xx] = " ", b
        fgr[xx] = fgr[xx]
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

-- horizontal bar with half-character precision ("\149" is a left half block)
function Canvas:bar(x, y, width, frac, fill, track)
  frac = math.max(0, math.min(1, frac or 0))
  self:rect(x, y, width, 1, track)
  local cells = width * frac
  local full = math.floor(cells)
  if full > 0 then self:rect(x, y, math.min(full, width), 1, fill) end
  if full < width and (cells - full) >= 0.4 then
    self:set(x + full, y, "\149", fill, track)
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

--------------------------------------------------------------------- format
local function comma(n)
  local s, k = tostring(math.floor(n)), nil
  repeat s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2") until k == 0
  return s
end

local function short(n)
  local a = math.abs(n)
  if a >= 1000000 then return string.format("%.1fM", n / 1000000) end
  if a >= 100000  then return string.format("%dK", math.floor(n / 1000)) end
  if a >= 10000   then return string.format("%.1fK", n / 1000) end
  return comma(n)
end

local function signed(n)
  return (n > 0 and "+" or "") .. short(n)
end

local function trim(str, width)
  if width < 1 then return "" end
  if #str <= width then return str end
  if width <= 2 then return str:sub(1, width) end
  return str:sub(1, width - 1) .. "."
end

local function prettify(id)
  local label = (id:match(":(.+)$") or id):gsub("_", " ")
  return (label:gsub("%a[%w]*", function(word)
    return word:sub(1, 1):upper() .. word:sub(2)
  end))
end

local function modOf(id)
  return id:match("^(.-):") or "minecraft"
end

-- stable colour per mod, so items from the same mod share a stripe colour
local tagCache = {}
local function tagColor(id)
  local mod = modOf(id)
  local c = tagCache[mod]
  if not c then
    local hash = 0
    for i = 1, #mod do hash = (hash * 31 + mod:byte(i)) % 4096 end
    c = theme.tags[(hash % #theme.tags) + 1]
    tagCache[mod] = c
  end
  return c
end

local function vaultLabel(name)
  local n = name:match("item_vault_(%d+)$")
  if n then return "Vault " .. n end
  return (name:gsub("^.-:", ""):gsub("_", " "))
end

--------------------------------------------------------------------- state
local VIEWS = { "STOCK", "MOVERS", "VAULTS" }
local SORTS = { "COUNT", "NAME", "CHANGE" }

local nameCache, stackCache = {}, {}
local state = {
  items    = {},     -- { id, label, count, delta, vaults = { name = count } }
  vaults   = {},     -- { name, label, used, size, items, ok }
  byId     = {},
  online   = 0,
  offline  = 0,
  slots    = 0,
  used     = 0,
  total    = 0,
  delta    = 0,
  types    = 0,
  view     = 1,
  sort     = 1,
  page     = 1,
  detail   = nil,    -- item id of the open overlay
  scanning = false,
  nextScan = 0,
  lastScan = 0,
}
local prevCounts = {}

--------------------------------------------------------------------- scanning
local function isVault(name)
  for _, t in ipairs({ peripheral.getType(name) }) do
    if config.includeAll then
      if t == "inventory" then return true end
    elseif t:lower():find(config.vaultPattern, 1, true) then
      return true
    end
  end
  if config.includeAll then
    local m = peripheral.wrap(name)
    return m ~= nil and m.list ~= nil
  end
  return false
end

local function findVaults()
  local found = {}
  for _, name in ipairs(peripheral.getNames()) do
    if isVault(name) then found[#found + 1] = name end
  end
  table.sort(found)
  return found
end

local function runAll(tasks)
  local batch = {}
  for i = 1, #tasks do
    batch[#batch + 1] = tasks[i]
    if #batch >= 50 or i == #tasks then
      parallel.waitForAll(table.unpack(batch))
      batch = {}
    end
  end
end

local function scan()
  local names = findVaults()
  local lists, sizes = {}, {}

  local tasks = {}
  for i = 1, #names do
    local name = names[i]
    tasks[i] = function()
      local ok, list = pcall(peripheral.call, name, "list")
      if ok and type(list) == "table" then
        lists[i] = list
        local ok2, size = pcall(peripheral.call, name, "size")
        sizes[i] = (ok2 and type(size) == "number") and size or 0
      else
        lists[i] = false
      end
    end
  end
  runAll(tasks)

  local totals, pending = {}, {}
  local vaults, online, offline = {}, 0, 0
  local slotsUsed, slotsTotal, grand = 0, 0, 0

  for i = 1, #names do
    local list = lists[i]
    local entry = {
      name = names[i], label = vaultLabel(names[i]),
      used = 0, size = sizes[i] or 0, items = 0, ok = list ~= false,
    }
    if list == false then
      offline = offline + 1
    else
      online = online + 1
      slotsTotal = slotsTotal + entry.size
      for slot, item in pairs(list) do
        local e = totals[item.name]
        if not e then
          e = { id = item.name, count = 0, vaults = {} }
          totals[item.name] = e
          if not nameCache[item.name] then
            pending[#pending + 1] = { vault = names[i], slot = slot, id = item.name }
          end
        end
        e.count = e.count + item.count
        e.vaults[names[i]] = (e.vaults[names[i]] or 0) + item.count
        entry.used = entry.used + 1
        entry.items = entry.items + item.count
        slotsUsed = slotsUsed + 1
        grand = grand + item.count
      end
    end
    vaults[#vaults + 1] = entry
  end

  -- getItemDetail costs a server tick each, so resolve a capped number of new
  -- names per scan; the rest fall back to a prettified id until a later pass
  local lookups = {}
  for i = 1, math.min(#pending, config.detailBudget) do
    local p = pending[i]
    lookups[i] = function()
      local ok, d = pcall(peripheral.call, p.vault, "getItemDetail", p.slot)
      if ok and type(d) == "table" then
        nameCache[p.id] = d.displayName or nameCache[p.id]
        stackCache[p.id] = d.maxCount or stackCache[p.id]
      end
    end
  end
  runAll(lookups)

  local items, byId, totalDelta = {}, {}, 0
  for id, e in pairs(totals) do
    e.label = nameCache[id] or prettify(id)
    e.delta = e.count - (prevCounts[id] or e.count)
    totalDelta = totalDelta + e.delta
    items[#items + 1] = e
    byId[id] = e
  end
  -- items that vanished entirely still count as movement
  for id, old in pairs(prevCounts) do
    if not totals[id] then totalDelta = totalDelta - old end
  end

  local nextPrev = {}
  for id, e in pairs(totals) do nextPrev[id] = e.count end
  prevCounts = nextPrev

  table.sort(vaults, function(a, b) return a.items > b.items end)

  state.items, state.byId = items, byId
  state.vaults = vaults
  state.online, state.offline = online, offline
  state.slots, state.used = slotsTotal, slotsUsed
  state.total, state.delta = grand, totalDelta
  state.types = #items
  state.lastScan = os.clock()
end

local function sortItems()
  local mode = SORTS[state.sort]
  table.sort(state.items, function(a, b)
    if mode == "COUNT" and a.count ~= b.count then return a.count > b.count end
    if mode == "CHANGE" then
      local da, db = math.abs(a.delta), math.abs(b.delta)
      if da ~= db then return da > db end
      if a.count ~= b.count then return a.count > b.count end
    end
    if a.label ~= b.label then return a.label < b.label end
    return a.id < b.id
  end)
end

local function movers()
  local list = {}
  for _, e in ipairs(state.items) do
    if e.delta ~= 0 then list[#list + 1] = e end
  end
  table.sort(list, function(a, b)
    local da, db = math.abs(a.delta), math.abs(b.delta)
    if da ~= db then return da > db end
    return a.label < b.label
  end)
  return list
end

--------------------------------------------------------------------- drawing
local canvas = Canvas.new(dev)
local zones = {}

local function zone(x1, y1, x2, y2, action, payload)
  zones[#zones + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2,
                        action = action, payload = payload }
end

local function chip(x, y, label, active)
  local bg = active and theme.accent or theme.panel
  local fg = active and theme.base or theme.muted
  canvas:rect(x, y, #label + 2, 1, bg)
  canvas:text(x + 1, y, label, fg, bg)
  return x + #label + 3
end

local function drawHeader(w, compact)
  -- title band
  canvas:rect(1, 1, w, 1, theme.band)
  canvas:set(1, 1, "\149", theme.accent, theme.band)
  canvas:text(3, 1, "VAULT NETWORK", theme.bandText, theme.band)
  local clock = textutils.formatTime(os.time(), true)
  local status = state.scanning and "SCANNING" or clock
  canvas:right(w - 1, 1, status,
    state.scanning and theme.warn or theme.bandText, theme.band)
  zone(1, 1, w, 1, "refresh")

  -- stats strip
  canvas:rect(1, 2, w, 1, theme.panel)
  local x = 2
  local function stat(value, label, color)
    canvas:text(x, 2, value, color, theme.panel); x = x + #value + 1
    canvas:text(x, 2, label, theme.muted, theme.panel); x = x + #label + 2
  end
  stat(short(state.total), "items", theme.qty)
  stat(tostring(state.types), "types", theme.text)
  stat(tostring(state.online), "vaults", theme.text)
  if state.offline > 0 then
    stat(tostring(state.offline), "offline", theme.neg)
  end
  if state.delta ~= 0 then
    local d = signed(state.delta)
    canvas:right(w - 1, 2, d .. " last scan",
      state.delta > 0 and theme.pos or theme.neg, theme.panel)
  end

  local y = 3
  if not compact then
    -- capacity gauge
    canvas:rect(1, y, w, 1, theme.panel)
    canvas:text(2, y, "SLOTS", theme.muted, theme.panel)
    local pct = state.slots > 0 and (state.used / state.slots) or 0
    local barW = math.max(6, math.min(28, w - 30))
    canvas:bar(8, y, barW, pct, pct > 0.9 and theme.warn or theme.accent, theme.alt)
    local info = string.format("%s/%s  %d%%", short(state.used),
      state.slots > 0 and short(state.slots) or "?", math.floor(pct * 100 + 0.5))
    canvas:text(9 + barW, y, info, theme.text, theme.panel)
    local secs = math.max(0, math.ceil(state.nextScan - os.clock()))
    local countdown = "next scan " .. secs .. "s"
    if w - #countdown - 2 > 9 + barW + #info then     -- only if it fits cleanly
      canvas:right(w - 1, y, countdown, theme.muted, theme.panel)
    end
    y = y + 1
  end

  -- view tabs + sort button
  canvas:rect(1, y, w, 1, theme.base)
  local tx = 2
  for i, name in ipairs(VIEWS) do
    local sx = tx
    tx = chip(tx, y, name, state.view == i)
    zone(sx, y, tx - 2, y, "view", i)
  end
  local sortLabel = "SORT: " .. SORTS[state.sort]
  local sx = w - #sortLabel - 2
  canvas:rect(sx, y, #sortLabel + 2, 1, theme.panel)
  canvas:text(sx + 1, y, sortLabel, theme.accent2, theme.panel)
  zone(sx, y, w, y, "sort")

  return y + 1
end

local function drawFooter(w, h, pages)
  canvas:rect(1, h, w, 1, theme.band)
  canvas:text(2, h, "< PREV", theme.bandText, theme.band)
  zone(1, h, math.floor(w / 3), h, "prev")
  local mid = string.format("PAGE %d/%d", state.page, pages)
  canvas:text(math.max(2, math.floor((w - #mid) / 2) + 1), h, mid,
    theme.bandText, theme.band)
  zone(math.floor(w / 3) + 1, h, math.floor(w * 2 / 3), h, "none")
  canvas:right(w - 1, h, "NEXT >", theme.bandText, theme.band)
  zone(math.floor(w * 2 / 3) + 1, h, w, h, "next")
end

-- one item row inside a column of width cw
local function drawItemRow(x, y, cw, item, maxCount, striped, showDelta)
  local rowBg = striped and theme.panel or theme.base
  canvas:rect(x, y, cw - 1, 1, rowBg)
  canvas:set(x, y, "\149", tagColor(item.id), rowBg)

  -- laid out from both edges: name on the left, count and delta flush right,
  -- and whatever is left in the middle becomes the share bar
  local qtyW   = 8
  local deltaW = (showDelta and cw >= 34) and 7 or 0
  local right  = x + cw - 2
  local nameW  = math.max(4, math.min(32, cw - 4 - qtyW - deltaW))

  canvas:text(x + 2, y, trim(item.label, nameW), theme.text, rowBg)

  local qtyRight = right - deltaW
  local barX, barEnd = x + 2 + nameW + 1, qtyRight - qtyW
  if barEnd - barX >= 5 then
    canvas:bar(barX, y, barEnd - barX + 1,
      maxCount > 0 and (item.count / maxCount) or 0, theme.accent, theme.alt)
  end

  canvas:right(qtyRight, y, short(item.count), theme.qty, rowBg)
  if deltaW > 0 and item.delta ~= 0 then
    canvas:right(right, y, signed(item.delta),
      item.delta > 0 and theme.pos or theme.neg, rowBg)
  end

  zone(x, y, x + cw - 2, y, "item", item.id)
end

local function drawGrid(list, top, w, h, emphasizeDelta)
  local rows = math.max(1, h - 1 - top + 1)
  -- only split into columns once a single column would overflow the page
  local maxCols = math.max(1, math.min(3, math.floor(w / config.colWidth)))
  local cols = math.max(1, math.min(maxCols, math.ceil(#list / rows)))
  local cw = math.floor(w / cols)
  local perPage = rows * cols
  local pages = math.max(1, math.ceil(#list / perPage))
  state.page = math.min(pages, math.max(1, state.page))

  local maxCount, showDelta = 0, false
  for _, e in ipairs(list) do
    if e.count > maxCount then maxCount = e.count end
    if e.delta ~= 0 then showDelta = true end
  end

  local first = (state.page - 1) * perPage
  local onPage = math.max(0, math.min(perPage, #list - first))
  local colRows = math.max(1, math.ceil(onPage / cols))   -- balance the columns
  for i = 1, onPage do
    local col = math.floor((i - 1) / colRows)
    local row = (i - 1) % colRows
    drawItemRow(1 + col * cw, top + row, cw, list[first + i], maxCount,
      row % 2 == 1, showDelta)
  end

  if #list == 0 then
    local msg = state.online == 0
      and "No vaults on the network - check your modems"
      or (emphasizeDelta and "Nothing moved during the last scan"
                        or  "All vaults are empty")
    canvas:text(3, top + math.floor(rows / 2), trim(msg, w - 4), theme.muted, theme.base)
  end

  return pages
end

local function drawVaults(top, w, h)
  local rows = math.max(1, h - 1 - top + 1)
  local perPage = rows
  local pages = math.max(1, math.ceil(#state.vaults / perPage))
  state.page = math.min(pages, math.max(1, state.page))

  local first = (state.page - 1) * perPage
  for i = 1, perPage do
    local v = state.vaults[first + i]
    if not v then break end
    local y = top + i - 1
    local rowBg = (i % 2 == 0) and theme.panel or theme.base
    canvas:rect(1, y, w, 1, rowBg)
    canvas:set(1, y, "\149", v.ok and theme.accent or theme.neg, rowBg)

    local nameW = math.max(8, math.floor(w * 0.34))
    canvas:text(3, y, trim(v.label, nameW), theme.text, rowBg)

    if v.ok then
      local pct = v.size > 0 and (v.used / v.size) or 0
      local barW = math.max(6, math.min(20, w - nameW - 26))
      local bx = 3 + nameW + 1
      canvas:bar(bx, y, barW, pct, pct > 0.9 and theme.warn or theme.accent2, theme.alt)
      canvas:text(bx + barW + 1, y,
        string.format("%d/%d", v.used, v.size), theme.muted, rowBg)
      canvas:right(w - 1, y, short(v.items) .. " items", theme.qty, rowBg)
    else
      canvas:text(3 + nameW + 1, y, "OFFLINE", theme.neg, rowBg)
    end
  end

  if #state.vaults == 0 then
    canvas:text(3, top + 1, "No vaults on the network - check your modems",
      theme.muted, theme.base)
  end
  return pages
end

local function drawDetail(w, h)
  local item = state.byId[state.detail]
  if not item then state.detail = nil return end

  zone(1, 1, w, h, "close")   -- tap anywhere to dismiss

  -- dim the list behind the panel so the breakdown reads as a layer
  local scrimTop = state.contentTop or 3
  canvas:rect(1, scrimTop, w, h - scrimTop, theme.base)

  local list = {}
  for name, count in pairs(item.vaults) do
    list[#list + 1] = { name = vaultLabel(name), count = count }
  end
  table.sort(list, function(a, b) return a.count > b.count end)

  local pw = math.min(w - 4, 46)
  local ph = math.min(h - 4, 7 + math.min(#list, 8))
  local px = math.floor((w - pw) / 2) + 1
  local py = math.floor((h - ph) / 2) + 1

  canvas:rect(px, py, pw, ph, theme.panel)
  canvas:rect(px, py, pw, 1, theme.accent)
  canvas:text(px + 1, py, trim(item.label, pw - 8), theme.base, theme.accent)
  canvas:right(px + pw - 2, py, "X", theme.base, theme.accent)

  canvas:text(px + 1, py + 1, trim(item.id, pw - 2), theme.muted, theme.panel)

  local stack = stackCache[item.id] or 64
  local line = string.format("%s  (%d stacks)", comma(item.count),
    math.floor(item.count / stack))
  canvas:text(px + 1, py + 2, trim(line, pw - 12), theme.qty, theme.panel)
  if item.delta ~= 0 then
    canvas:right(px + pw - 2, py + 2, signed(item.delta),
      item.delta > 0 and theme.pos or theme.neg, theme.panel)
  end

  canvas:text(px + 1, py + 3, "SPREAD ACROSS " .. #list .. " VAULT" ..
    (#list == 1 and "" or "S"), theme.muted, theme.panel)

  local top = py + 4
  local shown = math.min(#list, ph - 5)
  for i = 1, shown do
    local v = list[i]
    local y = top + i - 1
    local nameW = math.floor(pw * 0.4)
    canvas:text(px + 1, y, trim(v.name, nameW), theme.text, theme.panel)
    local barW = pw - nameW - 12
    if barW > 3 then
      canvas:bar(px + 1 + nameW + 1, y, barW, v.count / item.count,
        theme.accent2, theme.alt)
    end
    canvas:right(px + pw - 2, y, short(v.count), theme.qty, theme.panel)
  end
  if #list > shown then
    canvas:text(px + 1, py + ph - 1,
      "+" .. (#list - shown) .. " more", theme.muted, theme.panel)
  end
end

local function draw()
  local w, h = canvas.w, canvas.h
  zones = {}
  canvas:clear(theme.base)

  local compact = h < 16
  local top = drawHeader(w, compact)
  state.contentTop = top

  local pages
  local view = VIEWS[state.view]
  if view == "STOCK" then
    pages = drawGrid(state.items, top, w, h, false)
  elseif view == "MOVERS" then
    pages = drawGrid(movers(), top, w, h, true)
  else
    pages = drawVaults(top, w, h)
  end
  state.pages = pages

  drawFooter(w, h, pages)
  if state.detail then drawDetail(w, h) end
  canvas:flush()
end

--------------------------------------------------------------------- control
local function refresh()
  state.scanning = true
  draw()
  scan()
  sortItems()
  state.scanning = false
  state.nextScan = os.clock() + config.refresh
  draw()
end

-- the page total the last draw() worked out for the active view
local function pageCount()
  return state.pages or 1
end

local function act(action, payload)
  if action == "prev" then
    state.page = math.max(1, state.page - 1)
  elseif action == "next" then
    state.page = math.min(pageCount(), state.page + 1)
  elseif action == "sort" then
    state.sort = state.sort % #SORTS + 1
    sortItems()
    state.page = 1
  elseif action == "view" then
    state.view = payload
    state.page = 1
  elseif action == "item" then
    state.detail = payload
  elseif action == "close" then
    state.detail = nil
  elseif action == "refresh" then
    refresh()
    return
  elseif action ~= nil then
    return
  else
    return
  end
  draw()
end

local function hit(x, y)
  -- later zones (the overlay) win over earlier ones
  for i = #zones, 1, -1 do
    local z = zones[i]
    if x >= z.x1 and x <= z.x2 and y >= z.y1 and y <= z.y2 then
      if state.detail and z.action ~= "close" then return "close" end
      return z.action, z.payload
    end
  end
  return nil
end

--------------------------------------------------------------------- main
term.clear()
term.setCursorPos(1, 1)
print("Vault Network monitor")
print(mon and ("Display: " .. peripheral.getName(mon))
          or  "Display: terminal (no monitor attached)")
print("Keys: [q]uit  [r]efresh  [s]ort  [tab] view  arrows page")

-- test hook: inert in game, lets tests/ reach the internals of this script
if _G.__VAULT_TEST then
  _G.__VAULT_TEST.internals = {
    config = config, theme = theme, state = state, canvas = canvas,
    scan = scan, sortItems = sortItems, movers = movers, refresh = refresh,
    draw = draw, hit = hit, act = act, pageCount = pageCount,
    comma = comma, short = short, signed = signed, trim = trim,
    prettify = prettify, tagColor = tagColor, findVaults = findVaults,
    palette = PALETTE, vaultLabel = vaultLabel,
    zones = function() return zones end,
  }
end

applyPalette()
state.nextScan = os.clock() + config.refresh

local ok, err = pcall(function()
  refresh()
  local scanTimer = os.startTimer(config.refresh)
  local tickTimer = os.startTimer(1)

  while true do
    local ev = { os.pullEvent() }
    local name = ev[1]

    if name == "timer" then
      if ev[2] == scanTimer then
        refresh()
        scanTimer = os.startTimer(config.refresh)
      elseif ev[2] == tickTimer then
        draw()                       -- keeps the clock and countdown live
        tickTimer = os.startTimer(1)
      end

    elseif name == "monitor_touch" then
      act(hit(ev[3], ev[4]))

    elseif name == "mouse_click" and not mon then
      act(hit(ev[3], ev[4]))

    elseif name == "key" then
      local k = ev[2]
      if k == keys.q then break
      elseif k == keys.r then refresh()
      elseif k == keys.s then act("sort")
      elseif k == keys.tab then
        state.view = state.view % #VIEWS + 1
        state.page = 1
        draw()
      elseif k == keys.right or k == keys.down or k == keys.pageDown then act("next")
      elseif k == keys.left or k == keys.up or k == keys.pageUp then act("prev")
      elseif k == keys.escape then act("close")
      end

    elseif name == "monitor_resize" or name == "term_resize" then
      canvas:resize()
      draw()

    elseif name == "peripheral" or name == "peripheral_detach" then
      refresh()
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
print("Vault Network monitor stopped.")
