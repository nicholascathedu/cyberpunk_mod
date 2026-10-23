-- Milestone 0 discovery: dumps what the game exposes to scripts about animation,
-- so we can see whether any call accepts per-bone transforms.
-- Output goes to the CET log and to probe-output.txt in this mod's folder.

local Probe = {}

-- Types worth inspecting. Names that don't exist are reported and skipped.
Probe.types = {
  "entAnimatedComponent",
  "entSkinnedMeshComponent",
  "entAnimationControllerComponent",
  "AnimationControllerComponent",
  "animAnimFeature",
  "gamePuppet",
  "PlayerPuppet",
  "gamePhotoModeSystem",
}

local function dumpType(name)
  local ok, out = pcall(DumpType, name, true)
  if not ok then return "!! " .. name .. ": " .. tostring(out) end
  if out == nil or out == "" then return "!! " .. name .. ": no type info" end
  return out
end

function Probe.run()
  local lines = { "== cp-poser probe ==" }

  for _, t in ipairs(Probe.types) do
    lines[#lines + 1] = "---- " .. t .. " ----"
    lines[#lines + 1] = dumpType(t)
  end

  local player = Game.GetPlayer()
  if player then
    lines[#lines + 1] = "---- player instance ----"
    local ok, out = pcall(Dump, player, true)
    lines[#lines + 1] = ok and tostring(out) or ("!! " .. tostring(out))
  else
    lines[#lines + 1] = "!! no player (load a save first)"
  end

  local text = table.concat(lines, "\n")
  spdlog.info(text)
  local f = io.open("probe-output.txt", "w")
  if f then
    f:write(text)
    f:close()
  end
  return #lines
end

return Probe
