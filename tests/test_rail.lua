-- Tests for scripts/rail.lua, run against the CC mock in tests/cc_mock.lua
local mock = require("cc_mock")
local H = require("harness")
local describe, it, eq = H.describe, H.it, H.eq

local SCRIPT = (_G.ROOT or "") .. "scripts/rail.lua"

-- 15:00 in Minecraft hours, so every expected time in here is predictable
local AT_THREE = 15.0

local function stop(text)
  return { instruction = { id = "create:destination", data = { text = text } } }
end

-- a cyclic Euston working that calls here, then three stations, then back
local function eustonSchedule()
  return {
    cyclic = true,
    entries = {
      stop("Create Central *"),
      stop("Coventry"),
      stop("Rugby"),
      stop("London Euston"),
    },
  }
end

local function newEnv(opts)
  opts = opts or {}
  if opts.time == nil then opts.time = AT_THREE end
  if opts.width == nil then opts.width = 80 end
  if opts.height == nil then opts.height = 20 end
  return mock.newEnv(opts)
end

local function cfg(body)
  return { ["rail.cfg"] = "return {\n" .. body .. "\n}\n" }
end

-- a booked timetable, the way somebody's rail.cfg would look
local TIMETABLE = [[
  station = "Create Central",
  timetable = {
    { depart = "15:26", platform = 3, coaches = 9, via = "Coventry",
      origin = "Wolverhampton",
      calls = { "Coventry", "Rugby", "London Euston" } },
    { depart = "15:41", platform = 5, delay = 7,
      calls = { "Stafford", "Crewe", "Manchester Piccadilly" } },
    { depart = "15:52", platform = 10, cancelled = true,
      calls = { "Newport", "Cardiff Central" } },
  },
]]

describe("rail: boards on a bare computer", function()
  it("draws a departure board with nothing wired up", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "Departures")
    H.screenHas(env.frame, "Time")
    H.screenHas(env.frame, "Destination")
    H.screenHas(env.frame, "Expected")
    eq(env.internals.state.source, "demo")
  end)

  it("puts the station and the clock in the header", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "CREATE CENTRAL")
    H.screenHas(env.frame, "15:00")
  end)

  it("says so plainly when there is nothing to show", function()
    local env = newEnv({ files = cfg('  demo = false,') })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "no departures")
    eq(env.internals.state.source, "none")
  end)

  it("survives a monitor with only two colours", function()
    local env = newEnv({ color = false })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "Departures")
  end)
end)

describe("rail: the booked timetable", function()
  it("reads rail.cfg and lists it in departure order", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "timetable")
    local services = env.internals.state.services
    eq(#services, 3)
    eq(services[1].dest, "London Euston")
    eq(services[1].platform, "3")
    H.screenHas(env.frame, "15:26")
    H.screenHas(env.frame, "London Euston")
  end)

  it("shows On time, an expected time, or Cancelled", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    local status = env.internals.statusOf
    local services = env.internals.state.services
    eq((status(services[1])), "On time")
    eq((status(services[2])), "15:48", "41 past plus seven minutes late")
    eq((status(services[3])), "Cancelled")
    H.screenHas(env.frame, "Cancelled")
  end)

  it("takes the platform away from a cancelled service", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    local row = env.frame:contains("Cardiff Central") and
                select(2, env.frame:contains("Cardiff Central"))
    H.contains(env.frame:row(row), "Cancelled")
    H.falsy(env.frame:row(row):find(" 10 "), "no platform against a cancelled train")
  end)

  it("wraps around midnight rather than emptying the board", function()
    local env = newEnv({ time = 23.9, files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    eq(#env.internals.state.services, 3)
    H.screenHas(env.frame, "London Euston")
  end)

  it("builds the arrivals board from the origins", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "arrivals")
    H.screenHas(env.frame, "Arrivals")
    H.screenHas(env.frame, "Origin")
    H.screenHas(env.frame, "Wolverhampton")
  end)

  it("ignores a rail.cfg that does not parse, and says why", function()
    local env = newEnv({ files = { ["rail.cfg"] = "return { station = " } })
    H.runOk(env, SCRIPT)
    H.contains(env.printed(), "rail.cfg")
    H.screenHas(env.frame, "Departures")
  end)
end)

describe("rail: reading Create stations", function()
  local function stationEnv(extra)
    local opts = {
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
        ["create:track_station_1"] = {
          name = "Create Central Platform 5", enroute = true, train = "1M14",
        },
      },
    }
    for key, value in pairs(extra or {}) do opts[key] = value end
    return newEnv(opts)
  end

  it("pulls the calling points out of a Create schedule", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "live")
    local service = env.internals.state.services[1]
    eq(service.dest, "London Euston")
    eq(table.concat(service.calls, "|"), "Coventry|Rugby|London Euston")
    eq(service.platform, "3")
    eq(service.train, "1A23")
  end)

  it("stops the calling list when the schedule comes back here", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    local calls = env.internals.onwardCalls(
      { "A", "Create Central *", "B", "C", "Create Central *", "D" },
      "Create Central Platform 3")
    eq(table.concat(calls, "|"), "B|C")
  end)

  it("matches the * filters Create writes into schedules", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    local matches = env.internals.stopMatches
    H.truthy(matches("Create Central *", "Create Central Platform 3"))
    H.truthy(matches("Rugby", "Rugby"))
    H.falsy(matches("Rugby", "Rugby Parkway"))
  end)

  it("reads the origin off the far end of a cyclic schedule", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.previousCall(
      { "Create Central *", "Coventry", "Rugby", "London Euston" },
      "Create Central Platform 3"), "London Euston")
  end)

  it("numbers the platform from the station name", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    local platformOf = env.internals.platformOf
    eq(platformOf({ name = "New Street Platform 12", peripheral = "x" }), "12")
    eq(platformOf({ name = "Somewhere", peripheral = "create:track_station_4" }), "4")
  end)

  it("only advertises a platform once it knows what stops there", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    -- platform 5 has a train on the way but has never shown us a schedule
    eq(#env.internals.state.services, 1)
  end)

  it("remembers what a platform serves once a train has stood there", function()
    local env = stationEnv({
      events = { function(inner)
        local station = inner.stations["create:track_station_0"]
        station.present, station.imminent = false, true
        inner.pushNext({ "timer", 1 })
      end },
    })
    H.runOk(env, SCRIPT)
    local service = env.internals.state.services[1]
    eq(service.dest, "London Euston", "the calling pattern outlives the train")
    H.truthy(service.imminent)
    H.screenHas(env.frame, "London Euston")
  end)

  it("tracks where each train was last seen", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    local where = env.internals.state.trains["1A23"]
    eq(where.at, "Create Central Platform 3")
    H.truthy(where.standing)
  end)

  it("keeps the booked times and takes the live status", function()
    local env = stationEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "timetable")
    local service = env.internals.state.services[1]
    eq(service.depart, 15 * 60 + 26, "the booked time wins")
    eq(service.train, "1A23", "the live train is picked up")
    H.truthy(service.present)
  end)
end)

describe("rail: the platform board", function()
  it("leads on one train with its calling points", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "platform")
    H.screenHas(env.frame, "1st")
    H.screenHas(env.frame, "Calling at:")
    H.screenHas(env.frame, "2nd")
  end)

  it("filters to the platform it was started with", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "platform", "5")
    eq(env.internals.config.platform, "5")
    H.screenHas(env.frame, "Platform 5")
    H.screenHas(env.frame, "Manchester Piccadilly")
    H.screenLacks(env.frame, "London Euston")
  end)

  it("warns when a train is coming into the platform", function()
    local env = newEnv({
      files = cfg(TIMETABLE),
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
      },
      events = { function(inner)
        local station = inner.stations["create:track_station_0"]
        station.present, station.imminent = false, true
        inner.pushNext({ "timer", 1 })
      end },
    })
    H.runOk(env, SCRIPT, "platform", "3")
    H.screenHas(env.frame, "Approaching")
  end)
end)

describe("rail: the small displays", function()
  it("fits a single line of dot matrix", function()
    local env = newEnv({ width = 40, height = 1, files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "summary")
    H.screenHas(env.frame, "London Euston")
  end)

  it("uses a second and third row when it has them", function()
    local env = newEnv({ width = 50, height = 3, files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "summary")
    H.screenHas(env.frame, "15:26")
    H.screenHas(env.frame, "Calling at:")
  end)

  it("falls back to the small layout on a tiny screen", function()
    local env = newEnv({ width = 30, height = 2, files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "departures")
    H.screenHas(env.frame, "London")
  end)
end)

describe("rail: onboard displays", function()
  local ONBOARD = [[
  station = "Create Central",
  train = "1A23",
  route = { "Create Central", "Coventry", "Rugby", "London Euston" },
]]

  it("names the train's destination and the next station", function()
    local env = newEnv({ files = cfg(ONBOARD) })
    H.runOk(env, SCRIPT, "onboard")
    H.screenHas(env.frame, "This train is for")
    H.screenHas(env.frame, "LONDON EUSTON")
  end)

  it("follows the train reported by the stations", function()
    local env = newEnv({
      files = cfg(ONBOARD),
      stations = {
        ["create:track_station_9"] = {
          name = "Coventry", present = true, train = "1A23",
          schedule = eustonSchedule(),
        },
      },
    })
    H.runOk(env, SCRIPT, "onboard")
    local trip = env.internals.journey()
    eq(trip.index, 2, "at Coventry, the second stop")
    eq(trip.next, "Coventry")
    H.truthy(trip.standing)
  end)

  it("draws the route as a line of stops", function()
    local env = newEnv({ files = cfg(ONBOARD), height = 22 })
    H.runOk(env, SCRIPT, "route")
    H.screenHas(env.frame, "Create Central")
    H.screenHas(env.frame, "Coventry")
    H.screenHas(env.frame, "Rugby")
    H.screenHas(env.frame, "London Euston")
    H.screenHas(env.frame, "this stop")
  end)
end)

describe("rail: the concourse clock", function()
  it("draws the time in big digits over the next departures", function()
    local env = newEnv({ width = 70, height = 24, files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "concourse")
    H.screenHas(env.frame, "Welcome to Create Central")
    H.screenHas(env.frame, "London Euston")
    -- the digits are painted as blocks of background, not characters
    local painted = 0
    for y = 1, env.frame.h do
      for x = 1, env.frame.w do
        if env.frame.ch[y][x] == " " and env.frame.bg[y][x] ~= "f" then
          painted = painted + 1
        end
      end
    end
    H.truthy(painted > 60, "expected big digits, painted " .. painted .. " cells")
  end)
end)

describe("rail: Create displays and rednet", function()
  it("writes the next departure onto a display source", function()
    local env = newEnv({
      files = cfg(TIMETABLE),
      sources = { ["create_source_0"] = { width = 30, height = 3 } },
    })
    H.runOk(env, SCRIPT, "flap")
    local text = env.sourceText("create_source_0")
    H.contains(text, "15:26")
    H.contains(text, "LONDON EUSTON")
    for line in text:gmatch("[^\n]+") do
      H.truthy(#line <= 30, "line overflows the display: " .. line)
    end
  end)

  it("shortens itself for a nixie tube", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT)
    local lines = env.internals.flapLines(8, 1)
    eq(#lines, 1)
    eq(lines[1], "15:26")
  end)

  it("broadcasts what it can see when it runs as a hub", function()
    local env = newEnv({
      modem = "modem_0",
      files = cfg(TIMETABLE),
      events = { { "timer", 1 } },
    })
    H.runOk(env, SCRIPT, "hub")
    eq(#env.rednetSent, 1)
    eq(env.rednetSent[1].protocol, "rail")
    eq(#env.rednetSent[1].message.services, 3)
    eq(env.rednetSent[1].message.station, "Create Central")
  end)

  it("takes a hub broadcast in place of its own scan", function()
    local env = newEnv({
      modem = "modem_0",
      events = { { "rednet_message", 7, {
        station = "Create Central",
        services = { {
          depart = 15 * 60 + 33, platform = "9", dest = "Holyhead",
          calls = { "Chester", "Holyhead" },
        } },
      }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "hub")
    H.screenHas(env.frame, "Holyhead")
  end)
end)

describe("rail: odds and ends", function()
  it("scrolls a line of text that is too long to fit", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local marquee = env.internals.marquee
    eq(marquee("short", 20, 3), "short", "short text is left alone")
    eq(#marquee("a much longer message than the width", 10, 0), 10)
    H.truthy(marquee("abcdefghijklmno", 5, 0) ~= marquee("abcdefghijklmno", 5, 2))
  end)

  it("paints 2x3 pixel art with the drawing glyphs", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local canvas = env.internals.canvas
    local white, black = env.colors.white, env.colors.black

    canvas:sprite(1, 1, { "#.", "..", ".." }, white, black)
    eq(canvas.ch[1][1]:byte(), 129, "top left pixel only")
    eq(canvas.fg[1][1], "0")
    eq(canvas.bg[1][1], "f")

    -- the glyphs stop at five pixels, so a lit bottom right inverts the cell
    canvas:sprite(1, 1, { "#.", ".#", "##" }, white, black)
    eq(canvas.ch[1][1]:byte(), 134)
    eq(canvas.fg[1][1], "f", "colours swap when the mask is inverted")
    eq(canvas.bg[1][1], "0")
  end)

  it("reads and writes clock times", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.parseTime("15:26"), 926)
    eq(env.internals.parseTime("nonsense"), nil)
    eq(env.internals.hhmm(926), "15:26")
    eq(env.internals.hhmm(1440), "00:00")
    eq(env.internals.nowMinutes(), 900)
  end)

  it("writes the calling points the way a guard would say them", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local join = env.internals.joinCalls
    eq(join({ "Rugby" }), "Rugby only")
    eq(join({ "Coventry", "Rugby" }), "Coventry and Rugby")
    eq(join({ "A", "B", "C" }), "A, B and C")
  end)

  it("numbers the trains after the first one", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.ordinal(1), "1st")
    eq(env.internals.ordinal(2), "2nd")
    eq(env.internals.ordinal(3), "3rd")
    eq(env.internals.ordinal(4), "4th")
  end)

  it("writes a starter config that parses", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "setup")
    local written = env.files["rail.cfg"]
    H.truthy(written, "rail.cfg was not written")
    local chunk = load(written, "rail.cfg", "t", {})
    H.truthy(chunk, "the template does not parse")
    eq(type(chunk()), "table")
    H.contains(env.printed(), "wrote rail.cfg")
  end)

  it("will not overwrite a config that is already there", function()
    local env = newEnv({ files = { ["rail.cfg"] = "return {}" } })
    H.runOk(env, SCRIPT, "setup")
    eq(env.files["rail.cfg"], "return {}")
    H.contains(env.printed(), "already exists")
  end)

  it("lists its modes when asked for help", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "help")
    H.contains(env.printed(), "departures")
    H.contains(env.printed(), "concourse")
  end)

  it("boots into the mode named in the config", function()
    local env = newEnv({ files = cfg('  mode = "concourse",') })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "Welcome to Create Central")
  end)

  it("lets an argument beat the mode in the config", function()
    local env = newEnv({ files = cfg('  mode = "concourse",') })
    H.runOk(env, SCRIPT, "arrivals")
    H.screenHas(env.frame, "Arrivals")
  end)

  it("accepts the short names for the modes", function()
    local env = newEnv({ files = cfg(TIMETABLE) })
    H.runOk(env, SCRIPT, "arr")
    H.screenHas(env.frame, "Arrivals")
  end)

  it("redraws after the monitor is resized", function()
    local env = newEnv({
      files = cfg(TIMETABLE),
      events = { { "term_resize" }, { "monitor_resize", "monitor_0" } },
    })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "Departures")
  end)

  it("only blits the rows that changed", function()
    local env = newEnv({
      files = cfg(TIMETABLE),
      events = { { "timer", 2 }, { "timer", 2 }, { "timer", 2 } },
    })
    H.runOk(env, SCRIPT)
    H.truthy(env.screen.blits < 4 * env.internals.canvas.h,
             "the ticker should not repaint the whole board")
  end)
end)
