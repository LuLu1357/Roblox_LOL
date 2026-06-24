--!strict

local Utility = {}

function Utility.getRoot(unit: Instance?): BasePart?
	if not unit then
		return nil
	end

	if unit:IsA("BasePart") then
		return unit
	end

	if unit:IsA("Model") then
		local humanoidRootPart = unit:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
			return humanoidRootPart
		end
		return unit.PrimaryPart
	end

	return nil
end

function Utility.distance(a: Instance?, b: Instance?): number
	local rootA = Utility.getRoot(a)
	local rootB = Utility.getRoot(b)
	if not rootA or not rootB then
		return math.huge
	end
	return (rootA.Position - rootB.Position).Magnitude
end

function Utility.isAlive(unit: Instance?): boolean
	if not unit or not unit.Parent then
		return false
	end
	if unit:GetAttribute("Dead") == true then
		return false
	end

	local health = unit:GetAttribute("Health")
	if typeof(health) == "number" then
		return health > 0
	end

	local humanoid = unit:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end

	return false
end

function Utility.getTeam(unit: Instance?): string?
	if not unit then
		return nil
	end
	local teamName = unit:GetAttribute("Team")
	return if typeof(teamName) == "string" then teamName else nil
end

function Utility.areEnemies(a: Instance?, b: Instance?): boolean
	local teamA = Utility.getTeam(a)
	local teamB = Utility.getTeam(b)
	if not teamA or not teamB then
		return false
	end
	if teamA == "Neutral" and teamB == "Neutral" then
		return false
	end
	return teamA ~= teamB
end

function Utility.setHealth(unit: Instance, value: number)
	local maxHealthAttribute = unit:GetAttribute("MaxHealth")
	local maxHealth = if typeof(maxHealthAttribute) == "number" then maxHealthAttribute else value
	local newHealth = math.clamp(value, 0, maxHealth)
	unit:SetAttribute("Health", newHealth)

	local humanoid = unit:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = maxHealth
		humanoid.Health = newHealth
	end

	if newHealth <= 0 then
		unit:SetAttribute("Dead", true)
	end
end

function Utility.attachHealthBar(unit: Instance)
	local root = Utility.getRoot(unit)
	if not root then
		warn("[MOBA] Impossible d'ajouter une barre de vie, root manquant pour", unit:GetFullName())
		return
	end
	if root:FindFirstChild("MobaHealthBar") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MobaHealthBar"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(80, 10)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, math.max(root.Size.Y * 0.75, 3), 0)
	billboard.Parent = root

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(50, 15, 18)
	background.BorderSizePixel = 0
	background.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(55, 205, 105)
	fill.BorderSizePixel = 0
	fill.Parent = background

	local function update()
		local health = unit:GetAttribute("Health")
		local maxHealth = unit:GetAttribute("MaxHealth")
		if typeof(health) == "number" and typeof(maxHealth) == "number" and maxHealth > 0 then
			fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
			billboard.Enabled = health > 0
		end
	end

	unit:GetAttributeChangedSignal("Health"):Connect(update)
	unit:GetAttributeChangedSignal("MaxHealth"):Connect(update)
	unit:GetAttributeChangedSignal("Dead"):Connect(update)
	update()
end

return Utility
