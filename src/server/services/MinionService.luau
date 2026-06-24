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

local FORMATION_SLOTS = { -4, 0, 4 }

local TARGET_SEARCH_RANGE = 50
local TARGET_DROP_RANGE = 50

local function getGameSpeed(): number
	local debugConfig = SharedConstants.DEBUG
	if typeof(debugConfig) ~= "table" then
		return 1
	end

	local speed = debugConfig.GAME_SPEED
	if typeof(speed) ~= "number" or speed <= 0 then
		return 1
	end

	return speed
end

local function getMapFolder(childName: string): Instance?
	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[MOBA] Workspace.Map manquant :", childName, "indisponible.")
		return nil
	end

	local child = map:FindFirstChild(childName)
	if not child then
		warn("[MOBA] Workspace.Map." .. childName .. " manquant.")
		return nil
	end

	return child
end

local function sortedWaypoints(teamName: string, laneName: string): { BasePart }
	local paths = getMapFolder("Paths")
	local teamFolder = paths and paths:FindFirstChild(teamName)
	local lane = teamFolder and teamFolder:FindFirstChild(laneName)

	if not lane then
		warn(string.format("[MOBA] Chemin minion manquant : Paths.%s.%s", teamName, laneName))
		return {}
	end

	local waypoints = {}

	for _, child in lane:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(waypoints, child)
		end
	end

	table.sort(waypoints, function(a, b)
		return a.Name < b.Name
	end)

	if #waypoints == 0 then
		warn(string.format("[MOBA] Aucun waypoint pour %s %s", teamName, laneName))
	end

	return waypoints
end

local function isAllowedMinionTarget(candidate: Instance): boolean
	local unitType = candidate:GetAttribute("UnitType")

	return unitType == "Minion"
		or unitType == "Champion"
		or unitType == "Tower"
		or unitType == "Inhibitor"
		or unitType == "Nexus"
end

local function isValidMinionTarget(minion: Model, candidate: Instance, maxRange: number): boolean
	if candidate == minion then
		return false
	end

	if not candidate.Parent then
		return false
	end

	if not Utility.isAlive(candidate) then
		return false
	end

	if not Utility.areEnemies(minion, candidate) then
		return false
	end

	if not isAllowedMinionTarget(candidate) then
		return false
	end

	if Utility.distance(minion, candidate) > maxRange then
		return false
	end

	return true
end

local function findNearestEnemy(minion: Model, searchRange: number): Instance?
	local units = Workspace:FindFirstChild("Units")
	if not units then
		return nil
	end

	local bestTarget = nil
	local bestDistance = math.huge

	for _, candidate in units:GetChildren() do
		if isValidMinionTarget(minion, candidate, searchRange) then
			local distance = Utility.distance(minion, candidate)

			if distance < bestDistance then
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

local function getOffsetWaypoint(waypoints: { BasePart }, index: number, lateralOffset: number): Vector3
	local waypoint = waypoints[index]
	local previous = waypoints[math.max(1, index - 1)]
	local following = waypoints[math.min(#waypoints, index + 1)]

	local delta = following.Position - previous.Position
	local flatDirection = Vector3.new(delta.X, 0, delta.Z)

	if flatDirection.Magnitude < 0.1 then
		return waypoint.Position
	end

	local direction = flatDirection.Unit
	local normal = Vector3.new(-direction.Z, 0, direction.X)

	return waypoint.Position + normal * lateralOffset
end

local function runMinionAI(minion: Model, waypoints: { BasePart }, lateralOffset: number)
	task.spawn(function()
		local waypointIndex = 1

		local moveSpeedAttribute = minion:GetAttribute("MoveSpeed")
		local moveSpeed = if typeof(moveSpeedAttribute) == "number" then moveSpeedAttribute else 10

		local currentTarget: Instance? = nil

		while minion.Parent and Utility.isAlive(minion) do
			if currentTarget and not isValidMinionTarget(minion, currentTarget, TARGET_DROP_RANGE) then
				currentTarget = nil
				minion:SetAttribute("AggroTarget", nil)
			end

			if not currentTarget then
				currentTarget = findNearestEnemy(minion, TARGET_SEARCH_RANGE)

				if currentTarget then
					minion:SetAttribute("AggroTarget", currentTarget.Name)
				end
			end

			if currentTarget then
				local attackRangeAttribute = minion:GetAttribute("AttackRange")
				local attackRange = if typeof(attackRangeAttribute) == "number" then attackRangeAttribute else 8

				if Utility.distance(minion, currentTarget) <= attackRange then
					CombatService.tryAutoAttack(minion, currentTarget, nil)
				else
					local targetRoot = Utility.getRoot(currentTarget)

					if targetRoot then
						local gameSpeed = getGameSpeed()
						moveToward(minion, targetRoot.Position, moveSpeed * gameSpeed, 0.1)
					else
						currentTarget = nil
						minion:SetAttribute("AggroTarget", nil)
					end
				end
			else
				local waypoint = waypoints[waypointIndex]

				if waypoint then
					local targetPosition = getOffsetWaypoint(waypoints, waypointIndex, lateralOffset)
					local gameSpeed = getGameSpeed()

					if moveToward(minion, targetPosition, moveSpeed * gameSpeed, 0.1) then
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

local function spawnSingle(
	teamName: string,
	laneName: string,
	minionType: string,
	position: Vector3,
	lateralOffset: number,
	waypoints: { BasePart }
)
	local minion = UnitFactory.createMinion(teamName, minionType, position)

	if not minion then
		warn("[MOBA] Type de minion invalide :", minionType)
		return
	end

	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		warn("[MOBA] Workspace.Units manquant : minion non créé.")
		return
	end

	minion:SetAttribute("Lane", laneName)
	minion:SetAttribute("FormationOffset", lateralOffset)
	minion:SetAttribute("AggroTarget", nil)

	minion.Parent = units

	runMinionAI(minion, waypoints, lateralOffset)
end

function MinionService.spawnWaveForTeamAndLane(teamName: string, laneName: string)
	local debugConfig = SharedConstants.DEBUG

	if typeof(debugConfig) == "table" then
		if teamName == "Blue" and debugConfig.SPAWN_BLUE_MINIONS == false then
			return
		end

		if teamName == "Red" and debugConfig.SPAWN_RED_MINIONS == false then
			return
		end
	end
	local spawns = getMapFolder("MinionSpawns")
	local teamSpawns = spawns and spawns:FindFirstChild(teamName)
	local spawnPoint = teamSpawns and teamSpawns:FindFirstChild(laneName)

	if not spawnPoint or not spawnPoint:IsA("BasePart") then
		warn(string.format("[MOBA] Spawn minion manquant : MinionSpawns.%s.%s", teamName, laneName))
		return
	end

	local waypoints = sortedWaypoints(teamName, laneName)
	if #waypoints == 0 then
		return
	end

	local firstDelta = waypoints[1].Position - spawnPoint.Position
	local flatDirection = Vector3.new(firstDelta.X, 0, firstDelta.Z)
	local direction = if flatDirection.Magnitude > 0.1 then flatDirection.Unit else Vector3.new(1, 0, 0)
	local normal = Vector3.new(-direction.Z, 0, direction.X)

	for index = 1, MinionData.Wave.MeleeCount do
		local lateralOffset = FORMATION_SLOTS[index] or 0
		local position = spawnPoint.Position + direction * (8 - index * 2) + normal * lateralOffset

		spawnSingle(teamName, laneName, "Melee", position, lateralOffset, waypoints)
	end

	for index = 1, MinionData.Wave.RangedCount do
		local lateralOffset = FORMATION_SLOTS[index] or 0
		local position = spawnPoint.Position - direction * (7 + index * 2) + normal * lateralOffset

		spawnSingle(teamName, laneName, "Ranged", position, lateralOffset, waypoints)
	end

	if waveNumber % MinionData.Wave.SiegeEveryNWaves == 0 then
		spawnSingle(teamName, laneName, "Siege", spawnPoint.Position - direction * 17, 0, waypoints)
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
			task.wait(SharedConstants.MATCH.MINION_WAVE_INTERVAL / getGameSpeed())
		end
	end)
end

return MinionService