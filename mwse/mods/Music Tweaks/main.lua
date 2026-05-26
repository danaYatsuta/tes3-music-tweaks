local config = require("Music Tweaks.config")
local constants = require("Music Tweaks.constants")
local log = require("Music Tweaks.log")
local MusicStateMachine = require("Music Tweaks.musicStateMachine")

local musicStateMachine = MusicStateMachine:new()

-- ---------------------------- Helper Functions ---------------------------- --

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

-- ----------------------------- Event Callbacks ---------------------------- --

--- @param e cellChangedEventData
local function cellChangedCallback(e)
	if tes3.mobilePlayer.inCombat then
		return
	end

	-- LuaFormatter off
	if
		musicStateMachine.state == musicStateMachine.STATE.COMBAT or
		musicStateMachine.state == musicStateMachine.STATE.OTHER
	then
	-- LuaFormatter on
		if isCellDungeon(e.cell) then
			musicStateMachine:stateDungeon()
		elseif config.enablePause then
			musicStateMachine:statePause()
		else
			musicStateMachine:stateExplore()
		end

	elseif musicStateMachine.state == musicStateMachine.STATE.DUNGEON then
		if not isCellDungeon(e.cell) then
			if config.enablePause then
				musicStateMachine:statePause()
			else
				musicStateMachine:stateExplore()
			end
		end
		-- LuaFormatter off
	elseif
		musicStateMachine.state == musicStateMachine.STATE.EXPLORE or
		musicStateMachine.state == musicStateMachine.STATE.PAUSE
	then
	-- LuaFormatter on
		if isCellDungeon(e.cell) then
			musicStateMachine:stateDungeon()
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
		musicStateMachine.state == musicStateMachine.STATE.DUNGEON or
		musicStateMachine.state == musicStateMachine.STATE.EXPLORE or
		musicStateMachine.state == musicStateMachine.STATE.PAUSE
	then
	-- LuaFormatter on
		local enemy = e.actor.reference.object

		if enemy.level * 2 > tes3.player.object.level and (enemy.objectType ~= tes3.objectType.creature or enemy.level > 2) or
		not config.enableNoCombatForWeakEnemies then
			musicStateMachine:stateCombat()
		end
	end
end

--- @param e combatStoppedEventData
local function combatStoppedCallback(e)
	log("combatStoppedCallback called with %s", { state = musicStateMachine.state, enemy = e.actor.reference.id })

	if musicStateMachine.state == musicStateMachine.STATE.COMBAT and not tes3.mobilePlayer.inCombat then
		if isCellDungeon(tes3.player.cell) then
			log("Entering dungeon state because combat ended while in dungeon")
			musicStateMachine:stateDungeon()
		elseif config.enablePause then
			log("Entering pause state because combat ended while outside dungeon")
			musicStateMachine:statePause()
		else
			log("Entering pause state because combat ended while outside dungeon and pauses are disabled in config")
			musicStateMachine:stateExplore()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	log("musicChangeTrackCallback called with %s", { state = musicStateMachine.state, context = e.context })

	if e.context ~= "combat" and e.context ~= "explore" then
		return
	end

	if musicStateMachine.state == musicStateMachine.STATE.COMBAT then
		if e.context == "combat" then
			return
		end
	elseif musicStateMachine.state == musicStateMachine.STATE.DUNGEON then
		e.music = constants.SILENCE_FILEPATH

		return
	elseif musicStateMachine.state == musicStateMachine.STATE.EXPLORE then
		if config.enablePause then
			log("Entering pause state because explore track ended")

			musicStateMachine:statePause()
		else
			return
		end
	end

	return false
end

local function loadCallback()
	musicStateMachine:stateOther()
end

local function initialized()
	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStart, combatStartCallback)
	event.register(tes3.event.combatStopped, combatStoppedCallback)
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)
	event.register(tes3.event.load, loadCallback)

	log:info("Music Tweaks initialized")
end

event.register(tes3.event.initialized, initialized)

dofile("Music Tweaks.mcm")
