--!strict

local UserInputService = game:GetService("UserInputService")

local ShopController = {}
ShopController.__index = ShopController

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

function ShopController.new(gui: Instance, itemData: table)
	local self = setmetatable({}, ShopController)
	self.gui = gui
	self.itemData = itemData
	self.currentCharacter = nil
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
	createLabel(self.shopPanel, "BuySectionLabel", UDim2.fromOffset(20, 50), UDim2.fromOffset(120, 20), "BUY").TextXAlignment = Enum.TextXAlignment.Left
	createLabel(self.shopPanel, "CraftSectionLabel", UDim2.fromOffset(20, 178), UDim2.fromOffset(120, 20), "CRAFT").TextXAlignment = Enum.TextXAlignment.Left
	createLabel(self.shopPanel, "InventorySectionLabel", UDim2.fromOffset(20, 264), UDim2.fromOffset(160, 20), "INVENTORY").TextXAlignment = Enum.TextXAlignment.Left

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
		return label
	end

	-- populate a few example buttons (mirrors previous defaults)
	createShopButton("LongSword", "Sword\n350g", UDim2.fromOffset(20, 76))
	createShopButton("RubyCrystal", "Ruby\n400g", UDim2.fromOffset(168, 76))
	createShopButton("Boots", "Boots\n300g", UDim2.fromOffset(316, 76))
	createCraftButton("BFSword", "Craft BF\n300g", UDim2.fromOffset(20, 204))
	createCraftButton("GiantBelt", "Craft Belt\n300g", UDim2.fromOffset(168, 204))
	createCraftButton("SwiftBoots", "Craft Swift\n500g", UDim2.fromOffset(316, 204))

	for i = 1, 6 do
		createInventorySlot(i, UDim2.fromOffset(20 + (i - 1) * 74, 292))
	end

	return self
end

function ShopController:SetRemotes(buyRemote: RemoteEvent?, sellRemote: RemoteEvent?, craftRemote: RemoteEvent?)
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
				self.craftRemote:FireServer(targetItemId)
			end)
		end
	end

	if self.sellRemote then
		for slotIndex, button in self.inventorySlots do
			button.MouseButton2Click:Connect(function()
				self.sellRemote:FireServer(slotIndex)
			end)
		end
	end
end

function ShopController:BindCharacter(character: Model)
	self.currentCharacter = character
	-- update inventory text when attributes change
	local function updateInventory()
		for slotIndex, button in self.inventorySlots do
			local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			local short = itemId and tostring(itemId) or "Empty"
			button.Text = tostring(slotIndex) .. ": " .. (short ~= "" and short or "Empty")
		end
	end

	for i = 1, 6 do
		character:GetAttributeChangedSignal("InventorySlot" .. tostring(i)):Connect(updateInventory)
	end
	updateInventory()
end

function ShopController:UpdateForCharacter(character: Model)
	if not character then
		return
	end
	local gold = character:GetAttribute("Gold")
	local currentGold = if typeof(gold) == "number" then gold else 0

	for itemId, button in self.shopButtons do
		local item = self.itemData.Items[itemId]
		local cost = if typeof(item) == "table" and typeof(item.Cost) == "number" then item.Cost else 0
		local canBuy = currentGold >= cost

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

	-- craft buttons: simple availability check
	for targetItemId, button in self.craftButtons do
		local item = self.itemData.Items[targetItemId]
		local recipe = item and item.Recipe or nil
		local combineCost = recipe and recipe.CombineCost or 0
		local canCraft = true

		if typeof(combineCost) ~= "number" or currentGold < combineCost then
			canCraft = false
		end

		if item and item.Unique == true then
			for slotIndex = 1, 6 do
				local slotItemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
				if slotItemId == targetItemId then
					canCraft = false
					break
				end
			end
		end

		if recipe and typeof(recipe.Components) == "table" then
			local requiredCounts: { [string]: number } = {}
			for _, comp in recipe.Components do
				requiredCounts[comp] = (requiredCounts[comp] or 0) + 1
			end
			for comp, req in requiredCounts do
				local count = 0
				for i = 1, 6 do
					if character:GetAttribute("InventorySlot" .. tostring(i)) == comp then
						count += 1
					end
				end
				if count < req then
					canCraft = false
					break
				end
			end
		end

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

	-- update inventory slot labels
	for slotIndex, btn in self.inventorySlots do
		local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
		local short = itemId and tostring(itemId) or "Empty"
		btn.Text = tostring(slotIndex) .. ": " .. (short ~= "" and short or "Empty")
	end
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
