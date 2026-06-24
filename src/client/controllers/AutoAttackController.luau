--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local AutoAttackController = {}
local player = Players.LocalPlayer

local function getTargetFromMouse(): Model?
	local mouse = player:GetMouse()
	local targetPart = mouse.Target
	if not targetPart then
		return nil
	end
	local model = targetPart:FindFirstAncestorOfClass("Model")
	local units = Workspace:FindFirstChild("Units")
	if not model or not units or not model:IsDescendantOf(units) then
		return nil
	end
	if model == player.Character then
		return nil
	end
	return model
end

function AutoAttackController.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes or not remotes:IsA("Folder") then
		warn("[MOBA] Remotes indisponibles : vérifie que le serveur a démarré et que Workspace.Map existe.")
		return
	end

	local attackRequest = remotes:WaitForChild(SharedConstants.REMOTES.AUTO_ATTACK_REQUEST, 10)
	if not attackRequest or not attackRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent AutoAttackRequest indisponible.")
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SelectedTarget"
	highlight.FillColor = Color3.fromRGB(255, 75, 75)
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = Color3.fromRGB(255, 230, 190)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = Workspace

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local target = getTargetFromMouse()
		if target then
			highlight.Adornee = target
			highlight.Enabled = true
			attackRequest:FireServer(target)
		else
			highlight.Enabled = false
			highlight.Adornee = nil
		end
	end)
end

return AutoAttackController
