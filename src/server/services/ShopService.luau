--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Modules.ItemData)
local ChampionService = require(script.Parent.ChampionService)

local ShopService = {}

local function getNumberAttribute(instance: Instance, name: string, fallback: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else fallback
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

		champion:SetAttribute("MaxHealth", currentMax + maxHealth)
		champion:SetAttribute("Health", currentHealth + maxHealth)

		local humanoid = champion:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = currentMax + maxHealth
			humanoid.Health = currentHealth + maxHealth
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

	local gold = getNumberAttribute(champion, "Gold", 0)
	local cost = item.Cost

	if typeof(cost) ~= "number" then
		return false, "Invalid item cost"
	end

	if gold < cost then
		return false, "Not enough gold"
	end

	champion:SetAttribute("Gold", gold - cost)
	applyItemStats(champion, item)

	local inventoryCount = getNumberAttribute(champion, "InventoryCount", 0)
	champion:SetAttribute("InventoryCount", inventoryCount + 1)

	print(string.format("[MOBA] %s bought %s for %d gold", player.Name, item.DisplayName or itemId, cost))

	return true, "Bought"
end

function ShopService.start()
	print("[MOBA] ShopService started")
end

return ShopService