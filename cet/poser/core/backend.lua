-- The bridge between pose data and the game. Everything above this file is plain Lua;
-- everything game-specific about moving bones lives behind this interface.
--
-- A backend implements:
--   name                         string shown in the UI
--   available()                  true if it can move bones right now
--   apply(entity, bone, rot)     push one bone rotation ({x, y, z} degrees) to the game
--   clear(entity)                drop all overrides on an entity
--
-- Milestone 0 is about finding a backend that works. Until then the null backend
-- records what would have been sent, so the UI and pose logic can be tested.

local Backend = {}

local Null = { name = "none (bone override not wired yet)", sent = {} }

function Null.available() return false end

function Null.apply(_, bone, rot)
  Null.sent[bone] = rot
end

function Null.clear()
  Null.sent = {}
end

Backend.null = Null
Backend.current = Null

-- A native plugin (see native/README.md) registers itself here once it exists.
function Backend.use(b)
  Backend.current = b
end

return Backend
