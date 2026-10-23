# cyberpunk_mod (cp-poser)

Live, Blender-style posing for Cyberpunk 2077 Photo Mode. PC prototype; console gets
Blender-made pose packs from the same scene files later.

Plan and setup guide: https://claude.ai/artifact/CdYpB4x5qvJRKatwfvSTeo

## Status: milestone 0

Find a way to rotate a single bone live. The CET mod's UI, pose data, joint limits, locking,
undo and scene files work; the part that actually moves bones in game (the backend) does not
exist yet, so sliders change the data but not V.

## Layout

```
cet/poser/          Cyber Engine Tweaks mod (Lua)
  init.lua          overlay window: joint picker, sliders, lock, undo/redo, save/load, probe
  probe.lua         dumps animation-related game types to probe-output.txt
  core/rig.lua      joints and realistic rotation limits
  core/pose.lua     per-character bone rotations, limits, locks
  core/undo.lua     grouped undo/redo
  core/scene.lua    scene JSON save/load
  core/backend.lua  interface to whatever moves bones in game
  vendor/json.lua   rxi/json.lua (MIT)
native/             RED4ext plugin (planned)
tests/run.lua       tests for the core, no game needed
tools/install.ps1   copies the mod into the game
```

## Try it

1. Install CET and the other frameworks from the setup guide.
2. In PowerShell from this folder: `.\tools\install.ps1`
3. Start the game, load a save, open the CET overlay. The `cp-poser` window appears.
4. Press **Run probe** and send back `bin\x64\plugins\cyber_engine_tweaks\mods\cp-poser\probe-output.txt`.

## Tests

`luajit tests/run.lua` (or `lua5.1`). CI runs them on every push.
