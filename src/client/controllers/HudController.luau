--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ItemData = require(ReplicatedStorage.Modules.ItemData)
local AbilityData = require(ReplicatedStorage.Modules.AbilityData)

local HudController = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()

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

local function color3FromData(colorData: any): Color3
	if typeof(colorData) == "Color3" then
		return colorData
	end

	if typeof(colorData) == "table"
		and typeof(colorData.R) == "number"
		and typeof(colorData.G) == "number"
		and typeof(colorData.B) == "number"
	then
		return Color3.fromRGB(colorData.R, colorData.G, colorData.B)
	end

	return Color3.fromRGB(110, 110, 110)
end

local function formatSpellStatLine(label: string, value: any): string
	if typeof(value) ~= "number" then
		return ""
	end

	if label == "Cooldown" or label == "Duration" then
		return string.format("%s: %ss", label, tostring(value))
	end

	if label == "DashDistance" then
		return "Dash Distance: " .. tostring(value)
	end

	if label == "MaxHealthBonus" then
		return "Max Health Bonus: " .. tostring(value)
	end

	if label == "ExecuteBonusDamage" then
		return "Execute Bonus Damage: " .. tostring(value)
	end

	if label == "ExecuteThreshold" then
		return "Execute Threshold: " .. tostring(math.floor(value * 100)) .. "%"
	end

	return string.format("%s: %s", label, tostring(value))
end

local function buildSpellTooltipText(spell: table?, slot: number): string
	if typeof(spell) ~= "table" then
		return string.format("Slot %d\nNo spell available.", slot)
	end

	local lines: { string } = {}
	local name = if typeof(spell.DisplayName) == "string" then spell.DisplayName else "Spell"
	table.insert(lines, name)
	if typeof(spell.Type) == "string" then
		table.insert(lines, "Type: " .. spell.Type)
	end

	if typeof(spell.Damage) == "number" then
		table.insert(lines, formatSpellStatLine("Damage", spell.Damage))
	end
	if typeof(spell.Heal) == "number" then
		table.insert(lines, formatSpellStatLine("Heal", spell.Heal))
	end
	if typeof(spell.Range) == "number" then
		table.insert(lines, formatSpellStatLine("Range", spell.Range))
	end
	if typeof(spell.Radius) == "number" then
		table.insert(lines, formatSpellStatLine("Radius", spell.Radius))
	end
	if typeof(spell.Duration) == "number" then
		table.insert(lines, formatSpellStatLine("Duration", spell.Duration))
	end
	if typeof(spell.DashDistance) == "number" then
		table.insert(lines, formatSpellStatLine("DashDistance", spell.DashDistance))
	end
	if typeof(spell.MaxHealthBonus) == "number" then
		table.insert(lines, formatSpellStatLine("MaxHealthBonus", spell.MaxHealthBonus))
	end
	if typeof(spell.ExecuteThreshold) == "number" then
		table.insert(lines, formatSpellStatLine("ExecuteThreshold", spell.ExecuteThreshold))
	end
	if typeof(spell.ExecuteBonusDamage) == "number" then
		table.insert(lines, formatSpellStatLine("ExecuteBonusDamage", spell.ExecuteBonusDamage))
	end
	if typeof(spell.Cooldown) == "number" then
		table.insert(lines, formatSpellStatLine("Cooldown", spell.Cooldown))
	end

	if typeof(spell.Description) == "string" and spell.Description ~= "" then
		table.insert(lines, "")
		table.insert(lines, spell.Description)
	end

	return table.concat(lines, "\n")
end

function HudController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MobaHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "StatusPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromScale(0.5, 0.975)
	panel.Size = UDim2.fromOffset(520, 84)
	panel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local currentCharacter: Model? = nil
	local selectedInventorySlot: number? = nil
	local shopSellRequest: RemoteEvent? = nil
	local selectChampionRequest: RemoteEvent? = nil
	local debugSpawnDummyRequest: RemoteEvent? = nil
	local debugClearDummiesRequest: RemoteEvent? = nil
	local abilityRequest: RemoteEvent? = nil
	local abilityFeedbackRemote: RemoteEvent? = nil
	local scoreboardRequest: RemoteEvent? = nil
	local scoreboardUpdate: RemoteEvent? = nil
	local scoreboardPanel: Frame? = nil
	local scoreboardBlueRows: Frame? = nil
	local scoreboardRedRows: Frame? = nil
	local spellButtons: { [number]: TextButton } = {}
	local spellInfo: { [number]: table? } = {}
	local spellCooldownEnds: { [number]: number } = {}
	local hoveredSpellSlot: number? = nil

	local spellBar = Instance.new("Frame")
	spellBar.Name = "SpellBar"
	spellBar.Position = UDim2.fromOffset(18, 70)
	spellBar.Size = UDim2.fromOffset(484, 52)
	spellBar.BackgroundTransparency = 1
	spellBar.Parent = panel

	local function updateSpellCooldownUI()
		for slot = 1, 4 do
			local button = spellButtons[slot]
			if not button then
				continue
			end

			local endsAt = spellCooldownEnds[slot] or 0
			local remaining = endsAt - os.clock()
			local overlay = button:FindFirstChild("CooldownOverlay")
			local label = button:FindFirstChild("CooldownLabel")
			if remaining > 0 then
				if overlay and overlay:IsA("Frame") then
					overlay.Visible = true
				end
				if label and label:IsA("TextLabel") then
					label.Visible = true
					if remaining > 1 then
						label.Text = tostring(math.ceil(remaining))
					else
						label.Text = string.format("%.1f", remaining)
					end
				end
			else
				if overlay and overlay:IsA("Frame") then
					overlay.Visible = false
				end
				if label and label:IsA("TextLabel") then
					label.Visible = false
				end
			end
		end
	end

	local spellTooltip = Instance.new("Frame")
	spellTooltip.Name = "SpellTooltip"
	spellTooltip.Size = UDim2.fromOffset(280, 190)
	spellTooltip.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	spellTooltip.BackgroundTransparency = 0.04
	spellTooltip.BorderSizePixel = 0
	spellTooltip.ZIndex = 100
	spellTooltip.Visible = false
	spellTooltip.Parent = gui

	local spellTooltipCorner = Instance.new("UICorner")
	spellTooltipCorner.CornerRadius = UDim.new(0, 10)
	spellTooltipCorner.Parent = spellTooltip

	local tooltipText = Instance.new("TextLabel")
	tooltipText.Name = "TooltipText"
	tooltipText.Position = UDim2.fromOffset(10, 10)
	tooltipText.Size = UDim2.new(1, -20, 1, -20)
	tooltipText.BackgroundTransparency = 1
	tooltipText.ZIndex = 101
	tooltipText.Font = Enum.Font.Gotham
	tooltipText.TextColor3 = Color3.fromRGB(235, 240, 250)
	tooltipText.TextSize = 14
	tooltipText.TextWrapped = true
	tooltipText.TextXAlignment = Enum.TextXAlignment.Left
	tooltipText.TextYAlignment = Enum.TextYAlignment.Top
	tooltipText.RichText = false
	tooltipText.TextTransparency = 0
	tooltipText.Visible = true
	tooltipText.Text = ""
	tooltipText.Parent = spellTooltip

	local scoreboardTitleFont = Enum.Font.GothamBold
	local function createScoreboardRow(parent: Instance, text: string): TextLabel
		local row = Instance.new("TextLabel")
		row.Name = "ScoreboardRow"
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundTransparency = 0.08
		row.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
		row.BorderSizePixel = 0
		row.ZIndex = 202
		row.Font = Enum.Font.Gotham
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextTransparency = 0
		row.TextStrokeTransparency = 0.25
		row.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		row.TextSize = 16
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextYAlignment = Enum.TextYAlignment.Center
		row.Text = text
		row.ClipsDescendants = true
		row.Parent = parent
		return row
	end

	local function clearScoreboardRows()
		if scoreboardBlueRows then
			for _, child in ipairs(scoreboardBlueRows:GetChildren()) do
				if child.Name == "ScoreboardRow" then
					child:Destroy()
				end
			end
		end
		if scoreboardRedRows then
			for _, child in ipairs(scoreboardRedRows:GetChildren()) do
				if child.Name == "ScoreboardRow" then
					child:Destroy()
				end
			end
		end
	end

	local function renderScoreboard(payload: table)
		clearScoreboardRows()

		if scoreboardBlueRows and typeof(payload.Blue) == "table" then
			for _, entry in ipairs(payload.Blue) do
				local text = string.format(
					"%s | %s | LVL %d | %d/%d/%d | CS %d | %dg",
					tostring(entry.PlayerName or "Unknown"),
					tostring(entry.ChampionId or "None"),
					if typeof(entry.Level) == "number" then entry.Level else 1,
					if typeof(entry.Kills) == "number" then entry.Kills else 0,
					if typeof(entry.Deaths) == "number" then entry.Deaths else 0,
					if typeof(entry.Assists) == "number" then entry.Assists else 0,
					if typeof(entry.CS) == "number" then entry.CS else 0,
					if typeof(entry.Gold) == "number" then entry.Gold else 0
				)
				createScoreboardRow(scoreboardBlueRows, text)
			end
		end

		if scoreboardRedRows and typeof(payload.Red) == "table" then
			for _, entry in ipairs(payload.Red) do
				local text = string.format(
					"%s | %s | LVL %d | %d/%d/%d | CS %d | %dg",
					tostring(entry.PlayerName or "Unknown"),
					tostring(entry.ChampionId or "None"),
					if typeof(entry.Level) == "number" then entry.Level else 1,
					if typeof(entry.Kills) == "number" then entry.Kills else 0,
					if typeof(entry.Deaths) == "number" then entry.Deaths else 0,
					if typeof(entry.Assists) == "number" then entry.Assists else 0,
					if typeof(entry.CS) == "number" then entry.CS else 0,
					if typeof(entry.Gold) == "number" then entry.Gold else 0
				)
				createScoreboardRow(scoreboardRedRows, text)
			end
		end
	end

	local function createScoreboardPanel()
		scoreboardPanel = Instance.new("Frame")
		scoreboardPanel.Name = "ScoreboardPanel"
		scoreboardPanel.AnchorPoint = Vector2.new(0.5, 0)
		scoreboardPanel.Position = UDim2.fromScale(0.5, 0.08)
		scoreboardPanel.Size = UDim2.fromOffset(760, 360)
		scoreboardPanel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
		scoreboardPanel.BackgroundTransparency = 0.02
		scoreboardPanel.BorderSizePixel = 0
		scoreboardPanel.ZIndex = 200
		scoreboardPanel.Visible = false
		scoreboardPanel.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = scoreboardPanel

		local title = createLabel(scoreboardPanel, "ScoreboardTitle", UDim2.fromOffset(20, 16), UDim2.fromOffset(220, 28), "SCOREBOARD")
		title.Font = scoreboardTitleFont
		title.TextSize = 22
		title.ZIndex = 201
		local hint = createLabel(scoreboardPanel, "ScoreboardHint", UDim2.fromOffset(20, 44), UDim2.fromOffset(320, 18), "Release TAB to hide")
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 14
		hint.ZIndex = 201

		local blueTitle = createLabel(scoreboardPanel, "BlueTeamTitle", UDim2.fromOffset(20, 74), UDim2.fromOffset(180, 22), "Blue Team")
		blueTitle.TextColor3 = Color3.fromRGB(120, 180, 255)
		blueTitle.Font = Enum.Font.GothamBold
		blueTitle.TextSize = 18
		blueTitle.ZIndex = 201

		scoreboardBlueRows = Instance.new("Frame")
		scoreboardBlueRows.Name = "BlueTeamRows"
		scoreboardBlueRows.Position = UDim2.fromOffset(20, 102)
		scoreboardBlueRows.Size = UDim2.fromOffset(360, 220)
		scoreboardBlueRows.BackgroundTransparency = 1
		scoreboardBlueRows.ZIndex = 201
		scoreboardBlueRows.Parent = scoreboardPanel

		local blueLayout = Instance.new("UIListLayout")
		blueLayout.FillDirection = Enum.FillDirection.Vertical
		blueLayout.SortOrder = Enum.SortOrder.LayoutOrder
		blueLayout.Padding = UDim.new(0, 4)
		blueLayout.Parent = scoreboardBlueRows

		local redTitle = createLabel(scoreboardPanel, "RedTeamTitle", UDim2.fromOffset(380, 74), UDim2.fromOffset(180, 22), "Red Team")
		redTitle.TextColor3 = Color3.fromRGB(255, 120, 120)
		redTitle.Font = Enum.Font.GothamBold
		redTitle.TextSize = 18
		redTitle.ZIndex = 201

		scoreboardRedRows = Instance.new("Frame")
		scoreboardRedRows.Name = "RedTeamRows"
		scoreboardRedRows.Position = UDim2.fromOffset(380, 102)
		scoreboardRedRows.Size = UDim2.fromOffset(360, 220)
		scoreboardRedRows.BackgroundTransparency = 1
		scoreboardRedRows.ZIndex = 201
		scoreboardRedRows.Parent = scoreboardPanel

		local redLayout = Instance.new("UIListLayout")
		redLayout.FillDirection = Enum.FillDirection.Vertical
		redLayout.SortOrder = Enum.SortOrder.LayoutOrder
		redLayout.Padding = UDim.new(0, 4)
		redLayout.Parent = scoreboardRedRows
	end

	createScoreboardPanel()

	local function hideSpellTooltip()
		hoveredSpellSlot = nil
		spellTooltip.Visible = false
	end

	local function showSpellTooltip(slot: number)
		local button = spellButtons[slot]
		if not button then
			hideSpellTooltip()
			return
		end

		local tooltip = buildSpellTooltipText(spellInfo[slot], slot)
		if tooltip == "" then
			tooltip = "Slot " .. tostring(slot) .. "\nNo tooltip data."
			print("[MOBA][HUD] Spell tooltip", slot, tooltip)
		end
		tooltipText.Text = tooltip

		local absolutePos = button.AbsolutePosition
		spellTooltip.Position = UDim2.fromOffset(absolutePos.X, absolutePos.Y - 158)
		spellTooltip.Visible = true
	end

	local function updateSpellButton(slot: number)
		local button = spellButtons[slot]
		if not button then
			return
		end

		local spell = spellInfo[slot]
		local iconLabel = button:FindFirstChild("IconLabel") :: TextLabel?
		local keyLabel = button:FindFirstChild("KeyLabel") :: TextLabel?
		local bgColor = Color3.fromRGB(70, 70, 70)
		local text = "-"
		local textColor = Color3.fromRGB(255, 255, 255)

		if typeof(spell) == "table" then
			text = if typeof(spell.IconText) == "string" and spell.IconText ~= ""
				then spell.IconText
				else spell.DisplayName or "?"
			bgColor = color3FromData(spell.IconColor)
			textColor = Color3.fromRGB(20, 20, 20)
		else
			bgColor = Color3.fromRGB(45, 45, 45)
			textColor = Color3.fromRGB(180, 180, 180)
		end

		button.BackgroundColor3 = bgColor
		if iconLabel then
			iconLabel.Text = text
			iconLabel.TextColor3 = textColor
		end
		if keyLabel then
			keyLabel.Text = tostring(slot)
		end
	end

	local function updateSpellButtons()
		local championId = currentCharacter and currentCharacter:GetAttribute("ChampionId")
		local championSpells = if typeof(championId) == "string" then AbilityData.Spells[championId] else nil
		spellCooldownEnds = {}
		for slot = 1, 4 do
			spellInfo[slot] = championSpells and championSpells[slot] or nil
			updateSpellButton(slot)
		end
		hideSpellTooltip()
	end

	local function createSpellButton(slot: number, position: UDim2)
		local button = Instance.new("TextButton")
		button.Name = "SpellButton" .. tostring(slot)
		button.Position = position
		button.Size = UDim2.fromOffset(48, 48)
		button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = ""
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = false
		button.AutoButtonColor = true
		button.Parent = spellBar

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.Position = UDim2.fromOffset(0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.TextScaled = true
		iconLabel.Text = "-"
		iconLabel.Parent = button

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Position = UDim2.fromOffset(4, 4)
		keyLabel.Size = UDim2.fromOffset(12, 14)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
		keyLabel.TextSize = 12
		keyLabel.Text = tostring(slot)
		keyLabel.TextScaled = false
		keyLabel.Parent = button

		local cooldownOverlay = Instance.new("Frame")
		cooldownOverlay.Name = "CooldownOverlay"
		cooldownOverlay.Size = UDim2.fromScale(1, 1)
		cooldownOverlay.Position = UDim2.fromOffset(0, 0)
		cooldownOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		cooldownOverlay.BackgroundTransparency = 0.55
		cooldownOverlay.Visible = false
		cooldownOverlay.BorderSizePixel = 0
		cooldownOverlay.Parent = button

		local cooldownLabel = Instance.new("TextLabel")
		cooldownLabel.Name = "CooldownLabel"
		cooldownLabel.Size = UDim2.fromScale(1, 1)
		cooldownLabel.Position = UDim2.fromOffset(0, 0)
		cooldownLabel.BackgroundTransparency = 1
		cooldownLabel.Font = Enum.Font.GothamBold
		cooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		cooldownLabel.TextScaled = true
		cooldownLabel.Text = ""
		cooldownLabel.Visible = false
		cooldownLabel.Parent = button

		button.MouseButton1Click:Connect(function()
			if abilityRequest then
				local mousePosition = mouse and mouse.Hit and mouse.Hit.Position or nil
				abilityRequest:FireServer(slot, nil, mousePosition)
			end
		end)

		button.MouseEnter:Connect(function()
			hoveredSpellSlot = slot
			task.delay(0.45, function()
				if hoveredSpellSlot == slot then
					showSpellTooltip(slot)
				end
			end)
		end)

		button.MouseLeave:Connect(function()
			if hoveredSpellSlot == slot then
				hoveredSpellSlot = nil
			end
			hideSpellTooltip()
		end)

		spellButtons[slot] = button
		return button
	end

	for slot = 1, 4 do
		createSpellButton(slot, UDim2.fromOffset((slot - 1) * 56, 0))
	end

	task.spawn(function()
		while gui.Parent do
			updateSpellCooldownUI()
			task.wait(0.1)
		end
	end)

	local shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.fromOffset(760, 460)
	shopPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	shopPanel.BackgroundTransparency = 0.05
	shopPanel.BorderSizePixel = 0
	shopPanel.Visible = false
	shopPanel.Parent = gui

	local shopPanelCorner = Instance.new("UICorner")
	shopPanelCorner.CornerRadius = UDim.new(0, 12)
	shopPanelCorner.Parent = shopPanel

	local shopTitle = createLabel(shopPanel, "ShopTitle", UDim2.fromOffset(20, 14), UDim2.fromOffset(180, 30), "SHOP")
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	local shopCloseHint = createLabel(
		shopPanel,
		"ShopCloseHint",
		UDim2.fromOffset(540, 18),
		UDim2.fromOffset(200, 22),
		"Press P to close"
	)
	shopCloseHint.TextXAlignment = Enum.TextXAlignment.Right

	local buySectionLabel = createLabel(
		shopPanel,
		"BuySectionLabel",
		UDim2.fromOffset(20, 50),
		UDim2.fromOffset(120, 20),
		"BUY"
	)
	buySectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	local craftSectionLabel = createLabel(
		shopPanel,
		"CraftSectionLabel",
		UDim2.fromOffset(20, 178),
		UDim2.fromOffset(120, 20),
		"CRAFT"
	)
	craftSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	local inventorySectionLabel = createLabel(
		shopPanel,
		"InventorySectionLabel",
		UDim2.fromOffset(20, 264),
		UDim2.fromOffset(160, 20),
		"INVENTORY"
	)
	inventorySectionLabel.TextXAlignment = Enum.TextXAlignment.Left

	local shopItemDetails = Instance.new("Frame")
	shopItemDetails.Name = "ShopItemDetails"
	shopItemDetails.Position = UDim2.fromOffset(500, 60)
	shopItemDetails.Size = UDim2.fromOffset(240, 380)
	shopItemDetails.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
	shopItemDetails.BackgroundTransparency = 0.05
	shopItemDetails.BorderSizePixel = 0
	shopItemDetails.Parent = shopPanel

	local shopItemDetailsCorner = Instance.new("UICorner")
	shopItemDetailsCorner.CornerRadius = UDim.new(0, 10)
	shopItemDetailsCorner.Parent = shopItemDetails

	local shopItemDetailsText = Instance.new("TextLabel")
	shopItemDetailsText.Name = "ShopItemDetailsText"
	shopItemDetailsText.Position = UDim2.fromOffset(14, 12)
	shopItemDetailsText.Size = UDim2.new(1, -28, 1, -24)
	shopItemDetailsText.BackgroundTransparency = 1
	shopItemDetailsText.Font = Enum.Font.GothamMedium
	shopItemDetailsText.TextColor3 = Color3.fromRGB(240, 243, 250)
	shopItemDetailsText.TextSize = 16
	shopItemDetailsText.TextWrapped = true
	shopItemDetailsText.TextXAlignment = Enum.TextXAlignment.Left
	shopItemDetailsText.TextYAlignment = Enum.TextYAlignment.Top
	shopItemDetailsText.Text = "Empty Slot\n\nLeft click: details\nRight click: sell"
	shopItemDetailsText.Parent = shopItemDetails

	local championSelectPanel = Instance.new("Frame")
	championSelectPanel.Name = "ChampionSelectPanel"
	championSelectPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	championSelectPanel.Position = UDim2.fromScale(0.5, 0.5)
	championSelectPanel.Size = UDim2.fromOffset(560, 190)
	championSelectPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	championSelectPanel.BackgroundTransparency = 0.04
	championSelectPanel.BorderSizePixel = 0
	championSelectPanel.Visible = false
	championSelectPanel.Parent = gui

	local championSelectCorner = Instance.new("UICorner")
	championSelectCorner.CornerRadius = UDim.new(0, 12)
	championSelectCorner.Parent = championSelectPanel

	local championSelectTitle = createLabel(
		championSelectPanel,
		"ChampionSelectTitle",
		UDim2.fromOffset(20, 16),
		UDim2.fromOffset(300, 30),
		"SELECT CHAMPION"
	)
	championSelectTitle.TextXAlignment = Enum.TextXAlignment.Left

	local championSelectHint = createLabel(
		championSelectPanel,
		"ChampionSelectHint",
		UDim2.fromOffset(20, 48),
		UDim2.fromOffset(360, 20),
		"Choose a class to respawn"
	)
	championSelectHint.TextXAlignment = Enum.TextXAlignment.Left

	local closeChampionSelectButton = Instance.new("TextButton")
	closeChampionSelectButton.Name = "CloseChampionSelectButton"
	closeChampionSelectButton.Position = UDim2.fromOffset(510, 14)
	closeChampionSelectButton.Size = UDim2.fromOffset(30, 30)
	closeChampionSelectButton.BackgroundColor3 = Color3.fromRGB(65, 45, 50)
	closeChampionSelectButton.BorderSizePixel = 0
	closeChampionSelectButton.Font = Enum.Font.GothamBold
	closeChampionSelectButton.Text = "X"
	closeChampionSelectButton.TextColor3 = Color3.fromRGB(255, 220, 220)
	closeChampionSelectButton.TextScaled = true
	closeChampionSelectButton.Parent = championSelectPanel

	local closeChampionSelectCorner = Instance.new("UICorner")
	closeChampionSelectCorner.CornerRadius = UDim.new(0, 6)
	closeChampionSelectCorner.Parent = closeChampionSelectButton

	local championSelectButtons: { [string]: TextButton } = {}

	local function createChampionSelectButton(championId: string, position: UDim2): TextButton
		local button = Instance.new("TextButton")
		button.Name = championId
		button.Position = position
		button.Size = UDim2.fromOffset(96, 58)
		button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
		button.BackgroundTransparency = 0.05
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = championId
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Parent = championSelectPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		championSelectButtons[championId] = button
		button.MouseButton1Click:Connect(function()
			local remote = selectChampionRequest
			if not remote then
				return
			end

			remote:FireServer(championId)
			championSelectPanel.Visible = false
		end)
		return button
	end

	createChampionSelectButton("Tank", UDim2.fromOffset(20, 92))
	createChampionSelectButton("Assassin", UDim2.fromOffset(128, 92))
	createChampionSelectButton("Mage", UDim2.fromOffset(236, 92))
	createChampionSelectButton("Marksman", UDim2.fromOffset(344, 92))
	createChampionSelectButton("Support", UDim2.fromOffset(452, 92))

	closeChampionSelectButton.MouseButton1Click:Connect(function()
		championSelectPanel.Visible = false
	end)

	local trainingPanel = Instance.new("Frame")
	trainingPanel.Name = "TrainingPanel"
	trainingPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	trainingPanel.Position = UDim2.fromScale(0.5, 0.5)
	trainingPanel.Size = UDim2.fromOffset(360, 300)
	trainingPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	trainingPanel.BackgroundTransparency = 0.05
	trainingPanel.BorderSizePixel = 0
	trainingPanel.Visible = false
	trainingPanel.Parent = gui

	local trainingPanelCorner = Instance.new("UICorner")
	trainingPanelCorner.CornerRadius = UDim.new(0, 12)
	trainingPanelCorner.Parent = trainingPanel

	local trainingTitle = createLabel(
		trainingPanel,
		"TrainingTitle",
		UDim2.fromOffset(24, 18),
		UDim2.fromOffset(312, 30),
		"TRAINING DUMMIES"
	)
	trainingTitle.TextXAlignment = Enum.TextXAlignment.Left

	local trainingSpawnButtons: { [string]: TextButton } = {}

	local function createTrainingButton(name: string, text: string, position: UDim2): TextButton
		local button = Instance.new("TextButton")
		button.Name = name
		button.Position = position
		button.Size = UDim2.fromOffset(312, 34)
		button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
		button.BackgroundTransparency = 0.04
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Parent = trainingPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		return button
	end

	trainingSpawnButtons.EnemyChampion = createTrainingButton(
		"SpawnEnemyChampionButton",
		"Spawn Enemy Champion",
		UDim2.fromOffset(24, 68)
	)
	trainingSpawnButtons.AllyChampion = createTrainingButton(
		"SpawnAllyChampionButton",
		"Spawn Ally Champion",
		UDim2.fromOffset(24, 112)
	)
	trainingSpawnButtons.EnemyMinion = createTrainingButton(
		"SpawnEnemyMinionButton",
		"Spawn Enemy Minion",
		UDim2.fromOffset(24, 156)
	)
	trainingSpawnButtons.AllyMinion = createTrainingButton(
		"SpawnAllyMinionButton",
		"Spawn Ally Minion",
		UDim2.fromOffset(24, 200)
	)

	local clearDummiesButton = createTrainingButton(
		"ClearDummiesButton",
		"Clear Dummies",
		UDim2.fromOffset(24, 244)
	)
	clearDummiesButton.BackgroundColor3 = Color3.fromRGB(66, 45, 52)
	clearDummiesButton.TextColor3 = Color3.fromRGB(255, 220, 225)

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
			shopItemDetailsText.Text = "Empty Slot\n\nLeft click: details\nRight click: sell"
			return
		end

		local item = ItemData.Items[itemId]
		if typeof(item) ~= "table" then
			shopItemDetailsText.Text = "Unknown Item\n" .. itemId
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

		table.insert(lines, "")
		table.insert(lines, "Left click: details")
		table.insert(lines, "Right click slot to sell")
		shopItemDetailsText.Text = table.concat(lines, "\n")
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab then
			if scoreboardPanel then
				scoreboardPanel.Visible = true
			end
			if scoreboardRequest then
				scoreboardRequest:FireServer()
			end
			return
		end

		if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.P then
			shopPanel.Visible = not shopPanel.Visible
			if shopPanel.Visible then
				championSelectPanel.Visible = false
				trainingPanel.Visible = false
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab then
			if scoreboardPanel then
				scoreboardPanel.Visible = false
			end
			return
		end

		if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end
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

	local shopHintLabel = createLabel(panel, "ShopHint", UDim2.fromOffset(448, 8), UDim2.fromOffset(54, 24), "P: SHOP")
	shopHintLabel.TextXAlignment = Enum.TextXAlignment.Right

	local championSelectToggleButton = Instance.new("TextButton")
	championSelectToggleButton.Name = "ChampionSelectToggleButton"
	championSelectToggleButton.Position = UDim2.fromOffset(378, 60)
	championSelectToggleButton.Size = UDim2.fromOffset(124, 18)
	championSelectToggleButton.BackgroundColor3 = Color3.fromRGB(50, 66, 88)
	championSelectToggleButton.BorderSizePixel = 0
	championSelectToggleButton.Font = Enum.Font.GothamBold
	championSelectToggleButton.Text = "CHAMPIONS"
	championSelectToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	championSelectToggleButton.TextScaled = true
	championSelectToggleButton.Parent = panel

	local championSelectToggleCorner = Instance.new("UICorner")
	championSelectToggleCorner.CornerRadius = UDim.new(0, 5)
	championSelectToggleCorner.Parent = championSelectToggleButton

	local trainingToggleButton = Instance.new("TextButton")
	trainingToggleButton.Name = "TrainingToggleButton"
	trainingToggleButton.AnchorPoint = Vector2.new(0.5, 1)
	trainingToggleButton.Position = UDim2.new(0.5, 0, 0.975, -92)
	trainingToggleButton.Size = UDim2.fromOffset(104, 24)
	trainingToggleButton.BackgroundColor3 = Color3.fromRGB(52, 68, 58)
	trainingToggleButton.BorderSizePixel = 0
	trainingToggleButton.Font = Enum.Font.GothamBold
	trainingToggleButton.Text = "TRAINING"
	trainingToggleButton.TextColor3 = Color3.fromRGB(230, 255, 235)
	trainingToggleButton.TextScaled = true
	trainingToggleButton.Parent = gui

	local trainingToggleCorner = Instance.new("UICorner")
	trainingToggleCorner.CornerRadius = UDim.new(0, 6)
	trainingToggleCorner.Parent = trainingToggleButton

	local statsPanel = Instance.new("Frame")
	statsPanel.Name = "StatsPanel"
	statsPanel.AnchorPoint = Vector2.new(1, 1)
	statsPanel.Position = UDim2.new(1, 0, 0, -10)
	statsPanel.Size = UDim2.fromOffset(220, 300)
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
		if statsPanel.Visible then
			trainingPanel.Visible = false
		end
	end)
	championSelectToggleButton.MouseButton1Click:Connect(function()
		championSelectPanel.Visible = not championSelectPanel.Visible
		if championSelectPanel.Visible then
			shopPanel.Visible = false
			statsPanel.Visible = false
			trainingPanel.Visible = false
		end
	end)
	trainingToggleButton.MouseButton1Click:Connect(function()
		trainingPanel.Visible = not trainingPanel.Visible
		if trainingPanel.Visible then
			shopPanel.Visible = false
			championSelectPanel.Visible = false
			statsPanel.Visible = false
		end
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
		button.Parent = shopPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		shopButtons[itemId] = button
		return button
	end

	createShopButton("LongSword", "Sword\n350g", UDim2.fromOffset(20, 76))
	createShopButton("RubyCrystal", "Ruby\n400g", UDim2.fromOffset(168, 76))
	createShopButton("Boots", "Boots\n300g", UDim2.fromOffset(316, 76))
	createShopButton("BFSword", "B.F. Sword\n1300g", UDim2.fromOffset(20, 122))
	createShopButton("GiantBelt", "Giant Belt\n1100g", UDim2.fromOffset(168, 122))
	createShopButton("SwiftBoots", "Swift Boots\n900g", UDim2.fromOffset(316, 122))

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
		button.Parent = shopPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		craftButtons[targetItemId] = button
		return button
	end

	createCraftButton("BFSword", "Craft BF\n300g", UDim2.fromOffset(20, 204))
	createCraftButton("GiantBelt", "Craft Belt\n300g", UDim2.fromOffset(168, 204))
	createCraftButton("SwiftBoots", "Craft Swift\n500g", UDim2.fromOffset(316, 204))

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
		label.Parent = shopPanel

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
		label.MouseButton2Click:Connect(function()
			local character = currentCharacter
			local remote = shopSellRequest
			if not character or not remote then
				return
			end

			local itemId = character:GetAttribute("InventorySlot" .. tostring(slotIndex))
			if typeof(itemId) ~= "string" or itemId == "" then
				return
			end

			remote:FireServer(slotIndex)
		end)
		return label
	end

	createInventorySlot(1, UDim2.fromOffset(20, 292))
	createInventorySlot(2, UDim2.fromOffset(94, 292))
	createInventorySlot(3, UDim2.fromOffset(168, 292))
	createInventorySlot(4, UDim2.fromOffset(242, 292))
	createInventorySlot(5, UDim2.fromOffset(316, 292))
	createInventorySlot(6, UDim2.fromOffset(390, 292))

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
			local championId = character:GetAttribute("ChampionId")
			local championRole = character:GetAttribute("ChampionRole")
			for buttonChampionId, button in championSelectButtons do
				local isSelected = championId == buttonChampionId
				button.BackgroundColor3 = if isSelected
					then Color3.fromRGB(55, 95, 75)
					else Color3.fromRGB(38, 48, 64)
				button.TextColor3 = if isSelected
					then Color3.fromRGB(220, 255, 225)
					else Color3.fromRGB(255, 255, 255)
			end
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
				"Champion: %s\nRole: %s\nLVL: %s\nGold: %s\nXP: %s\nHP: %s / %s\nAD: %s\nRange: %s\nCooldown: %s\nSpeed: %s\nItems: %s",
				tostring(championId or "?"),
				tostring(championRole or "?"),
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
			"ChampionId",
			"ChampionRole",
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

			local selectedSlot = selectedInventorySlot
			if selectedSlot then
				local selectedItemId = character:GetAttribute("InventorySlot" .. tostring(selectedSlot))
				showItemDetails(selectedItemId)
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
		character:GetAttributeChangedSignal("ChampionId"):Connect(updateSpellButtons)
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
		updateSpellButtons()
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

	local selectChampionRemote = remotes:WaitForChild(SharedConstants.REMOTES.SELECT_CHAMPION_REQUEST, 10)
	if selectChampionRemote and selectChampionRemote:IsA("RemoteEvent") then
		selectChampionRequest = selectChampionRemote
	else
		warn("[MOBA] RemoteEvent SelectChampionRequest indisponible.")
	end

	local debugSpawnDummyRemote = remotes:WaitForChild(SharedConstants.REMOTES.DEBUG_SPAWN_DUMMY_REQUEST, 10)
	if debugSpawnDummyRemote and debugSpawnDummyRemote:IsA("RemoteEvent") then
		debugSpawnDummyRequest = debugSpawnDummyRemote
		for dummyKind, button in trainingSpawnButtons do
			local buttonDummyKind = dummyKind
			button.MouseButton1Click:Connect(function()
				local remote = debugSpawnDummyRequest
				if not remote then
					return
				end

				remote:FireServer(buttonDummyKind)
			end)
		end
	else
		warn("[MOBA] RemoteEvent DebugSpawnDummyRequest indisponible.")
	end

	local debugClearDummiesRemote = remotes:WaitForChild(SharedConstants.REMOTES.DEBUG_CLEAR_DUMMIES_REQUEST, 10)
	if debugClearDummiesRemote and debugClearDummiesRemote:IsA("RemoteEvent") then
		debugClearDummiesRequest = debugClearDummiesRemote
		clearDummiesButton.MouseButton1Click:Connect(function()
			local remote = debugClearDummiesRequest
			if not remote then
				return
			end

			remote:FireServer()
		end)
	else
		warn("[MOBA] RemoteEvent DebugClearDummiesRequest indisponible.")
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

	local shopSellRemote = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_SELL_REQUEST, 10)
	if not shopSellRemote or not shopSellRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopSellRequest indisponible.")
		return
	end
	shopSellRequest = shopSellRemote

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

	local abilityRequestRemote = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_REQUEST, 10)
	if abilityRequestRemote and abilityRequestRemote:IsA("RemoteEvent") then
		abilityRequest = abilityRequestRemote
	else
		warn("[MOBA] RemoteEvent AbilityRequest indisponible.")
	end

	local abilityFeedbackRemoteInstance = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_FEEDBACK, 10)
	if abilityFeedbackRemoteInstance and abilityFeedbackRemoteInstance:IsA("RemoteEvent") then
		abilityFeedbackRemote = abilityFeedbackRemoteInstance
		abilityFeedbackRemote.OnClientEvent:Connect(function(state, displayName, slot, cooldown, remaining)
			if typeof(slot) ~= "number" or slot < 1 or slot > 4 then
				return
			end

			local now = os.clock()
			if state == "Cast" then
				if typeof(cooldown) == "number" and cooldown > 0 then
					spellCooldownEnds[slot] = now + cooldown
					updateSpellCooldownUI()
				end
			elseif state == "Cooldown" then
				local value = if typeof(remaining) == "number" and remaining > 0 then remaining else cooldown
				if typeof(value) == "number" and value > 0 then
					spellCooldownEnds[slot] = now + value
					updateSpellCooldownUI()
				end
			end
		end)
	else
		warn("[MOBA] RemoteEvent AbilityFeedback indisponible.")
	end

	local scoreboardRequestRemote = remotes:WaitForChild(SharedConstants.REMOTES.SCOREBOARD_REQUEST, 10)
	local scoreboardUpdateRemote = remotes:WaitForChild(SharedConstants.REMOTES.SCOREBOARD_UPDATE, 10)
	if scoreboardRequestRemote and scoreboardRequestRemote:IsA("RemoteEvent") then
		scoreboardRequest = scoreboardRequestRemote
	else
		warn("[MOBA] RemoteEvent ScoreboardRequest indisponible.")
	end
	if scoreboardUpdateRemote and scoreboardUpdateRemote:IsA("RemoteEvent") then
		scoreboardUpdate = scoreboardUpdateRemote
		scoreboardUpdate.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "table" then
				return
			end
			renderScoreboard(payload)
		end)
	else
		warn("[MOBA] RemoteEvent ScoreboardUpdate indisponible.")
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
