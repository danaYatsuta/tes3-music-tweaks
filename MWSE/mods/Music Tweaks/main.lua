-- hello whoever is reading this code (including myself in the future). this is an attempt to implement a state machine in
-- a language that barely has any features to do so, done by a person who barely knows what they're doing.
-- please enjoy
--
-- "Enum" of possible music states; OTHER is title, level up, death, etc
local MusicState = { COMBAT = "combat", DUNGEON = "dungeon", EXPLORE = "explore", OTHER = "other", PAUSE = "pause" }

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

local function stateCombat()
	setMusicState(MusicState.COMBAT)
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
	if currentMusicState == MusicState.DUNGEON then
		if not isCellDungeon(e.cell) then
			statePause()
		end
	elseif currentMusicState == MusicState.EXPLORE then
		if isCellDungeon(e.cell) then
			stateDungeon()
		end
	elseif currentMusicState == MusicState.OTHER then
		if isCellDungeon(e.cell) then
			stateDungeon()
		else
			statePause()
		end
	elseif currentMusicState == MusicState.PAUSE then
		if isCellDungeon(e.cell) then
			stateDungeon()
		end
	end
end

--- @param e combatStartEventData
local function combatStartCallback(e)
	if currentMusicState == MusicState.DUNGEON or currentMusicState == MusicState.EXPLORE or currentMusicState ==
	MusicState.PAUSE then
		if e.target.reference ~= tes3.player then
			return
		end

		local enemy = e.actor.reference.object

		if enemy.level * 2 > tes3.player.object.level and (enemy.objectType ~= tes3.objectType.creature or enemy.level > 2) then
			stateCombat()
		end
	end
end

--- @param e combatStopEventData
local function combatStopCallback(e)
	if currentMusicState == MusicState.COMBAT then
		if isCellDungeon(tes3.player.cell) then
			stateDungeon()
		else
			statePause()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	if currentMusicState == MusicState.EXPLORE then
		if e.context == "explore" then
			statePause()
		end
	end
end

local function initialized()
	for _, v in pairs(MusicState) do
		validMusicState[v] = true
	end

	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStart, combatStartCallback)
	event.register(tes3.event.combatStop, combatStopCallback)
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)

	print("[Music Tweaks: INFO] Music Tweaks Initialized")
end

event.register(tes3.event.initialized, initialized)
