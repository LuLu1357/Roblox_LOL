--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JungleData = require(ReplicatedStorage.Modules.JungleData)
local MinionData = require(ReplicatedStorage.Modules.MinionData)
local Utility = require(script.Parent.Utility)

local UnitFactory = {}

local TEAM_COLORS = {
	Blue = Color3.fromRGB(55, 151, 255),
	Red = Color3.fromRGB(239, 71, 78),
	Neutral = Color3.fromRGB(190, 142, 75),
}

local function createVisualUnit(name: string, position: Vector3, color: Color3, scale: number): Model
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.Size = Vector3.new(scale, scale, scale)
	root.CFrame = CFrame.new(position + Vector3.new(0, scale / 2, 0))
	root.Color = color
	root.Material = Enum.Material.SmoothPlastic
	root.Shape = Enum.PartType.Ball
	root.Parent = model

	local accent = Instance.new("Part")
	accent.Name = "Accent"
	accent.Anchored = true
	accent.CanCollide = false
	accent.CanTouch = false
	accent.Size = Vector3.new(scale * 0.62, scale * 0.62, scale * 0.62)
	accent.CFrame = root.CFrame * CFrame.new(0, scale * 0.62, 0)
	accent.Color = color:Lerp(Color3.new(1, 1, 1), 0.35)
	accent.Material = Enum.Material.Neon
	accent.Shape = Enum.PartType.Ball
	accent.Parent = model

	model.PrimaryPart = root
	return model
end

function UnitFactory.createMinion(teamName: string, minionType: string, position: Vector3): Model?
	if not minionType then
		warn("[MOBA] Minion has no minion type")
		return nil
	end

	local data = MinionData and MinionData.Types and MinionData.Types[minionType]
	if not data then
		warn("[MOBA] Invalid or missing minion data for minion type:", minionType)
		return nil
	end

	local color = TEAM_COLORS[teamName] or Color3.new(1, 1, 1)
	local minion = createVisualUnit(teamName .. minionType, position, color, data.Scale)
	minion:SetAttribute("UnitType", "Minion")
	minion:SetAttribute("Team", teamName)
	minion:SetAttribute("MinionType", minionType)
	minion:SetAttribute("MaxHealth", data.MaxHealth)
	minion:SetAttribute("Health", data.MaxHealth)
	minion:SetAttribute("AttackDamage", data.AttackDamage)
	minion:SetAttribute("AttackRange", data.AttackRange)
	minion:SetAttribute("AttackCooldown", data.AttackCooldown)
	minion:SetAttribute("MoveSpeed", data.MoveSpeed)
	minion:SetAttribute("GoldReward", data.GoldReward)
	minion:SetAttribute("XPReward", data.XPReward)
	minion:SetAttribute("Dead", false)
	Utility.attachHealthBar(minion)
	return minion
end

function UnitFactory.createJungleMonster(campType: string, position: Vector3): Model?
	if not campType then
		warn("[MOBA] Jungle camp has no CampType attribute")
		return nil
	end

	local data = JungleData and JungleData.Camps and JungleData.Camps[campType]
	if not data then
		warn("[MOBA] Invalid or missing jungle camp data for camp type:", campType)
		return nil
	end

	local monster = createVisualUnit(campType, position, TEAM_COLORS.Neutral, data.Scale)
	monster:SetAttribute("UnitType", "JungleMonster")
	monster:SetAttribute("Team", "Neutral")
	monster:SetAttribute("CampType", campType)
	monster:SetAttribute("MaxHealth", data.MaxHealth)
	monster:SetAttribute("Health", data.MaxHealth)
	monster:SetAttribute("AttackDamage", data.AttackDamage)
	monster:SetAttribute("AttackRange", data.AttackRange)
	monster:SetAttribute("AttackCooldown", data.AttackCooldown)
	monster:SetAttribute("GoldReward", data.GoldReward)
	monster:SetAttribute("XPReward", data.XPReward)
	monster:SetAttribute("Dead", false)
	Utility.attachHealthBar(monster)
	return monster
end

return UnitFactory
