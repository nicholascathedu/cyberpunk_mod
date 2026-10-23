# Native bone override (RED4ext plugin)

Not written yet. This is the likely home of the milestone 0 backend.

Goal: after the game evaluates a character's animation each frame, overwrite the local
rotation of chosen bones with values from the CET mod, then let skinning use the result.

Plan:
1. Run the CET probe (`Run probe` button) and read `probe-output.txt`. If any script-visible
   call already accepts per-bone transforms, we use that and may not need this plugin.
2. Otherwise, find the post-animation pose buffer for an entity (RED4ext SDK types around
   `entAnimatedComponent` / the animation graph output) and hook the point where it is final.
3. Expose two natives to redscript/CET: `PoserSetBoneRotation(entity, bone, x, y, z)` and
   `PoserClear(entity)`, then register a backend in `cet/poser/core/backend.lua`.

Build: Visual Studio 2022 with "Desktop development with C++", RED4ext.SDK.
