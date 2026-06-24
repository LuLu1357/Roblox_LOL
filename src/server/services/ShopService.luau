--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Modules.ItemData)
local ChampionService = require(script.Parent.ChampionService)

local ShopService = {}

local MAX_INVENTORY_SLOTS = 6

local function getNumberAttribute(instance: Instance, name: string, fallback: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else fallback
end

local function getInventoryCount(champion: Model): number
	local count = 0

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local itemId = champion:GetAttribute("InventorySlot" .. tostring(slotIndex))
		if typeof(itemId) == "string" and itemId ~= "" then
			count += 1
		end
	end

	return count
end

local function hasItem(champion: Model, searchedItemId: string): boolean
	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local itemId = champion:GetAttribute("InventorySlot" .. tostring(slotIndex))
		if itemId == searchedItemId then
			return true
		end
	end

	return false
end

local function findFirstEmptySlot(champion: Model): number?
	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local attributeName = "InventorySlot" .. tostring(slotIndex)
		local itemId = champion:GetAttribute(attributeName)

		if typeof(itemId) ~= "string" or itemId == "" then
			return slotIndex
		end
	end

	return nil
end

local function setInventorySlot(champion: Model, slotIndex: number, itemId: string)
	champion:SetAttribute("InventorySlot" .. tostring(slotIndex), itemId)
	champion:SetAttribute("InventoryCount", getInventoryCount(champion))
end

local function clearInventorySlot(champion: Model, slotIndex: number)
	champion:SetAttribute("InventorySlot" .. tostring(slotIndex), "")
end

local function findItemSlots(champion: Model, requiredComponents: { string }): { number }?
	local matchedSlots: { number } = {}
	local usedSlots: { [number]: boolean } = {}

	for _, requiredItemId in requiredComponents do
		local matchedSlot: number? = nil

		for slotIndex = 1, MAX_INVENTORY_SLOTS do
			if not usedSlots[slotIndex] then
				local itemId = champion:GetAttribute("InventorySlot" .. tostring(slotIndex))
				if itemId == requiredItemId then
					matchedSlot = slotIndex
					break
				end
			end
		end

		if not matchedSlot then
			return nil
		end

		usedSlots[matchedSlot] = true
		table.insert(matchedSlots, matchedSlot)
	end

	return matchedSlots
end

local function applyItemStats(champion: Model, item)
	local stats = item.Stats
	if typeof(stats) ~= "table" then
		return
	end

	local attackDamage = stats.AttackDamage
	if typeof(attackDamage) == "number" then
		local current = getNumberAttribute(champion, "AttackDamage", 0)
		champion:SetAttribute("AttackDamage", current + attackDamage)
	end

	local maxHealth = stats.MaxHealth
	if typeof(maxHealth) == "number" then
		local currentMax = getNumberAttribute(champion, "MaxHealth", 0)
		local currentHealth = getNumberAttribute(champion, "Health", currentMax)
		local newMax = currentMax + maxHealth
		local newHealth = currentHealth + maxHealth

		champion:SetAttribute("MaxHealth", newMax)
		champion:SetAttribute("Health", newHealth)

		local humanoid = champion:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = newMax
			humanoid.Health = newHealth
		end
	end

	local moveSpeed = stats.MoveSpeed
	if typeof(moveSpeed) == "number" then
		local current = getNumberAttribute(champion, "MoveSpeed", 16)
		local newSpeed = current + moveSpeed

		champion:SetAttribute("MoveSpeed", newSpeed)

		local humanoid = champion:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = newSpeed
		end
	end
end

local function removeItemStats(champion: Model, item)
	local stats = item.Stats
	if typeof(stats) ~= "table" then
		return
	end

	local attackDamage = stats.AttackDamage
	if typeof(attackDamage) == "number" then
		local current = getNumberAttribute(champion, "AttackDamage", 0)
		champion:SetAttribute("AttackDamage", current - attackDamage)
	end

	local maxHealth = stats.MaxHealth
	if typeof(maxHealth) == "number" then
		local currentMax = getNumberAttribute(champion, "MaxHealth", 1)
		local currentHealth = getNumberAttribute(champion, "Health", currentMax)
		local newMax = math.max(1, currentMax - maxHealth)
		local newHealth = math.clamp(currentHealth, 1, newMax)

		champion:SetAttribute("MaxHealth", newMax)
		champion:SetAttribute("Health", newHealth)

		local humanoid = champion:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = newMax
			humanoid.Health = newHealth
		end
	end

	local moveSpeed = stats.MoveSpeed
	if typeof(moveSpeed) == "number" then
		local current = getNumberAttribute(champion, "MoveSpeed", 1)
		local newSpeed = math.max(1, current - moveSpeed)

		champion:SetAttribute("MoveSpeed", newSpeed)

		local humanoid = champion:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = newSpeed
		end
	end
end

local function getInventoryDebugText(champion: Model): string
	local parts = {}

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local itemId = champion:GetAttribute("InventorySlot" .. tostring(slotIndex))
		local itemText = if typeof(itemId) == "string" and itemId ~= "" then itemId else "-"
		table.insert(parts, string.format("%d=%s", slotIndex, itemText))
	end

	return table.concat(parts, " | ")
end

function ShopService.buyItem(player: Player, itemId: string): (boolean, string)
	local item = ItemData.Items[itemId]
	if typeof(item) ~= "table" then
		return false, "Unknown item"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	if champion:GetAttribute("Dead") == true then
		return false, "Champion is dead"
	end

	if item.Unique == true and hasItem(champion, itemId) then
		return false, "Unique item already owned"
	end

	local emptySlot = findFirstEmptySlot(champion)
	if not emptySlot then
		return false, "Inventory full"
	end

	local gold = getNumberAttribute(champion, "Gold", 0)
	local cost = item.Cost

	if typeof(cost) ~= "number" then
		return false, "Invalid item cost"
	end

	if gold < cost then
		return false, "Not enough gold"
	end

	champion:SetAttribute("Gold", gold - cost)
	setInventorySlot(champion, emptySlot, itemId)
	applyItemStats(champion, item)

	local itemName = if typeof(item.DisplayName) == "string" then item.DisplayName else itemId

	print(string.format(
		"[MOBA] %s bought %s for %d gold in slot %d",
		player.Name,
		itemName,
		cost,
		emptySlot
	))

	print(string.format(
		"[MOBA][SHOP] %s stats after %s: Gold=%s MaxHealth=%s AD=%s Speed=%s Items=%s Inventory=[%s]",
		player.Name,
		itemName,
		tostring(champion:GetAttribute("Gold")),
		tostring(champion:GetAttribute("MaxHealth")),
		tostring(champion:GetAttribute("AttackDamage")),
		tostring(champion:GetAttribute("MoveSpeed")),
		tostring(champion:GetAttribute("InventoryCount")),
		getInventoryDebugText(champion)
	))

	return true, "Bought"
end

function ShopService.sellItem(player: Player, slotIndex: number): (boolean, string)
	if slotIndex < 1 or slotIndex > MAX_INVENTORY_SLOTS or slotIndex % 1 ~= 0 then
		return false, "Invalid slot"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	if champion:GetAttribute("Dead") == true then
		return false, "Champion is dead"
	end

	local attributeName = "InventorySlot" .. tostring(slotIndex)
	local itemId = champion:GetAttribute(attributeName)
	if typeof(itemId) ~= "string" or itemId == "" then
		return false, "Empty slot"
	end

	local item = ItemData.Items[itemId]
	if typeof(item) ~= "table" then
		return false, "Unknown item"
	end

	local cost = item.Cost
	if typeof(cost) ~= "number" then
		return false, "Invalid item cost"
	end

	local refund = math.floor(cost * 0.7)
	local gold = getNumberAttribute(champion, "Gold", 0)
	local itemName = if typeof(item.DisplayName) == "string" then item.DisplayName else itemId

	champion:SetAttribute("Gold", gold + refund)
	removeItemStats(champion, item)
	setInventorySlot(champion, slotIndex, "")

	print(string.format(
		"[MOBA] %s sold %s from slot %d for %d gold",
		player.Name,
		itemName,
		slotIndex,
		refund
	))

	print(string.format(
		"[MOBA][SHOP] %s stats after selling %s: Gold=%s MaxHealth=%s AD=%s Speed=%s Items=%s Inventory=[%s]",
		player.Name,
		itemName,
		tostring(champion:GetAttribute("Gold")),
		tostring(champion:GetAttribute("MaxHealth")),
		tostring(champion:GetAttribute("AttackDamage")),
		tostring(champion:GetAttribute("MoveSpeed")),
		tostring(champion:GetAttribute("InventoryCount")),
		getInventoryDebugText(champion)
	))

	return true, "Sold"
end

function ShopService.craftItem(player: Player, targetItemId: string): (boolean, string)
	local targetItem = ItemData.Items[targetItemId]
	if typeof(targetItem) ~= "table" then
		return false, "Unknown item"
	end

	local recipe = targetItem.Recipe
	if typeof(recipe) ~= "table" then
		return false, "Item has no recipe"
	end

	local champion = ChampionService.getChampionFromPlayer(player)
	if not champion then
		return false, "Champion not found"
	end

	if champion:GetAttribute("Dead") == true then
		return false, "Champion is dead"
	end

	local components = recipe.Components
	if typeof(components) ~= "table" then
		return false, "Invalid recipe components"
	end

	local requiredComponents: { string } = {}
	local componentItems: { any } = {}
	for _, componentItemId in components do
		if typeof(componentItemId) ~= "string" then
			return false, "Invalid recipe component"
		end

		local componentItem = ItemData.Items[componentItemId]
		if typeof(componentItem) ~= "table" then
			return false, "Unknown recipe component"
		end

		table.insert(requiredComponents, componentItemId)
		table.insert(componentItems, componentItem)
	end

	if #requiredComponents == 0 then
		return false, "Recipe has no components"
	end

	local combineCost = recipe.CombineCost
	if typeof(combineCost) ~= "number" or combineCost < 0 then
		return false, "Invalid combine cost"
	end

	if targetItem.Unique == true and hasItem(champion, targetItemId) then
		return false, "Unique item already owned"
	end

	local componentSlots = findItemSlots(champion, requiredComponents)
	if not componentSlots then
		return false, "Missing components"
	end

	local firstConsumedSlot = componentSlots[1]
	if not firstConsumedSlot then
		return false, "Recipe has no components"
	end

	local gold = getNumberAttribute(champion, "Gold", 0)
	if gold < combineCost then
		return false, "Not enough gold"
	end

	for componentIndex, slotIndex in componentSlots do
		removeItemStats(champion, componentItems[componentIndex])
		clearInventorySlot(champion, slotIndex)
	end

	champion:SetAttribute("Gold", gold - combineCost)
	setInventorySlot(champion, firstConsumedSlot, targetItemId)
	applyItemStats(champion, targetItem)

	local itemName = if typeof(targetItem.DisplayName) == "string" then targetItem.DisplayName else targetItemId
	print(string.format(
		"[MOBA] %s crafted %s using %s and %d gold",
		player.Name,
		itemName,
		table.concat(requiredComponents, ", "),
		combineCost
	))

	print(string.format(
		"[MOBA][SHOP] %s stats after crafting %s: Gold=%s MaxHealth=%s AD=%s Speed=%s Items=%s Inventory=[%s]",
		player.Name,
		itemName,
		tostring(champion:GetAttribute("Gold")),
		tostring(champion:GetAttribute("MaxHealth")),
		tostring(champion:GetAttribute("AttackDamage")),
		tostring(champion:GetAttribute("MoveSpeed")),
		tostring(champion:GetAttribute("InventoryCount")),
		getInventoryDebugText(champion)
	))

	return true, "Crafted"
end

function ShopService.start()
	print("[MOBA] ShopService started")
end

return ShopService
