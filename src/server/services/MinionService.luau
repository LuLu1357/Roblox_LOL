--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MinionData = require(ReplicatedStorage.Modules.MinionData)
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local CombatService = require(script.Parent.CombatService)
local UnitFactory = require(script.Parent.UnitFactory)
local Utility = require(script.Parent.Utility)

local MinionService = {}
local waveNumber = 0

local function sortedWaypoints(teamName: string, laneName: string): { BasePart }
	local lane = Workspace.Map.Paths[teamName][laneName]
	local waypoints = {}
	for _, child in lane:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(waypoints, child)
		end
	end
	table.sort(waypoints, function(a, b)
		return a.Name < b.Name
	end)
	return waypoints
end

local function findNearestEnemy(minion: Model, searchRange: number): Instance?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		return nil
	end
	local bestTarget = nil
	local bestDistance = math.huge
	for _, candidate in units:GetChildren() do
		if candidate ~= minion and Utility.isAlive(candidate) and Utility.areEnemies(minion, candidate) then
			local distance = Utility.distance(minion, candidate)
			if distance <= searchRange and distance < bestDistance then
				bestTarget = candidate
				bestDistance = distance
			end
		end
	end
	return bestTarget
end

local function moveToward(minion: Model, targetPosition: Vector3, speed: number, deltaTime: number): boolean
	local root = Utility.getRoot(minion)
	if not root then
		return true
	end
	local current = root.Position
	local flatTarget = Vector3.new(targetPosition.X, current.Y, targetPosition.Z)
	local delta = flatTarget - current
	if delta.Magnitude <= 2 then
		return true
	end
	local step = math.min(speed * deltaTime, delta.Magnitude)
	local nextPosition = current + delta.Unit * step
	minion:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit))
	return false
end

local function runMinionAI(minion: Model, waypoints: { BasePart })
	task.spawn(function()
		local waypointIndex = 1
		local moveSpeedAttribute = minion:GetAttribute("MoveSpeed")
		local moveSpeed = if typeof(moveSpeedAttribute) == "number" then moveSpeedAttribute else 10

		while minion.Parent and Utility.isAlive(minion) do
			local target = findNearestEnemy(minion, 58)
			if target then
				local attackRangeAttribute = minion:GetAttribute("AttackRange")
				local attackRange = if typeof(attackRangeAttribute) == "number" then attackRangeAttribute else 8
				if Utility.distance(minion, target) <= attackRange then
					CombatService.tryAutoAttack(minion, target, nil)
				else
					local targetRoot = Utility.getRoot(target)
					if targetRoot then
						moveToward(minion, targetRoot.Position, moveSpeed, 0.1)
					end
				end
			else
				local waypoint = waypoints[waypointIndex]
				if waypoint then
					if moveToward(minion, waypoint.Position, moveSpeed, 0.1) then
						waypointIndex += 1
					end
				end
			end
			task.wait(0.1)
		end

		task.wait(2)
		if minion.Parent then
			minion:Destroy()
		end
	end)
end

local function spawnSingle(teamName: string, laneName: string, minionType: string, position: Vector3)
	local minion = UnitFactory.createMinion(teamName, minionType, position)
	if not minion then
		return
	end
	minion:SetAttribute("Lane", laneName)
	minion.Parent = Workspace:WaitForChild("Units")
	runMinionAI(minion, sortedWaypoints(teamName, laneName))
end

function MinionService.spawnWaveForTeamAndLane(teamName: string, laneName: string)
	local spawnPoint = Workspace.Map.MinionSpawns[teamName][laneName]
	local forward = if teamName == "Blue" then 1 else -1
	for index = 1, MinionData.Wave.MeleeCount do
		spawnSingle(
			teamName,
			laneName,
			"Melee",
			spawnPoint.Position + Vector3.new(-index * 4 * forward, 0, index * 2 - 4)
		)
	end
	for index = 1, MinionData.Wave.RangedCount do
		spawnSingle(
			teamName,
			laneName,
			"Ranged",
			spawnPoint.Position + Vector3.new(-index * 4 * forward, 0, index * 2 + 5)
		)
	end
	if waveNumber % MinionData.Wave.SiegeEveryNWaves == 0 then
		spawnSingle(teamName, laneName, "Siege", spawnPoint.Position + Vector3.new(-18 * forward, 0, 0))
	end
end

function MinionService.spawnWave()
	waveNumber += 1
	for _, teamName in SharedConstants.TEAMS do
		for _, laneName in SharedConstants.LANES do
			MinionService.spawnWaveForTeamAndLane(teamName, laneName)
		end
	end
	print(string.format("[MOBA] Wave %d spawned", waveNumber))
end

function MinionService.start()
	task.spawn(function()
		task.wait(3)
		while true do
			MinionService.spawnWave()
			task.wait(SharedConstants.MATCH.MINION_WAVE_INTERVAL)
		end
	end)
end

return MinionService
