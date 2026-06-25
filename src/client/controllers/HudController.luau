--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SharedConstants = require(ReplicatedStorage.Modules.SharedConstants)
local ItemData = require(ReplicatedStorage.Modules.ItemData)
local AbilityData = require(ReplicatedStorage.Modules.AbilityData)
local SpellBarController = require(script.Parent.hud.SpellBarController)
local ScoreboardController = require(script.Parent.hud.ScoreboardController)
local ChampionSelectPanelController = require(script.Parent.hud.ChampionSelectPanelController)
local TrainingPanelController = require(script.Parent.hud.TrainingPanelController)

local HudController = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local started = false

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
	if started then
		return
	end
	started = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "MobaHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "StatusPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromScale(0.5, 0.975)
	panel.Size = UDim2.fromOffset(520, 84)
	panel.BackgroundColor3 = Color3.fromRGB(17, 24, 34)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local championSelectPanelController: any = ChampionSelectPanelController.new(gui, nil)
	local trainingPanelController: any = TrainingPanelController.new(gui)
	local spellBarController: any = SpellBarController.new(panel, nil, nil, AbilityData, mouse)
	local ShopController = require(script.Parent.hud.ShopController)
	local StatsInventoryController = require(script.Parent.hud.StatsInventoryController)
	local shopController: any = ShopController.new(gui, ItemData)
	local statsInventoryController: any = StatsInventoryController.new(panel)

	-- Shop UI handled by ShopController

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.P then
			shopController:ToggleVisible()
			if shopController:IsVisible() then
				if championSelectPanelController then
					championSelectPanelController:SetVisible(false)
				end
				if trainingPanelController then
					trainingPanelController:SetVisible(false)
				end
			end
		end
	end)

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
	healthBack.Size = UDim2.fromOffset(484, 22)
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

	local statsToggleButton = Instance.new("TextButton")
	statsToggleButton.Name = "StatsToggleButton"
	statsToggleButton.Position = UDim2.fromOffset(378, 8)
	statsToggleButton.Size = UDim2.fromOffset(64, 24)
	statsToggleButton.BackgroundColor3 = Color3.fromRGB(50, 66, 88)
	statsToggleButton.BorderSizePixel = 0
	statsToggleButton.Font = Enum.Font.GothamBold
	statsToggleButton.Text = "STATS"
	statsToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	statsToggleButton.TextScaled = true
	statsToggleButton.Parent = panel

	local statsToggleCorner = Instance.new("UICorner")
	statsToggleCorner.CornerRadius = UDim.new(0, 6)
	statsToggleCorner.Parent = statsToggleButton

	local shopHintLabel = createLabel(panel, "ShopHint", UDim2.fromOffset(448, 8), UDim2.fromOffset(54, 24), "P: SHOP")
	shopHintLabel.TextXAlignment = Enum.TextXAlignment.Right

	local championSelectToggleButton = Instance.new("TextButton")
	championSelectToggleButton.Name = "ChampionSelectToggleButton"
	championSelectToggleButton.Position = UDim2.fromOffset(378, 60)
	championSelectToggleButton.Size = UDim2.fromOffset(124, 18)
	championSelectToggleButton.BackgroundColor3 = Color3.fromRGB(50, 66, 88)
	championSelectToggleButton.BorderSizePixel = 0
	championSelectToggleButton.Font = Enum.Font.GothamBold
	championSelectToggleButton.Text = "CHAMPIONS"
	championSelectToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	championSelectToggleButton.TextScaled = true
	championSelectToggleButton.Parent = panel

	local championSelectToggleCorner = Instance.new("UICorner")
	championSelectToggleCorner.CornerRadius = UDim.new(0, 5)
	championSelectToggleCorner.Parent = championSelectToggleButton

	local trainingToggleButton = Instance.new("TextButton")
	trainingToggleButton.Name = "TrainingToggleButton"
	trainingToggleButton.AnchorPoint = Vector2.new(0.5, 1)
	trainingToggleButton.Position = UDim2.new(0.5, 0, 0.975, -92)
	trainingToggleButton.Size = UDim2.fromOffset(104, 24)
	trainingToggleButton.BackgroundColor3 = Color3.fromRGB(52, 68, 58)
	trainingToggleButton.BorderSizePixel = 0
	trainingToggleButton.Font = Enum.Font.GothamBold
	trainingToggleButton.Text = "TRAINING"
	trainingToggleButton.TextColor3 = Color3.fromRGB(230, 255, 235)
	trainingToggleButton.TextScaled = true
	trainingToggleButton.Parent = gui

	local trainingToggleCorner = Instance.new("UICorner")
	trainingToggleCorner.CornerRadius = UDim.new(0, 6)
	trainingToggleCorner.Parent = trainingToggleButton

	-- Stats panel handled by StatsInventoryController

	statsToggleButton.MouseButton1Click:Connect(function()
		statsInventoryController:ToggleVisible()
		if statsInventoryController:IsVisible() then
			trainingPanelController:SetVisible(false)
			if championSelectPanelController then
				championSelectPanelController:SetVisible(false)
			end
		end
	end)
	championSelectToggleButton.MouseButton1Click:Connect(function()
		if championSelectPanelController then
			championSelectPanelController:ToggleVisible()
			if championSelectPanelController:IsVisible() then
				shopController:SetVisible(false)
				statsInventoryController:SetVisible(false)
				trainingPanelController:SetVisible(false)
			end
		end
	end)
	trainingToggleButton.MouseButton1Click:Connect(function()
		trainingPanelController:ToggleVisible()
		if trainingPanelController:IsVisible() then
			shopController:SetVisible(false)
			if championSelectPanelController then
				championSelectPanelController:SetVisible(false)
			end
			statsInventoryController:SetVisible(false)
		end
	end)

	-- Shop UI handled by ShopController

	-- Craft buttons handled by ShopController

	-- Craft and inventory logic handled by ShopController

	local function updateTeam()
		local teamName = player:GetAttribute("Team")
		teamLabel.Text = "ÉQUIPE " .. tostring(teamName or "?")
		teamLabel.TextColor3 = if teamName == "Red"
			then Color3.fromRGB(255, 100, 105)
			else Color3.fromRGB(100, 180, 255)
	end

	local function bindCharacter(character: Model)
		if spellBarController then
			spellBarController:BindCharacter(character)
		end

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

			if shopController then
				shopController:UpdateForCharacter(character)
			end
		end

		character:GetAttributeChangedSignal("Health"):Connect(updateHealth)
		character:GetAttributeChangedSignal("MaxHealth"):Connect(updateHealth)
		character:GetAttributeChangedSignal("Level"):Connect(updateProgression)
		character:GetAttributeChangedSignal("Gold"):Connect(function()
			updateProgression()
			if shopController then
				shopController:UpdateForCharacter(character)
			end
		end)
		character:GetAttributeChangedSignal("ChampionId"):Connect(function()
			if spellBarController then
				spellBarController:BindCharacter(character)
			end
			if championSelectPanelController then
				championSelectPanelController:UpdateSelection(character:GetAttribute("ChampionId"))
			end
		end)
		character:GetAttributeChangedSignal("XP"):Connect(updateProgression)

		updateHealth()
		updateProgression()

		if spellBarController then
			spellBarController:BindCharacter(character)
		end

		if shopController then
			shopController:BindCharacter(character)
		end

		if statsInventoryController then
			statsInventoryController:BindCharacter(character)
		end
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

	local selectChampionRemote = remotes:WaitForChild(SharedConstants.REMOTES.SELECT_CHAMPION_REQUEST, 10)
	if selectChampionRemote and selectChampionRemote:IsA("RemoteEvent") then
		if championSelectPanelController then
			championSelectPanelController:SetSelectChampionRequest(selectChampionRemote)
		end
	else
		warn("[MOBA] RemoteEvent SelectChampionRequest indisponible.")
	end

	local debugSpawnDummyRemote = remotes:WaitForChild(SharedConstants.REMOTES.DEBUG_SPAWN_DUMMY_REQUEST, 10)
	if debugSpawnDummyRemote and debugSpawnDummyRemote:IsA("RemoteEvent") then
		trainingPanelController:SetSpawnRemote(debugSpawnDummyRemote)
	else
		warn("[MOBA] RemoteEvent DebugSpawnDummyRequest indisponible.")
	end

	local debugClearDummiesRemote = remotes:WaitForChild(SharedConstants.REMOTES.DEBUG_CLEAR_DUMMIES_REQUEST, 10)
	if debugClearDummiesRemote and debugClearDummiesRemote:IsA("RemoteEvent") then
		trainingPanelController:SetClearDummiesRemote(debugClearDummiesRemote)
	else
		warn("[MOBA] RemoteEvent DebugClearDummiesRequest indisponible.")
	end

	local shopBuyRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_BUY_REQUEST, 10)
	if not shopBuyRequest or not shopBuyRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopBuyRequest indisponible.")
		return
	end

	local shopSellRemote = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_SELL_REQUEST, 10)
	if not shopSellRemote or not shopSellRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopSellRequest indisponible.")
		return
	end

	local shopCraftRequest = remotes:WaitForChild(SharedConstants.REMOTES.SHOP_CRAFT_REQUEST, 10)
	if not shopCraftRequest or not shopCraftRequest:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ShopCraftRequest indisponible.")
		return
	end

	-- Wire shop remotes into ShopController
	shopController:SetRemotes(shopBuyRequest, shopSellRemote, shopCraftRequest)

	local abilityRequestRemote = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_REQUEST, 10)
	if abilityRequestRemote and abilityRequestRemote:IsA("RemoteEvent") then
		spellBarController:SetAbilityRequest(abilityRequestRemote)
	else
		warn("[MOBA] RemoteEvent AbilityRequest indisponible.")
	end

	local abilityFeedbackRemoteInstance = remotes:WaitForChild(SharedConstants.REMOTES.ABILITY_FEEDBACK, 10)
	if abilityFeedbackRemoteInstance and abilityFeedbackRemoteInstance:IsA("RemoteEvent") then
		spellBarController:SetAbilityFeedbackRemote(abilityFeedbackRemoteInstance)
	else
		warn("[MOBA] RemoteEvent AbilityFeedback indisponible.")
	end

	local scoreboardRequestRemote = remotes:WaitForChild(SharedConstants.REMOTES.SCOREBOARD_REQUEST, 10)
	local scoreboardUpdateRemote = remotes:WaitForChild(SharedConstants.REMOTES.SCOREBOARD_UPDATE, 10)

	if not scoreboardRequestRemote or not scoreboardRequestRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ScoreboardRequest indisponible.")
	end
	if not scoreboardUpdateRemote or not scoreboardUpdateRemote:IsA("RemoteEvent") then
		warn("[MOBA] RemoteEvent ScoreboardUpdate indisponible.")
	end
	ScoreboardController.new(gui, scoreboardRequestRemote, scoreboardUpdateRemote)

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
