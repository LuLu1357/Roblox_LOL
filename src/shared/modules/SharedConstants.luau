--!strict

local SharedConstants = {}

SharedConstants.TEAMS = {
	BLUE = "Blue",
	RED = "Red",
}

SharedConstants.MATCH = {
	MAX_PLAYERS_PER_TEAM = 5,
	MIN_PLAYERS_TO_START = 1,
	RESPAWN_TIME = 8,
	MINION_WAVE_INTERVAL = 30,
}

SharedConstants.LANES = {
	TOP = "Top",
	MID = "Mid",
	BOT = "Bot",
}

SharedConstants.COMBAT = {
	AUTO_ATTACK_RANGE = 18,
	AUTO_ATTACK_COOLDOWN = 1.1,
	BASE_ATTACK_DAMAGE = 35,
	TARGET_SEARCH_RADIUS = 32,
}

SharedConstants.VISION = {
	PLAYER_RADIUS = 80,
	MINION_RADIUS = 45,
	TOWER_RADIUS = 110,
	JUNGLE_MONSTER_RADIUS = 30,
	UPDATE_INTERVAL = 0.25,
}

SharedConstants.MOVEMENT = {
	BASE_WALK_SPEED = 18,
	SPRINT_DISABLED_FOR_NOW = true,
}

SharedConstants.JUNGLE = {
	RESPAWN_TIME_SMALL = 65,
	RESPAWN_TIME_BIG = 120,
}

SharedConstants.REMOTES = {
	AUTO_ATTACK_REQUEST = "AutoAttackRequest",
	COMBAT_FEEDBACK = "CombatFeedback",
	VISION_UPDATE = "VisionUpdate",
	MATCH_STATE_UPDATE = "MatchStateUpdate",
	SHOP_BUY_REQUEST = "ShopBuyRequest",
	DEBUG_ADD_GOLD_REQUEST = "DebugAddGoldRequest",
}
SharedConstants.DEBUG = {
	GAME_SPEED = 3,

	SPAWN_BLUE_MINIONS = true,
	SPAWN_RED_MINIONS = true,

	ALLOW_DEBUG_GOLD = true,
	DEBUG_GOLD_AMOUNT = 10000,
}
return SharedConstants
