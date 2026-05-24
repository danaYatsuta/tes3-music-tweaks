-- hello whoever is reading this code (including myself in the future). this is an attempt to implement a state machine in
-- a language that barely has any features to do so, done by a person who barely knows what they're doing.
-- please enjoy
--
local config = require("Music Tweaks.config")

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
	-- tes3.messageBox("New music state: " .. newMusicState)
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

	stateExploreTimer = timer.start({
		duration = math.random(config.minPause, config.maxPause),
		callback = stateExplore,
		type = timer.real,
	})
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

local function stateOther()
	setMusicState(MusicState.OTHER)

	stopStateExploreTimer()
end

local function statePause()
	setMusicState(MusicState.PAUSE)

	changeMusicTrackToSilence()
	startStateExploreTimer()
end

--- @param cell tes3cell
local function isCellDungeon(cell)
if not config.enableNoExploreInDungeons then
		return false
	end

	local isInHostileInterior = not cell.isOrBehavesAsExterior and not cell.restingIsIllegal

	-- LuaFormatter off
	local isInRedMountainBeforeMainQuestComplete =
		cell.isOrBehavesAsExterior and
		cell.region.name == "Red Mountain Region" and
	    tes3.getJournalIndex({ id = "C3_DestroyDagoth" }) ~= 50
	-- LuaFormatter on

	if isInHostileInterior or isInRedMountainBeforeMainQuestComplete then
		return true
	end

	return false
end

--- @param e cellChangedEventData
local function cellChangedCallback(e)
	if tes3.mobilePlayer.inCombat then
		return
	end

	if currentMusicState == MusicState.DUNGEON then
		if not isCellDungeon(e.cell) then
			if config.enablePause then
				statePause()
			else
				stateExplore()
			end
		end
	elseif currentMusicState == MusicState.EXPLORE or currentMusicState == MusicState.PAUSE then
		if isCellDungeon(e.cell) then
			stateDungeon()
		end
	elseif currentMusicState == MusicState.OTHER then
		if isCellDungeon(e.cell) then
			stateDungeon()
		elseif config.enablePause then
			statePause()
		else
			stateExplore()
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
		currentMusicState == MusicState.PAUSE
	then
	-- LuaFormatter on
		local enemy = e.actor.reference.object

		if enemy.level * 2 > tes3.player.object.level and (enemy.objectType ~= tes3.objectType.creature or enemy.level > 2) or
		not config.enableNoCombatForWeakEnemies then
			stateCombat()
		end
	end
end

--- @param e combatStoppedEventData
local function combatStoppedCallback(e)
	if currentMusicState == MusicState.COMBAT and not tes3.mobilePlayer.inCombat then
		if isCellDungeon(tes3.player.cell) then
			stateDungeon()
		elseif config.enablePause then
			statePause()
		else
			stateExplore()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	print("[Music Tweaks: DEBUG] musicChangeTrackCallback called")

	if e.context ~= "combat" and e.context ~= "explore" then
		return
	end

	if currentMusicState == MusicState.COMBAT then
		if e.context == "combat" then
			return
		end
	elseif currentMusicState == MusicState.DUNGEON then
		e.music = SILENCE_FILEPATH

		return
	elseif currentMusicState == MusicState.EXPLORE then
		if config.enablePause then
			statePause()
		else
			return
		end
	end

	return false
end

--- @param e loadEventData
local function loadCallback(e)
	stateOther()
end

local function initialized()
	for _, v in pairs(MusicState) do
		validMusicState[v] = true
	end

	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStart, combatStartCallback)
	event.register(tes3.event.combatStopped, combatStoppedCallback)
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)
	event.register(tes3.event.load, loadCallback)

	print("[Music Tweaks: INFO] Music Tweaks initialized")
end

event.register(tes3.event.initialized, initialized)

dofile("Music Tweaks.mcm")
