--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local FogController = {}
local player = Players.LocalPlayer

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return model.PrimaryPart
end

local function setVisible(model: Model, visible: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = if visible then 0 else 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

function FogController.start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < SharedConstants.VISION.UPDATE_INTERVAL then
			return
		end
		elapsed = 0

		local character = player.Character
		local myRoot = character and getRoot(character)
		local myTeam = player:GetAttribute("Team")
		local units = Workspace:FindFirstChild("Units")
		if not myRoot or typeof(myTeam) ~= "string" or not units then
			return
		end

		for _, unit in units:GetChildren() do
			if unit:IsA("Model") and unit ~= character then
				local unitRoot = getRoot(unit)
				local unitTeam = unit:GetAttribute("Team")
				if unitRoot and typeof(unitTeam) == "string" then
					local visible = unitTeam == myTeam
						or (myRoot.Position - unitRoot.Position).Magnitude <= SharedConstants.VISION.PLAYER_RADIUS
					setVisible(unit, visible)
				end
			end
		end
	end)
end

return FogController
