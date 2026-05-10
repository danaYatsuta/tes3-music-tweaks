-- Music states
local EXPLORE = 0
local COMBAT = 1
local PAUSE = 2
local DUNGEON = 3
-- Title music, level up, death, etc
local OTHER = 4

-- Current music state. Starts out as OTHER because the game begins at main menu
local musicState = OTHER

local function initialized()
	print("[Music Tweaks: INFO] Music Tweaks Initialized")
end

event.register(tes3.event.initialized, initialized)
