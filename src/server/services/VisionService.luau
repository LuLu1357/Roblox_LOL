--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local Utility = require(script.Parent.Utility)

local VisionService = {}

VisionService.VisibleUnitsByTeam = {
	Blue = {},
	Red = {},
}

local function clearVisionTables()
	VisionService.VisibleUnitsByTeam.Blue = {}
	VisionService.VisibleUnitsByTeam.Red = {}
end

local function addVisible(teamName: string, unit: Instance)
	local teamTable = VisionService.VisibleUnitsByTeam[teamName]
	if teamTable then
		teamTable[unit] = true
	end
end

local function revealAround(sourceUnit: Instance, radius: number, units: Folder)
	local sourceRoot = Utility.getRoot(sourceUnit)
	local sourceTeam = Utility.getTeam(sourceUnit)
	if not sourceRoot or not sourceTeam or sourceTeam == "Neutral" then
		return
	end

	for _, candidate in units:GetChildren() do
		local candidateRoot = Utility.getRoot(candidate)
		if candidateRoot and (sourceRoot.Position - candidateRoot.Position).Magnitude <= radius then
			addVisible(sourceTeam, candidate)
		end
	end
end

function VisionService.canTeamSeeUnit(teamName: string?, unit: Instance): boolean
	if not teamName then
		return false
	end
	if Utility.getTeam(unit) == teamName then
		return true
	end
	local teamTable = VisionService.VisibleUnitsByTeam[teamName]
	return teamTable ~= nil and teamTable[unit] == true
end

function VisionService.canPlayerSeeUnit(player: Player, unit: Instance): boolean
	local teamName = player:GetAttribute("Team")
	return VisionService.canTeamSeeUnit(if typeof(teamName) == "string" then teamName else nil, unit)
end

function VisionService.updateVision()
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		return
	end

	clearVisionTables()
	for _, unit in units:GetChildren() do
		if Utility.isAlive(unit) then
			local unitType = unit:GetAttribute("UnitType")
			local radius = 0
			if unitType == "Champion" then
				radius = SharedConstants.VISION.PLAYER_RADIUS
			elseif unitType == "Minion" then
				radius = SharedConstants.VISION.MINION_RADIUS
			elseif unitType == "Tower" then
				radius = SharedConstants.VISION.TOWER_RADIUS
			elseif unitType == "JungleMonster" then
				radius = SharedConstants.VISION.JUNGLE_MONSTER_RADIUS
			end
			if radius > 0 then
				revealAround(unit, radius, units)
			end
		end
	end
end

function VisionService.start()
	task.spawn(function()
		while true do
			VisionService.updateVision()
			task.wait(SharedConstants.VISION.UPDATE_INTERVAL)
		end
	end)
end

return VisionService
