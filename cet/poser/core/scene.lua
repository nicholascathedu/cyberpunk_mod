-- Scene files: plain JSON holding every character's pose (and later, positions and camera).
-- Only non-default rotations are written, so files stay small and readable.

local json = require("vendor/json")
local Pose = require("core/pose")

local Scene = {}

Scene.FORMAT = "cp-poser-scene"
Scene.VERSION = 1

function Scene.encode(pose, meta)
  local doc = {
    format = Scene.FORMAT,
    version = Scene.VERSION,
    name = meta and meta.name or "untitled",
    characters = {},
  }
  for charId, c in pairs(pose.characters) do
    local bones = {}
    local any = false
    for bone, r in pairs(c.bones) do
      if r.x ~= 0 or r.y ~= 0 or r.z ~= 0 then
        bones[bone] = { r.x, r.y, r.z }
        any = true
      end
    end
    local locked = {}
    for bone in pairs(pose.locks[charId] or {}) do locked[#locked + 1] = bone end
    table.sort(locked)
    if any or #locked > 0 then
      doc.characters[#doc.characters + 1] = { id = charId, bones = bones, locked = locked }
    end
  end
  table.sort(doc.characters, function(a, b) return a.id < b.id end)
  return json.encode(doc)
end

-- Returns pose, meta on success; nil, error message on failure.
-- Values are loaded as saved (no clamping), so a scene always reloads exactly.
function Scene.decode(text)
  local ok, doc = pcall(json.decode, text)
  if not ok or type(doc) ~= "table" then return nil, "not valid JSON" end
  if doc.format ~= Scene.FORMAT then return nil, "not a poser scene file" end
  if type(doc.version) ~= "number" or doc.version > Scene.VERSION then
    return nil, "scene was saved by a newer version"
  end
  local pose = Pose.new()
  for _, c in ipairs(doc.characters or {}) do
    if type(c.id) ~= "string" then return nil, "character without an id" end
    pose.characters[c.id] = { bones = {} }
    for bone, r in pairs(c.bones or {}) do
      if type(r) ~= "table" or #r ~= 3 then return nil, "bad rotation for " .. tostring(bone) end
      pose.characters[c.id].bones[bone] = { x = r[1], y = r[2], z = r[3] }
    end
    for _, bone in ipairs(c.locked or {}) do pose:setLocked(c.id, bone, true) end
  end
  return pose, { name = doc.name }
end

return Scene
