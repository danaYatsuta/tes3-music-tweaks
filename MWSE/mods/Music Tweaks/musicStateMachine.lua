local config = require("Music Tweaks.config")
local constants = require("Music Tweaks.constants")

local STATE = { COMBAT = "combat", DUNGEON = "dungeon", EXPLORE = "explore", OTHER = "other", PAUSE = "pause" }
local VALID_STATES = {}

for _, musicState in pairs(STATE) do
	VALID_STATES[musicState] = true
end

-- --------------------------------- Fields --------------------------------- --

local MusicStateMachine = {
	-- Read-only both outside and within MusicStateMachine, used to expose possible states
	STATE = STATE,

	-- Read-only outside MusicStateMachine, writeable only in setState function within MusicStateMachine
	state = STATE.OTHER,

	-- Should not be accessed outside MusicStateMachine, writeable only in <stop,start>StateExploreTimer method within MusicStateMachine
	stateExploreTimer = nil,
}

-- ---------------------------- Private Functions --------------------------- --

-- Should only be called in <combat,dungeon...>State methods
local function setState(self, newState)
	if not VALID_STATES[newState] then
		return
	end

	tes3.messageBox("New music state: " .. newState)
	print("[Music Tweaks: DEBUG] New music state: " .. newState)
	self.state = newState
	print("[Music Tweaks: DEBUG] Now state is: " .. self.state)
end

local function stopStateExploreTimer(self)
	if self.stateExploreTimer then
		self.stateExploreTimer:cancel()
	end
end

local function startStateExploreTimer(self)
	stopStateExploreTimer(self)

	self.stateExploreTimer = timer.start({
		duration = math.random(config.minPause, config.maxPause),
		callback = function()
			self:stateExplore()
		end,
		type = timer.real,
	})
end

-- ---------------------------- Public Functions ---------------------------- --

function MusicStateMachine:new()
	local newMusicStateMachine = {}
	setmetatable(newMusicStateMachine, self)
	self.__index = self

	return newMusicStateMachine
end

function MusicStateMachine:stateCombat()
	setState(self, STATE.COMBAT)

	stopStateExploreTimer(self)
	tes3.skipToNextMusicTrack({ situation = tes3.musicSituation.combat, force = true })
end

function MusicStateMachine:stateDungeon()
	setState(self, STATE.DUNGEON)

	stopStateExploreTimer(self)
	tes3.worldController.audioController:changeMusicTrack(constants.SILENCE_FILEPATH)
end

function MusicStateMachine:stateExplore()
	setState(self, STATE.EXPLORE)

	tes3.skipToNextMusicTrack({ situation = tes3.musicSituation.explore, force = true })
end

function MusicStateMachine:stateOther()
	setState(self, STATE.OTHER)

	stopStateExploreTimer(self)
end

function MusicStateMachine:statePause()
	setState(self, STATE.PAUSE)

	tes3.worldController.audioController:changeMusicTrack(constants.SILENCE_FILEPATH)

	startStateExploreTimer(self)
end

return MusicStateMachine
