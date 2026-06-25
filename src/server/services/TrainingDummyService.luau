--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ChampionService = require(script.Parent.ChampionService)
local Utility = require(script.Parent.Utility)

local TrainingDummyService = {}
local started = false

type DummyDefinition = {
	unitType: string,
	maxHealth: number,
	isEnemy: boolean,
}

local DUMMY_DEFINITIONS: { [string]: DummyDefinition } = {
	EnemyChampion = {
		unitType = "Champion",
		maxHealth = 1000,
		isEnemy = true,
	},
	AllyChampion = {
		unitType = "Champion",
		maxHealth = 1000,
		isEnemy = false,
	},
	EnemyMinion = {
		unitType = "Minion",
		maxHealth = 400,
		isEnemy = true,
	},
	AllyMinion = {
		unitType = "Minion",
		maxHealth = 400,
		isEnemy = false,
	},
}

local function getOppositeTeam(teamName: string): string
	if teamName == SharedConstants.TEAMS.BLUE then
		return SharedConstants.TEAMS.RED
	end
	return SharedConstants.TEAMS.BLUE
end

local function getUnitsFolder(): Folder?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		units = Instance.new("Folder")
		units.Name = "Units"
		units.Parent = Workspace
	end

	if not units:IsA("Folder") then
		warn("[MOBA][DUMMY] Workspace.Units must be a Folder")
		return nil
	end

	return units
end

local function getPlayerTeam(player: Player, champion: Model): string
	local championTeam = champion:GetAttribute("Team")
	if typeof(championTeam) == "string" then
		return championTeam
	end

	local playerTeam = player:GetAttribute("Team")
	if typeof(playerTeam) == "string" then
		return playerTeam
	end

	return SharedConstants.TEAMS.BLUE
end

local function createSpawnCFrame(championRoot: BasePart): CFrame
	local lookVector = championRoot.CFrame.LookVector
	local spawnPosition = championRoot.Position + lookVector * 12
	spawnPosition = Vector3.new(spawnPosition.X, championRoot.Position.Y, spawnPosition.Z)

	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude < 0.001 then
		flatLook = Vector3.new(0, 0, -1)
	end

	return CFrame.lookAt(spawnPosition, spawnPosition + flatLook.Unit)
end

local function createDummyModel(dummyKind: string, definition: DummyDefinition, teamName: string, spawnCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "TrainingDummy_" .. dummyKind

	local color = if definition.isEnemy
		then Color3.fromRGB(239, 71, 78)
		else Color3.fromRGB(65, 190, 140)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = true
	root.Position = spawnCFrame.Position
	root.CFrame = spawnCFrame
	root.Color = color
	root.Material = Enum.Material.SmoothPlastic
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = spawnCFrame + Vector3.new(0, 2, 0)
	head.Color = color:Lerp(Color3.new(1, 1, 1), 0.25)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = definition.maxHealth
	humanoid.Health = definition.maxHealth
	humanoid.WalkSpeed = 0
	humanoid.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("IsTrainingDummy", true)
	model:SetAttribute("NoRewards", true)
	model:SetAttribute("Dead", false)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("AttackDamage", 0)
	model:SetAttribute("AttackRange", 0)
	model:SetAttribute("AttackCooldown", 999)
	model:SetAttribute("MoveSpeed", 0)
	model:SetAttribute("UnitType", definition.unitType)
	model:SetAttribute("Team", teamName)
	model:SetAttribute("MaxHealth", definition.maxHealth)
	model:SetAttribute("Health", definition.maxHealth)
	model:SetAttribute("GoldReward", 0)
	model:SetAttribute("XPReward", 0)

	return model
end

function TrainingDummyService.spawnDummy(player: Player, dummyKind: string): (boolean, string)
	local definition = DUMMY_DEFINITIONS[dummyKind]
	if not definition then
		return false, "Invalid dummy kind"
	end

	local units = getUnitsFolder()
	if not units then
		return false, "Units folder unavailable"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	local championRoot = Utility.getRoot(champion)
	if not championRoot then
		return false, "Champion root not found"
	end

	local playerTeam = getPlayerTeam(player, champion)
	local dummyTeam = if definition.isEnemy then getOppositeTeam(playerTeam) else playerTeam
	local dummy = createDummyModel(dummyKind, definition, dummyTeam, createSpawnCFrame(championRoot))
	dummy.Parent = units
	Utility.attachHealthBar(dummy)

	print(string.format("[MOBA][DUMMY] Spawned %s dummy for %s", dummyKind, player.Name))
	return true, "Spawned"
end

function TrainingDummyService.clearDummies(player: Player): (boolean, string)
	local units = getUnitsFolder()
	if not units then
		return false, "Units folder unavailable"
	end

	for _, unit in units:GetChildren() do
		if unit:IsA("Model") and unit:GetAttribute("IsTrainingDummy") == true then
			unit:Destroy()
		end
	end

	print(string.format("[MOBA][DUMMY] Cleared training dummies for %s", player.Name))
	return true, "Cleared"
end

function TrainingDummyService.start()
	if started then
		return
	end
	started = true

	getUnitsFolder()
	print("[MOBA][DUMMY] TrainingDummyService started")
end

return TrainingDummyService
