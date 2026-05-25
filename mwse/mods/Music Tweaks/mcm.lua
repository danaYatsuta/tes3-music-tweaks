local config = require("Music Tweaks.config")
local log = require("Music Tweaks.log")

local function validateMinPauseAndMaxPause()
	config.minPause = math.min(config.minPause, config.maxPause)
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Music Tweaks", config = config })
	template:saveOnClose("Music Tweaks", config)
	template:register()

	local page = template:createPage({ label = "Settings" })

	page:createYesNoButton({ label = "Enable pauses between Explore tracks", configKey = "enablePause" })
	page:createYesNoButton(
	{ label = "Enable no Combat music for weak enemies", configKey = "enableNoCombatForWeakEnemies" })
	page:createYesNoButton({ label = "Enable no Explore music in dungeons", configKey = "enableNoExploreInDungeons" })

	page:createSlider({
		label = "Minimal Pause",
		configKey = "minPause",
		min = 0,
		max = 300,
		callback = validateMinPauseAndMaxPause,
	})

	page:createSlider({
		label = "Maximal Pause",
		configKey = "maxPause",
		min = 1,
		max = 300,
		callback = validateMinPauseAndMaxPause,
	})

	page:createLogLevelOptions({ configKey = "logLevel", logger = log })
end

event.register(tes3.event.modConfigReady, registerModConfig)
