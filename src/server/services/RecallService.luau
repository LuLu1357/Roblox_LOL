--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ChampionService = require(script.Parent.ChampionService)
local CombatService = require(script.Parent.CombatService)

local RecallService = {}

type ActiveRecall = {
	Champion: Model,
	StartPosition: Vector3,
	StartedAt: number,
	ShopZone: BasePart,
}

local activeRecalls: { [Player]: ActiveRecall } = {}
local started = false

local function fireRecallState(player: Player, state: string, duration: number, reason: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes or not remotes:IsA("Folder") then
		return
	end

	local remote = remotes:FindFirstChild(SharedConstants.REMOTES.RECALL_STATE_UPDATE)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, state, duration, reason)
	end
end

function RecallService.cancelRecall(player: Player, reason: string)
	if not activeRecalls[player] then
		return
	end

	activeRecalls[player] = nil
	fireRecallState(player, "Canceled", 0, reason)
	print("[MOBA] " .. player.Name .. " recall canceled: " .. reason)
end

function RecallService.cancelRecallForChampion(champion: Model, reason: string)
	for player, recall in activeRecalls do
		if recall.Champion == champion then
			RecallService.cancelRecall(player, reason)
			return
		end
	end
end

function RecallService.startRecall(player: Player): (boolean, string)
	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	if champion:GetAttribute("Dead") == true then
		return false, "Champion is dead"
	end

	if activeRecalls[player] then
		return false, "Recall already active"
	end

	local root = champion:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false, "HumanoidRootPart not found"
	end

	local map = Workspace:FindFirstChild("Map")
	local shopZones = if map then map:FindFirstChild("ShopZones") else nil
	local teamName = player:GetAttribute("Team")
	if typeof(teamName) ~= "string" then
		return false, "Team not found"
	end

	local shopZoneName = teamName .. "Shop"
	local shopZone = if shopZones then shopZones:FindFirstChild(shopZoneName) else nil
	if not shopZone or not shopZone:IsA("BasePart") then
		return false, "Shop zone missing"
	end

	local recall: ActiveRecall = {
		Champion = champion,
		StartPosition = root.Position,
		StartedAt = os.clock(),
		ShopZone = shopZone,
	}
	activeRecalls[player] = recall

	local duration = SharedConstants.RECALL.DURATION
	local maxMoveDistance = SharedConstants.RECALL.MAX_MOVE_DISTANCE
	fireRecallState(player, "Started", duration, "")
	print("[MOBA] " .. player.Name .. " started recall")

	task.spawn(function()
		while os.clock() - recall.StartedAt < duration do
			task.wait(0.1)

			if activeRecalls[player] ~= recall then
				return
			end

			if champion:GetAttribute("Dead") == true then
				RecallService.cancelRecall(player, "Dead")
				return
			end

			local currentRoot = champion:FindFirstChild("HumanoidRootPart")
			if not currentRoot or not currentRoot:IsA("BasePart") then
				RecallService.cancelRecall(player, "HumanoidRootPart missing")
				return
			end

			local movedDistance = (currentRoot.Position - recall.StartPosition).Magnitude
			if movedDistance > maxMoveDistance then
				RecallService.cancelRecall(player, "Moved")
				return
			end
		end

		if activeRecalls[player] ~= recall then
			return
		end

		local currentRoot = champion:FindFirstChild("HumanoidRootPart")
		if not currentRoot or not currentRoot:IsA("BasePart") then
			RecallService.cancelRecall(player, "HumanoidRootPart missing")
			return
		end

		local finalShopZone = recall.ShopZone
		if not finalShopZone.Parent then
			RecallService.cancelRecall(player, "Shop zone missing")
			return
		end

		activeRecalls[player] = nil
		currentRoot.CFrame = finalShopZone.CFrame + Vector3.new(0, 5, 0)

		fireRecallState(player, "Completed", 0, "")
		print("[MOBA] " .. player.Name .. " completed recall")
	end)

	return true, "Started"
end

function RecallService.start()
	if started then
		return
	end
	started = true

	CombatService.onDamage(function(_attacker: Instance, target: Instance, damage: number)
		if damage <= 0 then
			return
		end

		if target:IsA("Model") and target:GetAttribute("UnitType") == "Champion" then
			RecallService.cancelRecallForChampion(target, "Damaged")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeRecalls[player] = nil
	end)

	print("[MOBA] RecallService started")
end

return RecallService
