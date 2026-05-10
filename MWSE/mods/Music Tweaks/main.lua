-- hello whoever is reading this code (including myself in the future). this is an attempt to implement a state machine in
-- a language that barely has any features to do so, done by a person who barely knows what they're doing.
-- please enjoy
-- 
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
