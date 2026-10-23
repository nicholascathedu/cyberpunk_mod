-- Plain Lua tests for the game-independent core. Run from the repo root:
--   luajit tests/run.lua     (or lua5.1 tests/run.lua)

package.path = "cet/poser/?.lua;" .. package.path

local Pose = require("core/pose")
local Undo = require("core/undo")
local Scene = require("core/scene")
local Rig = require("core/rig")

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

local function eq(a, b, msg)
  if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end

local function rotEq(r, x, y, z)
  eq(r.x, x, "x"); eq(r.y, y, "y"); eq(r.z, z, "z")
end

test("rig: every parent exists", function()
  for _, j in ipairs(Rig.joints) do
    if j.parent then assert(Rig.get(j.parent), j.name .. " has unknown parent " .. j.parent) end
  end
end)

test("rig: limits are ordered", function()
  for _, j in ipairs(Rig.joints) do
    for _, a in ipairs({ "x", "y", "z" }) do
      assert(j.limits[a][1] <= j.limits[a][2], j.name .. "." .. a)
    end
  end
end)

test("pose: untouched bone is zero", function()
  rotEq(Pose.new():get("player", "Head"), 0, 0, 0)
end)

test("pose: limits clamp", function()
  local p = Pose.new()
  rotEq(p:set("player", "RightForeArm", { x = 10, y = 200, z = -170 }), 0, 90, -150)
end)

test("pose: limits off passes through", function()
  local p = Pose.new()
  p.limitsEnabled = false
  rotEq(p:set("player", "RightForeArm", { x = 10, y = 200, z = -170 }), 10, 200, -170)
end)

test("pose: locked bone refuses edits", function()
  local p = Pose.new()
  p:set("player", "Head", { x = 5, y = 0, z = 0 })
  p:setLocked("player", "Head", true)
  eq(p:set("player", "Head", { x = 20, y = 0, z = 0 }), nil)
  rotEq(p:get("player", "Head"), 5, 0, 0)
  p:setLocked("player", "Head", false)
  rotEq(p:set("player", "Head", { x = 20, y = 0, z = 0 }), 20, 0, 0)
end)

test("pose: get returns a copy", function()
  local p = Pose.new()
  p:set("player", "Head", { x = 5, y = 0, z = 0 })
  p:get("player", "Head").x = 99
  rotEq(p:get("player", "Head"), 5, 0, 0)
end)

test("undo: a drag is one step", function()
  local p = Pose.new()
  local u = Undo.new(p)
  for v = 1, 30 do u:set("player", "Head", { x = v, y = 0, z = 0 }) end
  u:commit()
  eq(#u.past, 1)
  u:undo()
  rotEq(p:get("player", "Head"), 0, 0, 0)
  u:redo()
  rotEq(p:get("player", "Head"), 30, 0, 0)
end)

test("undo: new edit clears redo", function()
  local p = Pose.new()
  local u = Undo.new(p)
  u:set("player", "Head", { x = 10, y = 0, z = 0 }); u:commit()
  u:undo()
  u:set("player", "Neck", { x = 5, y = 0, z = 0 }); u:commit()
  eq(u:canRedo(), false)
end)

test("undo: no-op edit is not recorded", function()
  local p = Pose.new()
  local u = Undo.new(p)
  u:set("player", "Head", { x = 0, y = 0, z = 0 })
  eq(u:commit(), false)
  eq(#u.past, 0)
end)

test("undo: locked bone edit is not recorded", function()
  local p = Pose.new()
  p:setLocked("player", "Head", true)
  local u = Undo.new(p)
  u:set("player", "Head", { x = 10, y = 0, z = 0 })
  eq(u:commit(), false)
end)

test("undo: undo commits an open drag first", function()
  local p = Pose.new()
  local u = Undo.new(p)
  u:set("player", "Head", { x = 10, y = 0, z = 0 }); u:commit()
  u:set("player", "Head", { x = 20, y = 0, z = 0 })
  u:undo()
  rotEq(p:get("player", "Head"), 10, 0, 0)
end)

test("undo: history is capped", function()
  local p = Pose.new()
  local u = Undo.new(p, 3)
  for v = 1, 5 do u:set("player", "Head", { x = v, y = 0, z = 0 }); u:commit() end
  eq(#u.past, 3)
end)

test("scene: round trip keeps rotations and locks", function()
  local p = Pose.new()
  p:set("player", "RightForeArm", { x = 0, y = 12.5, z = -90 })
  p:set("judy", "Head", { x = 10, y = -5, z = 0 })
  p:setLocked("judy", "Neck", true)
  local q, meta = Scene.decode(Scene.encode(p, { name = "test" }))
  assert(q, meta)
  eq(meta.name, "test")
  rotEq(q:get("player", "RightForeArm"), 0, 12.5, -90)
  rotEq(q:get("judy", "Head"), 10, -5, 0)
  eq(q:isLocked("judy", "Neck"), true)
end)

test("scene: zero rotations are not written", function()
  local p = Pose.new()
  p:set("player", "Head", { x = 0, y = 0, z = 0 })
  assert(not Scene.encode(p):find("Head"))
end)

test("scene: rejects foreign and newer files", function()
  local _, e1 = Scene.decode('{"hello":1}')
  eq(e1, "not a poser scene file")
  local _, e2 = Scene.decode('{"format":"cp-poser-scene","version":99}')
  eq(e2, "scene was saved by a newer version")
  local _, e3 = Scene.decode("not json")
  eq(e3, "not valid JSON")
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
