--[[
  warn  --  scrolling hazard sign for CC: Tweaked                      v0.1.0

  Part of the cc-vaults package; install it with `vaults install warn`.

  Built for a long thin line of monitors over a doorway -- a 1x7 strip is what
  it was written on -- and it treats every monitor on the network as one
  continuous ribbon, so the text scrolls off one screen and onto the next.

  Big dot matrix letters on a black strip, hazard chevrons crawling along the
  top and bottom, and a rotating list of things to say about the blast doors.

    warn                  scroll the built in messages
    warn <text...>        scroll your own text instead ("|" splits messages)
    warn size             what each monitor measures, in characters
    warn setup            write a starter warn.cfg you can edit
    warn help             this list

  Wiring:
    computer -> monitors, either touching or over a wired modem and cable
]]

local VERSION = "0.1.0"
local CONFIG  = "warn.cfg"

--------------------------------------------------------------------- config
local config = {
  headline  = "WATCH YOUR STEP",  -- shown again between every other message
  textScale = 0.5,      -- monitor text scale; 0.5 is the most pixels
  scroll    = 0.15,     -- seconds between frames
  speed     = 3,        -- letters per second the ribbon moves
  scale     = 0,        -- letter size in pixels, 0 to fit the screen
  maxScale  = 4,        -- how big "fit the screen" is allowed to go
  stripes   = true,     -- hazard chevrons above and below the text
  theme     = "amber",  -- "amber" or "red"
  messages  = {
    "MIND THE DOORS. THE DOORS DO NOT MIND YOU.",
    "THESE DOORS WEIGH 400 TONNES. YOU WEIGH SIX PORK CHOPS.",
    "DAYS SINCE THE LAST DOOR RELATED INCIDENT: 0",
    "IF THE DOOR IS CLOSING, IT IS CLOSING WITH OR WITHOUT YOU.",
    "IN THE EVENT OF A CREEPER THE DOORS WILL BE FINE. YOU WILL NOT.",
    "NO RUNNING. NO PUSHING. NO BECOMING PART OF THE DOOR.",
    "THE DOOR HAS RIGHT OF WAY. THE DOOR HAS ALWAYS HAD RIGHT OF WAY.",
    "IRON DOORS: UNBEATEN IN 1,247 CONSECUTIVE ARGUMENTS.",
    "STAND CLEAR OF THE THRESHOLD. IT IS NOT A PHOTO OPPORTUNITY.",
    "THE DOORS OPEN AT WALKING PACE. SO SHOULD YOU.",
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

--------------------------------------------------------------------- font
-- 5x7 dot matrix, the shape real platform and gantry signs use.  Every glyph
-- is the same width, which is what lets the renderer find the letter under a
-- pixel with arithmetic instead of walking the string.
local GLYPH_W, GLYPH_H, GAP = 5, 7, 1
local CELL_W = GLYPH_W + GAP

local FONT = {
  ["A"] = ".###. #...# #...# ##### #...# #...# #...#",
  ["B"] = "####. #...# #...# ####. #...# #...# ####.",
  ["C"] = ".###. #...# #.... #.... #.... #...# .###.",
  ["D"] = "####. #...# #...# #...# #...# #...# ####.",
  ["E"] = "##### #.... #.... ####. #.... #.... #####",
  ["F"] = "##### #.... #.... ####. #.... #.... #....",
  ["G"] = ".###. #...# #.... #..## #...# #...# .###.",
  ["H"] = "#...# #...# #...# ##### #...# #...# #...#",
  ["I"] = ".###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.",
  ["J"] = "..### ...#. ...#. ...#. ...#. #..#. .##..",
  ["K"] = "#...# #..#. #.#.. ##... #.#.. #..#. #...#",
  ["L"] = "#.... #.... #.... #.... #.... #.... #####",
  ["M"] = "#...# ##.## #.#.# #.#.# #...# #...# #...#",
  ["N"] = "#...# ##..# #.#.# #..## #...# #...# #...#",
  ["O"] = ".###. #...# #...# #...# #...# #...# .###.",
  ["P"] = "####. #...# #...# ####. #.... #.... #....",
  ["Q"] = ".###. #...# #...# #...# #.#.# #..#. .##.#",
  ["R"] = "####. #...# #...# ####. #.#.. #..#. #...#",
  ["S"] = ".#### #.... #.... .###. ....# ....# ####.",
  ["T"] = "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
  ["U"] = "#...# #...# #...# #...# #...# #...# .###.",
  ["V"] = "#...# #...# #...# #...# #...# .#.#. ..#..",
  ["W"] = "#...# #...# #...# #.#.# #.#.# ##.## #...#",
  ["X"] = "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
  ["Y"] = "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..",
  ["Z"] = "##### ....# ...#. ..#.. .#... #.... #####",
  ["0"] = ".###. #...# #..## #.#.# ##..# #...# .###.",
  ["1"] = "..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.",
  ["2"] = ".###. #...# ....# ...#. ..#.. .#... #####",
  ["3"] = "##### ...#. ..##. ....# ....# #...# .###.",
  ["4"] = "...#. ..##. .#.#. #..#. ##### ...#. ...#.",
  ["5"] = "##### #.... ####. ....# ....# #...# .###.",
  ["6"] = "..##. .#... #.... ####. #...# #...# .###.",
  ["7"] = "##### ....# ...#. ..#.. .#... .#... .#...",
  ["8"] = ".###. #...# #...# .###. #...# #...# .###.",
  ["9"] = ".###. #...# #...# .#### ....# ...#. .##..",
  [" "] = "..... ..... ..... ..... ..... ..... .....",
  ["."] = "..... ..... ..... ..... ..... .##.. .##..",
  [","] = "..... ..... ..... ..... .##.. .##.. .#...",
  ["!"] = "..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..",
  ["?"] = ".###. #...# ....# ...#. ..#.. ..... ..#..",
  [":"] = "..... .##.. .##.. ..... .##.. .##.. .....",
  [";"] = "..... .##.. .##.. ..... .##.. .##.. .#...",
  ["'"] = "..#.. ..#.. .#... ..... ..... ..... .....",
  ['"'] = ".#.#. .#.#. ..... ..... ..... ..... .....",
  ["-"] = "..... ..... ..... .###. ..... ..... .....",
  ["+"] = "..... ..#.. ..#.. ##### ..#.. ..#.. .....",
  ["/"] = "....# ....# ...#. ..#.. .#... #.... #....",
  ["("] = "...#. ..#.. .#... .#... .#... ..#.. ...#.",
  [")"] = ".#... ..#.. ...#. ...#. ...#. ..#.. .#...",
  ["%"] = "##..# ##..# ...#. ..#.. .#... #..## #..##",
  ["&"] = ".##.. #..#. #.#.. .#... #.#.# #..#. .##.#",
  ["*"] = "..... #.#.# .###. ##### .###. #.#.# .....",
  ["\7"] = "..... ..#.. .###. ##### .###. ..#.. .....",
}
local MISSING = "##### #...# #...# #...# #...# #...# #####"

-- "..#.. .###. ..." -> { "..#..", ".###.", ... }, done once per glyph
local rows = {}
local function glyphRows(spec)
  if rows[spec] then return rows[spec] end
  local out = {}
  for row in spec:gmatch("%S+") do out[#out + 1] = row end
  rows[spec] = out
  return out
end
for _, spec in pairs(FONT) do glyphRows(spec) end
glyphRows(MISSING)

local function glyphFor(char)
  return glyphRows(FONT[char] or MISSING)
end

--------------------------------------------------------------------- device
-- Every monitor on the network, in peripheral-name order, laid end to end into
-- one strip.  Place them left to right in that order and a sentence runs
-- across the whole wall; a 1x7 line of blocks merges into a single monitor
-- and is just the one screen as far as this is concerned.  `warn size` prints
-- the order, which is the only way to check it without watching the wall.
local screens = {}
local strip = { w = 0, h = 0 }

local function findScreens()
  screens = {}
  for _, name in ipairs(peripheral.getNames()) do
    for _, kind in ipairs({ peripheral.getType(name) }) do
      if kind == "monitor" then
        screens[#screens + 1] = { name = name, dev = peripheral.wrap(name) }
        break
      end
    end
  end
  table.sort(screens, function(a, b) return a.name < b.name end)
  if #screens == 0 then
    screens[1] = { name = "term", dev = term.current() }
  end

  local col, tallest = 0, nil
  for _, sc in ipairs(screens) do
    if sc.name ~= "term" and sc.dev.setTextScale then
      pcall(sc.dev.setTextScale, config.textScale)
    end
    sc.w, sc.h = sc.dev.getSize()
    sc.col0 = col                 -- where this screen starts along the strip
    sc.px0  = col * 2
    sc.last = {}
    col = col + sc.w
    tallest = math.min(tallest or sc.h, sc.h)
  end
  strip.w, strip.h = col, tallest or 1
end

findScreens()

local isColor = screens[1].dev.isColour and screens[1].dev.isColour() or false

--------------------------------------------------------------------- theme
local THEMES = {
  amber = { base = colors.black, text = colors.orange, stripe = colors.yellow },
  red   = { base = colors.black, text = colors.red,    stripe = colors.yellow },
}

local theme = THEMES[tostring(config.theme):lower()] or THEMES.amber
if not isColor then
  theme = { base = colors.black, text = colors.white, stripe = colors.white }
end

-- a hotter amber and a deeper black than vanilla; advanced monitors only
local PALETTE = {
  [colors.black]  = 0x05070a,
  [colors.orange] = 0xffa621,
  [colors.yellow] = 0xffd733,
  [colors.red]    = 0xff3b30,
  [colors.white]  = 0xf4f6fa,
}

-- the palette is per display and outlives the program, so keep the old one
local savedPalette = {}
local function applyPalette()
  if not isColor then return end
  for _, sc in ipairs(screens) do
    if sc.dev.setPaletteColour then
      savedPalette[sc.name] = savedPalette[sc.name] or {}
      for slot, rgb in pairs(PALETTE) do
        savedPalette[sc.name][slot] = { sc.dev.getPaletteColour(slot) }
        sc.dev.setPaletteColour(slot, rgb)
      end
    end
  end
end

local function restorePalette()
  for _, sc in ipairs(screens) do
    for slot, rgb in pairs(savedPalette[sc.name] or {}) do
      if sc.dev.setPaletteColour then
        sc.dev.setPaletteColour(slot, rgb[1], rgb[2], rgb[3])
      end
    end
  end
end

--------------------------------------------------------------------- ribbon
local SEP = "   \7   "

local function upper(text)
  return tostring(text):upper()
end

local state = { offset = 0, crawl = 0, tick = 0, ribbon = "", glyphs = {}, starts = {} }

-- headline, message, headline, message: the line they actually have to read
-- comes back round every other message instead of once a lap
local function segments(custom)
  local out = {}
  local head = config.headline and upper(config.headline) or ""
  for _, message in ipairs(custom or config.messages or {}) do
    if head ~= "" and not custom then out[#out + 1] = head end
    out[#out + 1] = upper(message)
  end
  if #out == 0 then out[1] = head ~= "" and head or "WATCH YOUR STEP" end
  return out
end

local function buildRibbon(custom)
  local segs = segments(custom)
  local at = 0
  state.starts = {}
  for _, seg in ipairs(segs) do
    state.starts[#state.starts + 1] = at
    at = at + #seg + #SEP
  end
  -- the trailing separator is what makes the loop join up cleanly
  state.ribbon = table.concat(segs, SEP) .. SEP
  state.glyphs = {}
  for i = 1, #state.ribbon do
    state.glyphs[i] = glyphFor(state.ribbon:sub(i, i))
  end
end

--------------------------------------------------------------------- layout
-- A character cell is two pixels across and three down, and on a monitor those
-- pixels are square, so the drawing glyphs at 128-159 buy the strip three
-- times the vertical resolution the character grid has.
local layout = {}

local function relayout()
  local h = strip.h
  local stripe = (config.stripes and h >= 5) and 1 or 0
  local bandPx = (h - stripe * 2) * 3

  if bandPx < GLYPH_H then
    -- too short for letters made of pixels: ordinary text on one row instead
    layout = { plain = true, stripe = 0, charPx = 1,
               row = math.max(1, math.ceil(h / 2)) }
  else
    local scale = math.floor(bandPx / GLYPH_H)
    if (config.scale or 0) > 0 then scale = config.scale end
    scale = math.max(1, math.min(config.maxScale or 4, scale))
    layout = {
      plain = false, scale = scale, stripe = stripe,
      top = stripe * 3 + math.floor((bandPx - GLYPH_H * scale) / 2),
      charPx = CELL_W * scale,
    }
  end

  layout.step = math.max(1, math.floor(
    (config.speed or 3) * layout.charPx * (config.scroll or 0.15) + 0.5))
  layout.loop = math.max(1, #state.ribbon * layout.charPx)
  for _, sc in ipairs(screens) do sc.last = {} end
end

--------------------------------------------------------------------- ink
-- Is the pixel at (px, py) lit?  This is O(1) and there is no seam to special
-- case: the ribbon repeats for ever, so the letter under a pixel is a modulo
-- away however far the sign has scrolled.
local function textInk(px, py)
  local gy = py - layout.top
  if gy < 0 or gy >= GLYPH_H * layout.scale then return false end
  local col = px + state.offset
  local gx = math.floor((col % layout.charPx) / layout.scale)
  if gx >= GLYPH_W then return false end            -- the gap between letters
  local slot = math.floor(col / layout.charPx) % #state.ribbon + 1
  local row = state.glyphs[slot][math.floor(gy / layout.scale) + 1]
  return row:sub(gx + 1, gx + 1) == "#"
end

-- diagonal hazard bars, crawling the way the text does
local function stripeInk(px, py)
  return (px + py + state.crawl) % 8 < 4
end

--------------------------------------------------------------------- paint
local HEX = "0123456789abcdef"
local blitOf = {}
for i = 0, 15 do blitOf[2 ^ i] = HEX:sub(i + 1, i + 1) end

local BASE = blitOf[theme.base]

local function stripeRow(cy)
  return layout.stripe > 0 and (cy == 1 or cy == strip.h)
end

-- one row of one screen, as the three same-length strings blit wants
local function rowOf(sc, cy)
  local chars, fg, bg = {}, {}, {}

  if layout.plain then
    local ink = blitOf[theme.text]
    for cx = 1, sc.w do
      local char = " "
      if cy == layout.row then
        local col = (sc.col0 + cx - 1 + state.offset) % #state.ribbon
        char = state.ribbon:sub(col + 1, col + 1)
      end
      chars[cx], fg[cx], bg[cx] = char, ink, BASE
    end
    return table.concat(chars), table.concat(fg), table.concat(bg)
  end

  local stripey = stripeRow(cy)
  local ink = blitOf[stripey and theme.stripe or theme.text]
  local lit = stripey and stripeInk or textInk

  for cx = 1, sc.w do
    local px, py = sc.px0 + (cx - 1) * 2, (cy - 1) * 3
    local mask, bit = 0, 1
    for dy = 0, 2 do
      for dx = 0, 1 do
        if lit(px + dx, py + dy) then mask = mask + bit end
        bit = bit * 2
      end
    end
    -- the glyphs only cover five of the six pixels; with the sixth one set the
    -- mask inverts and the two colours swap
    local f, b = ink, BASE
    if mask >= 32 then mask, f, b = 31 - (mask - 32), b, f end
    chars[cx] = mask == 0 and " " or string.char(128 + mask)
    fg[cx], bg[cx] = f, b
  end
  return table.concat(chars), table.concat(fg), table.concat(bg)
end

local function paint()
  for _, sc in ipairs(screens) do
    for cy = 1, sc.h do
      local chars, fg, bg
      if cy > strip.h then                 -- a screen taller than the strip
        chars = string.rep(" ", sc.w)
        fg, bg = string.rep("0", sc.w), string.rep(BASE, sc.w)
      else
        chars, fg, bg = rowOf(sc, cy)
      end
      local key = chars .. fg .. bg
      if sc.last[cy] ~= key then           -- only repaint what actually moved
        sc.last[cy] = key
        sc.dev.setCursorPos(1, cy)
        sc.dev.blit(chars, fg, bg)
      end
    end
  end
end

local function advance()
  state.offset = (state.offset + layout.step) % layout.loop
  state.crawl = state.crawl - 1
  state.tick = state.tick + 1
end

-- jump to the next message, for when somebody taps the board
local function skip()
  local first
  for _, start in ipairs(state.starts) do
    local at = start * layout.charPx
    if not first then first = at end
    if at > state.offset then state.offset = at return end
  end
  state.offset = first or 0
end

--------------------------------------------------------------------- setup
local TEMPLATE = [[
-- warn.cfg -- edit and save, then run `warn` again to pick it up
return {
  headline = "WATCH YOUR STEP",   -- repeated between the other messages
  theme    = "amber",             -- "amber" or "red"
  speed    = 3,                   -- letters per second
  stripes  = true,                -- hazard chevrons top and bottom
  scale    = 0,                   -- letter size in pixels, 0 fits the screen
  messages = {
    "MIND THE DOORS. THE DOORS DO NOT MIND YOU.",
    "DAYS SINCE THE LAST DOOR RELATED INCIDENT: 0",
    "NO RUNNING. NO PUSHING. NO BECOMING PART OF THE DOOR.",
  },
}
]]

local function writeTemplate(force)
  if fs.exists(CONFIG) and not force then
    print(CONFIG .. " already exists; warn setup -f overwrites it")
    return
  end
  local handle = fs.open(CONFIG, "w")
  handle.write(TEMPLATE)
  handle.close()
  print("wrote " .. CONFIG .. " -- edit it, then run: warn")
end

--------------------------------------------------------------------- main
local args = { ... }
local first = tostring(args[1] or ""):lower()

if first == "help" or first == "-h" or first == "--help" then
  print("warn " .. VERSION .. " -- scrolling hazard sign")
  print("warn                 the built in messages")
  print("warn <text...>       your own text (\"|\" splits messages)")
  print("warn size            monitor sizes, in characters")
  print("warn setup           write " .. CONFIG)
  print("keys: [q]uit  [n]ext message; tapping a monitor skips too")
  return
end

if first == "setup" then
  writeTemplate(args[2] == "-f" or args[2] == "--force")
  return
end

if first == "size" then
  print(#screens .. " monitor(s), " .. strip.w .. "x" .. strip.h ..
        " characters end to end")
  for i, sc in ipairs(screens) do
    print("  " .. i .. ". " .. sc.name .. "  " .. sc.w .. "x" .. sc.h ..
          "  from column " .. (sc.col0 + 1))
  end
  print("they read left to right in that order")
  return
end

-- anything else on the command line is the text to scroll
local custom
if #args > 0 then
  custom = {}
  for part in table.concat(args, " "):gmatch("[^|]+") do
    part = part:match("^%s*(.-)%s*$")
    if part ~= "" then custom[#custom + 1] = part end
  end
  if #custom == 0 then custom = nil end
end

buildRibbon(custom)
relayout()

if _G.__VAULT_TEST then
  _G.__VAULT_TEST.internals = {
    config = config, theme = theme, state = state, screens = screens,
    strip = strip, palette = PALETTE, font = FONT, missing = MISSING,
    layout = function() return layout end,
    glyphFor = glyphFor, glyphRows = glyphRows, segments = segments,
    buildRibbon = buildRibbon, relayout = relayout, textInk = textInk,
    rowOf = rowOf, paint = paint, advance = advance, skip = skip,
  }
end

if configErr then printError(CONFIG .. ": " .. tostring(configErr)) end
print("warn " .. VERSION .. " -- " .. #screens .. " monitor(s), " ..
      strip.w .. "x" .. strip.h .. " characters" ..
      (configOk and (", " .. CONFIG) or ""))
print(#state.starts .. " message(s), " ..
      (layout.plain and "screen too short for big letters"
                     or ("letters " .. layout.scale * GLYPH_H .. " pixels tall")))
print("keys: [q]uit  [n]ext")

applyPalette()

local ok, err = pcall(function()
  paint()
  local tickTimer = os.startTimer(config.scroll)

  while true do
    local event = { os.pullEvent() }
    local name = event[1]

    if name == "timer" then
      if event[2] == tickTimer then
        advance()
        paint()
        tickTimer = os.startTimer(config.scroll)
      end

    elseif name == "monitor_touch" or name == "mouse_click" then
      skip()
      paint()

    elseif name == "key" then
      local key = event[2]
      if key == keys.q then break
      elseif key == keys.n or key == keys.space then
        skip()
        paint()
      end

    elseif name == "monitor_resize" or name == "term_resize"
        or name == "peripheral" or name == "peripheral_detach" then
      findScreens()
      relayout()
      paint()
    end
  end
end)

restorePalette()
for _, sc in ipairs(screens) do
  sc.dev.setBackgroundColour(colors.black)
  sc.dev.setTextColour(colors.white)
  sc.dev.clear()
  sc.dev.setCursorPos(1, 1)
end
if not ok then error(err, 0) end
print("warn stopped.")
