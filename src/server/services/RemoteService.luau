--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ChampionService = require(script.Parent.ChampionService)
local CombatService = require(script.Parent.CombatService)

local RemoteService = {}
local started = false

local function getOrCreateRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if existing then
		warn("[MOBA] ReplicatedStorage.Remotes." .. name .. " existe mais n'est pas un RemoteEvent, remplacement.")
		existing.Parent = nil
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function RemoteService.start()
	if started then
		return
	end
	started = true

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	assert(remotes:IsA("Folder"), "ReplicatedStorage.Remotes must be a Folder")

	local attackRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.AUTO_ATTACK_REQUEST)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.COMBAT_FEEDBACK)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.VISION_UPDATE)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.MATCH_STATE_UPDATE)

	attackRequest.OnServerEvent:Connect(function(player, target)
		if typeof(target) ~= "Instance" then
			return
		end
		local units = Workspace:FindFirstChild("Units")
		if not units or not units:IsA("Folder") or not target:IsDescendantOf(units) then
			return
		end
		local champion = ChampionService.getChampionFromPlayer(player)
		if not champion then
			return
		end
		CombatService.tryAutoAttack(champion, target, player)
	end)
end

return RemoteService
