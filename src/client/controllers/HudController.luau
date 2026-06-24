--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)

local HudController = {}
local player = Players.LocalPlayer

local function createLabel(parent: Instance, name: string, position: UDim2, size: UDim2, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.55
	label.TextScaled = true
	label.Text = text
	label.Parent = parent
	return label
end

function HudController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MobaHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "StatusPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromScale(0.5, 0.975)
	panel.Size = UDim2.fromOffset(380, 76)
	panel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local endMatchOverlay = Instance.new("Frame")
	endMatchOverlay.Name = "EndMatchOverlay"
	endMatchOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	endMatchOverlay.Position = UDim2.fromScale(0.5, 0.5)
	endMatchOverlay.Size = UDim2.fromScale(1, 1)
	endMatchOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	endMatchOverlay.BackgroundTransparency = 0.35
	endMatchOverlay.BorderSizePixel = 0
	endMatchOverlay.Visible = false
	endMatchOverlay.Parent = gui

	local endMatchTitle = createLabel(
		endMatchOverlay,
		"EndMatchTitle",
		UDim2.fromScale(0.2, 0.36),
		UDim2.fromScale(0.6, 0.12),
		"VICTORY"
	)
	endMatchTitle.TextStrokeTransparency = 0.2
	endMatchTitle.TextColor3 = Color3.fromRGB(120, 190, 255)

	local endMatchSubtitle = createLabel(
		endMatchOverlay,
		"EndMatchSubtitle",
		UDim2.fromScale(0.25, 0.49),
		UDim2.fromScale(0.5, 0.055),
		"Blue wins"
	)
	endMatchSubtitle.TextStrokeTransparency = 0.35

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local healthBack = Instance.new("Frame")
	healthBack.Name = "HealthBack"
	healthBack.Position = UDim2.fromOffset(18, 38)
	healthBack.Size = UDim2.fromOffset(344, 22)
	healthBack.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = panel

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(55, 205, 105)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack

	local teamLabel = createLabel(panel, "Team", UDim2.fromOffset(18, 8), UDim2.fromOffset(150, 24), "TEAM")
	teamLabel.TextXAlignment = Enum.TextXAlignment.Left
	local stateLabel = createLabel(panel, "State", UDim2.fromOffset(178, 8), UDim2.fromOffset(184, 24), "WAITING")
	stateLabel.TextXAlignment = Enum.TextXAlignment.Right
	local healthLabel = createLabel(healthBack, "Health", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), "650 / 650")

	local levelLabel = createLabel(panel, "Level", UDim2.fromOffset(18, 60), UDim2.fromOffset(90, 18), "LVL 1")
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left

	local goldLabel = createLabel(panel, "Gold", UDim2.fromOffset(118, 60), UDim2.fromOffset(100, 18), "Gold: 0")
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left

	local xpLabel = createLabel(panel, "XP", UDim2.fromOffset(228, 60), UDim2.fromOffset(134, 18), "XP: 0")
	xpLabel.TextXAlignment = Enum.TextXAlignment.Right

	local function updateTeam()
		local teamName = player:GetAttribute("Team")
		teamLabel.Text = "ÉQUIPE " .. tostring(teamName or "?")
		teamLabel.TextColor3 = if teamName == "Red"
			then Color3.fromRGB(255, 100, 105)
			else Color3.fromRGB(100, 180, 255)
	end

	local function bindCharacter(character: Model)
		local function updateHealth()
			local health = character:GetAttribute("Health")
			local maxHealth = character:GetAttribute("MaxHealth")
			if typeof(health) == "number" and typeof(maxHealth) == "number" and maxHealth > 0 then
				healthFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
				healthLabel.Text = string.format("%d / %d", math.floor(health), math.floor(maxHealth))
			end
		end
		local function updateProgression()
			local level = character:GetAttribute("Level")
			local gold = character:GetAttribute("Gold")
			local xp = character:GetAttribute("XP")

			levelLabel.Text = "LVL " .. tostring(level or 1)
			goldLabel.Text = "Gold: " .. tostring(gold or 0)
			xpLabel.Text = "XP: " .. tostring(xp or 0)
		end
		character:GetAttributeChangedSignal("Health"):Connect(updateHealth)
		character:GetAttributeChangedSignal("MaxHealth"):Connect(updateHealth)
		character:GetAttributeChangedSignal("Level"):Connect(updateProgression)
		character:GetAttributeChangedSignal("Gold"):Connect(updateProgression)
		character:GetAttributeChangedSignal("XP"):Connect(updateProgression)
		updateHealth()
		updateProgression()
	end

	player:GetAttributeChangedSignal("Team"):Connect(updateTeam)
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end
	updateTeam()

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes or not remotes:IsA("Folder") then
		warn("[MOBA] Remotes indisponibles : vérifie que le serveur a démarré et que Workspace.Map existe.")
		return
	end

	local matchRemote = remotes:WaitForChild(SharedConstants.REMOTES.MATCH_STATE_UPDATE, 10)
	if not matchRemote or not matchRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent MatchStateUpdate indisponible.")
		return
	end
	matchRemote.OnClientEvent:Connect(function(state, winner)
		if state == "Ended" then
			local winningTeam = tostring(winner)
			local playerTeam = tostring(player:GetAttribute("Team") or "?")
			local playerWon = winningTeam == playerTeam

			stateLabel.Text = "FIN : " .. winningTeam .. " WINS"

			endMatchOverlay.Visible = true
			endMatchTitle.Text = if playerWon then "VICTORY" else "DEFEAT"
			endMatchSubtitle.Text = winningTeam .. " wins"

			endMatchTitle.TextColor3 = if playerWon
				then Color3.fromRGB(120, 190, 255)
				else Color3.fromRGB(255, 100, 105)
		else
			stateLabel.Text = string.upper(tostring(state))
			endMatchOverlay.Visible = false
		end
	end)
end

return HudController
