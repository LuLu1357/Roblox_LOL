--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function getMouseWorldPosition(): Vector3?
	if mouse and mouse.Hit then
		return mouse.Hit.Position
	end
	return nil
end

local function fireAbility(slot: number, abilityRequest: RemoteEvent)
	local mousePosition = getMouseWorldPosition()
	abilityRequest:FireServer(slot, nil, mousePosition)
end

local moveState = {
	Forward = false,
	Left = false,
	Backward = false,
	Right = false,
}

local function setKey(keyCode: Enum.KeyCode, value: boolean)
	-- Roblox rapporte la position physique QWERTY des touches.
	-- Sur AZERTY : W = Z physique et A = Q physique.
	if keyCode == Enum.KeyCode.W then
		moveState.Forward = value
	elseif keyCode == Enum.KeyCode.A then
		moveState.Left = value
	elseif keyCode == Enum.KeyCode.S then
		moveState.Backward = value
	elseif keyCode == Enum.KeyCode.D then
		moveState.Right = value
	end
end

local function clearMoveState()
	moveState.Forward = false
	moveState.Left = false
	moveState.Backward = false
	moveState.Right = false
end

local function getMoveVector(): Vector3
	local x = 0
	local z = 0
	if moveState.Forward then
		z -= 1
	end
	if moveState.Backward then
		z += 1
	end
	if moveState.Left then
		x -= 1
	end
	if moveState.Right then
		x += 1
	end

	local vector = Vector3.new(x, 0, z)
	return if vector.Magnitude > 1 then vector.Unit else vector
end

local function requestJump()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Dead then
		return
	end

	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

function InputController.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local shopBuyRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_BUY_REQUEST) :: RemoteEvent
	local debugAddGoldRequest = remotes:WaitForChild(SharedConstants.REMOTES.DEBUG_ADD_GOLD_REQUEST) :: RemoteEvent
	local recallRequest = remotes:WaitForChild(SharedConstants.REMOTES.RECALL_REQUEST) :: RemoteEvent
	local recallStateUpdate = remotes:WaitForChild(SharedConstants.REMOTES.RECALL_STATE_UPDATE) :: RemoteEvent
	local abilityRequest = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_REQUEST) :: RemoteEvent
	local abilityFeedback = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_FEEDBACK) :: RemoteEvent

	recallStateUpdate.OnClientEvent:Connect(function(state, duration, reason)
		print("[MOBA][RECALL]", state, duration, reason)
	end)
	abilityFeedback.OnClientEvent:Connect(function(state, displayName, slot, cooldown)
		print("[MOBA][ABILITY]", state, displayName, slot, cooldown)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed then
			if input.KeyCode == Enum.KeyCode.One then
				fireAbility(1, abilityRequest)
				return
			elseif input.KeyCode == Enum.KeyCode.Two then
				fireAbility(2, abilityRequest)
				return
			elseif input.KeyCode == Enum.KeyCode.Three then
				fireAbility(3, abilityRequest)
				return
			elseif input.KeyCode == Enum.KeyCode.Four then
				fireAbility(4, abilityRequest)
				return
			elseif input.KeyCode == Enum.KeyCode.R then
				recallRequest:FireServer()
				return
			elseif input.KeyCode == Enum.KeyCode.Space then
				requestJump()
				return
			end
		end

		if input.KeyCode == Enum.KeyCode.G then
			debugAddGoldRequest:FireServer()
			return
		end
		if not gameProcessed then
			setKey(input.KeyCode, true)
		end
		if input.KeyCode == Enum.KeyCode.B then
			shopBuyRequest:FireServer("LongSword")
			return
		elseif input.KeyCode == Enum.KeyCode.N then
			shopBuyRequest:FireServer("RubyCrystal")
			return
		elseif input.KeyCode == Enum.KeyCode.M then
			shopBuyRequest:FireServer("Boots")
			return
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		setKey(input.KeyCode, false)
	end)

	UserInputService.WindowFocusReleased:Connect(clearMoveState)

	RunService:BindToRenderStep("MobaMovement", Enum.RenderPriority.Input.Value + 1, function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- En première personne, le déplacement suit la direction regardée.
			humanoid:Move(getMoveVector(), true)
		end
	end)
end

return InputController
