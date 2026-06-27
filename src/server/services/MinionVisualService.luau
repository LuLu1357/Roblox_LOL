--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local VisualConfig = require(ReplicatedStorage.Modules.VisualConfig)

local MinionVisualService = {}

local LOG_PREFIX = "[MOBA][MinionVisual]"
local DEFAULT_MELEE_VISUAL_NAME = "PiggyMeleeVisual"
local DEFAULT_VISUAL_OFFSET = Vector3.new(0, 2.5, 0)
local VISUAL_OFFSETS: { [string]: Vector3 } = {
	Melee = Vector3.new(0, 0.5, 0),
	Ranged = Vector3.new(0, 4, 0),
	Siege = Vector3.new(0, 2.5, 0),
}

local TARGET_HITBOX_NAME = "TargetHitbox"
local TARGET_HITBOX_PADDING = Vector3.new(1.5, 1, 1.5)
local loggedMessages: { [string]: boolean } = {}

local function warnLog(message: string)
	warn(LOG_PREFIX .. " " .. message)
end

local function logOnce(key: string, message: string)
	if loggedMessages[key] then
		return
	end

	loggedMessages[key] = true
	print(LOG_PREFIX .. " " .. message)
end

local function warnOnce(key: string, message: string)
	if loggedMessages[key] then
		return
	end

	loggedMessages[key] = true
	warnLog(message)
end

local function lowerName(instanceOrValue: any): string
	if typeof(instanceOrValue) == "Instance" then
		return string.lower(instanceOrValue.Name)
	end

	return string.lower(tostring(instanceOrValue))
end

local function findInstanceByPath(root: Instance, slashPath: string): Instance?
	local current: Instance? = root

	for pathPart in string.gmatch(slashPath, "[^/]+") do
		if not current then
			return nil
		end

		current = current:FindFirstChild(pathPart)
	end

	return current
end

local function getRoot(model: Model): BasePart?
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return model.PrimaryPart
end

local function getVisualOffset(minionType: string): Vector3
	return VISUAL_OFFSETS[minionType] or DEFAULT_VISUAL_OFFSET
end

local function getSbiresFolder(): Instance?
	local legacyAssetModels = VisualConfig.LegacyAssetModels
	if typeof(legacyAssetModels) == "table" then
		local minionsRoot = legacyAssetModels.MinionsRoot
		if typeof(minionsRoot) == "string" then
			local configuredRoot = findInstanceByPath(ServerStorage, minionsRoot)
			if configuredRoot then
				return configuredRoot
			end
		end
	end

	local assets = ServerStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local sbires = models and models:FindFirstChild("sbires")

	return sbires
end

local function getVisualRoot(model: Model): BasePart?
	local visualRoot = model:FindFirstChild("HumanoidRootPart")
	if visualRoot and visualRoot:IsA("BasePart") then
		return visualRoot
	end

	return model.PrimaryPart
end

local function isValidVisualSource(model: Model): boolean
	return getVisualRoot(model) ~= nil
end

local function isRuntimeVisualCandidate(model: Model): boolean
	return model:FindFirstAncestor("archive") == nil and model:FindFirstAncestor("candidates") == nil
end

local function resolveModelFromEntry(entry: any): (Model?, string?)
	local path: string? = nil
	local modelName: string? = nil

	if typeof(entry) == "string" then
		path = entry
	elseif typeof(entry) == "table" then
		local entryPath = entry.Path
		local entryModelName = entry.ModelName

		if typeof(entryPath) == "string" then
			path = entryPath
		end
		if typeof(entryModelName) == "string" then
			modelName = entryModelName
		end
	end

	if not path or path == "" then
		return nil, nil
	end

	local container = findInstanceByPath(ServerStorage, path)
	if not container then
		return nil, path
	end

	if container:IsA("Model") then
		return container, path
	end

	if modelName and modelName ~= "" then
		local model = container:FindFirstChild(modelName)
		if model and model:IsA("Model") then
			return model, path .. "/" .. modelName
		end

		return nil, path .. "/" .. modelName
	end

	return nil, path
end

local function findConfiguredMinionVisualSource(teamName: string?, minionType: string): Model?
	if typeof(teamName) ~= "string" then
		return nil
	end

	local assetModels = VisualConfig.AssetModels
	if typeof(assetModels) ~= "table" then
		return nil
	end

	local minions = assetModels.Minions
	if typeof(minions) ~= "table" then
		return nil
	end

	local teamConfig = minions[teamName]
	if typeof(teamConfig) ~= "table" then
		return nil
	end

	local entry = teamConfig[minionType]
	if entry == nil then
		return nil
	end

	if not findInstanceByPath(ServerStorage, "Assets/Models/Minions") then
		return nil
	end

	local source, expectedPath = resolveModelFromEntry(entry)
	if not expectedPath then
		return nil
	end

	if not source then
		warnOnce(
			"configured-missing:" .. teamName .. ":" .. minionType,
			"Configured Blender minion visual missing at ServerStorage." .. expectedPath .. "; using legacy/default fallback"
		)
		return nil
	end

	if not isRuntimeVisualCandidate(source) then
		warnOnce(
			"configured-runtime-invalid:" .. source:GetFullName(),
			"Configured Blender minion visual is in a non-runtime folder: " .. source:GetFullName()
		)
		return nil
	end

	if not isValidVisualSource(source) then
		warnOnce(
			"configured-root-invalid:" .. source:GetFullName(),
			"Configured Blender minion visual has no HumanoidRootPart or PrimaryPart: " .. source:GetFullName()
		)
		return nil
	end

	logOnce("selected:configured:" .. source:GetFullName(), "Configured minion visual selected: " .. source:GetFullName())
	return source
end

local function getFolderPreferenceScore(model: Model, preferredFolderName: string): number
	if model:FindFirstAncestor(preferredFolderName) then
		return 100
	end

	if model:FindFirstAncestor("cleaned") then
		return 30
	end

	if model.Parent == getSbiresFolder() then
		return 10
	end

	return 0
end

local function findModelByExactName(root: Instance, name: string, preferredFolderName: string): Model?
	local bestSource: Model? = nil
	local bestScore = -math.huge

	for _, descendant in root:GetDescendants() do
		if
			descendant:IsA("Model")
			and descendant.Name == name
			and isRuntimeVisualCandidate(descendant)
			and isValidVisualSource(descendant)
		then
			local score = getFolderPreferenceScore(descendant, preferredFolderName)
			if score > bestScore then
				bestSource = descendant
				bestScore = score
			end
		end
	end

	return bestSource
end

local function findMeleeVisualSource(sbires: Instance, teamName: string?): Model?
	local visualNames: { string } = {}
	if typeof(teamName) == "string" then
		table.insert(visualNames, teamName .. "Melee")
	end
	table.insert(visualNames, DEFAULT_MELEE_VISUAL_NAME)

	for _, visualName in visualNames do
		local source = findModelByExactName(sbires, visualName, "melee")
		if source then
			return source
		end
	end

	return nil
end

local function scoreRangedSource(model: Model, teamName: string?): number
	local name = lowerName(model)
	if not string.find(name, "ranged") then
		return -math.huge
	end
	if not isRuntimeVisualCandidate(model) then
		return -math.huge
	end
	if not isValidVisualSource(model) then
		return -math.huge
	end

	local score = 100
	if typeof(teamName) == "string" and string.find(name, string.lower(teamName)) then
		score += 50
	end
	if model:FindFirstAncestor("ranged") then
		score += 25
	end
	if model.Parent == getSbiresFolder() then
		score += 5
	end

	return score
end

local function findRangedVisualSource(sbires: Instance, teamName: string?): Model?
	local bestSource: Model? = nil
	local bestScore = -math.huge

	for _, descendant in sbires:GetDescendants() do
		if descendant:IsA("Model") then
			local score = scoreRangedSource(descendant, teamName)
			if score > bestScore then
				bestScore = score
				bestSource = descendant
			end
		end
	end

	return bestSource
end

local function logResolvedContainer(minionType: string, source: Model)
	local container = source.Parent
	local containerPath = if container then container:GetFullName() else source:GetFullName()
	logOnce("container:" .. minionType .. ":" .. containerPath, "Resolved " .. string.lower(minionType) .. " container: " .. containerPath)
end

local function getVisualSource(teamName: string?, minionType: string): Model?
	local configuredSource = findConfiguredMinionVisualSource(teamName, minionType)
	if configuredSource then
		return configuredSource
	end

	local sbires = getSbiresFolder()
	if not sbires then
		warnOnce(
			"missing-sbires",
			"Fallback to default visual because ServerStorage.Assets.Models.sbires is missing"
		)
		return nil
	end

	if minionType == "Melee" then
		local source = findMeleeVisualSource(sbires, teamName)
		if not source then
			warnOnce("missing-melee", "Fallback to default visual because no valid melee visual was found")
			return nil
		end

		logResolvedContainer("Melee", source)
		logOnce("selected:Melee:" .. source:GetFullName(), "Melee visual selected: " .. source:GetFullName())
		return source
	end

	if minionType == "Ranged" then
		local source = findRangedVisualSource(sbires, teamName)
		if not source then
			warnOnce("missing-ranged", "Fallback to default visual because no valid ranged visual was found")
			return nil
		end

		logResolvedContainer("Ranged", source)
		logOnce("selected:Ranged:" .. source:GetFullName(), "Ranged visual selected: " .. source:GetFullName())
		return source
	end

	if minionType == "Siege" then
		logOnce("selected:Siege:default", "Siege visual selected: default/current")
	else
		warnOnce("unknown:" .. minionType, "Fallback to default visual because MinionType is unknown: " .. minionType)
	end

	return nil
end

local function sanitizeVisualClone(visualModel: Model)
	local humanoid = visualModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		pcall(function()
			humanoid.EvaluateStateMachine = false
		end)
	end

	for _, descendant in visualModel:GetDescendants() do
		if descendant:IsA("BaseScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("Sound")
			or descendant:IsA("Fire")
			or descendant:IsA("BodyForce")
		then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.CastShadow = false
		end
	end
end

local function hideLegacyVisual(minionModel: Model, gameplayRoot: BasePart)
	gameplayRoot.Transparency = 1
	gameplayRoot.CanCollide = false
	gameplayRoot.CanTouch = false
	gameplayRoot.CastShadow = false

	local accent = minionModel:FindFirstChild("Accent")
	if accent and accent:IsA("BasePart") then
		accent.Transparency = 1
		accent.CanCollide = false
		accent.CanTouch = false
		accent.CanQuery = false
		accent.CastShadow = false
	end
end

local function createTargetHitbox(minionModel: Model, gameplayRoot: BasePart, visualModel: Model)
	local existingHitbox = minionModel:FindFirstChild(TARGET_HITBOX_NAME)
	if existingHitbox then
		existingHitbox:Destroy()
	end

	local visualCFrame, visualSize = visualModel:GetBoundingBox()
	local hitbox = Instance.new("Part")
	hitbox.Name = TARGET_HITBOX_NAME
	hitbox.Transparency = 1
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.Massless = true
	hitbox.CastShadow = false
	hitbox.Size = Vector3.new(
		math.max(visualSize.X + TARGET_HITBOX_PADDING.X, gameplayRoot.Size.X + TARGET_HITBOX_PADDING.X, 3),
		math.max(visualSize.Y + TARGET_HITBOX_PADDING.Y, gameplayRoot.Size.Y + TARGET_HITBOX_PADDING.Y, 4),
		math.max(visualSize.Z + TARGET_HITBOX_PADDING.Z, gameplayRoot.Size.Z + TARGET_HITBOX_PADDING.Z, 3)
	)
	hitbox.CFrame = visualCFrame
	hitbox:SetAttribute("IsTargetHitbox", true)
	hitbox.Parent = minionModel

	local weld = Instance.new("WeldConstraint")
	weld.Name = "TargetHitboxWeld"
	weld.Part0 = gameplayRoot
	weld.Part1 = hitbox
	weld.Parent = hitbox
end

local function getResolvedMinionType(minionModel: Model, minionType: string?): string?
	if typeof(minionType) == "string" then
		return minionType
	end

	local attribute = minionModel:GetAttribute("MinionType")
	return if typeof(attribute) == "string" then attribute else nil
end

local function getResolvedTeamName(minionModel: Model, teamName: string?): string?
	if typeof(teamName) == "string" then
		return teamName
	end

	local attribute = minionModel:GetAttribute("Team")
	return if typeof(attribute) == "string" then attribute else nil
end

function MinionVisualService.AttachVisual(minionModel: Model, teamName: string?, minionType: string?)
	local resolvedMinionType = getResolvedMinionType(minionModel, minionType)
	if not resolvedMinionType then
		warnLog("Unknown MinionType; minion keeps default/current visual: " .. minionModel:GetFullName())
		return
	end
	local resolvedTeamName = getResolvedTeamName(minionModel, teamName)

	local existingVisual = minionModel:FindFirstChild("VisualModel")
	if existingVisual and existingVisual:IsA("Model") then
		return
	elseif existingVisual then
		existingVisual:Destroy()
	end

	local gameplayRoot = getRoot(minionModel)
	if not gameplayRoot then
		warnLog("Cannot attach VisualModel; gameplay root missing on " .. minionModel:GetFullName())
		return
	end

	local source = getVisualSource(resolvedTeamName, resolvedMinionType)
	if not source then
		return
	end

	local visualModel = source:Clone()
	visualModel.Name = "VisualModel"
	sanitizeVisualClone(visualModel)

	local visualRoot = getVisualRoot(visualModel)
	if not visualRoot then
		warnLog("Cannot attach VisualModel; HumanoidRootPart/PrimaryPart missing in " .. source:GetFullName())
		visualModel:Destroy()
		return
	end

	visualModel.PrimaryPart = visualRoot
	visualModel.Parent = minionModel
	visualModel:PivotTo(gameplayRoot.CFrame * CFrame.new(getVisualOffset(resolvedMinionType)))
	sanitizeVisualClone(visualModel)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "VisualModelWeld"
	weld.Part0 = gameplayRoot
	weld.Part1 = visualRoot
	weld.Parent = visualRoot

	hideLegacyVisual(minionModel, gameplayRoot)
	createTargetHitbox(minionModel, gameplayRoot, visualModel)
	logOnce("attached:" .. resolvedMinionType, "Visual attached successfully")
end

return MinionVisualService
