--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local TeamService = {}

function TeamService.assignTeam(player: Player)
	local blueCount = 0
	local redCount = 0
	for _, other in Players:GetPlayers() do
		local teamName = other:GetAttribute("Team")
		if teamName == SharedConstants.TEAMS.BLUE then
			blueCount += 1
		elseif teamName == SharedConstants.TEAMS.RED then
			redCount += 1
		end
	end

	player:SetAttribute("Team", if blueCount <= redCount then SharedConstants.TEAMS.BLUE else SharedConstants.TEAMS.RED)
end

function TeamService.start()
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute("Team") then
			TeamService.assignTeam(player)
		end
	end
	Players.PlayerAdded:Connect(TeamService.assignTeam)
end

return TeamService
