-- Tests for vault_stock.lua, run against the CC mock in tests/cc_mock.lua
local mock = require("cc_mock")
local H = require("harness")
local describe, it, eq = H.describe, H.it, H.eq

local SCRIPT = (_G.ROOT or "") .. "vault_stock.lua"
local keys = mock.KEYS

local function item(name, count, display, maxCount)
  return { name = name, count = count, displayName = display, maxCount = maxCount }
end

-- a small but realistic network: three vaults, overlapping contents
local function sampleVaults()
  return {
    ["create:item_vault_0"] = {
      item("minecraft:iron_ingot", 64, "Iron Ingot"),
      item("minecraft:iron_ingot", 64, "Iron Ingot"),
      item("create:andesite_alloy", 32, "Andesite Alloy"),
    },
    ["create:item_vault_1"] = {
      item("minecraft:iron_ingot", 12, "Iron Ingot"),
      item("minecraft:cobblestone", 640, "Cobblestone"),
    },
    ["create:item_vault_2"] = {
      item("create:andesite_alloy", 8, "Andesite Alloy"),
    },
  }
end

local function newEnv(opts)
  opts = opts or {}
  opts.vaults = opts.vaults or sampleVaults()
  opts.extras = opts.extras or { modem_0 = "modem", drive_0 = "drive" }
  return mock.newEnv(opts)
end

describe("vault_stock: discovery and aggregation", function()
  it("only counts vault peripherals, ignoring modems and drives", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local found = env.internals.findVaults()
    eq(#found, 3, "vault count")
    eq(found[1], "create:item_vault_0")
  end)

  it("sums item counts across every vault", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local byId = env.internals.state.byId
    eq(byId["minecraft:iron_ingot"].count, 140)
    eq(byId["create:andesite_alloy"].count, 40)
    eq(byId["minecraft:cobblestone"].count, 640)
    eq(env.internals.state.total, 820, "grand total")
    eq(env.internals.state.types, 3, "unique types")
  end)

  it("records which vault each stack lives in", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    local iron = env.internals.state.byId["minecraft:iron_ingot"]
    eq(iron.vaults["create:item_vault_0"], 128)
    eq(iron.vaults["create:item_vault_1"], 12)
    eq(iron.vaults["create:item_vault_2"], nil)
  end)

  it("tracks slot usage against vault capacity", function()
    local env = newEnv({ sizes = { ["create:item_vault_0"] = 100 } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.used, 6, "occupied slots")
    eq(env.internals.state.slots, 100 + 27 + 27, "total slots")
  end)

  it("resolves display names through getItemDetail", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.state.byId["create:andesite_alloy"].label, "Andesite Alloy")
  end)

  it("falls back to a prettified id when the detail budget runs out", function()
    local vaults, expected = {}, {}
    local stacks = {}
    for i = 1, 60 do
      local id = "minecraft:test_item_" .. i
      stacks[i] = { name = id, count = i }
      expected[id] = true
    end
    vaults["create:item_vault_0"] = stacks
    local env = newEnv({ vaults = vaults })
    H.runOk(env, SCRIPT)
    -- detailBudget is 40, so the tail keeps the generated label
    eq(env.internals.state.byId["minecraft:test_item_60"].label, "Test Item 60")
    eq(env.internals.state.types, 60)
  end)

  it("survives a vault that stops responding", function()
    local env = newEnv({ broken = { ["create:item_vault_1"] = true } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.offline, 1)
    eq(env.internals.state.online, 2)
    eq(env.internals.state.byId["minecraft:cobblestone"], nil, "no data from the dead vault")
    H.screenHas(env.frame, "offline")
  end)

  it("reports an empty network instead of crashing", function()
    local env = mock.newEnv({ vaults = {}, extras = { modem_0 = "modem" } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.online, 0)
    H.screenHas(env.frame, "No vaults on the network")
  end)
end)

describe("vault_stock: formatting helpers", function()
  local env = newEnv()
  H.runOk(env, SCRIPT)
  local f = env.internals

  it("groups thousands with commas", function()
    eq(f.comma(0), "0")
    eq(f.comma(999), "999")
    eq(f.comma(1000), "1,000")
    eq(f.comma(1234567), "1,234,567")
  end)

  it("shortens large numbers", function()
    eq(f.short(999), "999")
    eq(f.short(9999), "9,999")
    eq(f.short(12500), "12.5K")
    eq(f.short(250000), "250K")
    eq(f.short(3400000), "3.4M")
  end)

  it("signs deltas", function()
    eq(f.signed(64), "+64")
    eq(f.signed(-64), "-64")
    eq(f.signed(0), "0")
  end)

  it("trims long labels with a marker", function()
    eq(f.trim("Andesite Alloy", 20), "Andesite Alloy")
    eq(f.trim("Andesite Alloy", 8), "Andesit.")
    eq(f.trim("Andesite Alloy", 0), "")
  end)

  it("prettifies item ids", function()
    eq(f.prettify("minecraft:iron_ingot"), "Iron Ingot")
    eq(f.prettify("create:andesite_alloy"), "Andesite Alloy")
    eq(f.prettify("mysterious"), "Mysterious")
  end)

  it("gives every mod a stable stripe colour", function()
    eq(f.tagColor("minecraft:iron_ingot"), f.tagColor("minecraft:dirt"))
    H.truthy(f.tagColor("create:cogwheel") ~= nil)
  end)
end)

describe("vault_stock: rendering", function()
  it("draws the header, totals and top item", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "VAULT NETWORK")
    H.screenHas(env.frame, "820", "grand total")
    H.screenHas(env.frame, "items")
    H.screenHas(env.frame, "vaults")
    H.screenHas(env.frame, "Cobblestone", "highest count sorts first")
    H.screenHas(env.frame, "STOCK")
    H.screenHas(env.frame, "MOVERS")
    H.screenHas(env.frame, "VAULTS")
    H.screenHas(env.frame, "PAGE 1/1")
  end)

  it("never blits outside the screen bounds", function()
    for _, size in ipairs({ { 18, 8 }, { 29, 12 }, { 51, 19 }, { 164, 81 } }) do
      local env = newEnv({ width = size[1], height = size[2] })
      local ok, err = env.run(SCRIPT)
      H.truthy(ok, "size " .. size[1] .. "x" .. size[2] .. ": " .. tostring(err))
      eq(#env.frame:row(1), size[1], "row width at " .. size[1] .. "x" .. size[2])
    end
  end)

  it("only repaints rows that changed", function()
    local env = newEnv({ events = { { "timer", 2 } } })  -- the 1s chrome tick
    H.runOk(env, SCRIPT)
    local blitsPerFullFrame = env.screen.h
    H.truthy(env.screen.blits < blitsPerFullFrame * 4,
      "expected dirty-row redraws, got " .. env.screen.blits .. " blits")
  end)

  it("uses a custom palette on advanced monitors", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.truthy(next(env.screen.palette) ~= nil, "palette should have been written")
  end)

  it("stays monochrome-safe on a basic monitor", function()
    local env = newEnv({ color = false })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "VAULT NETWORK")
    for y = 1, env.frame.h do
      for x = 1, env.frame.w do
        local bg = env.frame.bg[y][x]
        H.truthy(bg == "0" or bg == "7" or bg == "8" or bg == "f",
          "basic monitors only get greys, saw blit colour " .. bg)
      end
    end
  end)
end)

describe("vault_stock: interaction", function()
  local function tapAt(needle)
    return function(env)
      local _, y, x = env.screen:fgOf(needle)
      env.pushNext({ "monitor_touch", "monitor_0", x or 1, y or 1 })
    end
  end

  it("switches view when a tab is tapped", function()
    local env = newEnv({ events = { tapAt("VAULTS") } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.view, 3, "VAULTS view active")
    H.screenHas(env.frame, "Vault 0")
    H.screenHas(env.frame, "items")
  end)

  it("cycles the sort order when SORT is tapped", function()
    local env = newEnv({ events = { tapAt("SORT:") } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.sort, 2, "sort advanced to NAME")
    H.screenHas(env.frame, "SORT: NAME")
    -- alphabetical now: Andesite Alloy should be the first row
    local _, ironY = env.frame:fgOf("Iron Ingot")
    local _, andY = env.frame:fgOf("Andesite Alloy")
    H.truthy(andY < ironY, "Andesite Alloy should sort above Iron Ingot")
  end)

  it("opens a per-vault breakdown when an item is tapped", function()
    local env = newEnv({ events = { tapAt("Iron Ingot") } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.detail, "minecraft:iron_ingot")
    H.screenHas(env.frame, "SPREAD ACROSS 2 VAULTS")
    H.screenHas(env.frame, "minecraft:iron_ingot")
    H.screenHas(env.frame, "(2 stacks)", "140 iron at 64 per stack")
  end)

  it("closes the breakdown on the next tap", function()
    local env = newEnv({
      events = { tapAt("Iron Ingot"), { "monitor_touch", "monitor_0", 5, 10 } },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.detail, nil)
    H.screenLacks(env.frame, "SPREAD ACROSS")
  end)

  it("pages through a long list", function()
    local stacks = {}
    for i = 1, 400 do
      stacks[i] = item("minecraft:item_" .. i, i)
    end
    local env = mock.newEnv({
      vaults = { ["create:item_vault_0"] = stacks },
      width = 60, height = 20,
      events = { { "key", keys.right }, { "key", keys.right }, { "key", keys.left } },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.page, 2, "two forward, one back")
    H.truthy(env.internals.pageCount() > 2, "list should span several pages")
    H.screenHas(env.frame, "PAGE 2/")
  end)

  it("clamps paging at both ends", function()
    local env = newEnv({ events = { { "key", keys.left }, { "key", keys.right } } })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.page, 1)
  end)

  it("quits on q and restores the palette", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    H.contains(env.printed(), "stopped")
    for _, rgb in pairs(env.screen.palette) do
      eq(rgb[1], 0, "palette entries restored to their captured value")
    end
  end)
end)

describe("vault_stock: change tracking", function()
  it("reports deltas after a rescan", function()
    local env = newEnv({
      events = {
        function(e)
          e.setVault("create:item_vault_1", {
            item("minecraft:iron_ingot", 112, "Iron Ingot"),
            item("minecraft:cobblestone", 320, "Cobblestone"),
          })
        end,
        { "key", keys.r },
      },
    })
    H.runOk(env, SCRIPT)
    local byId = env.internals.state.byId
    eq(byId["minecraft:iron_ingot"].delta, 100, "12 -> 112")
    eq(byId["minecraft:cobblestone"].delta, -320, "640 -> 320")
    eq(env.internals.state.delta, -220, "net change")
  end)

  it("lists only changed items in the MOVERS view", function()
    local env = newEnv({
      events = {
        function(e)
          e.setVault("create:item_vault_2", { item("create:andesite_alloy", 108, "Andesite Alloy") })
        end,
        { "key", keys.r },
        { "key", keys.tab },
      },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.view, 2, "MOVERS view")
    local moved = env.internals.movers()
    eq(#moved, 1)
    eq(moved[1].id, "create:andesite_alloy")
    eq(moved[1].delta, 100)
    H.screenHas(env.frame, "+100")
    H.screenLacks(env.frame, "Cobblestone")
  end)

  it("says so when nothing moved", function()
    local env = newEnv({ events = { { "key", keys.r }, { "key", keys.tab } } })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "Nothing moved")
  end)

  it("counts a vanished item as movement in the header total", function()
    local env = newEnv({
      events = {
        function(e) e.removeVault("create:item_vault_1") end,
        { "key", keys.r },
      },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.delta, -652, "12 iron + 640 cobble removed")
    eq(env.internals.state.online, 2)
  end)

  it("rescans when a peripheral is attached", function()
    local env = newEnv({
      events = {
        function(e)
          e.setVault("create:item_vault_9", { item("minecraft:diamond", 5, "Diamond") })
        end,
        { "peripheral", "create:item_vault_9" },
      },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.online, 4)
    H.screenHas(env.frame, "Diamond")
  end)
end)

describe("vault_stock: sorting", function()
  it("sorts by count first", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.state.items[1].id, "minecraft:cobblestone")
    eq(env.internals.state.items[3].id, "create:andesite_alloy")
  end)

  it("sorts by absolute change in CHANGE mode", function()
    local env = newEnv({
      events = {
        function(e)
          e.setVault("create:item_vault_2", { item("create:andesite_alloy", 1008, "Andesite Alloy") })
        end,
        { "key", keys.r },
        { "key", keys.s }, { "key", keys.s },   -- COUNT -> NAME -> CHANGE
      },
    })
    H.runOk(env, SCRIPT)
    eq(env.internals.state.sort, 3)
    eq(env.internals.state.items[1].id, "create:andesite_alloy")
    H.screenHas(env.frame, "SORT: CHANGE")
  end)
end)

describe("vault_stock: layout", function()
  local function manyItems(n)
    local stacks = {}
    for i = 1, n do
      local tag = string.format("%02d", i)
      stacks[i] = item("minecraft:item_" .. tag, n - i + 1, "Item " .. tag)
    end
    return { ["create:item_vault_0"] = stacks }
  end

  it("uses one full-width column while the list fits", function()
    local env = mock.newEnv({ vaults = manyItems(8), width = 90, height = 20 })
    H.runOk(env, SCRIPT)
    local _, y = env.frame:fgOf("Item 01")
    local _, y2 = env.frame:fgOf("Item 08")
    eq(y2 - y, 7, "all eight items stack in a single column")
  end)

  it("balances items evenly once a second column is needed", function()
    -- 16 rows of space, 20 items: two columns of ten, not 16 and 4
    local env = mock.newEnv({ vaults = manyItems(20), width = 90, height = 20 })
    H.runOk(env, SCRIPT)
    local _, firstY = env.frame:fgOf("Item 01")
    local _, lastLeft = env.frame:fgOf("Item 10")
    local _, firstRight = env.frame:fgOf("Item 11")
    eq(lastLeft - firstY, 9, "ten items in the left column")
    eq(firstRight, firstY, "the eleventh item starts the right column")
  end)

  it("right-aligns counts against the column edge", function()
    local env = mock.newEnv({ vaults = manyItems(4), width = 60, height = 20 })
    H.runOk(env, SCRIPT)
    local row
    for y = 1, env.frame.h do
      if env.frame:row(y):find("Item 01", 1, true) then row = env.frame:row(y) end
    end
    H.truthy(row, "found the first item row")
    eq(row:match("(%S+)%s*$"), "4", "count sits at the right edge")
    H.truthy(#row:match("%s*$") <= 1, "no dead column of padding")
  end)

  it("only reserves a change column once something has moved", function()
    local env = mock.newEnv({ vaults = manyItems(3), width = 60, height = 20 })
    H.runOk(env, SCRIPT)
    local before = env.frame:row(select(2, env.frame:fgOf("Item 01")))

    local env2 = mock.newEnv({
      vaults = manyItems(3), width = 60, height = 20,
      events = {
        function(e)
          e.setVault("create:item_vault_0", { item("minecraft:item_01", 99, "Item 01") })
        end,
        { "key", keys.r },
      },
    })
    H.runOk(env2, SCRIPT)
    local after = env2.frame:row(select(2, env2.frame:fgOf("Item 01")))
    H.truthy(not before:find("+", 1, true), "no delta column at rest")
    H.contains(after, "+96", "the delta appears after a change")
  end)

  it("names vaults after their peripheral index", function()
    local env = newEnv()
    H.runOk(env, SCRIPT)
    eq(env.internals.vaultLabel("create:item_vault_7"), "Vault 7")
    eq(env.internals.vaultLabel("minecraft:chest_3"), "chest 3")
  end)

  it("dims the list behind the item breakdown", function()
    local env = newEnv({
      events = { function(e)
        local _, y, x = e.screen:fgOf("Cobblestone")
        e.pushNext({ "monitor_touch", "monitor_0", x or 2, y or 5 })
      end },
    })
    H.runOk(env, SCRIPT)
    H.screenHas(env.frame, "SPREAD ACROSS")
    H.screenLacks(env.frame, "Andesite Alloy", "rows behind the panel are cleared")
    H.screenHas(env.frame, "VAULT NETWORK", "the header stays put")
  end)
end)
