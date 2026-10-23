-- Joints exposed in milestone 1, with their parent and realistic rotation limits.
-- Rotations are Euler degrees (X, Y, Z) relative to the character's default stance.
-- Bone names follow the base body rig; verify each one in WolvenKit before relying on it.

local Rig = {}

local function joint(name, label, parent, x, y, z)
  return { name = name, label = label, parent = parent,
           limits = { x = x, y = y, z = z } }
end

-- Each limit is { min, max } in degrees.
Rig.joints = {
  joint("Hips",          "Hips",            nil,            {-45, 45},  {-45, 45},  {-30, 30}),
  joint("Spine",         "Spine (lower)",   "Hips",         {-30, 45},  {-30, 30},  {-20, 20}),
  joint("Spine1",        "Spine (mid)",     "Spine",        {-20, 30},  {-25, 25},  {-15, 15}),
  joint("Spine2",        "Spine (upper)",   "Spine1",       {-15, 25},  {-20, 20},  {-15, 15}),
  joint("Spine3",        "Chest",           "Spine2",       {-10, 20},  {-15, 15},  {-10, 10}),
  joint("Neck",          "Neck",            "Spine3",       {-40, 50},  {-60, 60},  {-30, 30}),
  joint("Head",          "Head",            "Neck",         {-30, 40},  {-30, 30},  {-25, 25}),

  joint("LeftShoulder",  "Left shoulder",   "Spine3",       {-15, 30},  {-15, 15},  {-20, 30}),
  joint("LeftArm",       "Left upper arm",  "LeftShoulder", {-90, 180}, {-90, 90},  {-60, 135}),
  joint("LeftForeArm",   "Left forearm",    "LeftArm",      {0, 0},     {-90, 90},  {0, 150}),
  joint("LeftHand",      "Left hand",       "LeftForeArm",  {-70, 80},  {-30, 30},  {-30, 20}),
  joint("RightShoulder", "Right shoulder",  "Spine3",       {-15, 30},  {-15, 15},  {-30, 20}),
  joint("RightArm",      "Right upper arm", "RightShoulder",{-90, 180}, {-90, 90},  {-135, 60}),
  joint("RightForeArm",  "Right forearm",   "RightArm",     {0, 0},     {-90, 90},  {-150, 0}),
  joint("RightHand",     "Right hand",      "RightForeArm", {-70, 80},  {-30, 30},  {-20, 30}),

  joint("LeftUpLeg",     "Left thigh",      "Hips",         {-120, 30}, {-45, 45},  {-30, 45}),
  joint("LeftLeg",       "Left shin",       "LeftUpLeg",    {0, 150},   {0, 0},     {0, 0}),
  joint("LeftFoot",      "Left foot",       "LeftLeg",      {-45, 30},  {-20, 20},  {-30, 30}),
  joint("RightUpLeg",    "Right thigh",     "Hips",         {-120, 30}, {-45, 45},  {-45, 30}),
  joint("RightLeg",      "Right shin",      "RightUpLeg",   {0, 150},   {0, 0},     {0, 0}),
  joint("RightFoot",     "Right foot",      "RightLeg",     {-45, 30},  {-20, 20},  {-30, 30}),
}

Rig.byName = {}
for i, j in ipairs(Rig.joints) do
  j.index = i
  Rig.byName[j.name] = j
end

function Rig.get(name)
  return Rig.byName[name]
end

return Rig
