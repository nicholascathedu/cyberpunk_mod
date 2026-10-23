-- A scene's pose data: per character, per bone Euler rotation relative to default stance.
-- All edits go through set(), which applies joint limits and respects locks.

local Rig = require("core/rig")

local Pose = {}
Pose.__index = Pose

local AXES = { "x", "y", "z" }

local function clamp(v, range)
  if v < range[1] then return range[1] end
  if v > range[2] then return range[2] end
  return v
end

function Pose.new()
  return setmetatable({ characters = {}, locks = {}, limitsEnabled = true }, Pose)
end

local function charTable(self, charId)
  local c = self.characters[charId]
  if not c then
    c = { bones = {} }
    self.characters[charId] = c
  end
  return c
end

-- Returns { x, y, z } (a copy); zero rotation if the bone was never touched.
function Pose:get(charId, bone)
  local c = self.characters[charId]
  local r = c and c.bones[bone]
  if not r then return { x = 0, y = 0, z = 0 } end
  return { x = r.x, y = r.y, z = r.z }
end

function Pose:isLocked(charId, bone)
  local l = self.locks[charId]
  return l ~= nil and l[bone] == true
end

function Pose:setLocked(charId, bone, locked)
  self.locks[charId] = self.locks[charId] or {}
  self.locks[charId][bone] = locked or nil
end

-- Applies limits for the bone. Unknown bones pass through unclamped.
function Pose:constrain(bone, rot)
  local j = Rig.get(bone)
  if not (self.limitsEnabled and j) then
    return { x = rot.x, y = rot.y, z = rot.z }
  end
  local out = {}
  for _, a in ipairs(AXES) do out[a] = clamp(rot[a], j.limits[a]) end
  return out
end

-- Sets a bone rotation. Returns the stored value, or nil if the bone is locked.
function Pose:set(charId, bone, rot)
  if self:isLocked(charId, bone) then return nil end
  local v = self:constrain(bone, rot)
  charTable(self, charId).bones[bone] = v
  return { x = v.x, y = v.y, z = v.z }
end

function Pose:reset(charId, bone)
  return self:set(charId, bone, { x = 0, y = 0, z = 0 })
end

-- Iterates bones with a non-default rotation for one character.
function Pose:posedBones(charId)
  local c = self.characters[charId]
  local list = {}
  if c then
    for bone, r in pairs(c.bones) do
      if r.x ~= 0 or r.y ~= 0 or r.z ~= 0 then list[#list + 1] = bone end
    end
  end
  table.sort(list)
  return list
end

return Pose
