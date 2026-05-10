-- hello whoever is reading this code (including myself in the future). this is an attempt to implement a state machine in
-- a language that barely has any features to do so, done by a person who barely knows what they're doing.
-- please enjoy
--
-- "Enum" of possible music states; OTHER is title, level up, death, etc
local MusicState = { EXPLORE = "explore", COMBAT = "combat", PAUSE = "pause", DUNGEON = "dungeon", OTHER = "other" }

-- Lookup table for the "enum"; populated in initialized
local validMusicState = {}

-- Current music state. Starts out as OTHER because the game begins at main menu
-- Should NEVER be written to outside of setState function
local currentMusicState = MusicState.OTHER

-- Should NEVER be called outside of stateExplore/stateCombat/etc functions 
local function setMusicState(newMusicState)
	if not validMusicState[newMusicState] then
		return
	end

	tes3.messageBox("New music state: " .. newMusicState)
	currentMusicState = newMusicState
end

local function stateDungeon()
	setMusicState(MusicState.DUNGEON)
end

local function statePause()
	setMusicState(MusicState.PAUSE)
end

--- @param cell tes3cell
local function isCellDungeon(cell)
	if cell.isOrBehavesAsExterior or cell.restingIsIllegal then
		return false
	end

	return true
end

--- @param e cellChangedEventData
local function cellChangedCallback(e)
	if currentMusicState == MusicState.PAUSE then
		if isCellDungeon(e.cell) then
			stateDungeon()
		end
	elseif currentMusicState == MusicState.OTHER then
		if isCellDungeon(e.cell) then
			stateDungeon()
		else
			statePause()
		end
	end
end

local function initialized()
	for _, v in pairs(MusicState) do
		validMusicState[v] = true
	end

	event.register(tes3.event.cellChanged, cellChangedCallback)
	print("[Music Tweaks: INFO] Music Tweaks Initialized")
end

event.register(tes3.event.initialized, initialized)
