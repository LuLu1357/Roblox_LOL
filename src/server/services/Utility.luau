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

	local humanoid = unit:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end

	local health = unit:GetAttribute("Health")
	return typeof(health) == "number" and health > 0 and unit:GetAttribute("Dead") ~= true
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

return Utility
