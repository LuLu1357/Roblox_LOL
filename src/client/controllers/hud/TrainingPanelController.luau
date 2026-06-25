--!strict

local TrainingPanelController = {}
TrainingPanelController.__index = TrainingPanelController

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

function TrainingPanelController.new(gui: Instance)
    local self = setmetatable({}, TrainingPanelController)
    self.gui = gui
    self.panel = Instance.new("Frame")
    self.panel.Name = "TrainingPanel"
    self.panel.AnchorPoint = Vector2.new(0.5, 0.5)
    self.panel.Position = UDim2.fromScale(0.5, 0.5)
    self.panel.Size = UDim2.fromOffset(360, 300)
    self.panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    self.panel.BackgroundTransparency = 0.05
    self.panel.BorderSizePixel = 0
    self.panel.Visible = false
    self.panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.panel

    local title = createLabel(
        self.panel,
        "TrainingTitle",
        UDim2.fromOffset(24, 18),
        UDim2.fromOffset(312, 30),
        "TRAINING DUMMIES"
    )
    title.TextXAlignment = Enum.TextXAlignment.Left

    local buttons: { [string]: TextButton } = {}
    self.trainingSpawnButtons = buttons

    local function createTrainingButton(name: string, text: string, position: UDim2): TextButton
        local button = Instance.new("TextButton")
        button.Name = name
        button.Position = position
        button.Size = UDim2.fromOffset(312, 34)
        button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
        button.BackgroundTransparency = 0.04
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Parent = self.panel

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button

        return button
    end

    buttons.EnemyChampion = createTrainingButton(
        "SpawnEnemyChampionButton",
        "Spawn Enemy Champion",
        UDim2.fromOffset(24, 68)
    )
    buttons.AllyChampion = createTrainingButton(
        "SpawnAllyChampionButton",
        "Spawn Ally Champion",
        UDim2.fromOffset(24, 112)
    )
    buttons.EnemyMinion = createTrainingButton(
        "SpawnEnemyMinionButton",
        "Spawn Enemy Minion",
        UDim2.fromOffset(24, 156)
    )
    buttons.AllyMinion = createTrainingButton(
        "SpawnAllyMinionButton",
        "Spawn Ally Minion",
        UDim2.fromOffset(24, 200)
    )

    local clearDummiesButton = createTrainingButton(
        "ClearDummiesButton",
        "Clear Dummies",
        UDim2.fromOffset(24, 244)
    )
    clearDummiesButton.BackgroundColor3 = Color3.fromRGB(66, 45, 52)
    clearDummiesButton.TextColor3 = Color3.fromRGB(255, 220, 225)
    self.clearDummiesButton = clearDummiesButton

    return self
end

function TrainingPanelController:SetVisible(visible: boolean)
    if self.panel then
        self.panel.Visible = visible
    end
end

function TrainingPanelController:IsVisible(): boolean
    return self.panel and self.panel.Visible or false
end

function TrainingPanelController:ToggleVisible()
    self:SetVisible(not self:IsVisible())
end

function TrainingPanelController:SetSpawnRemote(debugSpawnDummyRequest: RemoteEvent?)
    self.debugSpawnDummyRequest = if debugSpawnDummyRequest and debugSpawnDummyRequest:IsA("RemoteEvent") then debugSpawnDummyRequest else nil
    for dummyKind, button in self.trainingSpawnButtons do
        local buttonDummyKind = dummyKind
        button.MouseButton1Click:Connect(function()
            local remote = self.debugSpawnDummyRequest
            if not remote then
                return
            end
            remote:FireServer(buttonDummyKind)
        end)
    end
end

function TrainingPanelController:SetClearDummiesRemote(debugClearDummiesRequest: RemoteEvent?)
    self.debugClearDummiesRequest = if debugClearDummiesRequest and debugClearDummiesRequest:IsA("RemoteEvent") then debugClearDummiesRequest else nil
    if self.clearDummiesButton then
        self.clearDummiesButton.MouseButton1Click:Connect(function()
            local remote = self.debugClearDummiesRequest
            if not remote then
                return
            end
            remote:FireServer()
        end)
    end
end

return TrainingPanelController
