--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local AbilityVFXController = {}

local function getPosition(value: any): Vector3?
	if typeof(value) == "Vector3" then
		return value
	end
	return nil
end

local function createPart(shape: Enum.PartType, position: Vector3, size: Vector3, color: Color3, transparency: number)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Shape = shape
	part.Color = color
	part.Transparency = transparency
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace
	return part
end

local function createBall(position: Vector3, color: Color3, size: number, duration: number)
	local part = createPart(Enum.PartType.Ball, position, Vector3.new(0.2, 0.2, 0.2), color, 0.15)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, {
		Size = Vector3.new(size, size, size),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(part, duration + 0.05)
	return part
end

local function createRing(position: Vector3, color: Color3, radius: number, duration: number)
	local part = createPart(Enum.PartType.Cylinder, position, Vector3.new(radius * 2, 0.15, radius * 2), color, 0.3)
	part.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, {
		Size = Vector3.new(radius * 2.2, 0.15, radius * 2.2),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(part, duration + 0.05)
	return part
end

local function createBeam(startPos: Vector3, endPos: Vector3, color: Color3, duration: number)
	local distance = (endPos - startPos).Magnitude
	if distance < 0.5 then
		createBall(endPos, color, 1.2, duration)
		return
	end

	local midpoint = (startPos + endPos) / 2
	local part = createPart(Enum.PartType.Block, midpoint, Vector3.new(0.2, 0.2, distance), color, 0.25)
	part.CFrame = CFrame.new(midpoint, endPos) * CFrame.Angles(0, math.rad(90), 0)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, {
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(part, duration + 0.05)
	return part
end

local function createPulse(position: Vector3, color: Color3, radius: number, duration: number)
	local part = createPart(Enum.PartType.Ball, position, Vector3.new(0.2, 0.2, 0.2), color, 0.2)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, {
		Size = Vector3.new(radius, radius, radius),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(part, duration + 0.05)
	return part
end

local function getColorForPayload(payload: table): Color3
	local championId = payload.ChampionId
	local abilityType = payload.Type

	if abilityType == "SelfHeal" or abilityType == "AllyOrSelfHeal" or abilityType == "TeamHeal" then
		return Color3.fromRGB(80, 230, 140)
	end

	if abilityType == "ExecuteDamage" then
		return Color3.fromRGB(230, 40, 60)
	end

	if championId == "Mage" then
		return Color3.fromRGB(255, 130, 45)
	elseif championId == "Assassin" then
		return Color3.fromRGB(170, 80, 230)
	elseif championId == "Tank" then
		return Color3.fromRGB(220, 160, 80)
	elseif championId == "Marksman" then
		return Color3.fromRGB(255, 210, 80)
	elseif championId == "Support" then
		return Color3.fromRGB(140, 230, 190)
	end

	return Color3.fromRGB(120, 180, 255)
end

local function resolveAbilityPosition(payload: table): Vector3?
	return getPosition(payload.TargetPosition)
		or getPosition(payload.CenterPosition)
		or getPosition(payload.CasterPosition)
end

function AbilityVFXController.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes or not remotes:IsA("Folder") then
		warn("[MOBA][VFX] Remotes unavailable")
		return
	end

	local abilityVFX = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_VFX, 10)
	if not abilityVFX or not abilityVFX:IsA("RemoteEvent") then
		warn("[MOBA][VFX] AbilityVFX remote unavailable")
		return
	end

	abilityVFX.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		AbilityVFXController.play(payload)
	end)
end

function AbilityVFXController.play(payload: table)
	local abilityType = payload.Type
	local color = getColorForPayload(payload)
	local casterPos = getPosition(payload.CasterPosition)
	local targetPos = getPosition(payload.TargetPosition)
	local centerPos = getPosition(payload.CenterPosition)
	local position = targetPos or centerPos or casterPos
	local radius = typeof(payload.Radius) == "number" and payload.Radius or 20

	if abilityType == "RangedDamage" then
		if casterPos and targetPos then
			createBeam(casterPos, targetPos, color, 0.28)
		end
		if targetPos then
			createImpact(targetPos, color, 0.14, 0.22)
		else
			createPulse(position or Vector3.new(), color, 8, 0.22)
		end
		return
	end

	if abilityType == "MeleeDamage" or abilityType == "ExecuteDamage" then
		createPulse(position or Vector3.new(), color, 10, 0.18)
		createBall(position or Vector3.new(), color, 0.8, 0.18)
		return
	end

	if abilityType == "DashDamage" then
		if casterPos and targetPos then
			createBeam(casterPos, targetPos, color, 0.25)
		end
		createPulse(position or Vector3.new(), color, 8, 0.16)
		return
	end

	if abilityType == "DashForward" then
		local source = casterPos or position or Vector3.new()
		local destination = centerPos or casterPos or position or Vector3.new()
		createBeam(source, destination, color, 0.24)
		createPulse(destination, color, 10, 0.18)
		return
	end

	if abilityType == "AoEDamage" or abilityType == "AoEDamageAtTarget" then
		createRing(position or Vector3.new(), color, radius, 0.34)
		createPulse(position or Vector3.new(), color, math.max(radius * 0.5, 8), 0.24)
		return
	end

	if abilityType == "SelfHeal" or abilityType == "AllyOrSelfHeal" or abilityType == "TeamHeal" then
		local healColor = Color3.fromRGB(80, 230, 140)
		createPulse(position or Vector3.new(), healColor, 12, 0.26)
		if abilityType == "TeamHeal" then
			createRing(position or Vector3.new(), healColor, 22, 0.38)
		end
		return
	end

	if abilityType == "TemporaryMaxHealth" then
		local shieldColor = Color3.fromRGB(255, 200, 80)
		createRing(position or Vector3.new(), shieldColor, 16, 0.4)
		createPulse(position or Vector3.new(), shieldColor, 12, 0.22)
		return
	end

	if position then
		createPulse(position, color, 8, 0.18)
	end
end

local function createImpact(position: Vector3, color: Color3, size: number, duration: number)
	return createBall(position, color, size, duration)
end

return AbilityVFXController
