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
	panel.Size = UDim2.fromOffset(460, 138)
	panel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

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
	healthBack.Size = UDim2.fromOffset(424, 22)
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

	local function updateTeam()
		local teamName = player:GetAttribute("Team")
		teamLabel.Text = "ÉQUIPE " .. tostring(teamName or "?")
		teamLabel.TextColor3 = if teamName == "Red"
			then Color3.fromRGB(255, 100, 105)
			else Color3.fromRGB(100, 180, 255)
	end

	local function bindCharacter(character: Model)
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
		character:GetAttributeChangedSignal("Gold"):Connect(updateProgression)
		character:GetAttributeChangedSignal("XP"):Connect(updateProgression)
		for _, attributeName in statsAttributeNames do
			character:GetAttributeChangedSignal(attributeName):Connect(updateStatsPanel)
		end
		updateHealth()
		updateProgression()
		updateStatsPanel()
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
