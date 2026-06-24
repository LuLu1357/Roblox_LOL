--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Modules.ItemData)
local ChampionService = require(script.Parent.ChampionService)

local ShopService = {}

local MAX_INVENTORY_SLOTS = 6
local UNIQUE_ITEMS = {
	Boots = true,
}

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

local function getInventoryDebugText(champion: Model): string
	local parts = {}

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local itemId = champion:GetAttribute("InventorySlot" .. tostring(slotIndex))
		table.insert(parts, string.format("%d=%s", slotIndex, tostring(itemId or "-")))
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

	if UNIQUE_ITEMS[itemId] and hasItem(champion, itemId) then
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

function ShopService.start()
	print("[MOBA] ShopService started")
end

return ShopService