--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ItemData = require(ReplicatedStorage.Modules.ItemData)

local HudController = {}
local player = Players.LocalPlayer

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

function HudController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MobaHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "StatusPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromScale(0.5, 0.975)
	panel.Size = UDim2.fromOffset(520, 270)
	panel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local currentCharacter: Model? = nil
	local selectedInventorySlot: number? = nil

	local itemDetailsPanel = Instance.new("Frame")
	itemDetailsPanel.Name = "ItemDetailsPanel"
	itemDetailsPanel.Size = UDim2.fromOffset(260, 220)
	itemDetailsPanel.Position = UDim2.fromOffset(20, 210)
	itemDetailsPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	itemDetailsPanel.BackgroundTransparency = 0.05
	itemDetailsPanel.BorderSizePixel = 0
	itemDetailsPanel.Visible = false
	itemDetailsPanel.Parent = gui

	local itemDetailsCorner = Instance.new("UICorner")
	itemDetailsCorner.CornerRadius = UDim.new(0, 10)
	itemDetailsCorner.Parent = itemDetailsPanel

	local itemDetailsText = Instance.new("TextLabel")
	itemDetailsText.Name = "ItemDetailsText"
	itemDetailsText.Position = UDim2.fromOffset(14, 12)
	itemDetailsText.Size = UDim2.new(1, -28, 1, -58)
	itemDetailsText.BackgroundTransparency = 1
	itemDetailsText.Font = Enum.Font.GothamMedium
	itemDetailsText.TextColor3 = Color3.fromRGB(240, 243, 250)
	itemDetailsText.TextSize = 16
	itemDetailsText.TextWrapped = true
	itemDetailsText.TextXAlignment = Enum.TextXAlignment.Left
	itemDetailsText.TextYAlignment = Enum.TextYAlignment.Top
	itemDetailsText.Text = ""
	itemDetailsText.Parent = itemDetailsPanel

	local closeItemDetailsButton = Instance.new("TextButton")
	closeItemDetailsButton.Name = "CloseItemDetailsButton"
	closeItemDetailsButton.Position = UDim2.new(1, -88, 1, -38)
	closeItemDetailsButton.Size = UDim2.fromOffset(74, 26)
	closeItemDetailsButton.BackgroundColor3 = Color3.fromRGB(50, 66, 88)
	closeItemDetailsButton.BorderSizePixel = 0
	closeItemDetailsButton.Font = Enum.Font.GothamBold
	closeItemDetailsButton.Text = "Close"
	closeItemDetailsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeItemDetailsButton.TextScaled = true
	closeItemDetailsButton.Parent = itemDetailsPanel

	local closeItemDetailsCorner = Instance.new("UICorner")
	closeItemDetailsCorner.CornerRadius = UDim.new(0, 6)
	closeItemDetailsCorner.Parent = closeItemDetailsButton

	local sellItemButton = Instance.new("TextButton")
	sellItemButton.Name = "SellItemButton"
	sellItemButton.Position = UDim2.new(0, 14, 1, -38)
	sellItemButton.Size = UDim2.fromOffset(74, 26)
	sellItemButton.BackgroundColor3 = Color3.fromRGB(105, 38, 45)
	sellItemButton.BorderSizePixel = 0
	sellItemButton.Font = Enum.Font.GothamBold
	sellItemButton.Text = "SELL"
	sellItemButton.TextColor3 = Color3.fromRGB(255, 220, 220)
	sellItemButton.TextScaled = true
	sellItemButton.Visible = false
	sellItemButton.Parent = itemDetailsPanel

	local sellItemCorner = Instance.new("UICorner")
	sellItemCorner.CornerRadius = UDim.new(0, 6)
	sellItemCorner.Parent = sellItemButton

	local function getStatLine(statName: string, value: any): string
		local displayName = statName
		if statName == "AttackDamage" then
			displayName = "Attack Damage"
		elseif statName == "MaxHealth" then
			displayName = "Max Health"
		elseif statName == "MoveSpeed" then
			displayName = "Move Speed"
		elseif statName == "AttackRange" then
			displayName = "Attack Range"
		elseif statName == "AttackCooldown" then
			displayName = "Attack Cooldown"
		end

		if typeof(value) == "number" and value > 0 then
			return "+" .. tostring(value) .. " " .. displayName
		end

		return tostring(value) .. " " .. displayName
	end

	local function showItemDetails(itemId: any)
		if typeof(itemId) ~= "string" or itemId == "" then
			itemDetailsText.Text = "Empty Slot\nNo item equipped."
			sellItemButton.Visible = false
			itemDetailsPanel.Visible = true
			return
		end

		local item = ItemData.Items[itemId]
		if typeof(item) ~= "table" then
			itemDetailsText.Text = "Unknown Item\n" .. itemId
			sellItemButton.Visible = false
			itemDetailsPanel.Visible = true
			return
		end

		local displayName = if typeof(item.DisplayName) == "string" then item.DisplayName else itemId
		local cost = if typeof(item.Cost) == "number" then item.Cost else 0
		local lines: { string } = {}

		table.insert(lines, displayName)
		table.insert(lines, "Cost: " .. tostring(cost) .. "g")
		table.insert(lines, "")
		table.insert(lines, "Stats:")

		local stats = item.Stats
		if typeof(stats) == "table" then
			for statName, value in stats do
				table.insert(lines, getStatLine(statName, value))
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

		itemDetailsText.Text = table.concat(lines, "\n")
		sellItemButton.Visible = true
		itemDetailsPanel.Visible = true
	end

	closeItemDetailsButton.MouseButton1Click:Connect(function()
		itemDetailsPanel.Visible = false
		selectedInventorySlot = nil
	end)

	local endMatchOverlay = Instance.new("Frame")
	endMatchOverlay.Name = "EndMatchOverlay"
	endMatchOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	endMatchOverlay.Position = UDim2.fromScale(0.5, 0.5)
	endMatchOverlay.Size = UDim2.fromScale(1, 1)
	endMatchOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	endMatchOverlay.BackgroundTransparency = 0.35
	endMatchOverlay.BorderSizePixel = 0
	endMatchOverlay.Visible = false
	endMatchOverlay.Parent = gui

	local endMatchTitle = createLabel(
		endMatchOverlay,
		"EndMatchTitle",
		UDim2.fromScale(0.2, 0.36),
		UDim2.fromScale(0.6, 0.12),
		"VICTORY"
	)
	endMatchTitle.TextStrokeTransparency = 0.2
	endMatchTitle.TextColor3 = Color3.fromRGB(120, 190, 255)

	local endMatchSubtitle = createLabel(
		endMatchOverlay,
		"EndMatchSubtitle",
		UDim2.fromScale(0.25, 0.49),
		UDim2.fromScale(0.5, 0.055),
		"Blue wins"
	)
	endMatchSubtitle.TextStrokeTransparency = 0.35

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local healthBack = Instance.new("Frame")
	healthBack.Name = "HealthBack"
	healthBack.Position = UDim2.fromOffset(18, 38)
	healthBack.Size = UDim2.fromOffset(484, 22)
	healthBack.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = panel

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(55, 205, 105)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack

	local teamLabel = createLabel(panel, "Team", UDim2.fromOffset(18, 8), UDim2.fromOffset(150, 24), "TEAM")
	teamLabel.TextXAlignment = Enum.TextXAlignment.Left
	local stateLabel = createLabel(panel, "State", UDim2.fromOffset(178, 8), UDim2.fromOffset(184, 24), "WAITING")
	stateLabel.TextXAlignment = Enum.TextXAlignment.Right
	local healthLabel = createLabel(healthBack, "Health", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), "650 / 650")

	local levelLabel = createLabel(panel, "Level", UDim2.fromOffset(18, 60), UDim2.fromOffset(90, 18), "LVL 1")
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left

	local goldLabel = createLabel(panel, "Gold", UDim2.fromOffset(118, 60), UDim2.fromOffset(100, 18), "Gold: 0")
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left

	local xpLabel = createLabel(panel, "XP", UDim2.fromOffset(228, 60), UDim2.fromOffset(134, 18), "XP: 0")
	xpLabel.TextXAlignment = Enum.TextXAlignment.Right

	local statsToggleButton = Instance.new("TextButton")
	statsToggleButton.Name = "StatsToggleButton"
	statsToggleButton.Position = UDim2.fromOffset(378, 8)
	statsToggleButton.Size = UDim2.fromOffset(64, 24)
	statsToggleButton.BackgroundColor3 = Color3.fromRGB(50, 66, 88)
	statsToggleButton.BorderSizePixel = 0
	statsToggleButton.Font = Enum.Font.GothamBold
	statsToggleButton.Text = "STATS"
	statsToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	statsToggleButton.TextScaled = true
	statsToggleButton.Parent = panel

	local statsToggleCorner = Instance.new("UICorner")
	statsToggleCorner.CornerRadius = UDim.new(0, 6)
	statsToggleCorner.Parent = statsToggleButton

	local statsPanel = Instance.new("Frame")
	statsPanel.Name = "StatsPanel"
	statsPanel.AnchorPoint = Vector2.new(1, 1)
	statsPanel.Position = UDim2.new(1, 0, 0, -10)
	statsPanel.Size = UDim2.fromOffset(220, 238)
	statsPanel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	statsPanel.BackgroundTransparency = 0.08
	statsPanel.BorderSizePixel = 0
	statsPanel.Visible = false
	statsPanel.Parent = panel

	local statsPanelCorner = Instance.new("UICorner")
	statsPanelCorner.CornerRadius = UDim.new(0, 10)
	statsPanelCorner.Parent = statsPanel

	local statsText = Instance.new("TextLabel")
	statsText.Name = "StatsText"
	statsText.Position = UDim2.fromOffset(14, 12)
	statsText.Size = UDim2.new(1, -28, 1, -24)
	statsText.BackgroundTransparency = 1
	statsText.Font = Enum.Font.GothamMedium
	statsText.TextColor3 = Color3.fromRGB(235, 240, 248)
	statsText.TextSize = 18
	statsText.TextXAlignment = Enum.TextXAlignment.Left
	statsText.TextYAlignment = Enum.TextYAlignment.Top
	statsText.Text = ""
	statsText.Parent = statsPanel

	statsToggleButton.MouseButton1Click:Connect(function()
		statsPanel.Visible = not statsPanel.Visible
	end)

	local shopButtons: { [string]: TextButton } = {}

	local function createShopButton(itemId: string, text: string, position: UDim2): TextButton
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
		button.Parent = panel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		shopButtons[itemId] = button
		return button
	end

	createShopButton("LongSword", "Sword\n350g", UDim2.fromOffset(18, 88))
	createShopButton("RubyCrystal", "Ruby\n400g", UDim2.fromOffset(166, 88))
	createShopButton("Boots", "Boots\n300g", UDim2.fromOffset(314, 88))
	createShopButton("BFSword", "B.F. Sword\n1300g", UDim2.fromOffset(18, 132))
	createShopButton("GiantBelt", "Giant Belt\n1100g", UDim2.fromOffset(166, 132))
	createShopButton("SwiftBoots", "Swift Boots\n900g", UDim2.fromOffset(314, 132))

	local craftButtons: { [string]: TextButton } = {}

	local function createCraftButton(targetItemId: string, text: string, position: UDim2): TextButton
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
		button.Parent = panel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		craftButtons[targetItemId] = button
		return button
	end

	createCraftButton("BFSword", "Craft BF\n300g", UDim2.fromOffset(18, 176))
	createCraftButton("GiantBelt", "Craft Belt\n300g", UDim2.fromOffset(166, 176))
	createCraftButton("SwiftBoots", "Craft Swift\n500g", UDim2.fromOffset(314, 176))

	local function countInventoryItem(character: Model, itemId: string): number
		local count = 0

		for slotIndex = 1, 6 do
			local slotItemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			if slotItemId == itemId then
				count += 1
			end
		end

		return count
	end

	local function canCraftItem(character: Model, targetItemId: string): boolean
		local item = ItemData.Items[targetItemId]
		if typeof(item) ~= "table" then
			return false
		end

		local recipe = item.Recipe
		if typeof(recipe) ~= "table" then
			return false
		end

		local combineCost = recipe.CombineCost
		if typeof(combineCost) ~= "number" then
			return false
		end

		local gold = character:GetAttribute("Gold")
		if typeof(gold) ~= "number" or gold < combineCost then
			return false
		end

		if item.Unique == true then
			for slotIndex = 1, 6 do
				local slotItemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
				if slotItemId == targetItemId then
					return false
				end
			end
		end

		local components = recipe.Components
		if typeof(components) ~= "table" then
			return false
		end

		local requiredCounts: { [string]: number } = {}
		for _, componentItemId in components do
			if typeof(componentItemId) ~= "string" then
				return false
			end

			requiredCounts[componentItemId] = (requiredCounts[componentItemId] or 0) + 1
		end

		for componentItemId, requiredCount in requiredCounts do
			if countInventoryItem(character, componentItemId) < requiredCount then
				return false
			end
		end

		return true
	end

	local function updateCraftButtons(character: Model)
		for targetItemId, button in craftButtons do
			local canCraft = canCraftItem(character, targetItemId)

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
	end

	local inventorySlots: { [number]: TextButton } = {}

	local function getShortItemName(itemId: any): string
		if typeof(itemId) ~= "string" or itemId == "" then
			return "Empty"
		end

		if itemId == "LongSword" then
			return "Sword"
		elseif itemId == "RubyCrystal" then
			return "Ruby"
		elseif itemId == "Boots" then
			return "Boots"
		elseif itemId == "BFSword" then
			return "B.F."
		elseif itemId == "GiantBelt" then
			return "Belt"
		elseif itemId == "SwiftBoots" then
			return "Swift"
		end

		return itemId
	end

	local function createInventorySlot(slotIndex: number, position: UDim2): TextButton
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
		label.Parent = panel

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = label

		inventorySlots[slotIndex] = label
		label.MouseButton1Click:Connect(function()
			selectedInventorySlot = slotIndex
			local character = currentCharacter
			if not character then
				showItemDetails(nil)
				return
			end

			local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			showItemDetails(itemId)
		end)
		return label
	end

	createInventorySlot(1, UDim2.fromOffset(18, 222))
	createInventorySlot(2, UDim2.fromOffset(92, 222))
	createInventorySlot(3, UDim2.fromOffset(166, 222))
	createInventorySlot(4, UDim2.fromOffset(240, 222))
	createInventorySlot(5, UDim2.fromOffset(314, 222))
	createInventorySlot(6, UDim2.fromOffset(388, 222))

	local function updateTeam()
		local teamName = player:GetAttribute("Team")
		teamLabel.Text = "ÉQUIPE " .. tostring(teamName or "?")
		teamLabel.TextColor3 = if teamName == "Red"
			then Color3.fromRGB(255, 100, 105)
			else Color3.fromRGB(100, 180, 255)
	end

	local function bindCharacter(character: Model)
		currentCharacter = character

		local function updateHealth()
			local health = character:GetAttribute("Health")
			local maxHealth = character:GetAttribute("MaxHealth")
			if typeof(health) == "number" and typeof(maxHealth) == "number" and maxHealth > 0 then
				healthFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
				healthLabel.Text = string.format("%d / %d", math.floor(health), math.floor(maxHealth))
			end
		end
		local function updateStatsPanel()
			local level = character:GetAttribute("Level")
			local gold = character:GetAttribute("Gold")
			local xp = character:GetAttribute("XP")
			local health = character:GetAttribute("Health")
			local maxHealth = character:GetAttribute("MaxHealth")
			local attackDamage = character:GetAttribute("AttackDamage")
			local attackRange = character:GetAttribute("AttackRange")
			local attackCooldown = character:GetAttribute("AttackCooldown")
			local moveSpeed = character:GetAttribute("MoveSpeed")
			local inventoryCount = character:GetAttribute("InventoryCount")

			statsText.Text = string.format(
				"LVL: %s\nGold: %s\nXP: %s\nHP: %s / %s\nAD: %s\nRange: %s\nCooldown: %s\nSpeed: %s\nItems: %s",
				tostring(level or 1),
				tostring(gold or 0),
				tostring(xp or 0),
				tostring(health or 0),
				tostring(maxHealth or 0),
				tostring(attackDamage or 0),
				tostring(attackRange or 0),
				tostring(attackCooldown or 0),
				tostring(moveSpeed or 0),
				tostring(inventoryCount or 0)
			)
		end

		local statsAttributeNames = {
			"Level",
			"Gold",
			"XP",
			"Health",
			"MaxHealth",
			"AttackDamage",
			"AttackRange",
			"AttackCooldown",
			"MoveSpeed",
			"InventoryCount",
		}

		local function updateInventory()
			for slotIndex = 1, 6 do
				local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
				local label = inventorySlots[slotIndex]

				if label then
					local itemName = getShortItemName(itemId)
					label.Text = tostring(slotIndex) .. ": " .. itemName

					if itemName == "Empty" then
						label.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
						label.TextColor3 = Color3.fromRGB(145, 145, 145)
					elseif itemName == "Sword" then
						label.BackgroundColor3 = Color3.fromRGB(80, 58, 42)
						label.TextColor3 = Color3.fromRGB(255, 220, 170)
					elseif itemName == "Ruby" then
						label.BackgroundColor3 = Color3.fromRGB(82, 35, 45)
						label.TextColor3 = Color3.fromRGB(255, 150, 160)
					elseif itemName == "Boots" then
						label.BackgroundColor3 = Color3.fromRGB(45, 62, 82)
						label.TextColor3 = Color3.fromRGB(170, 215, 255)
					else
						label.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
						label.TextColor3 = Color3.fromRGB(255, 255, 255)
					end
				end
			end
		end

		local function updateInventoryAndCraft()
			updateInventory()
			updateCraftButtons(character)
		end

		local function updateProgression()
			local level = character:GetAttribute("Level")
			local gold = character:GetAttribute("Gold")
			local xp = character:GetAttribute("XP")

			levelLabel.Text = "LVL " .. tostring(level or 1)
			goldLabel.Text = "Gold: " .. tostring(gold or 0)
			xpLabel.Text = "XP: " .. tostring(xp or 0)

			local currentGold = if typeof(gold) == "number" then gold else 0

			for itemId, button in shopButtons do
				local item = ItemData.Items[itemId]
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
		end
		character:GetAttributeChangedSignal("Health"):Connect(updateHealth)
		character:GetAttributeChangedSignal("MaxHealth"):Connect(updateHealth)
		character:GetAttributeChangedSignal("Level"):Connect(updateProgression)
		character:GetAttributeChangedSignal("Gold"):Connect(function()
			updateProgression()
			updateCraftButtons(character)
		end)
		character:GetAttributeChangedSignal("XP"):Connect(updateProgression)
		for _, attributeName in statsAttributeNames do
			character:GetAttributeChangedSignal(attributeName):Connect(updateStatsPanel)
		end
		for slotIndex = 1, 6 do
			character:GetAttributeChangedSignal("InventorySlot" .. tostring(slotIndex)):Connect(updateInventoryAndCraft)
		end
		character:GetAttributeChangedSignal("InventoryCount"):Connect(updateInventoryAndCraft)
		updateHealth()
		updateProgression()
		updateStatsPanel()
		updateInventoryAndCraft()
	end

	player:GetAttributeChangedSignal("Team"):Connect(updateTeam)
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end
	updateTeam()

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes or not remotes:IsA("Folder") then
		warn("[MOBA] Remotes indisponibles : vérifie que le serveur a démarré et que Workspace.Map existe.")
		return
	end

	local shopBuyRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_BUY_REQUEST, 10)
	if not shopBuyRequest or not shopBuyRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopBuyRequest indisponible.")
		return
	end

	for itemId, button in shopButtons do
		button.MouseButton1Click:Connect(function()
			shopBuyRequest:FireServer(itemId)
		end)
	end

	local shopSellRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_SELL_REQUEST, 10)
	if not shopSellRequest or not shopSellRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopSellRequest indisponible.")
		return
	end

	sellItemButton.MouseButton1Click:Connect(function()
		local slotIndex = selectedInventorySlot
		if not slotIndex then
			return
		end

		shopSellRequest:FireServer(slotIndex)
		selectedInventorySlot = nil
		itemDetailsPanel.Visible = false
	end)

	local shopCraftRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_CRAFT_REQUEST, 10)
	if not shopCraftRequest or not shopCraftRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopCraftRequest indisponible.")
		return
	end

	for targetItemId, button in craftButtons do
		button.MouseButton1Click:Connect(function()
			local character = currentCharacter
			if not character or not canCraftItem(character, targetItemId) then
				return
			end

			shopCraftRequest:FireServer(targetItemId)
		end)
	end

	local matchRemote = remotes:WaitForChild(SharedConstants.REMOTES.MATCH_STATE_UPDATE, 10)
	if not matchRemote or not matchRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent MatchStateUpdate indisponible.")
		return
	end
	matchRemote.OnClientEvent:Connect(function(state, winner)
		if state == "Ended" then
			local winningTeam = tostring(winner)
			local playerTeam = tostring(player:GetAttribute("Team") or "?")
			local playerWon = winningTeam == playerTeam

			stateLabel.Text = "FIN : " .. winningTeam .. " WINS"

			endMatchOverlay.Visible = true
			endMatchTitle.Text = if playerWon then "VICTORY" else "DEFEAT"
			endMatchSubtitle.Text = winningTeam .. " wins"

			endMatchTitle.TextColor3 = if playerWon
				then Color3.fromRGB(120, 190, 255)
				else Color3.fromRGB(255, 100, 105)
		else
			stateLabel.Text = string.upper(tostring(state))
			endMatchOverlay.Visible = false
		end
	end)
end

return HudController
