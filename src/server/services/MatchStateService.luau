--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local MatchStateService = {}
MatchStateService.State = "WaitingForPlayers"

local function broadcastState(winningTeam: string?)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(SharedConstants.REMOTES.MATCH_STATE_UPDATE)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireAllClients(MatchStateService.State, winningTeam)
	end
end

function MatchStateService.canStart(): boolean
	return #Players:GetPlayers() >= SharedConstants.MATCH.MIN_PLAYERS_TO_START
end

function MatchStateService.startMatch()
	if MatchStateService.State ~= "WaitingForPlayers" then
		return
	end
	MatchStateService.State = "InGame"
	broadcastState(nil)
	print("[MOBA] Match started")
end

function MatchStateService.endMatch(winningTeam: string)
	if MatchStateService.State == "Ended" then
		return
	end
	MatchStateService.State = "Ended"
	broadcastState(winningTeam)
	print(string.format("[MOBA] Match ended — %s wins", winningTeam))
end
function MatchStateService.isMatchEnded(): boolean
	return MatchStateService.State == "Ended"
end

function MatchStateService.start()
	task.spawn(function()
		while MatchStateService.State == "WaitingForPlayers" do
			if MatchStateService.canStart() then
				MatchStateService.startMatch()
				break
			end
			task.wait(1)
		end
	end)
end

return MatchStateService
