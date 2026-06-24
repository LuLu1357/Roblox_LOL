--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ChampionData = require(ReplicatedStorage.Modules.ChampionData)
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local Utility = require(script.Parent.Utility)

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

	local data = ChampionData.Default
	local teamName = player:GetAttribute("Team")
	if typeof(teamName) ~= "string" then
		teamName = SharedConstants.TEAMS.BLUE
		player:SetAttribute("Team", teamName)
	end

	character:SetAttribute("UnitType", "Champion")
	character:SetAttribute("OwnerUserId", player.UserId)
	character:SetAttribute("Team", teamName)
	character:SetAttribute("MaxHealth", data.MaxHealth)
	character:SetAttribute("Health", data.MaxHealth)
	character:SetAttribute("AttackDamage", data.AttackDamage)
	character:SetAttribute("AttackRange", data.AttackRange)
	character:SetAttribute("AttackCooldown", data.AttackCooldown)
	character:SetAttribute("MoveSpeed", data.MoveSpeed)
	character:SetAttribute("Dead", false)

	humanoid.WalkSpeed = data.MoveSpeed
	humanoid.MaxHealth = data.MaxHealth
	humanoid.Health = data.MaxHealth

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

function ChampionService.start()
	for _, player in Players:GetPlayers() do
		initializePlayer(player)
	end
	Players.PlayerAdded:Connect(initializePlayer)
end

return ChampionService
