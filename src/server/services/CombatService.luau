--!strict
local EconomyProgressionService = require(script.Parent.EconomyProgressionService)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local Utility = require(script.Parent.Utility)
local VisionService = require(script.Parent.VisionService)

local CombatService = {}
local lastAttackByUnit = setmetatable({}, { __mode = "k" })

type DamageListener = (Instance, Instance, number) -> ()
local damageListeners: { DamageListener } = {}

function CombatService.onDamage(listener: DamageListener)
	table.insert(damageListeners, listener)
end

local function emitDamage(attacker: Instance, target: Instance, damage: number)
	for _, listener in damageListeners do
		task.spawn(listener, attacker, target, damage)
	end
end

local championAggroEvent = ServerStorage:FindFirstChild("MobaChampionAggro")
if not championAggroEvent or not championAggroEvent:IsA("BindableEvent") then
	if championAggroEvent then
		championAggroEvent:Destroy()
	end
	championAggroEvent = Instance.new("BindableEvent")
	championAggroEvent.Name = "MobaChampionAggro"
	championAggroEvent.Parent = ServerStorage
end

local VALID_ATTACKERS = {
	Champion = true,
	Minion = true,
	Tower = true,
	JungleMonster = true,
}

local VALID_TARGETS = {
	Champion = true,
	Minion = true,
	Tower = true,
	JungleMonster = true,
	Nexus = true,
	Inhibitor = true,
}

local function emitCombatFeedback(attacker: Instance, target: Instance, damage: number)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(SharedConstants.REMOTES.COMBAT_FEEDBACK)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireAllClients(attacker, target, damage)
	end
end

local function getNumberAttribute(unit: Instance, name: string, fallback: number): number
	local value = unit:GetAttribute(name)
	return if typeof(value) == "number" then value else fallback
end

local function getUnitType(unit: Instance): string?
	local unitType = unit:GetAttribute("UnitType")
	return if typeof(unitType) == "string" then unitType else nil
end

local function getGameSpeed(): number
	local debugConfig = SharedConstants.DEBUG
	if typeof(debugConfig) ~= "table" then
		return 1
	end

	local speed = debugConfig.GAME_SPEED
	if typeof(speed) ~= "number" or speed <= 0 then
		return 1
	end

	return speed
end

local function getPlayerFromChampion(champion: Instance): Player?
	if not champion or not champion:IsA("Model") then
		return nil
	end

	local ownerUserId = champion:GetAttribute("OwnerUserId")
	if typeof(ownerUserId) ~= "number" then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == ownerUserId then
			return player
		end
	end

	return nil
end

local function canAttack(attacker: Instance, target: Instance, player: Player?): (boolean, string)
	local attackerType = getUnitType(attacker)
	local targetType = getUnitType(target)
	if not attackerType or not VALID_ATTACKERS[attackerType] then
		return false, "Invalid attacker type"
	end
	if not targetType or not VALID_TARGETS[targetType] then
		return false, "Invalid target type"
	end
	if player and attackerType ~= "Champion" then
		return false, "Player can only command champion attacks"
	end
	if player then
		local ownerUserId = attacker:GetAttribute("OwnerUserId")
		if typeof(ownerUserId) ~= "number" or ownerUserId ~= player.UserId then
			return false, "Player does not own attacker"
		end
	end
	if not Utility.isAlive(attacker) then
		return false, "Attacker dead"
	end
	if not Utility.isAlive(target) then
		return false, "Target dead"
	end
	if not Utility.areEnemies(attacker, target) then
		return false, "Not enemies"
	end

	local range = getNumberAttribute(attacker, "AttackRange", SharedConstants.COMBAT.AUTO_ATTACK_RANGE)
	if Utility.distance(attacker, target) > range then
		return false, "Out of range"
	end

	local now = os.clock()
	local lastAttack = lastAttackByUnit[attacker] or 0
	local cooldown = getNumberAttribute(attacker, "AttackCooldown", SharedConstants.COMBAT.AUTO_ATTACK_COOLDOWN)
	if now - lastAttack < cooldown / getGameSpeed() then
		return false, "Attack cooldown"
	end

	if player and not VisionService.canPlayerSeeUnit(player, target) then
		return false, "Target not visible"
	end

	return true, "OK"
end

function CombatService.applyDamage(attacker: Instance, target: Instance, amount: number)
	local health = target:GetAttribute("Health")
	if typeof(health) ~= "number" then
		return
	end
	local damage = math.min(math.max(amount, 0), health)
	Utility.setHealth(target, health - damage)

	if damage > 0 then
		emitCombatFeedback(attacker, target, damage)
		emitDamage(attacker, target, damage)
	end
	if target:GetAttribute("Dead") == true then
		CombatService.handleDeath(attacker, target)
	end
end

function CombatService.handleDeath(killer: Instance, victim: Instance)
	local victimIsChampion = victim:GetAttribute("UnitType") == "Champion"
	local victimNoRewards = victim:GetAttribute("NoRewards") == true
	local victimTrainingDummy = victim:GetAttribute("IsTrainingDummy") == true

	if victimIsChampion and not victimNoRewards and not victimTrainingDummy then
		local victimPlayer = getPlayerFromChampion(victim)
		if victimPlayer then
			local deaths = getNumberAttribute(victimPlayer, "Deaths", 0)
			victimPlayer:SetAttribute("Deaths", deaths + 1)
		end
	end

	if killer and killer:GetAttribute("UnitType") == "Champion" and victimIsChampion then
		local killerTrainingDummy = killer:GetAttribute("IsTrainingDummy") == true
		local killerNoRewards = killer:GetAttribute("NoRewards") == true
		if not killerTrainingDummy and not killerNoRewards and not victimNoRewards and not victimTrainingDummy then
			local killerPlayer = getPlayerFromChampion(killer)
			local victimPlayer = getPlayerFromChampion(victim)
			if killerPlayer and killerPlayer ~= victimPlayer then
				local kills = getNumberAttribute(killerPlayer, "Kills", 0)
				killerPlayer:SetAttribute("Kills", kills + 1)
			end
		end
	end

	EconomyProgressionService.awardKillRewards(killer, victim)

	if victimIsChampion then
		EconomyProgressionService.saveChampionProgressionToPlayer(victim)
	end

	victim:SetAttribute("Dead", true)
	local root = Utility.getRoot(victim)
	if root then
		root.CanCollide = false
	end
	local humanoid = victim:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

function CombatService.tryAutoAttack(attacker: Instance, target: Instance, player: Player?): (boolean, string)
	local allowed, reason = canAttack(attacker, target, player)
	if not allowed then
		return false, reason
	end

	lastAttackByUnit[attacker] = os.clock()
	local damage = getNumberAttribute(attacker, "AttackDamage", SharedConstants.COMBAT.BASE_ATTACK_DAMAGE)
	CombatService.applyDamage(attacker, target, damage)
	if getUnitType(attacker) == "Champion" and getUnitType(target) == "Champion" then
		(championAggroEvent :: BindableEvent):Fire(attacker, target)
	end
	return true, "Attack success"
end

return CombatService
