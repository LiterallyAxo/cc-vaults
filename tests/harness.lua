-- Tiny test harness: describe/it plus a handful of assertions.
local H = { groups = {}, passed = 0, failed = 0, failures = {} }

local current

function H.describe(name, fn)
  current = { name = name }
  H.groups[#H.groups + 1] = current
  fn()
  current = nil
end

function H.it(name, fn)
  local group = current and current.name or "?"
  local ok, err = xpcall(fn, function(e)
    return tostring(e) .. "\n" .. debug.traceback("", 2)
  end)
  if ok then
    H.passed = H.passed + 1
    io.write("  ok   ", name, "\n")
  else
    H.failed = H.failed + 1
    H.failures[#H.failures + 1] = { group = group, name = name, err = err }
    io.write("  FAIL ", name, "\n")
  end
end

local function fmt(v)
  if type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end

function H.eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%sexpected %s, got %s",
      msg and (msg .. ": ") or "", fmt(expected), fmt(actual)), 2)
  end
end

function H.truthy(value, msg)
  if not value then error(msg or "expected a truthy value", 2) end
end

function H.falsy(value, msg)
  if value then error((msg or "expected a falsy value") .. ", got " .. fmt(value), 2) end
end

function H.near(actual, expected, tolerance, msg)
  if math.abs(actual - expected) > (tolerance or 0.001) then
    error(string.format("%sexpected ~%s, got %s",
      msg and (msg .. ": ") or "", fmt(expected), fmt(actual)), 2)
  end
end

function H.contains(haystack, needle, msg)
  if not tostring(haystack):find(needle, 1, true) then
    error(string.format("%sexpected to find %s in:\n%s",
      msg and (msg .. ": ") or "", fmt(needle), tostring(haystack)), 2)
  end
end

function H.screenHas(screen, needle, msg)
  if not screen:contains(needle) then
    error(string.format("%sscreen does not contain %s. Screen was:\n%s",
      msg and (msg .. ": ") or "", fmt(needle), screen:dump()), 2)
  end
end

function H.screenLacks(screen, needle, msg)
  if screen:contains(needle) then
    error(string.format("%sscreen unexpectedly contains %s. Screen was:\n%s",
      msg and (msg .. ": ") or "", fmt(needle), screen:dump()), 2)
  end
end

-- run a script and fail loudly if it blew up
function H.runOk(env, path, ...)
  local ok, err = env.run(path, ...)
  if not ok then
    error("script " .. path .. " errored: " .. tostring(err) ..
      "\nprinted output:\n" .. env.printed(), 2)
  end
  return env
end

function H.report()
  io.write("\n")
  for _, f in ipairs(H.failures) do
    io.write("FAILED: ", f.group, " > ", f.name, "\n", f.err, "\n\n")
  end
  io.write(string.format("%d passed, %d failed\n", H.passed, H.failed))
  return H.failed == 0
end

return H
