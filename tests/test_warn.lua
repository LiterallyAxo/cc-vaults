-- Tests for scripts/warn.lua, run against the CC mock in tests/cc_mock.lua
local mock = require("cc_mock")
local H = require("harness")
local describe, it, eq = H.describe, H.it, H.eq

local SCRIPT = (_G.ROOT or "") .. "scripts/warn.lua"

-- roughly what a 1x7 line of blocks gives you at text scale 0.5: one merged
-- monitor, long and short
local STRIP_W, STRIP_H = 108, 10

local function newEnv(opts)
  opts = opts or {}
  if opts.width == nil then opts.width = STRIP_W end
  if opts.height == nil then opts.height = STRIP_H end
  return mock.newEnv(opts)
end

local function cfg(body)
  return { ["warn.cfg"] = "return {\n" .. body .. "\n}\n" }
end

-- a few scroll frames, so the sign has actually moved when the frame is caught.
-- Each tick books the next timer, so the ids run 1, 2, 3...
local function ticks(n)
  local out = {}
  for i = 1, n or 4 do out[i] = { "timer", i } end
  return out
end

-- how many cells of a frame row are not blank
local function inked(frame, y)
  local n = 0
  for x = 1, frame.w do
    if frame.ch[y][x] ~= " " then n = n + 1 end
  end
  return n
end

local function anyInk(frame)
  local n = 0
  for y = 1, frame.h do n = n + inked(frame, y) end
  return n
end

describe("warn: the sign itself", function()
  it("draws something on a long thin strip", function()
    local env = newEnv({ events = ticks(4) })
    H.runOk(env, SCRIPT)
    H.truthy(anyInk(env.frame) > 0, "nothing was drawn")
    eq(env.internals.strip.w, STRIP_W)
    eq(env.internals.strip.h, STRIP_H)
  end)

  it("says what it found and how big the letters came out", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local printed = env.printed()
    H.contains(printed, "1 monitor(s), 108x10 characters")
    H.contains(printed, "pixels tall")
  end)

  it("scrolls WATCH YOUR STEP between every message", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local state = env.internals.state
    H.contains(state.ribbon, "WATCH YOUR STEP")
    -- ten messages, each preceded by the headline
    eq(#state.starts, 20)
    eq(#env.internals.config.messages, 10)
  end)

  it("has a glyph for every character it can be asked to draw", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local internals = env.internals
    local missing = internals.glyphRows(internals.missing)
    for i = 1, #internals.state.ribbon do
      local char = internals.state.ribbon:sub(i, i)
      if internals.glyphFor(char) == missing then
        error("no glyph for " .. string.format("%q", char), 2)
      end
    end
  end)

  it("keeps every glyph 5 wide and 7 tall", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    for char, spec in pairs(env.internals.font) do
      local glyph = env.internals.glyphRows(spec)
      eq(#glyph, 7, "rows of " .. string.format("%q", char))
      for _, row in ipairs(glyph) do
        eq(#row, 5, "width of " .. string.format("%q", char))
      end
    end
  end)

  it("moves the ribbon along on every tick", function()
    local env = newEnv({ events = ticks(3) })
    H.runOk(env, SCRIPT)
    local layout = env.internals.layout()
    eq(env.internals.state.offset, layout.step * 3)
    eq(env.internals.state.tick, 3)
  end)

  it("draws a different frame once it has scrolled", function()
    local shots = {}
    local function shoot(env) shots[#shots + 1] = env.screen:dump() end
    local env = newEnv({ events = { shoot, { "timer", 1 }, { "timer", 2 }, shoot } })
    H.runOk(env, SCRIPT)
    eq(#shots, 2)
    H.truthy(shots[1] ~= shots[2], "the sign did not move")
  end)

  it("loops for ever without running off the end of the ribbon", function()
    local env = newEnv({ events = ticks(400) })
    H.runOk(env, SCRIPT)
    local layout = env.internals.layout()
    H.truthy(env.internals.state.offset < layout.loop, "offset escaped the loop")
    H.truthy(anyInk(env.frame) > 0, "the sign went blank")
  end)
end)

describe("warn: fitting the screen", function()
  it("sizes the letters to the height it is given", function()
    local tall = newEnv({ height = 10, events = ticks(2) })
    H.runOk(tall, SCRIPT)
    eq(tall.internals.layout().scale, 3)

    local short = newEnv({ height = 5, events = ticks(2) })
    H.runOk(short, SCRIPT)
    eq(short.internals.layout().scale, 1)
  end)

  it("puts hazard stripes on the top and bottom rows", function()
    local env = newEnv({ events = ticks(2) })
    H.runOk(env, SCRIPT)
    local frame = env.frame
    -- a chevron cell is yellow on black, or black on yellow where the glyph
    -- mask had to invert, so either half of the pair can be the yellow one
    local function hazard(y)
      for x = 1, frame.w do
        if frame.fg[y][x] ~= "4" and frame.bg[y][x] ~= "4" then return false end
      end
      return true
    end
    H.truthy(hazard(1), "top row is not yellow")         -- colours.yellow
    H.truthy(hazard(frame.h), "bottom row is not yellow")
    H.truthy(inked(frame, 1) > 0, "top stripe is blank")
    H.truthy(inked(frame, frame.h) > 0, "bottom stripe is blank")
  end)

  it("drops the stripes when told to", function()
    local env = newEnv({ files = cfg("  stripes = false,"), events = ticks(2) })
    H.runOk(env, SCRIPT)
    eq(env.internals.layout().stripe, 0)
  end)

  it("falls back to ordinary text on a screen too short for pixels", function()
    local env = newEnv({ height = 2, events = ticks(2) })
    H.runOk(env, SCRIPT)
    eq(env.internals.layout().plain, true)
    H.screenHas(env.frame, "WATCH YOUR STEP")
    H.contains(env.printed(), "too short for big letters")
  end)

  it("survives a monitor with only two colours", function()
    local env = newEnv({ color = false, events = ticks(2) })
    H.runOk(env, SCRIPT)
    eq(env.internals.theme.text, env.colors.white)
    H.truthy(anyInk(env.frame) > 0, "nothing was drawn")
  end)

  it("relays out when the monitor is resized", function()
    local env = newEnv({ events = { { "monitor_resize", "monitor_0" }, { "timer", 1 } } })
    H.runOk(env, SCRIPT)
    H.truthy(anyInk(env.frame) > 0, "nothing was drawn after the resize")
  end)
end)

describe("warn: several monitors as one ribbon", function()
  local function stripEnv(extra)
    local opts = { monitors = { "monitor_0", "monitor_1", "monitor_2" },
                   width = 36, height = 10, events = ticks(3) }
    for key, value in pairs(extra or {}) do opts[key] = value end
    return newEnv(opts)
  end

  it("joins them end to end, in peripheral-name order", function()
    local env = stripEnv()
    H.runOk(env, SCRIPT)
    local screens = env.internals.screens
    eq(#screens, 3)
    eq(screens[1].name, "monitor_0")
    eq(screens[3].name, "monitor_2")
    eq(screens[1].col0, 0)
    eq(screens[2].col0, 36)
    eq(screens[3].col0, 72)
    eq(env.internals.strip.w, 108)
  end)

  it("draws on every one of them", function()
    local env = stripEnv()
    H.runOk(env, SCRIPT)
    H.truthy(anyInk(env.frame) > 0, "monitor_0 is blank")
    H.truthy(anyInk(env.frames["monitor_1"]) > 0, "monitor_1 is blank")
    H.truthy(anyInk(env.frames["monitor_2"]) > 0, "monitor_2 is blank")
  end)

  it("gives each screen its own slice of the same ribbon", function()
    local env = stripEnv()
    H.runOk(env, SCRIPT)
    -- the second screen must show what a 108 wide strip shows from column 37,
    -- which is what makes a sentence run across the whole wall
    local internals = env.internals
    local wide = internals.rowOf({ w = 108, px0 = 0, col0 = 0 }, 5)
    local second = internals.rowOf(internals.screens[2], 5)
    eq(second, wide:sub(37, 72))
  end)
end)

describe("warn: what the player can change", function()
  it("scrolls text given on the command line instead", function()
    local env = newEnv({ events = ticks(2) })
    H.runOk(env, SCRIPT, "keep", "out", "of", "the", "doorway")
    H.contains(env.internals.state.ribbon, "KEEP OUT OF THE DOORWAY")
    H.falsy(env.internals.state.ribbon:find("WATCH YOUR STEP", 1, true),
      "the headline should stand aside for custom text")
    eq(#env.internals.state.starts, 1)
  end)

  it("splits custom text on a pipe", function()
    local env = newEnv({ events = ticks(2) })
    H.runOk(env, SCRIPT, "doors closing | stand clear")
    eq(#env.internals.state.starts, 2)
    H.contains(env.internals.state.ribbon, "DOORS CLOSING")
    H.contains(env.internals.state.ribbon, "STAND CLEAR")
  end)

  it("reads warn.cfg", function()
    local env = newEnv({
      files = cfg('  headline = "STAND CLEAR",\n  theme = "red",\n' ..
                  '  messages = { "the door wins" },'),
      events = ticks(2),
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.theme.text, env.colors.red)
    H.contains(env.internals.state.ribbon, "STAND CLEAR")
    H.contains(env.internals.state.ribbon, "THE DOOR WINS")
    H.contains(env.printed(), "warn.cfg")
  end)

  it("writes a starter config", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "setup")
    H.contains(env.files["warn.cfg"], "headline")
    H.contains(env.printed(), "wrote warn.cfg")
  end)

  it("will not overwrite a config without being told twice", function()
    local env = newEnv({ files = cfg('  speed = 9,') })
    H.runOk(env, SCRIPT, "setup")
    H.contains(env.printed(), "already exists")
    H.contains(env.files["warn.cfg"], "speed = 9")
  end)

  it("prints the monitor sizes so the order can be checked", function()
    local env = newEnv({ monitors = { "monitor_0", "monitor_1" }, width = 54 })
    H.runOk(env, SCRIPT, "size")
    local printed = env.printed()
    H.contains(printed, "2 monitor(s), 108x10 characters")
    H.contains(printed, "monitor_0  54x10  from column 1")
    H.contains(printed, "monitor_1  54x10  from column 55")
  end)

  it("lists what it can do", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "help")
    H.contains(env.printed(), "scrolling hazard sign")
    H.contains(env.printed(), "warn size")
  end)
end)

describe("warn: installing it", function()
  local RAW = "https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/"

  -- the repo as it is on disk, so this fails if the manifest and the file
  -- ever drift apart
  local function repoFile(path)
    local handle = assert(io.open((_G.ROOT or "") .. path, "r"))
    local body = handle:read("a")
    handle:close()
    return body
  end

  local MANIFEST = repoFile("manifest.txt")
  local BODY = repoFile("scripts/warn.lua")

  local function manifestLine()
    for line in MANIFEST:gmatch("[^\r\n]+") do
      local name, file, version = line:match("^%s*([^|]-)%s*|%s*([^|]-)%s*|%s*([^|]-)%s*|")
      if name == "warn" then return file, version end
    end
  end

  it("is in the manifest, pointing at the file it ships", function()
    local file, version = manifestLine()
    eq(file, "scripts/warn.lua")
    H.truthy(version and version ~= "", "no version in the manifest")
  end)

  it("says the same version in the manifest, the header and the code", function()
    local _, version = manifestLine()
    eq(BODY:match('local VERSION%s*=%s*"([^"]+)"'), version, "VERSION constant")
    eq(BODY:match("warn%s+%-%-.-v([%d%.]+)"), version, "header comment")
  end)

  it("installs as warn.lua from a vaults install", function()
    local env = mock.newEnv({ urls = {
      [RAW .. "manifest.txt"] = MANIFEST,
      [RAW .. "scripts/warn.lua"] = BODY,
    } })
    H.runOk(env, (_G.ROOT or "") .. "vaults.lua", "install", "warn")
    local _, version = manifestLine()
    eq(env.files["warn.lua"], BODY, "installed to the computer root as warn.lua")
    H.contains(env.printed(), "+ warn.lua")
    H.contains(env.printed(), "Run:  warn")
    H.contains(env.files[".vaults-state"], "warn|" .. version)
  end)

  it("runs what was installed", function()
    local env = newEnv({ files = { ["warn.lua"] = BODY }, events = ticks(2) })
    H.runOk(env, SCRIPT)
    H.truthy(anyInk(env.frame) > 0, "the installed copy drew nothing")
  end)
end)

describe("warn: skipping and stopping", function()
  it("jumps to the next message when the monitor is tapped", function()
    local env = newEnv({ events = { { "monitor_touch", "monitor_0", 4, 4 } } })
    H.runOk(env, SCRIPT)
    local internals = env.internals
    eq(internals.state.offset, internals.state.starts[2] * internals.layout().charPx)
  end)

  it("jumps on the n key too, and wraps back round at the end", function()
    local env = newEnv({ events = { { "key", mock.KEYS.n } } })
    H.runOk(env, SCRIPT)
    H.truthy(env.internals.state.offset > 0, "n did nothing")

    local wrapped = newEnv({ events = { function(e)
      e.globals.__VAULT_TEST.internals.state.offset = 1e9
      e.pushNext({ "key", mock.KEYS.n })
    end } })
    H.runOk(wrapped, SCRIPT)
    eq(wrapped.internals.state.offset, 0)
  end)

  it("puts the palette back and clears the sign on the way out", function()
    local env = newEnv({ events = ticks(2) })
    H.runOk(env, SCRIPT)
    eq(env.screen:isBlank(), true)
    -- the mock records the last palette written; a restored slot is the
    -- default the mock reports, not the script's amber
    for slot in pairs(env.internals.palette) do
      local r, g, b = env.screen.palette[slot][1], env.screen.palette[slot][2],
                      env.screen.palette[slot][3]
      eq(r, 0, "palette slot not restored")
      eq(g, 0, "palette slot not restored")
      eq(b, 0, "palette slot not restored")
    end
    H.contains(env.printed(), "warn stopped.")
  end)
end)
