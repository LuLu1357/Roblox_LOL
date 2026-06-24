--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}
local player = Players.LocalPlayer

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

function InputController.start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed then
			setKey(input.KeyCode, true)
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
