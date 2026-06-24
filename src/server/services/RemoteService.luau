--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ShopService = require(script.Parent.ShopService)


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

	local shopBuyRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_BUY_REQUEST)
	local shopSellRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_SELL_REQUEST)
	local shopCraftRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_CRAFT_REQUEST)
	local debugAddGoldRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.DEBUG_ADD_GOLD_REQUEST)
	debugAddGoldRequest.OnServerEvent:Connect(function(player)
		local debugConfig = SharedConstants.DEBUG
		if typeof(debugConfig) ~= "table" or debugConfig.ALLOW_DEBUG_GOLD ~= true then
			warn("[MOBA] Debug gold refused:", player.Name)
			return
		end

		local champion = ChampionService.getChampionFromPlayer(player)
		if not champion then
			return
		end

		local amount = debugConfig.DEBUG_GOLD_AMOUNT
		if typeof(amount) ~= "number" then
			amount = 1000
		end

		local gold = champion:GetAttribute("Gold")
		if typeof(gold) ~= "number" then
			gold = 0
		end

		champion:SetAttribute("Gold", gold + amount)

		print(string.format(
			"[MOBA][DEBUG] Added %d gold to %s. New gold = %d",
			amount,
			player.Name,
			gold + amount
		))
	end)

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

	shopBuyRequest.OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) ~= "string" then
			return
		end

		local success, reason = ShopService.buyItem(player, itemId)
		if not success then
			warn("[MOBA] Shop buy failed:", player.Name, itemId, reason)
		end
	end)

	shopSellRequest.OnServerEvent:Connect(function(player, slotIndex)
		if typeof(slotIndex) ~= "number" then
			return
		end

		local success, reason = ShopService.sellItem(player, slotIndex)
		if not success then
			warn("[MOBA] Shop sell failed:", player.Name, slotIndex, reason)
		end
	end)

	shopCraftRequest.OnServerEvent:Connect(function(player, targetItemId)
		if typeof(targetItemId) ~= "string" then
			return
		end

		local success, reason = ShopService.craftItem(player, targetItemId)
		if not success then
			warn("[MOBA] Shop craft failed:", player.Name, targetItemId, reason)
		end
	end)
end

return RemoteService
