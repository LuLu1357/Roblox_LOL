--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ChampionData = require(ReplicatedStorage.Modules.ChampionData)

local ChampionService = {}

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then
		return
	end

	local data = ChampionData.Default
	local teamName = player:GetAttribute("Team")
	if typeof(teamName) ~= "string" then
		teamName = "Blue"
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

	local units = Workspace:WaitForChild("Units")
	character.Parent = units
	local map = Workspace:FindFirstChild("Map")
	local playerSpawns = map and map:FindFirstChild("PlayerSpawns")
	local spawn = playerSpawns and playerSpawns:FindFirstChild(teamName)
	if spawn and spawn:IsA("BasePart") then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
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
	if character and character:GetAttribute("UnitType") == "Champion" then
		return character
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
