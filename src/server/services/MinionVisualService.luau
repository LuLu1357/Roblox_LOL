--!strict

local ServerStorage = game:GetService("ServerStorage")

local MinionVisualService = {}

local LOG_PREFIX = "[MOBA][MinionVisual]"
local PIGGY_VISUAL_NAME = "PiggyFlyingMinion"
local VISUAL_OFFSET = Vector3.new(0, 5, 0)
local loggedChoices: { [string]: boolean } = {}

local function warnLog(message: string)
	warn(LOG_PREFIX .. " " .. message)
end

local function logChoice(minionType: string, choice: string)
	local key = minionType .. ":" .. choice
	if loggedChoices[key] then
		return
	end

	loggedChoices[key] = true
	print(LOG_PREFIX .. " " .. minionType .. " visual = " .. choice)
end

local function getRoot(model: Model): BasePart?
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return model.PrimaryPart
end

local function getSbiresFolder(): Instance?
	local assets = ServerStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local sbires = models and models:FindFirstChild("sbires")

	return sbires
end

local function getPiggyVisualSource(): Model?
	local sbires = getSbiresFolder()
	if not sbires then
		warnLog("Missing ServerStorage.Assets.Models.sbires; minion gameplay continues without VisualModel")
		return nil
	end

	local cleaned = sbires:FindFirstChild("cleaned")
	local source = cleaned and cleaned:FindFirstChild(PIGGY_VISUAL_NAME)
	if not source or not source:IsA("Model") then
		warnLog("Missing ServerStorage.Assets.Models.sbires.cleaned.PiggyFlyingMinion; Melee minion keeps default/current visual")
		return nil
	end

	local visualRoot = source:FindFirstChild("HumanoidRootPart")
	if not visualRoot or not visualRoot:IsA("BasePart") then
		warnLog("PiggyFlyingMinion has no HumanoidRootPart; Melee minion keeps default/current visual")
		return nil
	end

	return source
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

local function getResolvedMinionType(minionModel: Model, minionType: string?): string?
	if typeof(minionType) == "string" then
		return minionType
	end

	local attribute = minionModel:GetAttribute("MinionType")
	return if typeof(attribute) == "string" then attribute else nil
end

function MinionVisualService.AttachVisual(minionModel: Model, _teamName: string?, minionType: string?)
	local resolvedMinionType = getResolvedMinionType(minionModel, minionType)
	if resolvedMinionType == "Ranged" or resolvedMinionType == "Siege" then
		logChoice(resolvedMinionType, "default/current")
		return
	end

	if resolvedMinionType ~= "Melee" then
		warnLog("Unknown MinionType; minion keeps default/current visual: " .. minionModel:GetFullName())
		return
	end

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

	local source = getPiggyVisualSource()
	if not source then
		logChoice("Melee", "default/current")
		return
	end
	logChoice("Melee", PIGGY_VISUAL_NAME)

	local visualModel = source:Clone()
	visualModel.Name = "VisualModel"
	sanitizeVisualClone(visualModel)

	local visualRoot = visualModel:FindFirstChild("HumanoidRootPart")
	if not visualRoot or not visualRoot:IsA("BasePart") then
		warnLog("Cannot attach VisualModel; HumanoidRootPart missing in " .. source:GetFullName())
		visualModel:Destroy()
		return
	end

	visualModel.PrimaryPart = visualRoot
	visualModel.Parent = minionModel
	visualModel:PivotTo(gameplayRoot.CFrame * CFrame.new(VISUAL_OFFSET))
	sanitizeVisualClone(visualModel)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "VisualModelWeld"
	weld.Part0 = gameplayRoot
	weld.Part1 = visualRoot
	weld.Parent = visualRoot

	hideLegacyVisual(minionModel, gameplayRoot)
end

return MinionVisualService
