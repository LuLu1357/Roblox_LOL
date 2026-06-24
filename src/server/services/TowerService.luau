--!strict

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local CombatService = require(script.Parent.CombatService)
local Utility = require(script.Parent.Utility)

local TowerService = {}
local AGGRO_DURATION = 3
local activeTowers: { Model } = {}
local forcedAggro = setmetatable({}, { __mode = "k" })
local started = false

type AggroState = {
	target: Instance,
	expiresAt: number,
}

local function getRange(tower: Model): number
	local value = tower:GetAttribute("AttackRange")
	return if typeof(value) == "number" then value else 90
end

local function isValidTowerTarget(tower: Model, candidate: Instance, range: number): boolean
	if not Utility.isAlive(candidate) or not Utility.areEnemies(tower, candidate) then
		return false
	end
	local unitType = candidate:GetAttribute("UnitType")
	if unitType ~= "Minion" and unitType ~= "Champion" and unitType ~= "Inhibitor" and unitType ~= "Nexus" then
		return false
	end
	return Utility.distance(tower, candidate) <= range
end

local function getForcedTarget(tower: Model, range: number): Instance?
	local state = forcedAggro[tower] :: AggroState?
	if not state then
		return nil
	end
	if os.clock() >= state.expiresAt or not isValidTowerTarget(tower, state.target, range) then
		forcedAggro[tower] = nil
		tower:SetAttribute("ForcedAggroTarget", nil)
		tower:SetAttribute("ForcedAggroUntil", nil)
		return nil
	end
	return state.target
end

local function findNearestTarget(tower: Model, range: number): Instance?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		return nil
	end

	local bestTarget = nil
	local bestDistance = math.huge
	for _, candidate in units:GetChildren() do
		if isValidTowerTarget(tower, candidate, range) then
			local distance = Utility.distance(tower, candidate)
			if distance < bestDistance then
				bestTarget = candidate
				bestDistance = distance
			end
		end
	end
	return bestTarget
end

local function findTarget(tower: Model): Instance?
	local range = getRange(tower)
	return getForcedTarget(tower, range) or findNearestTarget(tower, range)
end

local function registerChampionAggro(attacker: Instance, victim: Instance)
	if attacker:GetAttribute("UnitType") ~= "Champion" or victim:GetAttribute("UnitType") ~= "Champion" then
		return
	end
	for _, tower in activeTowers do
		if Utility.isAlive(tower) and Utility.getTeam(tower) == Utility.getTeam(victim) then
			local range = getRange(tower)
			if Utility.distance(tower, victim) <= range and isValidTowerTarget(tower, attacker, range) then
				forcedAggro[tower] = {
					target = attacker,
					expiresAt = os.clock() + AGGRO_DURATION,
				}
				tower:SetAttribute("ForcedAggroTarget", attacker.Name)
				tower:SetAttribute("ForcedAggroUntil", os.clock() + AGGRO_DURATION)
			end
		end
	end
end

local function runTower(tower: Model)
	Utility.attachHealthBar(tower)
	table.insert(activeTowers, tower)
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
	if started then
		return
	end
	started = true

	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[MOBA] Workspace.Map manquant : tours non démarrées.")
		return
	end
	local towers = map:FindFirstChild("Towers")
	if not towers then
		warn("[MOBA] Workspace.Map.Towers manquant.")
		return
	end
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		warn("[MOBA] Workspace.Units manquant : tours non enregistrées.")
		return
	end

	local championAggroEvent = ServerStorage:FindFirstChild("MobaChampionAggro")
	if championAggroEvent and championAggroEvent:IsA("BindableEvent") then
		championAggroEvent.Event:Connect(registerChampionAggro)
	else
		warn("[MOBA] Signal serveur MobaChampionAggro manquant : priorité champion désactivée.")
	end
	for _, tower in towers:GetChildren() do
		if tower:IsA("Model") then
			tower.Parent = units
			runTower(tower)
		end
	end
end

return TowerService
