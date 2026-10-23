-- cp-poser: Cyber Engine Tweaks entry point.
-- Milestone 0 UI: pick a joint, rotate it with sliders, lock it, undo/redo, save/load a scene,
-- and run the discovery probe. The rotation rings come in milestone 1.

local Rig = require("core/rig")
local Pose = require("core/pose")
local Undo = require("core/undo")
local Scene = require("core/scene")
local Backend = require("core/backend")
local Probe = require("probe")

local CHAR = "player"   -- milestone 0 poses V only
local SCENE_FILE = "scenes/quicksave.json"

local state = {
  overlayOpen = false,
  pose = Pose.new(),
  selected = "RightForeArm",
  status = "",
}
state.undo = Undo.new(state.pose)

local function push(bone)
  local player = Game.GetPlayer()
  if player then Backend.current.apply(player, bone, state.pose:get(CHAR, bone)) end
end

local function pushAll()
  for _, j in ipairs(Rig.joints) do push(j.name) end
end

local function save()
  local f = io.open(SCENE_FILE, "w")
  if not f then state.status = "Could not write " .. SCENE_FILE; return end
  f:write(Scene.encode(state.pose, { name = "quicksave" }))
  f:close()
  state.status = "Saved " .. SCENE_FILE
end

local function load()
  local f = io.open(SCENE_FILE, "r")
  if not f then state.status = "No scene at " .. SCENE_FILE; return end
  local pose, err = Scene.decode(f:read("*a"))
  f:close()
  if not pose then state.status = "Load failed: " .. err; return end
  state.pose = pose
  state.undo = Undo.new(pose)
  pushAll()
  state.status = "Loaded " .. SCENE_FILE
end

local function jointCombo()
  local current = Rig.get(state.selected)
  if ImGui.BeginCombo("Joint", current.label) then
    for _, j in ipairs(Rig.joints) do
      if ImGui.Selectable(j.label, j.name == state.selected) then state.selected = j.name end
    end
    ImGui.EndCombo()
  end
end

local function rotationSliders()
  local bone = state.selected
  local j = Rig.get(bone)
  local rot = state.pose:get(CHAR, bone)
  local locked = state.pose:isLocked(CHAR, bone)
  local changed = false

  for _, axis in ipairs({ "x", "y", "z" }) do
    local lo, hi = -180, 180
    if state.pose.limitsEnabled then lo, hi = j.limits[axis][1], j.limits[axis][2] end
    if lo == hi then
      ImGui.Text(axis:upper() .. ": fixed by joint limits")
    else
      local v, used = ImGui.SliderFloat(axis:upper(), rot[axis], lo, hi, "%.1f deg")
      if used and not locked then rot[axis] = v; changed = true end
      if ImGui.IsItemDeactivatedAfterEdit() then state.undo:commit() end
    end
  end

  if changed then
    state.undo:set(CHAR, bone, rot)
    push(bone)
  end

  local newLocked = ImGui.Checkbox("Lock joint", locked)
  if newLocked ~= locked then state.pose:setLocked(CHAR, bone, newLocked) end

  if ImGui.Button("Reset joint") and not locked then
    state.undo:set(CHAR, bone, { x = 0, y = 0, z = 0 })
    state.undo:commit()
    push(bone)
  end
end

registerForEvent("onInit", function()
  spdlog.info("cp-poser loaded, backend: " .. Backend.current.name)
end)

registerForEvent("onOverlayOpen", function() state.overlayOpen = true end)
registerForEvent("onOverlayClose", function() state.overlayOpen = false end)

registerForEvent("onDraw", function()
  if not state.overlayOpen then return end
  if not ImGui.Begin("cp-poser") then ImGui.End(); return end

  ImGui.Text("Backend: " .. Backend.current.name)
  ImGui.Separator()

  jointCombo()
  rotationSliders()

  ImGui.Separator()
  if ImGui.Button("Undo") then state.undo:undo(); pushAll() end
  ImGui.SameLine()
  if ImGui.Button("Redo") then state.undo:redo(); pushAll() end
  ImGui.SameLine()
  state.pose.limitsEnabled = ImGui.Checkbox("Joint limits", state.pose.limitsEnabled)

  if ImGui.Button("Save scene") then save() end
  ImGui.SameLine()
  if ImGui.Button("Load scene") then load() end

  ImGui.Separator()
  if ImGui.Button("Run probe") then
    state.status = "Probe wrote " .. Probe.run() .. " sections to probe-output.txt"
  end

  if state.status ~= "" then ImGui.TextWrapped(state.status) end
  ImGui.End()
end)
