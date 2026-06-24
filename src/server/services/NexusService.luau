--!strict

local Workspace = game:GetService("Workspace")

local MatchStateService = require(script.Parent.MatchStateService)
local Utility = require(script.Parent.Utility)

local NexusService = {}

function NexusService.start()
	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[MOBA] Workspace.Map manquant : objectifs non démarrés.")
		return
	end
	local nexusFolder = map:FindFirstChild("Nexus")
	if not nexusFolder then
		warn("[MOBA] Workspace.Map.Nexus manquant.")
		return
	end
	local units = Workspace:FindFirstChild("Units")
	if not units or not units:IsA("Folder") then
		warn("[MOBA] Workspace.Units manquant : objectifs non enregistrés.")
		return
	end

	for _, nexus in nexusFolder:GetChildren() do
		if nexus:IsA("Model") then
			Utility.attachHealthBar(nexus)
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

	local inhibitors = map:FindFirstChild("Inhibitors")
	if not inhibitors then
		warn("[MOBA] Workspace.Map.Inhibitors manquant.")
		return
	end
	for _, inhibitor in inhibitors:GetChildren() do
		if inhibitor:IsA("Model") then
			Utility.attachHealthBar(inhibitor)
			inhibitor.Parent = units
		end
	end
end

return NexusService
