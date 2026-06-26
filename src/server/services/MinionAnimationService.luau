--!strict

local MinionAnimationService = {}

local LOG_PREFIX = "[MOBA][SpectralMinion]"

local function warnLog(message: string)
	warn(LOG_PREFIX .. " " .. message)
end

local function findAnimation(visualModel: Model, animationName: string): Animation?
	local animations = visualModel:FindFirstChild("Animations")
	if not animations then
		return nil
	end

	local animation = animations:FindFirstChild(animationName)
	if animation and animation:IsA("Animation") then
		return animation
	end

	return nil
end

local function getAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	local created = Instance.new("Animator")
	created.Parent = humanoid
	return created
end

local function loadTrack(animator: Animator, animation: Animation, visualModel: Model, animationName: string): AnimationTrack?
	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not ok then
		warnLog(string.format("Cannot load %s on %s: %s", animationName, visualModel:GetFullName(), tostring(trackOrError)))
		return nil
	end

	return trackOrError :: AnimationTrack
end

function MinionAnimationService.Attach(minionModel: Model, visualModel: Model)
	local humanoid = visualModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warnLog("VisualModel has no Humanoid: " .. visualModel:GetFullName())
		return
	end

	local animator = getAnimator(humanoid)
	local armsAnimation = findAnimation(visualModel, "Arms")
	local attackAnimation = findAnimation(visualModel, "Attack")

	local armsTrack: AnimationTrack? = nil
	local attackTrack: AnimationTrack? = nil

	if armsAnimation then
		armsTrack = loadTrack(animator, armsAnimation, visualModel, "Arms")
		if armsTrack then
			armsTrack.Looped = true
			armsTrack.Priority = Enum.AnimationPriority.Idle
			armsTrack:Play(0.2)
		end
	else
		warnLog("Missing Arms animation on " .. visualModel:GetFullName())
	end

	if attackAnimation then
		attackTrack = loadTrack(animator, attackAnimation, visualModel, "Attack")
		if attackTrack then
			attackTrack.Looped = false
			attackTrack.Priority = Enum.AnimationPriority.Action
		end
	else
		warnLog("Missing Attack animation on " .. visualModel:GetFullName())
	end

	local cleanedUp = false
	local attackConnection: RBXScriptConnection? = nil
	local stateConnection: RBXScriptConnection? = nil
	local ancestryConnection: RBXScriptConnection? = nil

	local function cleanup()
		if cleanedUp then
			return
		end

		cleanedUp = true

		if attackConnection then
			attackConnection:Disconnect()
			attackConnection = nil
		end
		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end
		if ancestryConnection then
			ancestryConnection:Disconnect()
			ancestryConnection = nil
		end

		if armsTrack and armsTrack.IsPlaying then
			armsTrack:Stop(0.2)
		end
		if attackTrack and attackTrack.IsPlaying then
			attackTrack:Stop(0.05)
		end
	end

	attackConnection = minionModel:GetAttributeChangedSignal("AttackTick"):Connect(function()
		if cleanedUp or minionModel:GetAttribute("Dead") == true then
			return
		end

		if attackTrack then
			if attackTrack.IsPlaying then
				attackTrack:Stop(0.03)
			end
			attackTrack:Play(0.05)
		end
	end)

	stateConnection = minionModel:GetAttributeChangedSignal("MinionState"):Connect(function()
		local state = minionModel:GetAttribute("MinionState")
		if state == "Dead" then
			cleanup()
			return
		end

		if armsTrack and not armsTrack.IsPlaying then
			armsTrack:Play(0.2)
		end
	end)

	ancestryConnection = minionModel.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			cleanup()
		end
	end)
end

return MinionAnimationService
