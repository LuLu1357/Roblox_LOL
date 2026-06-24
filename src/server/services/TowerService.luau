--!strict

local Workspace = game:GetService("Workspace")

local CombatService = require(script.Parent.CombatService)
local Utility = require(script.Parent.Utility)

local TowerService = {}

local function findTarget(tower: Model): Instance?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		return nil
	end

	local bestTarget = nil
	local bestDistance = math.huge
	local rangeAttribute = tower:GetAttribute("AttackRange")
	local range = if typeof(rangeAttribute) == "number" then rangeAttribute else 90
	for _, candidate in units:GetChildren() do
		if Utility.isAlive(candidate) and Utility.areEnemies(tower, candidate) then
			local distance = Utility.distance(tower, candidate)
			if distance <= range and distance < bestDistance then
				bestTarget = candidate
				bestDistance = distance
			end
		end
	end
	return bestTarget
end

local function runTower(tower: Model)
	task.spawn(function()
		while tower.Parent and Utility.isAlive(tower) do
			local target = findTarget(tower)
			if target then
				CombatService.tryAutoAttack(tower, target, nil)
			end
			task.wait(0.2)
		end
	end)
end

function TowerService.start()
	local map = Workspace:WaitForChild("Map")
	local towers = map:WaitForChild("Towers")
	local units = Workspace:WaitForChild("Units")
	for _, tower in towers:GetChildren() do
		if tower:IsA("Model") then
			tower.Parent = units
			runTower(tower)
		end
	end
end

return TowerService
