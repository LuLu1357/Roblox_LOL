--!strict

local Workspace = game:GetService("Workspace")

local MatchStateService = require(script.Parent.MatchStateService)

local NexusService = {}

function NexusService.start()
	local map = Workspace:WaitForChild("Map")
	local nexusFolder = map:WaitForChild("Nexus")
	local units = Workspace:WaitForChild("Units")

	for _, nexus in nexusFolder:GetChildren() do
		if nexus:IsA("Model") then
			nexus:GetAttributeChangedSignal("Health"):Connect(function()
				local health = nexus:GetAttribute("Health")
				if typeof(health) == "number" and health <= 0 then
					local teamName = nexus:GetAttribute("Team")
					local winner = if teamName == "Blue" then "Red" else "Blue"
					MatchStateService.endMatch(winner)
				end
			end)
			nexus.Parent = units
		end
	end
end

return NexusService
