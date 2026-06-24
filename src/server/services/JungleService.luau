--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local JungleData = require(ReplicatedStorage.Modules.JungleData)
local CombatService = require(script.Parent.CombatService)
local UnitFactory = require(script.Parent.UnitFactory)
local Utility = require(script.Parent.Utility)

local JungleService = {}

local function findChampion(monster: Model, leashRange: number): Instance?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		return nil
	end
	local bestTarget = nil
	local bestDistance = math.huge
	for _, candidate in units:GetChildren() do
		if candidate:GetAttribute("UnitType") == "Champion" and Utility.isAlive(candidate) then
			local distance = Utility.distance(monster, candidate)
			if distance <= leashRange and distance < bestDistance then
				bestTarget = candidate
				bestDistance = distance
			end
		end
	end
	return bestTarget
end

function JungleService.spawnCamp(campPart: BasePart)
	local campTypeAttribute = campPart:GetAttribute("CampType")
	if typeof(campTypeAttribute) ~= "string" then
		return
	end
	local data = JungleData.Camps[campTypeAttribute]
	if not data then
		warn("[MOBA] Invalid jungle camp:", campTypeAttribute)
		return
	end

	local monster = UnitFactory.createJungleMonster(campTypeAttribute, campPart.Position)
	if not monster then
		return
	end
	monster.Parent = Workspace:WaitForChild("Units")

	monster:GetAttributeChangedSignal("Dead"):Connect(function()
		if monster:GetAttribute("Dead") == true then
			task.delay(2, function()
				if monster.Parent then
					monster:Destroy()
				end
			end)
			task.delay(data.RespawnTime, function()
				if campPart.Parent then
					JungleService.spawnCamp(campPart)
				end
			end)
		end
	end)

	task.spawn(function()
		while monster.Parent and Utility.isAlive(monster) do
			local target = findChampion(monster, 45)
			if target then
				CombatService.tryAutoAttack(monster, target, nil)
			end
			task.wait(0.3)
		end
	end)
end

function JungleService.start()
	local camps = Workspace:WaitForChild("Map"):WaitForChild("JungleCamps")
	for _, campPart in camps:GetChildren() do
		if campPart:IsA("BasePart") then
			JungleService.spawnCamp(campPart)
		end
	end
end

return JungleService
