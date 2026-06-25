--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ChampionData = require(ReplicatedStorage.Modules.ChampionData)
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local Utility = require(script.Parent.Utility)
local EconomyProgressionService = require(script.Parent.EconomyProgressionService)
local ChampionService = {}

local function getSpawnForTeam(teamName: string): BasePart?
	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[MOBA] Workspace.Map manquant : impossible de placer les champions.")
		return nil
	end
	local playerSpawns = map:FindFirstChild("PlayerSpawns")
	if not playerSpawns then
		warn("[MOBA] Workspace.Map.PlayerSpawns manquant.")
		return nil
	end
	local spawn = playerSpawns:FindFirstChild(teamName)
	if spawn and spawn:IsA("BasePart") then
		return spawn
	end
	warn("[MOBA] Spawn joueur manquant pour l'équipe", teamName)
	return nil
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		root = character:WaitForChild("HumanoidRootPart", 10)
	end
	if not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then
		warn("[MOBA] Champion incomplet pour", player.Name)
		return
	end

	local selectedChampionId = player:GetAttribute("SelectedChampionId")
	local data = ChampionData.getChampion(if typeof(selectedChampionId) == "string" then selectedChampionId else nil)
	if selectedChampionId ~= data.Id then
		player:SetAttribute("SelectedChampionId", data.Id)
	end

	local teamName = player:GetAttribute("Team")
	if typeof(teamName) ~= "string" then
		teamName = SharedConstants.TEAMS.BLUE
		player:SetAttribute("Team", teamName)
	end

	character:SetAttribute("UnitType", "Champion")
	character:SetAttribute("OwnerUserId", player.UserId)
	character:SetAttribute("Team", teamName)
	character:SetAttribute("ChampionId", data.Id)
	character:SetAttribute("ChampionRole", data.Role)
	character:SetAttribute("MaxHealth", data.MaxHealth)
	character:SetAttribute("Health", data.MaxHealth)
	character:SetAttribute("AttackDamage", data.AttackDamage)
	character:SetAttribute("AttackRange", data.AttackRange)
	character:SetAttribute("AttackCooldown", data.AttackCooldown)
	character:SetAttribute("MoveSpeed", data.MoveSpeed)
	character:SetAttribute("InventoryCount", 0)
	character:SetAttribute("Dead", false)

	EconomyProgressionService.applyPlayerProgressionToChampion(player, character)

	local restoredMaxHealth = character:GetAttribute("MaxHealth")
	if typeof(restoredMaxHealth) == "number" then
		character:SetAttribute("Health", restoredMaxHealth)
	end

	local finalMaxHealth = character:GetAttribute("MaxHealth")
	if typeof(finalMaxHealth) ~= "number" then
		finalMaxHealth = data.MaxHealth
	end
	local finalMoveSpeed = character:GetAttribute("MoveSpeed")
	if typeof(finalMoveSpeed) ~= "number" then
		finalMoveSpeed = data.MoveSpeed
	end

	humanoid.WalkSpeed = finalMoveSpeed

	humanoid.MaxHealth = finalMaxHealth
	humanoid.Health = finalMaxHealth

	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		warn("[MOBA] Workspace.Units manquant : champion non enregistré.")
		return
	end
	character.Parent = units
	local spawn = getSpawnForTeam(teamName)
	if spawn then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
	Utility.attachHealthBar(character)
	print(string.format("[MOBA] %s spawned as %s", player.Name, data.DisplayName))

	local watchedAttributes = {
		"ChampionId",
		"ChampionRole",
		"Level",
		"Gold",
		"XP",
		"MaxHealth",
		"AttackDamage",
		"AttackRange",
		"AttackCooldown",
		"MoveSpeed",
		"InventoryCount",
		"InventorySlot1",
		"InventorySlot2",
		"InventorySlot3",
		"InventorySlot4",
		"InventorySlot5",
		"InventorySlot6",
	}

	for _, attributeName in watchedAttributes do
		character:GetAttributeChangedSignal(attributeName):Connect(function()
			print(string.format(
				"[MOBA][STATS] %s %s = %s",
				player.Name,
				attributeName,
				tostring(character:GetAttribute(attributeName))
			))
		end)
	end
end

local function initializePlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(setupCharacter, player, character)
	end)
	if player.Character then
		task.defer(setupCharacter, player, player.Character)
	end
end

function ChampionService.getChampionFromPlayer(player: Player): Model?
	local character = player.Character
	if character and character.Parent and character:GetAttribute("UnitType") == "Champion" then
		return character
	end
	local units = Workspace:FindFirstChild("Units")
	if units then
		for _, unit in units:GetChildren() do
			if unit:IsA("Model") and unit:GetAttribute("UnitType") == "Champion" and unit:GetAttribute("OwnerUserId") == player.UserId then
				return unit
			end
		end
	end
	return nil
end

function ChampionService.setSelectedChampion(player: Player, championId: string): (boolean, string)
	local targetData = ChampionData.Champions[championId]
	if not targetData then
		return false, "Unknown champion"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	local shouldRespawn = champion ~= nil and champion:GetAttribute("Dead") ~= true
	if champion and shouldRespawn then
		EconomyProgressionService.saveChampionProgressionToPlayer(champion)

		local currentChampionId = champion:GetAttribute("ChampionId")
		local currentData = ChampionData.getChampion(
			if typeof(currentChampionId) == "string" then currentChampionId else nil
		)
		local currentMaxHealth = champion:GetAttribute("MaxHealth")
		local currentAttackDamage = champion:GetAttribute("AttackDamage")
		local maxHealthBonus = if typeof(currentMaxHealth) == "number"
			then currentMaxHealth - currentData.MaxHealth
			else 0
		local attackDamageBonus = if typeof(currentAttackDamage) == "number"
			then currentAttackDamage - currentData.AttackDamage
			else 0

		player:SetAttribute("ProgressionMaxHealth", math.max(1, targetData.MaxHealth + maxHealthBonus))
		player:SetAttribute("ProgressionAttackDamage", targetData.AttackDamage + attackDamageBonus)
	end

	player:SetAttribute("SelectedChampionId", championId)
	print(string.format("[MOBA] %s selected champion %s", player.Name, targetData.DisplayName))

	if shouldRespawn then
		player:LoadCharacter()
	end

	return true, "Selected"
end

function ChampionService.start()
	for _, player in Players:GetPlayers() do
		initializePlayer(player)
	end
	Players.PlayerAdded:Connect(initializePlayer)
end

return ChampionService
