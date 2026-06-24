--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local JungleData = require(ReplicatedStorage.Modules.JungleData)

local MapValidatorService = {}

local EXPECTED_TOWERS = 22
local EXPECTED_INHIBITORS = 6
local EXPECTED_NEXUS = 2
local MIN_WAYPOINTS = 7

local function addIssue(issues: { string }, message: string)
	table.insert(issues, message)
	warn("[MOBA MapValidator] " .. message)
end

local function getFolder(parent: Instance, name: string, issues: { string }): Instance?
	local child = parent:FindFirstChild(name)
	if not child then
		addIssue(issues, parent:GetFullName() .. "." .. name .. " manquant")
	end
	return child
end

local function countModels(folder: Instance?): number
	local count = 0
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				count += 1
			end
		end
	end
	return count
end

local function validateCount(folder: Instance?, label: string, expected: number, issues: { string })
	local actual = countModels(folder)
	if actual ~= expected then
		addIssue(issues, string.format("%s : %d présent(s), %d attendu(s)", label, actual, expected))
	end
end

local function validatePaths(map: Instance, issues: { string })
	local paths = getFolder(map, "Paths", issues)
	if not paths then
		return
	end
	for _, teamName in { "Blue", "Red" } do
		local team = getFolder(paths, teamName, issues)
		if team then
			for _, laneName in { "Top", "Mid", "Bot" } do
				local lane = getFolder(team, laneName, issues)
				if lane then
					local waypointCount = 0
					for _, child in lane:GetChildren() do
						if child:IsA("BasePart") then
							waypointCount += 1
						end
					end
					if waypointCount < MIN_WAYPOINTS then
						addIssue(
							issues,
							string.format("Paths.%s.%s contient %d waypoints, minimum %d", teamName, laneName, waypointCount, MIN_WAYPOINTS)
						)
					end
				end
			end
		end
	end
end

local function validateSpawns(map: Instance, issues: { string })
	local playerSpawns = getFolder(map, "PlayerSpawns", issues)
	local minionSpawns = getFolder(map, "MinionSpawns", issues)
	for _, teamName in { "Blue", "Red" } do
		if playerSpawns and not playerSpawns:FindFirstChild(teamName) then
			addIssue(issues, "PlayerSpawns." .. teamName .. " manquant")
		end
		local teamSpawns = minionSpawns and minionSpawns:FindFirstChild(teamName)
		if not teamSpawns then
			addIssue(issues, "MinionSpawns." .. teamName .. " manquant")
		else
			for _, laneName in { "Top", "Mid", "Bot" } do
				if not teamSpawns:FindFirstChild(laneName) then
					addIssue(issues, string.format("MinionSpawns.%s.%s manquant", teamName, laneName))
				end
			end
		end
	end
end

local function validateJungle(map: Instance, issues: { string })
	local camps = getFolder(map, "JungleCamps", issues)
	if not camps then
		return
	end
	local campCount = 0
	for _, camp in camps:GetChildren() do
		if camp:IsA("BasePart") then
			campCount += 1
			local campType = camp:GetAttribute("CampType")
			if typeof(campType) ~= "string" or not JungleData.Camps[campType] then
				addIssue(issues, camp:GetFullName() .. " possède un CampType invalide")
			end
		end
	end
	if campCount == 0 then
		addIssue(issues, "JungleCamps ne contient aucun camp")
	end
end

local function validateStaticMap(): boolean
	local issues = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then
		addIssue(issues, "Workspace.Map manquant")
		return false
	end

	validateCount(getFolder(map, "Towers", issues), "Tours", EXPECTED_TOWERS, issues)
	validateCount(getFolder(map, "Inhibitors", issues), "Inhibiteurs", EXPECTED_INHIBITORS, issues)
	validateCount(getFolder(map, "Nexus", issues), "Nexus", EXPECTED_NEXUS, issues)
	validatePaths(map, issues)
	validateSpawns(map, issues)
	validateJungle(map, issues)

	if #issues == 0 then
		print("[MOBA] Map validation passed — 22 towers, 6 inhibitors, 2 Nexus")
		return true
	end
	warn(string.format("[MOBA MapValidator] Validation terminée avec %d problème(s)", #issues))
	return false
end

local function validateRuntimeHealthBars()
	local units = Workspace:FindFirstChild("Units")
	if not units then
		warn("[MOBA MapValidator] Workspace.Units absent pour la vérification des barres de vie")
		return
	end
	local checked = 0
	local missing = 0
	for _, unit in units:GetChildren() do
		local health = unit:GetAttribute("Health")
		local root = if unit:IsA("Model") then unit:FindFirstChild("HumanoidRootPart") or unit.PrimaryPart else nil
		if typeof(health) == "number" and root and root:IsA("BasePart") then
			checked += 1
			if not root:FindFirstChild("MobaHealthBar") then
				missing += 1
				warn("[MOBA MapValidator] Barre de vie absente : " .. unit:GetFullName())
			end
		end
	end
	if checked > 0 and missing == 0 then
		print(string.format("[MOBA] Health bar validation passed — %d units checked", checked))
	end
end

function MapValidatorService.start()
	validateStaticMap()
	task.delay(5, validateRuntimeHealthBars)
end

return MapValidatorService
