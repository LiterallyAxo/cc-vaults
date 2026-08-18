--[[
  Create Vault Stock Monitor  --  ComputerCraft (CC: Tweaked)

  Scans every Create Item Vault (and any other inventory you point it at)
  attached to the computer's peripheral network, totals up the items, and
  paints the result on an attached monitor.

  Setup:
    computer -> wired modem -> networking cable -> modem on each vault
    (right-click every modem so it turns red / says "peripheral attached")
    the monitor may be attached directly or over the same cable network.

  Controls (the monitor is touch enabled, the terminal uses keys):
    tap left / right third of the footer .... previous / next page
    tap the middle of the footer ............ change sort order
    tap the title bar ....................... force a rescan
    keys: arrows / pgup / pgdn, [s]ort, [r]efresh, [q]uit
]]

--------------------------------------------------------------------- config
local config = {
  refresh      = 5,       -- seconds between rescans
  textScale    = 0.5,     -- monitor text scale (0.5 = smallest = most rows)
  vaultPattern = "vault", -- peripheral type must contain this...
  includeAll   = false,   -- ...unless true, then every inventory is counted
  minColWidth  = 24,      -- narrower than this and we drop to fewer columns
  detailBudget = 40,      -- getItemDetail() lookups per scan (it is a slow call)
}

--------------------------------------------------------------------- output
local mon = peripheral.find("monitor")
local out = mon or term
if mon then
  mon.setTextScale(config.textScale)
end

local isColor = out.isColor and out.isColor()
local C = {
  bg     = colors.black,
  fg     = colors.white,
  barBg  = isColor and colors.blue or colors.white,
  barFg  = isColor and colors.white or colors.black,
  rowAlt = isColor and colors.gray or colors.black,
  count  = isColor and colors.yellow or colors.white,
  dim    = isColor and colors.lightGray or colors.white,
  bad    = isColor and colors.red or colors.white,
}

--------------------------------------------------------------------- helpers
local function isVault(name)
  local types = { peripheral.getType(name) }
  for _, t in ipairs(types) do
    if config.includeAll then
      if t == "inventory" then return true end
    elseif t:lower():find(config.vaultPattern, 1, true) then
      return true
    end
  end
  -- fallback for builds that do not report the generic "inventory" type
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

local function prettify(id)
  local label = id:match(":(.+)$") or id
  label = label:gsub("_", " ")
  return (label:gsub("%a[%w]*", function(word)
    return word:sub(1, 1):upper() .. word:sub(2)
  end))
end

local function fmtCount(n)
  if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
  if n >= 100000  then return string.format("%dK", math.floor(n / 1000)) end
  if n >= 10000   then return string.format("%.1fK", n / 1000) end
  local s, k = tostring(n), nil
  repeat s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2") until k == 0
  return s
end

--------------------------------------------------------------------- scanning
local nameCache = {}   -- item id -> display name
local SORTS = { "COUNT", "NAME" }
local state = {
  items   = {},        -- array of { id = ..., label = ..., count = ... }
  vaults  = 0,
  offline = 0,
  slots   = 0,
  used    = 0,
  total   = 0,
  page    = 1,
  sort    = 1,
}

local function scan()
  local vaults = findVaults()
  local raw, sizes, failed = {}, {}, 0

  local batch = {}
  for i = 1, #vaults do
    local name = vaults[i]
    batch[#batch + 1] = function()
      local ok, list = pcall(peripheral.call, name, "list")
      if ok and type(list) == "table" then
        raw[i] = list
        local ok2, size = pcall(peripheral.call, name, "size")
        sizes[i] = (ok2 and type(size) == "number") and size or 0
      else
        raw[i] = false
      end
    end
    -- run in chunks so a huge network does not spawn thousands of coroutines
    if #batch >= 50 or i == #vaults then
      parallel.waitForAll(table.unpack(batch))
      batch = {}
    end
  end

  local totals, slotsUsed, grand = {}, 0, 0
  local pending = {}   -- ids that still need a real display name
  for i, list in pairs(raw) do
    if list == false then
      failed = failed + 1
    else
      for slot, item in pairs(list) do
        local entry = totals[item.name]
        if not entry then
          entry = { id = item.name, count = 0 }
          totals[item.name] = entry
          if not nameCache[item.name] then
            pending[#pending + 1] = { vault = vaults[i], slot = slot, id = item.name }
          end
        end
        entry.count = entry.count + item.count
        slotsUsed = slotsUsed + 1
        grand = grand + item.count
      end
    end
  end

  -- getItemDetail costs a server tick, so only resolve a few new names per
  -- scan; anything left over falls back to a prettified item id this round
  local lookups = {}
  for i = 1, math.min(#pending, config.detailBudget) do
    local p = pending[i]
    lookups[#lookups + 1] = function()
      local ok, detail = pcall(peripheral.call, p.vault, "getItemDetail", p.slot)
      if ok and type(detail) == "table" and detail.displayName then
        nameCache[p.id] = detail.displayName
      end
    end
  end
  if #lookups > 0 then parallel.waitForAll(table.unpack(lookups)) end

  local items = {}
  for id, entry in pairs(totals) do
    entry.label = nameCache[id] or prettify(id)
    items[#items + 1] = entry
  end

  local slotTotal = 0
  for _, s in pairs(sizes) do slotTotal = slotTotal + s end

  state.items   = items
  state.vaults  = #vaults - failed
  state.offline = failed
  state.slots   = slotTotal
  state.used    = slotsUsed
  state.total   = grand
end

local function sortItems()
  local byCount = SORTS[state.sort] == "COUNT"
  table.sort(state.items, function(a, b)
    if byCount and a.count ~= b.count then return a.count > b.count end
    if a.label ~= b.label then return a.label < b.label end
    return a.id < b.id
  end)
end

--------------------------------------------------------------------- drawing
local buttons = {}   -- footer hit boxes, rebuilt by draw()

local function write(x, y, text, fg, bg)
  out.setCursorPos(x, y)
  out.setTextColor(fg or C.fg)
  out.setBackgroundColor(bg or C.bg)
  out.write(text)
end

local function layout()
  local w, h = out.getSize()
  local top, bottom = 3, h - 1
  local rows = math.max(1, bottom - top + 1)
  local cols = math.max(1, math.floor(w / config.minColWidth))
  return w, h, top, rows, cols, math.floor(w / cols), rows * cols
end

local function pageCount()
  local _, _, _, _, _, _, perPage = layout()
  return math.max(1, math.ceil(#state.items / perPage))
end

local function draw()
  local w, h, top, rows, cols, colW, perPage = layout()
  out.setBackgroundColor(C.bg)
  out.clear()

  ---- title bar
  write(1, 1, string.rep(" ", w), C.barFg, C.barBg)
  write(2, 1, "CREATE VAULT STOCK", C.barFg, C.barBg)
  local right = string.format("%d vault%s  %s items",
    state.vaults, state.vaults == 1 and "" or "s", fmtCount(state.total))
  if state.offline > 0 then right = right .. "  !" .. state.offline end
  write(math.max(2, w - #right), 1, right,
    state.offline > 0 and C.bad or C.barFg, C.barBg)

  ---- sub header
  local slotInfo = state.slots > 0
    and (state.used .. "/" .. state.slots) or tostring(state.used)
  write(2, 2, string.format("%d unique  %s slots used", #state.items, slotInfo),
    C.dim, C.bg)
  local sortLabel = "sort: " .. SORTS[state.sort]:lower()
  write(math.max(2, w - #sortLabel), 2, sortLabel, C.dim, C.bg)

  ---- item grid
  local pages = pageCount()
  state.page = math.min(pages, math.max(1, state.page))
  local first = (state.page - 1) * perPage
  for i = 1, perPage do
    local item = state.items[first + i]
    if not item then break end
    local col = math.floor((i - 1) / rows)
    local row = (i - 1) % rows
    local x = 1 + col * colW
    local y = top + row
    local bg = (row % 2 == 1) and C.rowAlt or C.bg
    if bg ~= C.bg then write(x, y, string.rep(" ", colW - 1), C.fg, bg) end
    local count = fmtCount(item.count)
    local nameW = colW - #count - 3
    local label = item.label
    if #label > nameW then label = label:sub(1, math.max(1, nameW - 1)) .. "\7" end
    write(x + 1, y, label, C.fg, bg)
    write(x + colW - 1 - #count, y, count, C.count, bg)
  end

  if #state.items == 0 then
    local msg = state.vaults == 0
      and "No vaults found - check the modems on your cable network"
      or  "All vaults are empty"
    write(2, top + math.floor(rows / 2), msg:sub(1, w - 2), C.bad, C.bg)
  end

  ---- footer
  write(1, h, string.rep(" ", w), C.barFg, C.barBg)
  local prevLabel, nextLabel = "< PREV", "NEXT >"
  local midLabel = string.format("PAGE %d/%d  [SORT]", state.page, pages)
  write(2, h, prevLabel, C.barFg, C.barBg)
  write(math.max(2, math.floor((w - #midLabel) / 2) + 1), h, midLabel, C.barFg, C.barBg)
  write(math.max(2, w - #nextLabel), h, nextLabel, C.barFg, C.barBg)
  buttons = {
    { x1 = 1,                          x2 = math.floor(w / 3),     y = h, action = "prev" },
    { x1 = math.floor(w / 3) + 1,      x2 = math.floor(w * 2 / 3), y = h, action = "sort" },
    { x1 = math.floor(w * 2 / 3) + 1,  x2 = w,                     y = h, action = "next" },
  }

  out.setBackgroundColor(C.bg)
  out.setTextColor(C.fg)
end

--------------------------------------------------------------------- control
local function refresh()
  scan()
  sortItems()
  draw()
end

local function pageBy(delta)
  state.page = math.min(pageCount(), math.max(1, state.page + delta))
  draw()
end

local function hit(x, y)
  for _, b in ipairs(buttons) do
    if y == b.y and x >= b.x1 and x <= b.x2 then return b.action end
  end
  if y <= 2 then return "refresh" end
  return nil
end

local function act(action)
  if action == "prev" then
    pageBy(-1)
  elseif action == "next" then
    pageBy(1)
  elseif action == "sort" then
    state.sort = state.sort % #SORTS + 1
    sortItems()
    state.page = 1
    draw()
  elseif action == "refresh" then
    refresh()
  end
end

--------------------------------------------------------------------- main
term.clear()
term.setCursorPos(1, 1)
print("Create Vault Stock Monitor")
print(mon and ("Output: monitor (" .. peripheral.getName(mon) .. ")")
          or  "Output: terminal (no monitor attached)")
print("Scanning...  press Q to quit")

refresh()

local timer = os.startTimer(config.refresh)
while true do
  local event = { os.pullEvent() }
  local name = event[1]

  if name == "timer" and event[2] == timer then
    refresh()
    timer = os.startTimer(config.refresh)

  elseif name == "monitor_touch" then
    act(hit(event[3], event[4]))

  elseif name == "mouse_click" and not mon then
    act(hit(event[3], event[4]))

  elseif name == "key" then
    local key = event[2]
    if key == keys.q then break
    elseif key == keys.r then refresh()
    elseif key == keys.s then act("sort")
    elseif key == keys.right or key == keys.down or key == keys.pageDown then pageBy(1)
    elseif key == keys.left or key == keys.up or key == keys.pageUp then pageBy(-1)
    end

  elseif name == "peripheral" or name == "peripheral_detach" then
    refresh()

  elseif name == "monitor_resize" then
    draw()
  end
end

for _, screen in ipairs({ out, term }) do
  screen.setBackgroundColor(colors.black)
  screen.setTextColor(colors.white)
  screen.clear()
  screen.setCursorPos(1, 1)
end
print("Vault monitor stopped.")
