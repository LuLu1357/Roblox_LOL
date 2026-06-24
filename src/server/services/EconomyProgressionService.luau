--!strict

local EconomyProgressionService = {}
local Players = game:GetService("Players")

local MAX_LEVEL = 18

local DEFAULT_REWARDS = {
	Minion = {
		Gold = 20,
		XP = 30,
	},

	JungleMonster = {
		Gold = 35,
		XP = 45,
	},

	Champion = {
		Gold = 300,
		XP = 150,
	},

	Tower = {
		Gold = 150,
		XP = 0,
	},

	Inhibitor = {
		Gold = 0,
		XP = 0,
	},

	Nexus = {
		Gold = 0,
		XP = 0,
	},
}

local function getUnitType(unit: Instance): string?
	local unitType = unit:GetAttribute("UnitType")
	return if typeof(unitType) == "string" then unitType else nil
end

local function getNumberAttribute(unit: Instance, name: string, fallback: number): number
	local value = unit:GetAttribute(name)
	return if typeof(value) == "number" then value else fallback
end

local function isChampion(unit: Instance): boolean
	return getUnitType(unit) == "Champion"
end

local function getXPNeededForNextLevel(level: number): number
	return level * 100
end

function EconomyProgressionService.ensureChampionProgression(champion: Instance)
	if not isChampion(champion) then
		return
	end

	if typeof(champion:GetAttribute("Gold")) ~= "number" then
		champion:SetAttribute("Gold", 0)
	end

	if typeof(champion:GetAttribute("XP")) ~= "number" then
		champion:SetAttribute("XP", 0)
	end

	if typeof(champion:GetAttribute("Level")) ~= "number" then
		champion:SetAttribute("Level", 1)
	end
end

function EconomyProgressionService.tryLevelUp(champion: Instance)
	if not isChampion(champion) then
		return
	end

	EconomyProgressionService.ensureChampionProgression(champion)

	local level = getNumberAttribute(champion, "Level", 1)
	local xp = getNumberAttribute(champion, "XP", 0)

	while level < MAX_LEVEL do
		local needed = getXPNeededForNextLevel(level)

		if xp < needed then
			break
		end

		xp -= needed
		level += 1

		local maxHealth = getNumberAttribute(champion, "MaxHealth", 650)
		local health = getNumberAttribute(champion, "Health", maxHealth)
		local attackDamage = getNumberAttribute(champion, "AttackDamage", 35)

		champion:SetAttribute("MaxHealth", maxHealth + 60)
		champion:SetAttribute("Health", health + 60)
		champion:SetAttribute("AttackDamage", attackDamage + 4)

		print(string.format("[MOBA] %s reached level %d", champion.Name, level))
	end

	champion:SetAttribute("Level", level)
	champion:SetAttribute("XP", xp)
end

function EconomyProgressionService.awardKillRewards(killer: Instance, killed: Instance)
	if not isChampion(killer) then
		return
	end

	EconomyProgressionService.ensureChampionProgression(killer)

	local killedType = getUnitType(killed)
	if not killedType then
		return
	end

	local defaultReward = DEFAULT_REWARDS[killedType]
	if not defaultReward then
		return
	end

	local goldReward = getNumberAttribute(killed, "GoldReward", defaultReward.Gold)
	local xpReward = getNumberAttribute(killed, "XPReward", defaultReward.XP)

	local currentGold = getNumberAttribute(killer, "Gold", 0)
	local currentXP = getNumberAttribute(killer, "XP", 0)

	killer:SetAttribute("Gold", currentGold + goldReward)
	killer:SetAttribute("XP", currentXP + xpReward)

	if goldReward > 0 or xpReward > 0 then
		print(string.format(
			"[MOBA] %s gained %d gold and %d XP from %s",
			killer.Name,
			goldReward,
			xpReward,
			killed.Name
		))
	end

	EconomyProgressionService.tryLevelUp(killer)
end
function EconomyProgressionService.saveChampionProgressionToPlayer(champion: Instance)
	local ownerUserId = champion:GetAttribute("OwnerUserId")
	if typeof(ownerUserId) ~= "number" then
		return
	end

	for _, player in Players:GetPlayers() do
		if player.UserId == ownerUserId then
			player:SetAttribute("Gold", champion:GetAttribute("Gold") or 0)
			player:SetAttribute("XP", champion:GetAttribute("XP") or 0)
			player:SetAttribute("Level", champion:GetAttribute("Level") or 1)
			player:SetAttribute("ProgressionMaxHealth", champion:GetAttribute("MaxHealth") or 650)
			player:SetAttribute("ProgressionAttackDamage", champion:GetAttribute("AttackDamage") or 35)
			return
		end
	end
end

function EconomyProgressionService.applyPlayerProgressionToChampion(player: Player, champion: Instance)
	local gold = player:GetAttribute("Gold")
	local xp = player:GetAttribute("XP")
	local level = player:GetAttribute("Level")
	local maxHealth = player:GetAttribute("ProgressionMaxHealth")
	local attackDamage = player:GetAttribute("ProgressionAttackDamage")

	champion:SetAttribute("Gold", if typeof(gold) == "number" then gold else 0)
	champion:SetAttribute("XP", if typeof(xp) == "number" then xp else 0)
	champion:SetAttribute("Level", if typeof(level) == "number" then level else 1)

	if typeof(maxHealth) == "number" then
		champion:SetAttribute("MaxHealth", maxHealth)
	end

	if typeof(attackDamage) == "number" then
		champion:SetAttribute("AttackDamage", attackDamage)
	end
end
function EconomyProgressionService.start()
	print("[MOBA] EconomyProgressionService started")
end

return EconomyProgressionService