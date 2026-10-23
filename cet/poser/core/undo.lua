-- Undo/redo for bone edits. A slider drag is many small set() calls, so edits are
-- grouped: begin() before the drag, commit() when it ends, and the whole drag
-- becomes one undo step.

local Undo = {}
Undo.__index = Undo

function Undo.new(pose, limit)
  return setmetatable({ pose = pose, past = {}, future = {}, open = nil, limit = limit or 200 }, Undo)
end

local function key(charId, bone) return charId .. "\0" .. bone end

-- Records the "before" value of a bone the first time it is touched in the open group.
function Undo:touch(charId, bone)
  self.open = self.open or { before = {}, order = {} }
  local k = key(charId, bone)
  if not self.open.before[k] then
    self.open.before[k] = { charId = charId, bone = bone, rot = self.pose:get(charId, bone) }
    self.open.order[#self.open.order + 1] = k
  end
end

-- Convenience: one undoable edit.
function Undo:set(charId, bone, rot)
  self:touch(charId, bone)
  return self.pose:set(charId, bone, rot)
end

local function same(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end

function Undo:commit()
  local g = self.open
  self.open = nil
  if not g then return false end
  local step = {}
  for _, k in ipairs(g.order) do
    local b = g.before[k]
    local after = self.pose:get(b.charId, b.bone)
    if not same(b.rot, after) then
      step[#step + 1] = { charId = b.charId, bone = b.bone, before = b.rot, after = after }
    end
  end
  if #step == 0 then return false end
  self.past[#self.past + 1] = step
  if #self.past > self.limit then table.remove(self.past, 1) end
  self.future = {}
  return true
end

-- Undo/redo bypass locks: they restore exactly what was recorded.
local function apply(pose, step, field)
  for _, e in ipairs(step) do
    pose.characters[e.charId] = pose.characters[e.charId] or { bones = {} }
    local r = e[field]
    pose.characters[e.charId].bones[e.bone] = { x = r.x, y = r.y, z = r.z }
  end
end

function Undo:undo()
  self:commit()
  local step = table.remove(self.past)
  if not step then return false end
  apply(self.pose, step, "before")
  self.future[#self.future + 1] = step
  return true
end

function Undo:redo()
  local step = table.remove(self.future)
  if not step then return false end
  apply(self.pose, step, "after")
  self.past[#self.past + 1] = step
  return true
end

function Undo:canUndo() return #self.past > 0 or self.open ~= nil end
function Undo:canRedo() return #self.future > 0 end

return Undo
