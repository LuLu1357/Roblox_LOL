--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AbilityService = require(script.Parent.AbilityService)
local ShopService = require(script.Parent.ShopService)
local RecallService = require(script.Parent.RecallService)
local TrainingDummyService = require(script.Parent.TrainingDummyService)


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

local function getPlayerNumberAttribute(player: Player, attributeName: string, fallback: number): number
	local value = player:GetAttribute(attributeName)
	return if typeof(value) == "number" then value else fallback
end

local function resolveUnitTarget(instance: Instance?): Model?
	local units = Workspace:FindFirstChild("Units")
	if not instance or not units or not units:IsA("Folder") or not instance:IsDescendantOf(units) then
		return nil
	end

	local current: Instance? = instance
	while current and current ~= units do
		if current:IsA("Model") and typeof(current:GetAttribute("UnitType")) == "string" then
			return current
		end

		current = current.Parent
	end

	return nil
end

local function buildScoreboardEntry(player: Player): table
	local champion = ChampionService.getChampionFromPlayer(player)
	local championId = "None"
	if champion then
		local championAttr = champion:GetAttribute("ChampionId")
		if typeof(championAttr) == "string" and championAttr ~= "" then
			championId = championAttr
		end
	else
		local selectedChampionId = player:GetAttribute("SelectedChampionId")
		if typeof(selectedChampionId) == "string" and selectedChampionId ~= "" then
			championId = selectedChampionId
		end
	end

	local level = if champion
		then getPlayerNumberAttribute(champion, "Level", getPlayerNumberAttribute(player, "Level", 1))
		else getPlayerNumberAttribute(player, "Level", 1)
	local gold = if champion
		then getPlayerNumberAttribute(champion, "Gold", getPlayerNumberAttribute(player, "Gold", 0))
		else getPlayerNumberAttribute(player, "Gold", 0)
	local kills = getPlayerNumberAttribute(player, "Kills", 0)
	local deaths = getPlayerNumberAttribute(player, "Deaths", 0)
	local assists = getPlayerNumberAttribute(player, "Assists", 0)
	local cs = getPlayerNumberAttribute(player, "CS", 0)

	return {
		PlayerName = player.Name,
		ChampionId = championId,
		Level = level,
		Kills = kills,
		Deaths = deaths,
		Assists = assists,
		CS = cs,
		Gold = gold,
	}
end

local function containsPlayerEntry(entries: { table }, playerName: string): boolean
	for _, entry in ipairs(entries) do
		if entry.PlayerName == playerName then
			return true
		end
	end
	return false
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
	local abilityRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.ABILITY_REQUEST)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.ABILITY_FEEDBACK)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.ABILITY_VFX)
	local scoreboardRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SCOREBOARD_REQUEST)
	local scoreboardUpdate = getOrCreateRemote(remotes, SharedConstants.REMOTES.SCOREBOARD_UPDATE)
	local recallRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.RECALL_REQUEST)
	getOrCreateRemote(remotes, SharedConstants.REMOTES.RECALL_STATE_UPDATE)
	local selectChampionRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SELECT_CHAMPION_REQUEST)

	local shopBuyRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_BUY_REQUEST)
	local shopSellRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_SELL_REQUEST)
	local shopCraftRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.SHOP_CRAFT_REQUEST)
	local debugAddGoldRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.DEBUG_ADD_GOLD_REQUEST)
	local debugSpawnDummyRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.DEBUG_SPAWN_DUMMY_REQUEST)
	local debugClearDummiesRequest = getOrCreateRemote(remotes, SharedConstants.REMOTES.DEBUG_CLEAR_DUMMIES_REQUEST)
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

	debugSpawnDummyRequest.OnServerEvent:Connect(function(player, dummyKind)
		local debugConfig = SharedConstants.DEBUG
		if typeof(debugConfig) ~= "table" or debugConfig.ALLOW_TRAINING_DUMMIES ~= true then
			warn("[MOBA][DUMMY] Spawn refused:", player.Name)
			return
		end

		if typeof(dummyKind) ~= "string" then
			return
		end

		local success, reason = TrainingDummyService.spawnDummy(player, dummyKind)
		if not success then
			warn("[MOBA][DUMMY] Spawn failed:", player.Name, dummyKind, reason)
		end
	end)

	debugClearDummiesRequest.OnServerEvent:Connect(function(player)
		local debugConfig = SharedConstants.DEBUG
		if typeof(debugConfig) ~= "table" or debugConfig.ALLOW_TRAINING_DUMMIES ~= true then
			warn("[MOBA][DUMMY] Clear refused:", player.Name)
			return
		end

		local success, reason = TrainingDummyService.clearDummies(player)
		if not success then
			warn("[MOBA][DUMMY] Clear failed:", player.Name, reason)
		end
	end)

	attackRequest.OnServerEvent:Connect(function(player, target)
		if typeof(target) ~= "Instance" then
			return
		end

		local resolvedTarget = resolveUnitTarget(target)
		if not resolvedTarget then
			return
		end

		local champion = ChampionService.getChampionFromPlayer(player)
		if not champion then
			return
		end

		CombatService.tryAutoAttack(champion, resolvedTarget, player)
	end)

	abilityRequest.OnServerEvent:Connect(function(player, slot, target, mousePosition)
		if typeof(slot) ~= "number" then
			return
		end

		local optionalTarget = if typeof(target) == "Instance" then resolveUnitTarget(target) else nil
		local optionalMousePosition = if typeof(mousePosition) == "Vector3" then mousePosition else nil
		local success, reason = AbilityService.castAbility(player, slot, optionalTarget, optionalMousePosition)
		if not success then
			warn("[MOBA] Ability failed:", player.Name, slot, reason)
		end
	end)

	scoreboardRequest.OnServerEvent:Connect(function(player)
		local blueEntries = {}
		local redEntries = {}
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			local entry = buildScoreboardEntry(otherPlayer)
			local teamName = otherPlayer:GetAttribute("Team")
			if teamName == SharedConstants.TEAMS.RED then
				table.insert(redEntries, entry)
			else
				table.insert(blueEntries, entry)
			end
		end

		local requesterFound = containsPlayerEntry(blueEntries, player.Name) or containsPlayerEntry(redEntries, player.Name)
		if not requesterFound then
			local requesterEntry = buildScoreboardEntry(player)
			local requesterTeam = player:GetAttribute("Team")
			if requesterTeam == SharedConstants.TEAMS.RED then
				table.insert(redEntries, requesterEntry)
			else
				table.insert(blueEntries, requesterEntry)
			end
			warn("[MOBA][SCOREBOARD] Requester was missing from payload, added fallback:", player.Name)
		end

		print(string.format(
			"[MOBA][SCOREBOARD] Sending to %s | Blue=%d Red=%d",
			player.Name,
			#blueEntries,
			#redEntries
		))

		scoreboardUpdate:FireClient(player, {
			Blue = blueEntries,
			Red = redEntries,
		})
	end)

	recallRequest.OnServerEvent:Connect(function(player)
		local success, reason = RecallService.startRecall(player)
		if not success then
			warn("[MOBA] Recall failed:", player.Name, reason)
		end
	end)

	selectChampionRequest.OnServerEvent:Connect(function(player, championId)
		if typeof(championId) ~= "string" then
			return
		end

		local success, reason = ChampionService.setSelectedChampion(player, championId)
		if not success then
			warn("[MOBA] Select champion failed:", player.Name, championId, reason)
		end
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
