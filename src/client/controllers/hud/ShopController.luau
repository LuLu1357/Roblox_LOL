--!strict

local ShopController = {}
ShopController.__index = ShopController

local MAX_INVENTORY_SLOTS = 6
local EMPTY_DETAILS_TEXT = "Empty Slot\n\nLeft click: details\nRight click: sell"
local STAT_DISPLAY_NAMES = {
	AttackDamage = "Attack Damage",
	MaxHealth = "Max Health",
	MoveSpeed = "Move Speed",
	AttackRange = "Attack Range",
	AttackCooldown = "Attack Cooldown",
}
local STAT_DISPLAY_ORDER = {
	"AttackDamage",
	"MaxHealth",
	"MoveSpeed",
	"AttackRange",
	"AttackCooldown",
}

local function createLabel(parent: Instance, name: string, position: UDim2, size: UDim2, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.55
	label.TextScaled = true
	label.Text = text
	label.Parent = parent
	return label
end

local function getStatLine(statName: string, value: any): string
	local displayName = STAT_DISPLAY_NAMES[statName] or statName

	if typeof(value) == "number" and value > 0 then
		return "+" .. tostring(value) .. " " .. displayName
	end

	return tostring(value) .. " " .. displayName
end

local function getShortItemName(itemId: any): string
	if typeof(itemId) ~= "string" or itemId == "" then
		return "Empty"
	end

	if itemId == "LongSword" then
		return "Sword"
	end
	if itemId == "RubyCrystal" then
		return "Ruby"
	end
	if itemId == "Boots" then
		return "Boots"
	end
	if itemId == "BFSword" then
		return "B.F."
	end
	if itemId == "GiantBelt" then
		return "Belt"
	end
	if itemId == "SwiftBoots" then
		return "Swift"
	end

	return itemId
end

local function countInventoryItem(character: Model, searchedItemId: string): number
	local count = 0

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
		if itemId == searchedItemId then
			count += 1
		end
	end

	return count
end

local function hasItem(character: Model, searchedItemId: string): boolean
	return countInventoryItem(character, searchedItemId) > 0
end

local function findComponentSlots(character: Model, requiredComponents: { string }): { number }?
	local matchedSlots: { number } = {}
	local usedSlots: { [number]: boolean } = {}

	for _, requiredItemId in requiredComponents do
		local matchedSlot: number? = nil

		for slotIndex = 1, MAX_INVENTORY_SLOTS do
			if not usedSlots[slotIndex] then
				local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
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

local function hasUniqueGroupItemExceptSlots(
	character: Model,
	itemData: table,
	uniqueGroup: string,
	ignoredSlots: { number }
): boolean
	local ignored: { [number]: boolean } = {}
	for _, slotIndex in ignoredSlots do
		ignored[slotIndex] = true
	end

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		if not ignored[slotIndex] then
			local slotItemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			if typeof(slotItemId) == "string" and slotItemId ~= "" then
				local slotItem = itemData.Items[slotItemId]
				if typeof(slotItem) == "table" and slotItem.UniqueGroup == uniqueGroup then
					return true
				end
			end
		end
	end

	return false
end

function ShopController.new(gui: Instance, itemData: table)
	local self = setmetatable({}, ShopController)
	self.gui = gui
	self.itemData = itemData
	self.currentCharacter = nil
	self.selectedInventorySlot = nil
	self.remotesBound = false
	self.shopPanel = Instance.new("Frame")
	self.shopPanel.Name = "ShopPanel"
	self.shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	self.shopPanel.Size = UDim2.fromOffset(760, 460)
	self.shopPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	self.shopPanel.BackgroundTransparency = 0.05
	self.shopPanel.BorderSizePixel = 0
	self.shopPanel.Visible = false
	self.shopPanel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = self.shopPanel

	createLabel(self.shopPanel, "ShopTitle", UDim2.fromOffset(20, 14), UDim2.fromOffset(180, 30), "SHOP").TextXAlignment = Enum.TextXAlignment.Left
	createLabel(self.shopPanel, "ShopCloseHint", UDim2.fromOffset(540, 18), UDim2.fromOffset(200, 22), "Press P to close").TextXAlignment = Enum.TextXAlignment.Right
	createLabel(self.shopPanel, "BuySectionLabel", UDim2.fromOffset(20, 50), UDim2.fromOffset(120, 20), "BUY").TextXAlignment = Enum.TextXAlignment.Left
	createLabel(self.shopPanel, "CraftSectionLabel", UDim2.fromOffset(20, 178), UDim2.fromOffset(120, 20), "CRAFT").TextXAlignment = Enum.TextXAlignment.Left
	createLabel(self.shopPanel, "InventorySectionLabel", UDim2.fromOffset(20, 264), UDim2.fromOffset(160, 20), "INVENTORY").TextXAlignment = Enum.TextXAlignment.Left

	self.shopItemDetails = Instance.new("Frame")
	self.shopItemDetails.Name = "ShopItemDetails"
	self.shopItemDetails.Position = UDim2.fromOffset(500, 60)
	self.shopItemDetails.Size = UDim2.fromOffset(240, 380)
	self.shopItemDetails.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
	self.shopItemDetails.BackgroundTransparency = 0.05
	self.shopItemDetails.BorderSizePixel = 0
	self.shopItemDetails.Parent = self.shopPanel

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 10)
	detailsCorner.Parent = self.shopItemDetails

	self.shopItemDetailsText = Instance.new("TextLabel")
	self.shopItemDetailsText.Name = "ShopItemDetailsText"
	self.shopItemDetailsText.Position = UDim2.fromOffset(14, 12)
	self.shopItemDetailsText.Size = UDim2.new(1, -28, 1, -24)
	self.shopItemDetailsText.BackgroundTransparency = 1
	self.shopItemDetailsText.Font = Enum.Font.GothamMedium
	self.shopItemDetailsText.TextColor3 = Color3.fromRGB(240, 243, 250)
	self.shopItemDetailsText.TextSize = 16
	self.shopItemDetailsText.TextWrapped = true
	self.shopItemDetailsText.TextXAlignment = Enum.TextXAlignment.Left
	self.shopItemDetailsText.TextYAlignment = Enum.TextYAlignment.Top
	self.shopItemDetailsText.Text = EMPTY_DETAILS_TEXT
	self.shopItemDetailsText.Parent = self.shopItemDetails

	self.shopButtons = {}
	self.craftButtons = {}
	self.inventorySlots = {}

	local function createShopButton(itemId: string, text: string, position: UDim2)
		local button = Instance.new("TextButton")
		button.Name = itemId
		button.Position = position
		button.Size = UDim2.fromOffset(128, 38)
		button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
		button.BackgroundTransparency = 0.05
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextScaled = true
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextStrokeTransparency = 0.65
		button.Text = text
		button.Parent = self.shopPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		self.shopButtons[itemId] = button
		return button
	end

	local function createCraftButton(targetItemId: string, text: string, position: UDim2)
		local button = Instance.new("TextButton")
		button.Name = "Craft" .. targetItemId
		button.Position = position
		button.Size = UDim2.fromOffset(128, 38)
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		button.BackgroundTransparency = 0.05
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextScaled = true
		button.TextColor3 = Color3.fromRGB(145, 145, 145)
		button.TextTransparency = 0.25
		button.TextStrokeTransparency = 0.65
		button.AutoButtonColor = false
		button.Active = false
		button.Text = text
		button.Parent = self.shopPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		self.craftButtons[targetItemId] = button
		return button
	end

	local function createInventorySlot(slotIndex: number, position: UDim2)
		local label = Instance.new("TextButton")
		label.Name = "InventorySlot" .. tostring(slotIndex)
		label.Size = UDim2.fromOffset(66, 30)
		label.Position = position
		label.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
		label.BackgroundTransparency = 0.05
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.7
		label.Text = tostring(slotIndex) .. ": Empty"
		label.Parent = self.shopPanel

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = label

		self.inventorySlots[slotIndex] = label
		label.MouseButton1Click:Connect(function()
			self.selectedInventorySlot = slotIndex
			local character = self.currentCharacter
			if not character then
				self:ShowItemDetails(nil)
				return
			end

			local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			self:ShowItemDetails(itemId)
		end)
		return label
	end

	createShopButton("LongSword", "Sword\n350g", UDim2.fromOffset(20, 76))
	createShopButton("RubyCrystal", "Ruby\n400g", UDim2.fromOffset(168, 76))
	createShopButton("Boots", "Boots\n300g", UDim2.fromOffset(316, 76))
	createShopButton("BFSword", "B.F. Sword\n1300g", UDim2.fromOffset(20, 122))
	createShopButton("GiantBelt", "Giant Belt\n1100g", UDim2.fromOffset(168, 122))
	createShopButton("SwiftBoots", "Swift Boots\n900g", UDim2.fromOffset(316, 122))

	createCraftButton("BFSword", "Craft BF\n300g", UDim2.fromOffset(20, 204))
	createCraftButton("GiantBelt", "Craft Belt\n300g", UDim2.fromOffset(168, 204))
	createCraftButton("SwiftBoots", "Craft Swift\n500g", UDim2.fromOffset(316, 204))

	for i = 1, 6 do
		createInventorySlot(i, UDim2.fromOffset(20 + (i - 1) * 74, 292))
	end

	return self
end

function ShopController:SetRemotes(buyRemote: RemoteEvent?, sellRemote: RemoteEvent?, craftRemote: RemoteEvent?)
	if self.remotesBound then
		return
	end
	self.remotesBound = true

	self.buyRemote = if buyRemote and buyRemote:IsA("RemoteEvent") then buyRemote else nil
	self.sellRemote = if sellRemote and sellRemote:IsA("RemoteEvent") then sellRemote else nil
	self.craftRemote = if craftRemote and craftRemote:IsA("RemoteEvent") then craftRemote else nil

	if self.buyRemote then
		for itemId, button in self.shopButtons do
			button.MouseButton1Click:Connect(function()
				self.buyRemote:FireServer(itemId)
			end)
		end
	end

	if self.craftRemote then
		for targetItemId, button in self.craftButtons do
			button.MouseButton1Click:Connect(function()
				local character = self.currentCharacter
				if not character or not self:CanCraftItem(character, targetItemId) then
					return
				end

				self.craftRemote:FireServer(targetItemId)
			end)
		end
	end

	if self.sellRemote then
		for slotIndex, button in self.inventorySlots do
			button.MouseButton2Click:Connect(function()
				local character = self.currentCharacter
				if not character then
					return
				end

				local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
				if typeof(itemId) ~= "string" or itemId == "" then
					return
				end

				self.sellRemote:FireServer(slotIndex)
			end)
		end
	end
end

function ShopController:BindCharacter(character: Model)
	self.currentCharacter = character
	local function updateForBoundCharacter()
		if self.currentCharacter ~= character then
			return
		end
		self:UpdateForCharacter(character)
	end

	for slotIndex = 1, MAX_INVENTORY_SLOTS do
		character:GetAttributeChangedSignal("InventorySlot" .. tostring(slotIndex)):Connect(updateForBoundCharacter)
	end
	character:GetAttributeChangedSignal("InventoryCount"):Connect(updateForBoundCharacter)
	character:GetAttributeChangedSignal("Gold"):Connect(updateForBoundCharacter)

	self:UpdateForCharacter(character)
end

function ShopController:ShowItemDetails(itemId: any)
	if not self.shopItemDetailsText then
		return
	end

	if typeof(itemId) ~= "string" or itemId == "" then
		self.shopItemDetailsText.Text = EMPTY_DETAILS_TEXT
		return
	end

	local item = self.itemData.Items[itemId]
	if typeof(item) ~= "table" then
		self.shopItemDetailsText.Text = "Unknown Item\n" .. itemId
		return
	end

	local displayName = if typeof(item.DisplayName) == "string" then item.DisplayName else itemId
	local cost = if typeof(item.Cost) == "number" then item.Cost else 0
	local sellRefund = math.floor(cost * 0.7)
	local lines: { string } = {}

	table.insert(lines, displayName)
	table.insert(lines, "Cost: " .. tostring(cost) .. "g")
	table.insert(lines, "Sell: " .. tostring(sellRefund) .. "g")
	table.insert(lines, "")
	table.insert(lines, "Stats:")

	local statLines: { string } = {}
	local emittedStats: { [string]: boolean } = {}
	local stats = item.Stats
	if typeof(stats) == "table" then
		for _, statName in STAT_DISPLAY_ORDER do
			local value = stats[statName]
			if value ~= nil then
				table.insert(statLines, getStatLine(statName, value))
				emittedStats[statName] = true
			end
		end

		for statName, value in stats do
			if typeof(statName) == "string" and not emittedStats[statName] then
				table.insert(statLines, getStatLine(statName, value))
			end
		end
	end

	if #statLines > 0 then
		for _, statLine in statLines do
			table.insert(lines, statLine)
		end
	else
		table.insert(lines, "No stats")
	end

	local recipe = item.Recipe
	if typeof(recipe) == "table" then
		local recipeParts: { string } = {}
		local components = recipe.Components
		if typeof(components) == "table" then
			for _, componentItemId in components do
				if typeof(componentItemId) == "string" then
					table.insert(recipeParts, componentItemId)
				end
			end
		end

		local combineCost = recipe.CombineCost
		if typeof(combineCost) == "number" then
			table.insert(recipeParts, tostring(combineCost) .. "g")
		end

		if #recipeParts > 0 then
			table.insert(lines, "")
			table.insert(lines, "Recipe:")
			table.insert(lines, table.concat(recipeParts, " + "))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Left click: details")
	table.insert(lines, "Right click slot to sell")
	self.shopItemDetailsText.Text = table.concat(lines, "\n")
end

function ShopController:CanCraftItem(character: Model, targetItemId: string): boolean
	local item = self.itemData.Items[targetItemId]
	if typeof(item) ~= "table" then
		return false
	end

	local recipe = item.Recipe
	if typeof(recipe) ~= "table" then
		return false
	end

	local combineCost = recipe.CombineCost
	if typeof(combineCost) ~= "number" or combineCost < 0 then
		return false
	end

	local gold = character:GetAttribute("Gold")
	if typeof(gold) ~= "number" or gold < combineCost then
		return false
	end

	if item.Unique == true and hasItem(character, targetItemId) then
		return false
	end

	local components = recipe.Components
	if typeof(components) ~= "table" then
		return false
	end

	local requiredComponents: { string } = {}
	for _, componentItemId in components do
		if typeof(componentItemId) ~= "string" then
			return false
		end

		local componentItem = self.itemData.Items[componentItemId]
		if typeof(componentItem) ~= "table" then
			return false
		end

		table.insert(requiredComponents, componentItemId)
	end

	if #requiredComponents == 0 then
		return false
	end

	local componentSlots = findComponentSlots(character, requiredComponents)
	if not componentSlots then
		return false
	end

	local uniqueGroup = item.UniqueGroup
	if
		typeof(uniqueGroup) == "string"
		and hasUniqueGroupItemExceptSlots(character, self.itemData, uniqueGroup, componentSlots)
	then
		return false
	end

	return true
end

function ShopController:UpdateInventory(character: Model)
	for slotIndex, button in self.inventorySlots do
		local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
		local itemName = getShortItemName(itemId)
		button.Text = tostring(slotIndex) .. ": " .. itemName

		if itemName == "Empty" then
			button.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
			button.TextColor3 = Color3.fromRGB(145, 145, 145)
		elseif itemName == "Sword" then
			button.BackgroundColor3 = Color3.fromRGB(80, 58, 42)
			button.TextColor3 = Color3.fromRGB(255, 220, 170)
		elseif itemName == "Ruby" then
			button.BackgroundColor3 = Color3.fromRGB(82, 35, 45)
			button.TextColor3 = Color3.fromRGB(255, 150, 160)
		elseif itemName == "Boots" then
			button.BackgroundColor3 = Color3.fromRGB(45, 62, 82)
			button.TextColor3 = Color3.fromRGB(170, 215, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	local selectedSlot = self.selectedInventorySlot
	if selectedSlot then
		local selectedItemId = character:GetAttribute("InventorySlot" .. tostring(selectedSlot))
		self:ShowItemDetails(selectedItemId)
	end
end

function ShopController:UpdateForCharacter(character: Model)
	if not character then
		return
	end
	local gold = character:GetAttribute("Gold")
	local currentGold = if typeof(gold) == "number" then gold else 0

	for itemId, button in self.shopButtons do
		local item = self.itemData.Items[itemId]
		local canBuy = false
		if typeof(item) == "table" and typeof(item.Cost) == "number" then
			canBuy = currentGold >= item.Cost
		end

		button.AutoButtonColor = canBuy
		button.Active = canBuy

		if canBuy then
			button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.TextTransparency = 0
		else
			button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
			button.TextColor3 = Color3.fromRGB(145, 145, 145)
			button.TextTransparency = 0.25
		end
	end

	for targetItemId, button in self.craftButtons do
		local canCraft = self:CanCraftItem(character, targetItemId)

		button.AutoButtonColor = canCraft
		button.Active = canCraft
		if canCraft then
			button.BackgroundColor3 = Color3.fromRGB(48, 68, 52)
			button.TextColor3 = Color3.fromRGB(220, 255, 225)
			button.TextTransparency = 0
		else
			button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
			button.TextColor3 = Color3.fromRGB(145, 145, 145)
			button.TextTransparency = 0.25
		end
	end

	self:UpdateInventory(character)
end

function ShopController:SetVisible(visible: boolean)
	if self.shopPanel then
		self.shopPanel.Visible = visible
	end
end

function ShopController:ToggleVisible()
	self:SetVisible(not (self.shopPanel and self.shopPanel.Visible or false))
end

function ShopController:IsVisible()
	return self.shopPanel and self.shopPanel.Visible or false
end

return ShopController
