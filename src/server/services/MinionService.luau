--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MinionData = require(ReplicatedStorage.Modules.MinionData)
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local CombatService = require(script.Parent.CombatService)
local UnitFactory = require(script.Parent.UnitFactory)
local Utility = require(script.Parent.Utility)
local MatchStateService = require(script.Parent.MatchStateService)

local MinionService = {}

local waveNumber = 0

local FORMATION_SLOTS = { -4, 0, 4 }

local TARGET_SEARCH_RANGE = 50
local TARGET_DROP_RANGE = 50
local MINION_VISUAL_LOG_LIMIT = 6

type MinionAnimationState = {
	IdleTrack: AnimationTrack?,
	WalkTrack: AnimationTrack?,
	AttackTrack: AnimationTrack?,
	IsWalking: boolean,
}

local minionAnimationStates = setmetatable({}, { __mode = "k" }) :: { [Model]: MinionAnimationState }
local minionVisualLogCount = 0

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

local function getFirstBasePart(instance: Instance): BasePart?
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function getMinionVisualTemplate(): Model?
	local assets = ServerStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local minions = models and models:FindFirstChild("Minions")
	local template = minions and minions:FindFirstChild("MeleeMinionVisual")

	if template and template:IsA("Model") then
		return template
	end

	warn("[MOBA][MINION_VISUAL] ServerStorage.Assets.Models.Minions.MeleeMinionVisual missing")
	return nil
end

local function removeUnsafeVisualDescendants(visual: Model)
	for _, descendant in visual:GetDescendants() do
		if
			descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("Sound")
		then
			descendant:Destroy()
		end
	end
end

local function configureVisualParts(visual: Model)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function hideLegacyGameplayVisual(minion: Model)
	for _, child in minion:GetChildren() do
		if child:IsA("BasePart") then
			child.Transparency = 1
			child.CastShadow = false
		end
	end
end

local function applyTeamAccent(visual: Model, teamName: string?)
	local accentColor: Color3?
	if teamName == SharedConstants.TEAMS.BLUE then
		accentColor = Color3.fromRGB(85, 155, 255)
	elseif teamName == SharedConstants.TEAMS.RED then
		accentColor = Color3.fromRGB(235, 85, 80)
	end

	if not accentColor then
		return
	end

	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			local partName = string.lower(descendant.Name)
			if partName == "torso" or partName == "uppertorso" or partName == "body" then
				descendant.Color = descendant.Color:Lerp(accentColor, 0.28)
				return
			end
		end
	end
end

local function useAnimationControllerForVisual(visual: Model)
	local humanoid = visual:FindFirstChildWhichIsA("Humanoid", true)
	local existingAnimator = humanoid and humanoid:FindFirstChildWhichIsA("Animator")
	local animationController = visual:FindFirstChildWhichIsA("AnimationController", true)

	if not animationController then
		animationController = Instance.new("AnimationController")
		animationController.Name = "AnimationController"
		animationController.Parent = visual
	end

	local controllerAnimator = animationController:FindFirstChildWhichIsA("Animator")
	if existingAnimator then
		existingAnimator.Parent = animationController
	elseif not controllerAnimator then
		controllerAnimator = Instance.new("Animator")
		controllerAnimator.Parent = animationController
	end

	if humanoid then
		humanoid:Destroy()
	end
end

local function getAnimator(visual: Model): Animator?
	local animationController = visual:FindFirstChildWhichIsA("AnimationController", true)
	if animationController then
		local animator = animationController:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animationController
		end
		return animator
	end

	local humanoid = visual:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	return nil
end

local function loadAnimationTrack(animator: Animator, visual: Model, animationName: string, priority: Enum.AnimationPriority): AnimationTrack?
	local animation = visual:FindFirstChild(animationName, true)
	if not animation or not animation:IsA("Animation") then
		return nil
	end

	local success, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success then
		warn(string.format("[MOBA][MINION_VISUAL] Failed to load %s: %s", animationName, tostring(trackOrError)))
		return nil
	end

	local track = trackOrError :: AnimationTrack
	track.Priority = priority
	return track
end

local function setupMinionAnimations(minion: Model, visual: Model)
	local animator = getAnimator(visual)
	if not animator then
		warn("[MOBA][MINION_VISUAL] Animator missing for", minion.Name)
		return
	end

	local idleTrack = loadAnimationTrack(animator, visual, "IdleAnimation", Enum.AnimationPriority.Idle)
	local walkTrack = loadAnimationTrack(animator, visual, "WalkAnimation", Enum.AnimationPriority.Movement)
	local attackTrack = loadAnimationTrack(animator, visual, "AttackAnimation", Enum.AnimationPriority.Action)

	if idleTrack then
		idleTrack.Looped = true
		idleTrack:Play(0.1)
	end

	if walkTrack then
		walkTrack.Looped = true
	end

	if attackTrack then
		attackTrack.Looped = false
	end

	minionAnimationStates[minion] = {
		IdleTrack = idleTrack,
		WalkTrack = walkTrack,
		AttackTrack = attackTrack,
		IsWalking = false,
	}
end

local function setMinionWalking(minion: Model, isWalking: boolean)
	local state = minionAnimationStates[minion]
	if not state or state.IsWalking == isWalking then
		return
	end

	state.IsWalking = isWalking

	if state.WalkTrack then
		if isWalking and not state.WalkTrack.IsPlaying then
			state.WalkTrack:Play(0.1)
		elseif not isWalking and state.WalkTrack.IsPlaying then
			state.WalkTrack:Stop(0.15)
		end
	end

	if state.IdleTrack then
		if isWalking and state.IdleTrack.IsPlaying then
			state.IdleTrack:Stop(0.15)
		elseif not isWalking and not state.IdleTrack.IsPlaying then
			state.IdleTrack:Play(0.15)
		end
	end
end

local function playMinionAttackAnimation(minion: Model)
	local state = minionAnimationStates[minion]
	local attackTrack = state and state.AttackTrack
	if not attackTrack then
		return
	end

	if attackTrack.IsPlaying then
		attackTrack:Stop(0)
	end

	attackTrack:Play(0.05, 1, getGameSpeed())
end

local function attachMinionVisual(minion: Model)
	local template = getMinionVisualTemplate()
	local root = Utility.getRoot(minion) or getFirstBasePart(minion)

	if not template or not root then
		return
	end

	local oldVisual = minion:FindFirstChild("VisualModel")
	if oldVisual then
		oldVisual:Destroy()
	end

	local visual = template:Clone()
	visual.Name = "VisualModel"
	removeUnsafeVisualDescendants(visual)
	useAnimationControllerForVisual(visual)
	configureVisualParts(visual)
	applyTeamAccent(visual, Utility.getTeam(minion))
	visual.Parent = minion

	local visualRoot: BasePart? = nil
	local foundVisualRoot = visual:FindFirstChild("HumanoidRootPart", true)
	if foundVisualRoot and foundVisualRoot:IsA("BasePart") then
		visualRoot = foundVisualRoot
	else
		visualRoot = getFirstBasePart(visual)
	end

	visual:PivotTo(root.CFrame)

	if visualRoot then
		visual.PrimaryPart = visualRoot
		visualRoot.CFrame = root.CFrame

		local weld = Instance.new("WeldConstraint")
		weld.Name = "VisualRootWeld"
		weld.Part0 = root
		weld.Part1 = visualRoot
		weld.Parent = visualRoot
	end

	hideLegacyGameplayVisual(minion)
	setupMinionAnimations(minion, visual)

	if minionVisualLogCount < MINION_VISUAL_LOG_LIMIT then
		minionVisualLogCount += 1
		print("[MOBA][MINION_VISUAL] Attached animated visual")
	end
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
					setMinionWalking(minion, false)
					local didAttack = CombatService.tryAutoAttack(minion, currentTarget, nil)
					if didAttack then
						playMinionAttackAnimation(minion)
					end
				else
					local targetRoot = Utility.getRoot(currentTarget)

					if targetRoot then
						local gameSpeed = getGameSpeed()
						local reachedTarget = moveToward(minion, targetRoot.Position, moveSpeed * gameSpeed, 0.1)
						setMinionWalking(minion, not reachedTarget)
					else
						currentTarget = nil
						minion:SetAttribute("AggroTarget", nil)
						setMinionWalking(minion, false)
					end
				end
			else
				local waypoint = waypoints[waypointIndex]

				if waypoint then
					local targetPosition = getOffsetWaypoint(waypoints, waypointIndex, lateralOffset)
					local gameSpeed = getGameSpeed()
					local reachedWaypoint = moveToward(minion, targetPosition, moveSpeed * gameSpeed, 0.1)

					setMinionWalking(minion, not reachedWaypoint)

					if reachedWaypoint then
						waypointIndex += 1
					end
				else
					setMinionWalking(minion, false)
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
	attachMinionVisual(minion)

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

		while not MatchStateService.isMatchEnded() do
			MinionService.spawnWave()
			task.wait(SharedConstants.MATCH.MINION_WAVE_INTERVAL / getGameSpeed())
		end

		print("[MOBA] Minion spawning stopped — match ended")
	end)
end

return MinionService
