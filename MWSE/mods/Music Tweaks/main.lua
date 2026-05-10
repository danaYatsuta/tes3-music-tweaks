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

local musicStates = { EXPLORE, COMBAT, PAUSE, DUNGEON, OTHER }

-- Current music state. Starts out as OTHER because the game begins at main menu
-- Should NEVER be written to outside of setState function
local musicState = OTHER

-- Should NEVER be called outside of stateExplore/stateCombat/etc functions 
local function setMusicState(newMusicState)
	if not musicStates[newMusicState] then
		return
	end

	tes3.messageBox("New music state: " .. musicState)
	musicState = newMusicState
end

local function statePause()
	setMusicState(PAUSE)
end

local function stateDungeon()
	setMusicState(DUNGEON)
end

--- @param e cellChangedEventData
local function cellChangedCallback(e)
	if musicState == OTHER then
		if (e.cell.isOrBehavesAsExterior or e.cell.restingIsIllegal) then
			statePause()
		else
			stateDungeon()
		end
	end
end

local function initialized()
	event.register(tes3.event.cellChanged, cellChangedCallback)
	print("[Music Tweaks: INFO] Music Tweaks Initialized")
end

event.register(tes3.event.initialized, initialized)
