--!strict

local StatsInventoryController = {}
StatsInventoryController.__index = StatsInventoryController

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

function StatsInventoryController.new(panel: Instance)
	local self = setmetatable({}, StatsInventoryController)
	self.panel = panel

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

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = statsPanel

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

	self.statsPanel = statsPanel
	self.statsText = statsText
	return self
end

function StatsInventoryController:BindCharacter(character: Model)
	self.character = character

	local function updateStats()
		local championId = character:GetAttribute("ChampionId")
		local championRole = character:GetAttribute("ChampionRole")
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

		self.statsText.Text = string.format(
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

	local attrs = {
		"ChampionId","ChampionRole","Level","Gold","XP","Health","MaxHealth",
		"AttackDamage","AttackRange","AttackCooldown","MoveSpeed","InventoryCount",
	}

	for _, name in attrs do
		character:GetAttributeChangedSignal(name):Connect(updateStats)
	end
	updateStats()
end

function StatsInventoryController:SetVisible(visible: boolean)
	if self.statsPanel then
		self.statsPanel.Visible = visible
	end
end

function StatsInventoryController:ToggleVisible()
	self:SetVisible(not (self.statsPanel and self.statsPanel.Visible or false))
end

function StatsInventoryController:IsVisible()
	return self.statsPanel and self.statsPanel.Visible or false
end

return StatsInventoryController
