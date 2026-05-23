-- hello whoever is reading this code (including myself in the future). this is an attempt to implement a state machine in
-- a language that barely has any features to do so, done by a person who barely knows what they're doing.
-- please enjoy
--
-- "Enum" of possible music states; OTHER is title, level up, death, etc
local MusicState = { COMBAT = "combat", DUNGEON = "dungeon", EXPLORE = "explore", OTHER = "other", PAUSE = "pause" }

-- Lookup table for the "enum"; populated in initialized
local validMusicState = {}

local SILENCE_FILEPATH = "data files/music/silence.mp3"

-- Current music state. Starts out as OTHER because the game begins at main menu
-- Should NEVER be written to outside of setState function
local currentMusicState = MusicState.OTHER

-- Should NEVER be called outside of stateExplore/stateCombat/etc functions
local function setMusicState(newMusicState)
	if not validMusicState[newMusicState] then
		return
	end

	print("[Music Tweaks: DEBUG] New music state: " .. newMusicState)
	tes3.messageBox("New music state: " .. newMusicState)
	currentMusicState = newMusicState
end

local function stateExplore()
	setMusicState(MusicState.EXPLORE)

	tes3.skipToNextMusicTrack({ situation = tes3.musicSituation.explore, force = true })
end

-- Should NEVER be accessed outside of startStateExploreTimer and stopStateExploreTimer
local stateExploreTimer = nil

local function stopStateExploreTimer()
	if stateExploreTimer then
		stateExploreTimer:cancel()
	end
end

local function startStateExploreTimer()
	stopStateExploreTimer()

	stateExploreTimer = timer.start({ duration = math.random(60, 120), callback = stateExplore, type = timer.real })
end

local function changeMusicTrackToSilence()
	tes3.worldController.audioController:changeMusicTrack(SILENCE_FILEPATH)
end

local function stateCombat()
	setMusicState(MusicState.COMBAT)

	stopStateExploreTimer()
	tes3.skipToNextMusicTrack({ situation = tes3.musicSituation.combat, force = true })
end

local function stateDungeon()
	setMusicState(MusicState.DUNGEON)

	stopStateExploreTimer()
	changeMusicTrackToSilence()
end

local function statePause()
	setMusicState(MusicState.PAUSE)

	changeMusicTrackToSilence()
	startStateExploreTimer()
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
	if tes3.mobilePlayer.inCombat then
		return
	end

	if currentMusicState == MusicState.DUNGEON then
		if not isCellDungeon(e.cell) then
			statePause()
		end
	elseif currentMusicState == MusicState.EXPLORE or currentMusicState == MusicState.PAUSE then
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

--- @param e combatStartEventData
local function combatStartCallback(e)
	if e.target.reference ~= tes3.player then
		return
	end

	-- LuaFormatter off
	if
		currentMusicState == MusicState.DUNGEON or
		currentMusicState == MusicState.EXPLORE or
		currentMusicState == MusicState.PAUSE then
	-- LuaFormatter on
		local enemy = e.actor.reference.object

		if enemy.level * 2 > tes3.player.object.level and (enemy.objectType ~= tes3.objectType.creature or enemy.level > 2) then
			stateCombat()
		end
	end
end

--- @param e combatStoppedEventData
local function combatStoppedCallback(e)
	if currentMusicState == MusicState.COMBAT and not tes3.mobilePlayer.inCombat then
		if isCellDungeon(tes3.player.cell) then
			stateDungeon()
		else
			statePause()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	if e.context ~= "combat" and e.context ~= "explore" then
		return
	end

	if currentMusicState == MusicState.EXPLORE then
		statePause()
	elseif currentMusicState == MusicState.DUNGEON then
		e.music = SILENCE_FILEPATH

		return
	end

	return false

end

local function initialized()
	for _, v in pairs(MusicState) do
		validMusicState[v] = true
	end

	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStart, combatStartCallback)
	event.register(tes3.event.combatStopped, combatStoppedCallback)
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)

	print("[Music Tweaks: INFO] Music Tweaks initialized")
end

event.register(tes3.event.initialized, initialized)
