local config = require("Music Tweaks.config")
local constants = require("Music Tweaks.constants")
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

	if musicStateMachine.state == musicStateMachine.STATE.DUNGEON then
		if not isCellDungeon(e.cell) then
			if config.enablePause then
				musicStateMachine:statePause()
			else
				musicStateMachine:stateExplore()
			end
		end
	elseif musicStateMachine.state == musicStateMachine.STATE.EXPLORE or musicStateMachine.state ==
	musicStateMachine.STATE.PAUSE then
		if isCellDungeon(e.cell) then
			musicStateMachine:stateDungeon()
		end
	elseif musicStateMachine.state == musicStateMachine.STATE.COMBAT or musicStateMachine.state ==
	musicStateMachine.STATE.OTHER then
		if isCellDungeon(e.cell) then
			musicStateMachine:stateDungeon()
		elseif config.enablePause then
			musicStateMachine:statePause()
		else
			musicStateMachine:stateExplore()
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
	if musicStateMachine.state == musicStateMachine.STATE.COMBAT and not tes3.mobilePlayer.inCombat then
		if isCellDungeon(tes3.player.cell) then
			musicStateMachine:stateDungeon()
		elseif config.enablePause then
			musicStateMachine:statePause()
		else
			musicStateMachine:stateExplore()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	print("[Music Tweaks: DEBUG] musicChangeTrackCallback called with e.context = " .. e.context .. ", state: " ..
	      musicStateMachine.state)

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

	print("[Music Tweaks: INFO] Music Tweaks initialized")
end

event.register(tes3.event.initialized, initialized)

dofile("Music Tweaks.mcm")
