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
    H.truthy(matches("Create Central *", "Create Central"),
             "a wildcard for every platform covers the bare station too")
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
    -- no platform in the name is platform 1; the number on the end of the
    -- peripheral is Create's load order and means nothing to a passenger
    eq(platformOf({ name = "Somewhere", peripheral = "create:track_station_4" }), "1")
  end)

  it("fills in every platform from one schedule read anywhere", function()
    local env = stationEnv()
    H.runOk(env, SCRIPT)
    -- platform 5 has never had a train stand at it, but the schedule read at
    -- platform 3 names this station, so we know what calls at 5 as well
    eq(#env.internals.state.services, 2)
    local platforms = {}
    for _, service in ipairs(env.internals.state.services) do
      platforms[service.platform] = service.dest
    end
    eq(platforms["3"], "London Euston")
    eq(platforms["5"], "London Euston")
  end)

  it("keeps two platforms apart even when both are platform 1", function()
    local env = newEnv({
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central North", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
        ["create:track_station_1"] = { name = "Create Central South", enroute = true },
      },
    })
    H.runOk(env, SCRIPT)
    -- both come out as platform 1, but they are two different station blocks
    eq(#env.internals.state.services, 2)
    H.truthy(env.internals.state.known["create:track_station_0"])
    H.truthy(env.internals.state.known["create:track_station_1"])
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

  it("keeps the pattern on the board after the train has left entirely", function()
    local env = stationEnv({
      events = { function(inner)
        -- the train has gone: not present, not imminent, not even signalled
        local station = inner.stations["create:track_station_0"]
        station.present, station.imminent, station.enroute = false, false, false
        inner.pushNext({ "timer", 1 })
      end },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "live", "an empty platform is not a demo")
    local service = env.internals.state.services[1]
    eq(service.dest, "London Euston")
    H.truthy(service.expected, "with nothing in sight it is Expected, not On time")
    H.screenHas(env.frame, "London Euston")
    H.screenHas(env.frame, "Expected")
  end)

  it("never invents departures at a station it can actually see", function()
    local env = newEnv({
      stations = {
        ["create:track_station_0"] = { name = "Create Central Platform 3" },
      },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "none")
    eq(#env.internals.state.services, 0)
    -- "Liverpool Lime Street" only ever appears in the demo timetable
    H.screenLacks(env.frame, "Liverpool Lime Street")
  end)

  it("writes what it learned to disk and reads it back on the next boot", function()
    local first = stationEnv()
    H.runOk(first, SCRIPT)
    local saved = first.files["rail.dat"]
    H.truthy(saved, "rail.dat was not written")

    -- a fresh computer, nothing standing at the platform, but it remembers
    local second = newEnv({
      files = { ["rail.dat"] = saved },
      stations = {
        ["create:track_station_0"] = { name = "Create Central Platform 3" },
      },
    })
    H.runOk(second, SCRIPT)
    eq(second.internals.state.known["create:track_station_0"].dest, "London Euston")
    H.contains(second.printed(), "remembered")
  end)

  it("measures how often a platform turns round instead of guessing", function()
    local env
    -- `r` forces a rescan; the scan timer gets a fresh id every time it fires,
    -- so a pushed `timer 1` only ever lands once
    local function rescan(inner) inner.pushNext({ "key", inner.keys.r }) end
    env = stationEnv({
      events = { function(inner)
        local station = inner.stations["create:track_station_0"]
        station.present = false
        inner.setTime(15.5)              -- half an in-game hour later
        rescan(inner)
      end, function(inner)
        local station = inner.stations["create:track_station_0"]
        station.present, station.train = true, "1A25"
        rescan(inner)
      end },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.known["create:track_station_0"].every, 30,
       "30 in-game minutes between trains")
  end)

  it("times a hop by watching a train leave one station and reach the next", function()
    -- one computer wired to both ends, which is what a hub at a junction sees
    local env = newEnv({
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
        ["create:track_station_1"] = { name = "Coventry Platform 1" },
      },
      events = { function(inner)
        local station = inner.stations["create:track_station_0"]
        -- a station with no train reports no train name, which is how the
        -- departure is spotted at all
        station.present, station.train = false, nil
        inner.pushNext({ "key", inner.keys.r })
      end, function(inner)
        inner.setTime(15.25)                                       -- 15 mins on
        local far = inner.stations["create:track_station_1"]
        far.present, far.train = true, "1A23"                      -- arrives
        inner.pushNext({ "key", inner.keys.r })
      end },
    })
    H.runOk(env, SCRIPT)
    local key = env.internals.legKey("Create Central Platform 3", "Coventry Platform 1")
    local leg = env.internals.state.legs[key]
    H.truthy(leg, "the hop was never timed")
    eq(leg.mins, 15, "15 in-game minutes from one to the other")
    eq(leg.n, 1)
  end)

  it("predicts an arrival from a timed hop rather than a guess", function()
    local env = newEnv({
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", enroute = true, train = "1A23",
        },
      },
      files = { ["rail.dat"] = [[return {
        known = { ["create:track_station_0"] = {
                    dest = "London Euston", origin = "Coventry", platform = "3",
                    seen = 890, train = "1A23", calls = { "London Euston" } } },
        legs  = { ["Coventry\0Create Central Platform 3"] = { mins = 12, n = 4 } },
        sightings = { ["1A23"] = { at = "Coventry", t = 894, standing = false,
                                   leftAt = 894 } },
      }]] },
    })
    H.runOk(env, SCRIPT)
    local service = env.internals.state.services[1]
    -- left Coventry at 14:54, and that hop has been timed at 12 minutes
    eq(service.arrive, 894 + 12, "arrival comes off the measured hop")
    H.truthy(not service.estimate, "a timed hop is not an estimate")
  end)

  it("holds a departure time still instead of sliding it with the clock", function()
    local env = stationEnv({
      events = { function(inner)
        inner.setTime(15.1)                    -- six in-game minutes later
        inner.pushNext({ "key", inner.keys.r })
      end },
    })
    H.runOk(env, SCRIPT)
    local service = env.internals.state.services[1]
    -- the train arrived at 15:00 and has not moved, so it is still due to
    -- leave 10 real seconds (12 in-game minutes) after it got there
    eq(service.arrive, 900, "arrival is when it actually arrived")
    eq(service.depart, 900 + 12, "and departure does not creep with the clock")
  end)

  it("learns hop times from another station over rednet", function()
    local env = newEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 9, {
        station = "Somewhere Else",
        legs = { ["Rugby\0Coventry"] = { mins = 21, n = 3 } },
        sightings = { ["1M14"] = { at = "Rugby", t = 880, leftAt = 880 } },
      }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    -- the services were for another station and rightly ignored...
    H.truthy(env.internals.state.source ~= "hub")
    -- ...but the timings are worth having whoever sent them
    eq(env.internals.state.legs["Rugby\0Coventry"].mins, 21)
    eq(env.internals.state.sightings["1M14"].at, "Rugby")
  end)

  it("falls back to the configured leg time until a hop has been timed", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local mins, samples = env.internals.legMinutes("Nowhere", "Elsewhere")
    eq(samples, 0)
    eq(mins, env.internals.minutesFor(45), "45 real seconds in in-game minutes")
  end)

  it("reports what it has timed, and says when it is still settling", function()
    local env = newEnv({
      files = { ["rail.dat"] = [[return {
        known = {},
        legs = { ["Coventry\0Rugby"] = { mins = 12, n = 1 },
                 ["Rugby\0London Euston"] = { mins = 30, n = 5 } },
        sightings = { ["1A23"] = { at = "Rugby", t = 900, standing = true } },
      }]] },
    })
    H.runOk(env, SCRIPT, "times")
    local printed = env.printed()
    H.contains(printed, "2 hop(s) timed")
    H.contains(printed, "Coventry -> Rugby")
    H.contains(printed, "still settling")       -- only one trip so far
    H.contains(printed, "Rugby -> London Euston")
    H.contains(printed, "1A23  at Rugby")
  end)

  it("says how to teach it when it has timed nothing", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "times")
    H.contains(env.printed(), "no hops timed yet")
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

  it("opens every modem, not just the first one it finds", function()
    local env = newEnv({
      modem = { "modem_0", "ender_modem_1" },
      files = cfg(TIMETABLE),
      events = { { "timer", 1 } },
    })
    H.runOk(env, SCRIPT, "hub")
    eq(env.internals.link.modems, 2, "a hub needs the cable and the radio")
    eq(#env.rednetSent, 1)
  end)

  it("checks the radio and reports what it hears", function()
    local env = newEnv({
      modem = { "modem_0", "ender_modem_1" },
      events = {
        { "rednet_message", 12, {
          station = "Create Central", services = { {} },
        }, "rail" },
        { "rednet_message", 13, {
          station = "Somewhere Else", services = {},
          legs = { ["A B"] = { mins = 9, n = 2 } },
        }, "rail" },
        { "timer", 1 },
      },
    })
    H.runOk(env, SCRIPT, "link")
    local printed = env.printed()
    H.contains(printed, "ender_modem_1  wireless")
    H.contains(printed, "modem_0  wired")
    H.contains(printed, "rednet open on 2 modem(s)")
    H.contains(printed, "computer 12: Create Central")
    H.contains(printed, "1 services")
    H.contains(printed, "computer 13: Somewhere Else")
    H.contains(printed, "1 hop times")
    H.contains(printed, "its departures are not ours")
  end)

  it("works out its own departures from a schedule another computer shared", function()
    local env = newEnv({
      modem = "ender_modem_0",
      -- this station has never had a train stand at it, so on its own it has
      -- nothing to say; the schedule arrives over the radio
      stations = {
        ["create:track_station_0"] = { name = "Create Central Platform 2" },
      },
      events = { { "rednet_message", 9, {
        station = "Somewhere Else",
        patterns = { ["1A23"] = { train = "1A23", at = 900, stops = {
          "Create Central *", "Coventry", "Rugby", "London Euston",
        } } },
      }, "rail" }, function(inner)
        inner.pushNext({ "key", inner.keys.r })   -- rescan with what arrived
      end },
    })
    H.runOk(env, SCRIPT)
    local service = env.internals.state.services[1]
    H.truthy(service, "no departure was worked out from the shared schedule")
    eq(service.dest, "London Euston")
    eq(service.platform, "2")
    H.screenHas(env.frame, "London Euston")
  end)

  it("gossips schedules and timings from every mode, not just a hub", function()
    local env = newEnv({
      modem = "ender_modem_0",
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
      },
      events = { { "timer", 1 } },
    })
    H.runOk(env, SCRIPT)               -- a plain departures board, not a hub
    eq(#env.rednetSent, 1)
    local sent = env.rednetSent[1].message
    H.truthy(sent.patterns["1A23"], "the schedule was not passed on")
    eq(sent.patterns["1A23"].stops[4], "London Euston")
    H.falsy(sent.services, "only a hub claims to be the authority on departures")
  end)

  it("registers the other rail computers it hears", function()
    local env = newEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 21, { station = "Rugby" }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.peers[21].station, "Rugby")
  end)

  it("says so when there is no modem to check", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "link")
    H.contains(env.printed(), "no modem attached")
  end)

  it("says so when the radio is quiet", function()
    local env = newEnv({ modem = "ender_modem_0", events = { { "timer", 1 } } })
    H.runOk(env, SCRIPT, "link")
    H.contains(env.printed(), "nothing heard")
  end)

  it("believes a hub that reports nothing over its own demo timetable", function()
    local env = newEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 7, {
        station = "Create Central", services = {},
      }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.source, "hub")
    H.screenHas(env.frame, "no departures")
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

  it("lists the stations it can see, and what stops there", function()
    local env = newEnv({
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
      },
    })
    H.runOk(env, SCRIPT, "stations")
    local printed = env.printed()
    H.contains(printed, "create:track_station_0")
    H.contains(printed, "Create Central Platform 3")
    H.contains(printed, "platform 3")
    H.contains(printed, "[ours]")
    H.contains(printed, "train standing")
    H.contains(printed, "Coventry, Rugby, London Euston")
  end)

  it("says which way to look when no station is wired up", function()
    local env = newEnv()
    H.runOk(env, SCRIPT, "stations")
    H.contains(env.printed(), "no create train stations")
    H.contains(env.printed(), "modem")
  end)

  it("points at the station name when nothing matches the config", function()
    local env = newEnv({
      files = cfg('  station = "Somewhere Else",'),
      stations = {
        ["create:track_station_0"] = { name = "Create Central Platform 3" },
      },
    })
    H.runOk(env, SCRIPT, "stations")
    H.contains(env.printed(), "[not ours]")
    H.contains(env.printed(), "Somewhere Else")
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

describe("rail: several screens, stats and updates", function()
  local function boardEnv(extra)
    local opts = {
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
      },
    }
    for key, value in pairs(extra or {}) do opts[key] = value end
    return newEnv(opts)
  end

  it("gives each monitor its own mode, in peripheral-name order", function()
    local env = boardEnv({ monitors = { "monitor_0", "monitor_1" } })
    H.runOk(env, SCRIPT, "departures", "arrivals")
    H.screenHas(env.frame, "Departures")
    H.screenHas(env.frames["monitor_1"], "Arrivals")
  end)

  it("repeats the last mode when there are more screens than modes", function()
    local env = boardEnv({ monitors = { "monitor_0", "monitor_1", "monitor_2" } })
    H.runOk(env, SCRIPT, "departures")
    H.screenHas(env.frame, "Departures")
    H.screenHas(env.frames["monitor_1"], "Departures")
    H.screenHas(env.frames["monitor_2"], "Departures")
  end)

  it("lists every screen and its job at startup", function()
    local env = boardEnv({ monitors = { "monitor_0", "monitor_1" } })
    H.runOk(env, SCRIPT, "departures", "platform")
    local printed = env.printed()
    H.contains(printed, "display: monitor_0")
    H.contains(printed, "display: monitor_1")
    H.contains(printed, "platform")
  end)

  it("draws a stats board", function()
    local env = boardEnv({ modem = "ender_modem_0" })
    H.runOk(env, SCRIPT, "stats")
    H.screenHas(env.frame, "rail")
    H.screenHas(env.frame, "source")
    H.screenHas(env.frame, "hops timed")
    H.screenHas(env.frame, "master")
  end)

  it("makes a hub the master and says so", function()
    local env = boardEnv({ modem = "ender_modem_0", events = { { "timer", 1 } } })
    H.runOk(env, SCRIPT, "hub")
    H.contains(env.printed(), "master: this computer is the mesh database")
    eq(env.rednetSent[1].message.master, true)
  end)

  it("does not claim to be master on an ordinary board", function()
    local env = boardEnv({ modem = "ender_modem_0", events = { { "timer", 1 } } })
    H.runOk(env, SCRIPT)
    H.falsy(env.rednetSent[1].message.master)
  end)

  it("only the master asks the update server", function()
    local board = boardEnv({ modem = "ender_modem_0", events = { { "timer", 1 } } })
    H.runOk(board, SCRIPT)
    eq(#board.httpRequests, 0, "a board must never poll github")

    local hub = boardEnv({ modem = "ender_modem_0", events = { { "timer", 1 } } })
    H.runOk(hub, SCRIPT, "hub")
    H.truthy(#hub.httpRequests > 0, "the master should have checked")
    H.contains(hub.httpRequests[1], "manifest.txt")
  end)

  it("warns when a second master turns up", function()
    local env = boardEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 4, { station = "Elsewhere", master = true },
                   "rail" } },
    })
    H.runOk(env, SCRIPT, "hub")
    H.contains(env.printed(), "another master is running on computer 4")
  end)

  it("installs a script pushed over the mesh and reboots", function()
    local env = boardEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 4, {
        station = "Create Central", update = "9.9.9",
        source = 'local VERSION = "9.9.9"\n' .. string.rep("-- new\n", 40),
      }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    H.contains(env.printed(), "mesh pushed rail 9.9.9")
    H.truthy(env.rebooted, "it should have restarted onto the new script")
  end)

  it("refuses a pushed script that does not look like rail", function()
    local env = boardEnv({
      modem = "ender_modem_0",
      events = { { "rednet_message", 4, {
        station = "Create Central", update = "9.9.9", source = "rm -rf",
      }, "rail" } },
    })
    H.runOk(env, SCRIPT)
    H.falsy(env.rebooted, "a short or unrecognisable payload must be ignored")
  end)
end)

-- A whole railway, run for more than a Minecraft day.  Four stations with
-- nothing in common in their names, one train going round, and the clock left
-- to roll past midnight -- which is every twenty real minutes, and is where
-- timestamps that are "minutes past midnight" quietly start going backwards.
describe("rail: a railway left running for a day and a half", function()
  local LINE  = { "Aberdare", "Barmouth", "Cwmbran", "Dolgellau" }
  local DWELL, LEG = 12, 48             -- in-game minutes
  local CYCLE = #LINE * (DWELL + LEG)   -- 240: one full round trip
  local RUN, STEP = 2160, 6             -- 36 in-game hours, checked every 6

  local function lineSchedule()
    local entries = {}
    for i, name in ipairs(LINE) do entries[i] = stop(name) end
    return { cyclic = true, entries = entries }
  end

  -- where the train is at a given point in the cycle: standing at a station,
  -- or somewhere between two of them
  local function whereIs(elapsed)
    local into = elapsed % CYCLE
    local slot = math.floor(into / (DWELL + LEG)) + 1
    local within = into % (DWELL + LEG)
    if within < DWELL then return slot, "standing" end
    -- imminent for the last few minutes of the approach, as Create signals it
    local nextSlot = slot % #LINE + 1
    if within > (DWELL + LEG) - 6 then return nextSlot, "imminent" end
    return nextSlot, "away"
  end

  local function simulate(assertions)
    local env
    local seen = {}
    local events = {}
    for step = 1, RUN / STEP do
      events[step] = function(inner)
        -- record what the board was showing before moving the world on
        -- internals only lands on env after the run, so reach into the
        -- sandbox for the live state while the script is still going
        local live = inner.globals.__VAULT_TEST.internals
        if step > 1 and live then
          local state = live.state
          seen[#seen + 1] = {
            at       = step * STEP,
            source   = state.source,
            services = #state.services,
            service  = state.services[1],
            now      = inner.worldMinutes(),
          }
        end
        inner.advance(STEP)
        local elapsed = step * STEP
        local slot, how = whereIs(elapsed)
        for i, name in ipairs(LINE) do
          local station = inner.stations["create:track_station_" .. (i - 1)]
          station.present  = (i == slot and how == "standing")
          station.imminent = (i == slot and how == "imminent")
          station.enroute  = (i == slot and how == "away")
          station.train    = (i == slot and how == "standing") and "1A23" or nil
        end
        inner.pushNext({ "key", inner.keys.r })
      end
    end

    local stations = {}
    for i, name in ipairs(LINE) do
      stations["create:track_station_" .. (i - 1)] = {
        name = name, schedule = lineSchedule(),
      }
    end
    -- start with the train standing at Aberdare
    stations["create:track_station_0"].present = true
    stations["create:track_station_0"].train = "1A23"

    env = newEnv({
      time = 6.0, stations = stations, events = events,
      files = cfg('  station = "Aberdare",\n  code = "ABD",'),
    })
    H.runOk(env, SCRIPT)
    return env, seen
  end

  it("never loses the calling points, and never falls back to the demo", function()
    local env, seen = simulate()
    H.truthy(#seen > 300, "the simulation did not run: " .. #seen .. " samples")

    local hours = (seen[#seen].now - seen[1].now) / 60
    H.truthy(hours > 24, ("only %.1f in-game hours elapsed"):format(hours))

    for _, sample in ipairs(seen) do
      local at = ("at +%d min (source %s)"):format(sample.at, sample.source)
      eq(sample.source, "live", "dropped off live " .. at)
      H.truthy(sample.service, "no service on the board " .. at)
      eq(sample.service.dest, "Dolgellau", "wrong destination " .. at)
      eq(table.concat(sample.service.calls, "|"), "Barmouth|Cwmbran|Dolgellau",
         "calling points changed " .. at)
    end
  end)

  it("keeps predicted times sane the whole way through", function()
    local _, seen = simulate()
    for _, sample in ipairs(seen) do
      local service, now = sample.service, sample.now
      local at = ("at +%d min"):format(sample.at)
      -- a departure is never in the distant past, and never further off than
      -- one round trip; either would mean the arithmetic had drifted
      H.truthy(service.depart > now - 60,
               ("departure %d minutes in the past %s"):format(now - service.depart, at))
      H.truthy(service.depart < now + CYCLE + 60,
               ("departure %d minutes away %s"):format(service.depart - now, at))
      H.truthy(service.arrive <= service.depart + 1, "arrival after departure " .. at)
    end
  end)

  it("converges on the real hop times and stays there", function()
    local env = simulate()
    local legs = env.internals.state.legs
    for i = 1, #LINE do
      local from, to = LINE[i], LINE[i % #LINE + 1]
      local leg = legs[env.internals.legKey(from, to)]
      H.truthy(leg, ("never timed %s -> %s"):format(from, to))
      H.truthy(leg.n >= 5, ("only %d samples for %s -> %s"):format(leg.n, from, to))
      -- the simulated hop is LEG minutes; allow a step of sampling slop
      H.truthy(math.abs(leg.mins - LEG) <= STEP,
               ("%s -> %s settled on %.1f, not %d"):format(from, to, leg.mins, LEG))
    end
  end)

  it("hands a day and a half of learning to another computer intact", function()
    local env = simulate()
    local learned = env.internals.state

    -- exactly what link.publish would put on the wire
    local payload = {
      station   = "Aberdare",
      sightings = learned.sightings,
      legs      = learned.legs,
      patterns  = learned.patterns,
    }

    -- a board at Aberdare with no station wired to it at all
    local board = newEnv({
      time = 6.0, day = 1,
      modem = "ender_modem_0",
      files = cfg('  station = "Aberdare",'),
      events = { { "rednet_message", 7, payload, "rail" }, function(inner)
        inner.pushNext({ "key", inner.keys.r })
      end },
    })
    H.runOk(board, SCRIPT)

    local mirrored = board.internals.state
    for key, leg in pairs(learned.legs) do
      H.truthy(mirrored.legs[key], "hop time did not cross the mesh: " .. key)
      eq(mirrored.legs[key].n, leg.n, "sample count disagrees for " .. key)
    end
    H.truthy(mirrored.patterns["1A23"], "the schedule did not cross the mesh")
  end)
end)

describe("rail: the master console", function()
  local function hubEnv(extra)
    local opts = {
      width = 56, height = 20, modem = "ender_modem_0",
      stations = {
        ["create:track_station_0"] = {
          name = "Create Central Platform 3", present = true,
          train = "1A23", schedule = eustonSchedule(),
        },
      },
    }
    for key, value in pairs(extra or {}) do opts[key] = value end
    return newEnv(opts)
  end

  it("puts an engineering console on a hub's monitor", function()
    local env = hubEnv()
    H.runOk(env, SCRIPT, "hub")
    H.screenHas(env.frame, "MASTER")
    H.screenHas(env.frame, "source")
    H.screenHas(env.frame, "hop times")
    H.screenHas(env.frame, "[ Resync ]")
    H.screenHas(env.frame, "[ Updates ]")
    H.screenHas(env.frame, "[ Rescan ]")
    H.screenHas(env.frame, "[ Forget ]")
  end)

  it("does not turn an ordinary board into a console", function()
    local env = hubEnv()
    H.runOk(env, SCRIPT)
    H.screenLacks(env.frame, "MASTER")
    H.screenHas(env.frame, "Departures")
  end)

  it("runs the button that was touched", function()
    local env = hubEnv({
      events = { function(inner)
        -- find Resync where it was actually drawn and press it
        local live = inner.globals.__VAULT_TEST.internals
        local button = live.state.buttons[1]
        inner.pushNext({ "monitor_touch", "monitor_0", button.x1 + 1, button.y })
      end },
    })
    H.runOk(env, SCRIPT, "hub")
    H.contains(env.printed(), "resync: asked the mesh to report in")
    local asked = false
    for _, sent in ipairs(env.rednetSent) do
      if sent.message.resync then asked = true end
    end
    H.truthy(asked, "resync was not broadcast")
  end)

  it("answers somebody else's resync with what it knows", function()
    local env = hubEnv({
      events = { { "rednet_message", 8, { station = "Elsewhere", resync = true },
                   "rail" } },
    })
    H.runOk(env, SCRIPT)
    local replied = false
    for _, sent in ipairs(env.rednetSent) do
      if sent.message.patterns and not sent.message.resync then replied = true end
    end
    H.truthy(replied, "a resync request went unanswered")
  end)

  it("forgets everything when told to, and starts learning again", function()
    local env = hubEnv({
      events = { function(inner)
        local live = inner.globals.__VAULT_TEST.internals
        H.truthy(next(live.state.known), "nothing was learned to forget")
        for _, button in ipairs(live.state.buttons) do
          if button.key == "forget" then
            inner.pushNext({ "monitor_touch", "monitor_0", button.x1, button.y })
          end
        end
      end },
    })
    H.runOk(env, SCRIPT, "hub")
    H.contains(env.printed(), "memory cleared")
  end)

  it("says why the update button did nothing when http is off", function()
    local env = hubEnv({
      noHttp = true,
      events = { function(inner)
        local live = inner.globals.__VAULT_TEST.internals
        for _, button in ipairs(live.state.buttons) do
          if button.key == "update" then
            inner.pushNext({ "monitor_touch", "monitor_0", button.x1, button.y })
          end
        end
      end },
    })
    H.runOk(env, SCRIPT, "hub")
    H.contains(env.printed(), "the http API is off")
  end)
end)
