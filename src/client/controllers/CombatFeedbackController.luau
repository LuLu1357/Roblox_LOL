--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local CombatFeedbackController = {}
local player = Players.LocalPlayer

local function getRoot(unit: Instance): BasePart?
	if unit:IsA("BasePart") then
		return unit
	end
	if unit:IsA("Model") then
		local root = unit:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root
		end
		return unit.PrimaryPart
	end
	return nil
end

local function showDamageFlash(target: Instance)
	local highlight = Instance.new("Highlight")
	highlight.Name = "DamageFlash"
	highlight.Adornee = target
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(255, 35, 35)
	highlight.FillTransparency = 0.2
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.15
	highlight.Parent = Workspace

	local tween = TweenService:Create(
		highlight,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 1, OutlineTransparency = 1 }
	)
	tween:Play()
	task.delay(0.22, function()
		highlight:Destroy()
	end)
end

local function showAttackRay(attacker: Instance, target: Instance, originPosition: Vector3?)
	local attackerRoot = getRoot(attacker)
	local targetRoot = getRoot(target)
	if not attackerRoot or not targetRoot then
		return
	end

	local startPosition = originPosition or attackerRoot.Position
	local endPosition = targetRoot.Position
	local distance = (endPosition - startPosition).Magnitude
	if distance < 0.1 then
		return
	end

	local teamName = attacker:GetAttribute("Team")
	local color = if teamName == "Blue"
		then Color3.fromRGB(75, 180, 255)
		elseif teamName == "Red" then Color3.fromRGB(255, 75, 75)
		else Color3.fromRGB(255, 205, 95)

	local ray = Instance.new("Part")
	ray.Name = "AttackRay"
	ray.Anchored = true
	ray.CanCollide = false
	ray.CanQuery = false
	ray.CanTouch = false
	ray.CastShadow = false
	ray.Material = Enum.Material.Neon
	ray.Color = color
	ray.Transparency = 0.1
	ray.Size = Vector3.new(0.45, 0.45, distance)
	ray.CFrame = CFrame.lookAt((startPosition + endPosition) / 2, endPosition)
	ray.Parent = Workspace

	TweenService:Create(ray, TweenInfo.new(0.16), { Transparency = 1 }):Play()
	task.delay(0.18, function()
		ray:Destroy()
	end)
end

local function createDamageWarning(): (Frame, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatFeedbackGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Parent = player:WaitForChild("PlayerGui")

	local overlay = Instance.new("Frame")
	overlay.Name = "DamageWarning"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(210, 20, 25)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "DamageAmount"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.36)
	label.Size = UDim2.fromOffset(260, 50)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 225, 225)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.TextTransparency = 1
	label.Parent = gui

	return overlay, label
end

function CombatFeedbackController.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes or not remotes:IsA("Folder") then
		warn("[MOBA] Combat feedback indisponible : dossier Remotes absent.")
		return
	end
	local remote = remotes:WaitForChild(SharedConstants.REMOTES.COMBAT_FEEDBACK, 10)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent CombatFeedback indisponible.")
		return
	end

	local overlay, damageLabel = createDamageWarning()
	remote.OnClientEvent:Connect(function(attacker, target, damage, originPosition)
		if typeof(attacker) ~= "Instance" or typeof(target) ~= "Instance" or typeof(damage) ~= "number" then
			return
		end
		local visualOrigin = if typeof(originPosition) == "Vector3" then originPosition else nil
		showAttackRay(attacker, target, visualOrigin)
		showDamageFlash(target)

		if target == player.Character then
			overlay.BackgroundTransparency = 0.82
			damageLabel.Text = string.format("-%d", math.round(damage))
			damageLabel.TextTransparency = 0
			TweenService:Create(overlay, TweenInfo.new(0.38), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(damageLabel, TweenInfo.new(0.38), { TextTransparency = 1 }):Play()
		end
	end)
end

return CombatFeedbackController
