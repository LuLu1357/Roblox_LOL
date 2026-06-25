--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AbilityData = require(ReplicatedStorage.Modules.AbilityData)
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ChampionService = require(script.Parent.ChampionService)
local CombatService = require(script.Parent.CombatService)
local Utility = require(script.Parent.Utility)

local AbilityService = {}
local cooldowns: { [Player]: { [number]: number } } = {}
local started = false

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isEnemy(attacker: Model, target: Model): boolean
	local attackerTeam = attacker:GetAttribute("Team")
	local targetTeam = target:GetAttribute("Team")
	return typeof(attackerTeam) == "string"
		and typeof(targetTeam) == "string"
		and attackerTeam ~= targetTeam
end

local function isValidEnemyTarget(attacker: Model, target: Instance): boolean
	if not target:IsA("Model") then
		return false
	end

	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") or not target:IsDescendantOf(units) then
		return false
	end

	if target:GetAttribute("Dead") == true then
		return false
	end

	local unitType = target:GetAttribute("UnitType")
	if unitType ~= "Champion" and unitType ~= "Minion" and unitType ~= "JungleMonster" then
		return false
	end

	return isEnemy(attacker, target)
end

local function findNearestEnemy(champion: Model, range: number): Model?
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		return nil
	end

	local root = getRoot(champion)
	if not root then
		return nil
	end

	local bestTarget: Model? = nil
	local bestDistance = range

	for _, candidate in units:GetChildren() do
		if candidate:IsA("Model") and isValidEnemyTarget(champion, candidate) then
			local targetRoot = getRoot(candidate)
			if targetRoot then
				local distance = (targetRoot.Position - root.Position).Magnitude
				if distance <= bestDistance then
					bestDistance = distance
					bestTarget = candidate
				end
			end
		end
	end

	return bestTarget
end

local function getTargetInRange(champion: Model, optionalTarget: Instance?, range: number): Model?
	local root = getRoot(champion)
	if not root then
		return nil
	end

	if optionalTarget and isValidEnemyTarget(champion, optionalTarget) and optionalTarget:IsA("Model") then
		local targetRoot = getRoot(optionalTarget)
		if targetRoot and (targetRoot.Position - root.Position).Magnitude <= range then
			return optionalTarget
		end
	end

	return findNearestEnemy(champion, range)
end

local function getHealthPercent(target: Model): number
	local health = target:GetAttribute("Health")
	local maxHealth = target:GetAttribute("MaxHealth")

	if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" or maxHealth <= 0 then
		return 1
	end

	return math.clamp(health / maxHealth, 0, 1)
end

local function findEnemiesInRadius(champion: Model, centerPosition: Vector3, radius: number): { Model }
	local results: { Model } = {}
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		return results
	end

	for _, candidate in units:GetChildren() do
		if candidate:IsA("Model") and isValidEnemyTarget(champion, candidate) then
			local targetRoot = getRoot(candidate)
			if targetRoot and (targetRoot.Position - centerPosition).Magnitude <= radius then
				table.insert(results, candidate)
			end
		end
	end

	return results
end

local function isAlly(champion: Model, target: Model): boolean
	local championTeam = champion:GetAttribute("Team")
	local targetTeam = target:GetAttribute("Team")

	return typeof(championTeam) == "string"
		and typeof(targetTeam) == "string"
		and championTeam == targetTeam
end

local function findNearestWoundedAlly(champion: Model, range: number): Model?
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		return nil
	end

	local root = getRoot(champion)
	if not root then
		return nil
	end

	local bestTarget: Model? = nil
	local bestDistance = range

	for _, candidate in units:GetChildren() do
		if candidate:IsA("Model") and candidate:GetAttribute("Dead") ~= true then
			local unitType = candidate:GetAttribute("UnitType")
			if unitType == "Champion" and isAlly(champion, candidate) then
				local health = candidate:GetAttribute("Health")
				local maxHealth = candidate:GetAttribute("MaxHealth")
				local targetRoot = getRoot(candidate)

				if typeof(health) == "number"
					and typeof(maxHealth) == "number"
					and health < maxHealth
					and targetRoot
				then
					local distance = (targetRoot.Position - root.Position).Magnitude
					if distance <= bestDistance then
						bestDistance = distance
						bestTarget = candidate
					end
				end
			end
		end
	end

	return bestTarget
end

local function healModel(target: Model, amount: number): number
	local health = target:GetAttribute("Health")
	local maxHealth = target:GetAttribute("MaxHealth")

	if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" or maxHealth <= 0 then
		return 0
	end

	local newHealth = math.min(maxHealth, health + amount)
	local healed = newHealth - health

	if healed <= 0 then
		return 0
	end

	Utility.setHealth(target, newHealth)

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = newHealth
	end

	return healed
end

local function fireAbilityFeedback(player: Player, displayName: string, slot: number, cooldown: number)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes or not remotes:IsA("Folder") then
		return
	end

	local remote = remotes:FindFirstChild(SharedConstants.REMOTES.ABILITY_FEEDBACK)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, "Cast", displayName, slot, cooldown)
	end
end

function AbilityService.castAbility(player: Player, slot: number, optionalTarget: Instance?): (boolean, string)
	if slot < 1 or slot > 4 or slot % 1 ~= 0 then
		return false, "Invalid slot"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	if champion:GetAttribute("Dead") == true then
		return false, "Champion is dead"
	end

	local championId = champion:GetAttribute("ChampionId")
	if typeof(championId) ~= "string" then
		return false, "ChampionId not found"
	end

	local spell = AbilityData.getSpell(championId, slot)
	if not spell then
		return false, "Ability not found"
	end

	local cooldown = spell.Cooldown
	if typeof(cooldown) ~= "number" or cooldown < 0 then
		return false, "Invalid cooldown"
	end

	local playerCooldowns = cooldowns[player]
	if not playerCooldowns then
		playerCooldowns = {}
		cooldowns[player] = playerCooldowns
	end

	local now = os.clock()
	local readyAt = playerCooldowns[slot] or 0
	if now < readyAt then
		return false, "On cooldown"
	end

	local abilityType = spell.Type
	if abilityType == "SelfHeal" then
		local health = champion:GetAttribute("Health")
		local maxHealth = champion:GetAttribute("MaxHealth")
		local heal = spell.Heal
		if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" or typeof(heal) ~= "number" then
			return false, "Invalid heal data"
		end

		local newHealth = math.min(maxHealth, health + heal)
		if newHealth <= health then
			return false, "Already full health"
		end

		Utility.setHealth(champion, newHealth)
		print(string.format("[MOBA][ABILITY] %s cast %s for %d", player.Name, spell.DisplayName, newHealth - health))
	elseif abilityType == "MeleeDamage" or abilityType == "RangedDamage" or abilityType == "DashDamage" then
		local range = spell.Range
		local damage = spell.Damage
		if typeof(range) ~= "number" or range <= 0 or typeof(damage) ~= "number" or damage <= 0 then
			return false, "Invalid damage data"
		end

		local maxSearchRadius = SharedConstants.ABILITIES.MAX_TARGET_SEARCH_RADIUS
		if typeof(maxSearchRadius) == "number" then
			range = math.min(range, maxSearchRadius)
		end

		local target = getTargetInRange(champion, optionalTarget, range)
		if not target then
			return false, "No target"
		end

		if abilityType == "DashDamage" then
			local root = getRoot(champion)
			local targetRoot = getRoot(target)
			local dashOffset = spell.DashOffset
			if not root or not targetRoot or typeof(dashOffset) ~= "number" then
				return false, "Dash unavailable"
			end

			root.CFrame = targetRoot.CFrame + (-targetRoot.CFrame.LookVector * dashOffset)
		end

		CombatService.applyDamage(champion, target, damage)
		print(string.format(
			"[MOBA][ABILITY] %s cast %s on %s for %d",
			player.Name,
			spell.DisplayName,
			target.Name,
			damage
		))
	elseif abilityType == "AoEDamage" then
		local radius = spell.Radius
		local damage = spell.Damage
		if typeof(radius) ~= "number" or radius <= 0 or typeof(damage) ~= "number" or damage <= 0 then
			return false, "Invalid AoE data"
		end

		local root = getRoot(champion)
		if not root then
			return false, "Champion root missing"
		end

		local targets = findEnemiesInRadius(champion, root.Position, radius)
		if #targets == 0 then
			return false, "No target"
		end

		for _, target in targets do
			CombatService.applyDamage(champion, target, damage)
		end

		print(string.format(
			"[MOBA][ABILITY] %s cast %s hitting %d targets",
			player.Name,
			spell.DisplayName,
			#targets
		))
	elseif abilityType == "AoEDamageAtTarget" then
		local range = spell.Range
		local radius = spell.Radius
		local damage = spell.Damage
		if typeof(range) ~= "number" or range <= 0 or typeof(radius) ~= "number" or radius <= 0
			or typeof(damage) ~= "number" or damage <= 0 then
			return false, "Invalid AoE target data"
		end

		local maxSearchRadius = SharedConstants.ABILITIES.MAX_TARGET_SEARCH_RADIUS
		if typeof(maxSearchRadius) == "number" then
			range = math.min(range, maxSearchRadius)
		end

		local target = getTargetInRange(champion, optionalTarget, range)
		if not target then
			return false, "No target"
		end

		local targetRoot = getRoot(target)
		if not targetRoot then
			return false, "Target root missing"
		end

		local targets = findEnemiesInRadius(champion, targetRoot.Position, radius)
		if #targets == 0 then
			return false, "No target"
		end

		for _, enemy in targets do
			CombatService.applyDamage(champion, enemy, damage)
		end

		print(string.format(
			"[MOBA][ABILITY] %s cast %s hitting %d targets",
			player.Name,
			spell.DisplayName,
			#targets
		))
	elseif abilityType == "DashForward" then
		local dashDistance = spell.DashDistance
		if typeof(dashDistance) ~= "number" or dashDistance <= 0 then
			return false, "Invalid dash data"
		end

		local root = getRoot(champion)
		if not root then
			return false, "Champion root missing"
		end

		root.CFrame = root.CFrame + root.CFrame.LookVector * dashDistance
		print(string.format(
			"[MOBA][ABILITY] %s cast %s",
			player.Name,
			spell.DisplayName
		))
	elseif abilityType == "TemporaryMaxHealth" then
		local maxHealthBonus = spell.MaxHealthBonus
		local duration = spell.Duration
		if typeof(maxHealthBonus) ~= "number" or maxHealthBonus <= 0 or typeof(duration) ~= "number" or duration <= 0 then
			return false, "Invalid buff data"
		end

		local health = champion:GetAttribute("Health")
		local maxHealth = champion:GetAttribute("MaxHealth")
		if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" then
			return false, "Invalid champion health"
		end

		local newMaxHealth = maxHealth + maxHealthBonus
		local newHealth = math.min(newMaxHealth, health + maxHealthBonus)
		champion:SetAttribute("MaxHealth", newMaxHealth)
		Utility.setHealth(champion, newHealth)

		print(string.format(
			"[MOBA][ABILITY] %s cast %s for %d bonus health",
			player.Name,
			spell.DisplayName,
			maxHealthBonus
		))

		task.delay(duration, function()
			local currentMax = champion:GetAttribute("MaxHealth")
			local currentHealth = champion:GetAttribute("Health")
			if typeof(currentMax) ~= "number" or typeof(currentHealth) ~= "number" then
				return
			end

			local reducedMaxHealth = math.max(1, currentMax - maxHealthBonus)
			champion:SetAttribute("MaxHealth", reducedMaxHealth)
			local finalHealth = math.max(1, math.min(currentHealth, reducedMaxHealth))
			Utility.setHealth(champion, finalHealth)
			print(string.format(
				"[MOBA][ABILITY] %s %s ended",
				player.Name,
				spell.DisplayName
			))
		end)
	elseif abilityType == "ExecuteDamage" then
		local range = spell.Range
		local damage = spell.Damage
		local executeBonus = spell.ExecuteBonusDamage
		local threshold = spell.ExecuteThreshold
		if typeof(range) ~= "number" or range <= 0 or typeof(damage) ~= "number" or damage <= 0
			or typeof(executeBonus) ~= "number" or executeBonus < 0 or typeof(threshold) ~= "number" then
			return false, "Invalid execute data"
		end

		local maxSearchRadius = SharedConstants.ABILITIES.MAX_TARGET_SEARCH_RADIUS
		if typeof(maxSearchRadius) == "number" then
			range = math.min(range, maxSearchRadius)
		end

		local target = getTargetInRange(champion, optionalTarget, range)
		if not target then
			return false, "No target"
		end

		local damageFinal = damage
		if getHealthPercent(target) <= threshold then
			damageFinal = damageFinal + executeBonus
		end

		CombatService.applyDamage(champion, target, damageFinal)
		print(string.format(
			"[MOBA][ABILITY] %s cast %s on %s for %d",
			player.Name,
			spell.DisplayName,
			target.Name,
			damageFinal
		))
	elseif abilityType == "AllyOrSelfHeal" then
		local range = spell.Range
		local heal = spell.Heal
		if typeof(range) ~= "number" or range <= 0 or typeof(heal) ~= "number" or heal <= 0 then
			return false, "Invalid heal data"
		end

		local target = findNearestWoundedAlly(champion, range)
		if not target then
			target = champion
		end

		local healed = healModel(target, heal)
		if healed <= 0 then
			return false, "Already full health"
		end

		local targetName = if target == champion then "self" else target.Name
		print(string.format(
			"[MOBA][ABILITY] %s cast %s on %s for %d",
			player.Name,
			spell.DisplayName,
			targetName,
			healed
		))
	elseif abilityType == "TeamHeal" then
		local radius = spell.Radius
		local heal = spell.Heal
		if typeof(radius) ~= "number" or radius <= 0 or typeof(heal) ~= "number" or heal <= 0 then
			return false, "Invalid heal data"
		end

		local root = getRoot(champion)
		if not root then
			return false, "Champion root missing"
		end

		local units = Workspace:FindFirstChild("Units")
		if not units or not units:IsA("Folder") then
			return false, "Units missing"
		end

		local totalHealed = 0
		local healedCount = 0

		for _, candidate in units:GetChildren() do
			if candidate:IsA("Model") and candidate:GetAttribute("UnitType") == "Champion"
				and candidate:GetAttribute("Dead") ~= true and isAlly(champion, candidate)
			then
				local candidateRoot = getRoot(candidate)
				if candidateRoot and (candidateRoot.Position - root.Position).Magnitude <= radius then
					local healed = healModel(candidate, heal)
					if healed > 0 then
						healedCount += 1
						totalHealed += healed
					end
				end
			end
		end

		if totalHealed <= 0 then
			return false, "Already full health"
		end

		print(string.format(
			"[MOBA][ABILITY] %s cast %s healing %d targets for %d total",
			player.Name,
			spell.DisplayName,
			healedCount,
			totalHealed
		))
	else
		return false, "Unsupported ability type"
	end

	playerCooldowns[slot] = now + cooldown
	fireAbilityFeedback(player, spell.DisplayName, slot, cooldown)
	return true, "Cast"
end

function AbilityService.start()
	if started then
		return
	end
	started = true

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)

	print("[MOBA] AbilityService started")
end

return AbilityService
