-- Renders the monitor to your terminal so you can see the layout without
-- launching Minecraft:   lua tests/preview.lua [view] [width] [height]
--   stock: stock | movers | vaults | detail
--   rail:  departures | arrivals | platform | summary | onboard | route
--          | concourse
--   warn:  warn  (a 1x7 strip of monitors is about 108x10)
local here = (arg and arg[0] or "tests/preview.lua"):gsub("[^/\\]+$", "")
if here == "" then here = "./" end
package.path = here .. "?.lua;" .. package.path

local mock = require("cc_mock")
local keys = mock.KEYS

local view   = (arg[1] or "stock"):lower()
local width  = tonumber(arg[2]) or (view == "warn" and 108) or 82
local height = tonumber(arg[3]) or (view == "warn" and 10) or 26

--------------------------------------------------------------------- render
-- Paint a captured frame with the script's own palette, in 24-bit ANSI colour.
-- CC draws with 2x3 block glyphs at 128-159; a terminal has the same shapes in
-- the Unicode sextant block, which skips the plain left half block.
local function glyph(ch)
  local byte = ch:byte()
  if byte >= 128 and byte <= 159 then
    local mask = byte - 128
    if mask == 0 then return " " end
    if mask == 21 then return utf8.char(0x258C) end
    return utf8.char(0x1FB00 + (mask < 21 and mask - 1 or mask - 2))
  end
  if ch == "\7" then return utf8.char(0x25CF) end
  return ch
end

local function render(frame, palette)
  local HEX = "0123456789abcdef"
  local rgbOf = {}
  for i = 0, 15 do
    local rgb = palette[2 ^ i] or 0x808080
    rgbOf[HEX:sub(i + 1, i + 1)] = { (rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff }
  end
  io.write("\n")
  for y = 1, frame.h do
    io.write("  ")
    for x = 1, frame.w do
      local f, b = rgbOf[frame.fg[y][x]], rgbOf[frame.bg[y][x]]
      io.write(string.format("\27[38;2;%d;%d;%dm\27[48;2;%d;%d;%dm",
        f[1], f[2], f[3], b[1], b[2], b[3]), glyph(frame.ch[y][x]))
    end
    io.write("\27[0m\n")
  end
  io.write("\n")
end

--------------------------------------------------------------------- warn
-- The hazard sign, mid-scroll: a few ticks in, so the ribbon is under way.
if view == "warn" or view == "sign" then
  local events = {}
  for i = 1, tonumber(arg[4]) or 12 do events[i] = { "timer", i } end
  local env = mock.newEnv({ width = width, height = height, events = events })
  local ok, err = env.run(here .. "../scripts/warn.lua")
  if not ok then
    io.write("script error: ", tostring(err), "\n")
    os.exit(1)
  end
  render(env.frame, env.internals.palette)
  return
end

--------------------------------------------------------------------- rail
local RAIL = {
  departures = true, arrivals = true, platform = true, summary = true,
  onboard = true, route = true, concourse = true,
}

if RAIL[view] then
  local schedule = {
    cyclic = true,
    entries = {
      { instruction = { id = "create:destination", data = { text = "Create Central *" } } },
      { instruction = { id = "create:destination", data = { text = "Coventry" } } },
      { instruction = { id = "create:destination", data = { text = "Rugby" } } },
      { instruction = { id = "create:destination", data = { text = "London Euston" } } },
    },
  }
  local env = mock.newEnv({
    width = width, height = height, time = 15.44,
    stations = {
      ["create:track_station_0"] = {
        name = "Create Central Platform 3", present = true,
        train = "1A23", schedule = schedule,
      },
      ["create:track_station_1"] = {
        name = "Create Central Platform 5", enroute = true, train = "1M14",
      },
    },
    events = {
      -- let the ticker scroll a little before the frame is captured
      { "timer", 2 }, { "timer", 2 }, { "timer", 2 }, { "timer", 2 },
    },
  })
  local ok, err = env.run(here .. "../scripts/rail.lua", view)
  if not ok then
    io.write("script error: ", tostring(err), "\n")
    os.exit(1)
  end
  render(env.frame, env.internals.palette)
  return
end

local function stack(id, count, label) return { name = id, count = count, displayName = label } end

local vaults = {
  ["create:item_vault_0"] = {
    stack("minecraft:cobblestone", 6400, "Cobblestone"),
    stack("minecraft:iron_ingot", 1280, "Iron Ingot"),
    stack("create:andesite_alloy", 892, "Andesite Alloy"),
    stack("minecraft:oak_log", 448, "Oak Log"),
    stack("thermal:copper_ingot", 320, "Copper Ingot"),
  },
  ["create:item_vault_1"] = {
    stack("minecraft:redstone", 2304, "Redstone Dust"),
    stack("create:zinc_ingot", 704, "Zinc Ingot"),
    stack("minecraft:gold_ingot", 192, "Gold Ingot"),
    stack("minecraft:iron_ingot", 640, "Iron Ingot"),
    stack("create:brass_ingot", 384, "Brass Ingot"),
  },
  ["create:item_vault_2"] = {
    stack("minecraft:diamond", 64, "Diamond"),
    stack("create:precision_mechanism", 37, "Precision Mechanism"),
    stack("minecraft:netherite_scrap", 9, "Netherite Scrap"),
    stack("create:andesite_alloy", 1600, "Andesite Alloy"),
    stack("minecraft:sand", 12800, "Sand"),
  },
  ["create:item_vault_3"] = {
    stack("minecraft:wheat", 576, "Wheat"),
    stack("minecraft:bread", 128, "Bread"),
    stack("minecraft:sugar_cane", 1024, "Sugar Cane"),
  },
}

local events = {}
local function churn(env)
  env.setVault("create:item_vault_1", {
    stack("minecraft:redstone", 2304, "Redstone Dust"),
    stack("create:zinc_ingot", 1216, "Zinc Ingot"),
    stack("minecraft:gold_ingot", 128, "Gold Ingot"),
    stack("minecraft:iron_ingot", 640, "Iron Ingot"),
    stack("create:brass_ingot", 384, "Brass Ingot"),
  })
end

if view == "movers" then
  events = { churn, { "key", keys.r }, { "key", keys.tab } }
elseif view == "vaults" then
  events = { { "key", keys.tab }, { "key", keys.tab } }
elseif view == "detail" then
  events = { function(env)
    local _, y, x = env.screen:fgOf("Iron Ingot")
    env.pushNext({ "monitor_touch", "monitor_0", x or 2, y or 5 })
  end }
end

local env = mock.newEnv({
  vaults = vaults,
  sizes = { ["create:item_vault_0"] = 27, ["create:item_vault_1"] = 27,
            ["create:item_vault_2"] = 27, ["create:item_vault_3"] = 108 },
  width = width, height = height,
  events = events,
})

local ok, err = env.run(here .. "../scripts/stock.lua")
if not ok then
  io.write("script error: ", tostring(err), "\n")
  os.exit(1)
end

-- render with the script's own palette, using 24-bit ANSI colour
render(env.frame, env.internals.palette)
