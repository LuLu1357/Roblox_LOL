--!strict

local ChampionSelectPanelController = {}
ChampionSelectPanelController.__index = ChampionSelectPanelController

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

function ChampionSelectPanelController.new(gui: Instance, selectChampionRequest: RemoteEvent?)
    local self = setmetatable({}, ChampionSelectPanelController)
    self.gui = gui
    self.selectChampionRequest = selectChampionRequest
    self.panel = Instance.new("Frame")
    self.panel.Name = "ChampionSelectPanel"
    self.panel.AnchorPoint = Vector2.new(0.5, 0.5)
    self.panel.Position = UDim2.fromScale(0.5, 0.5)
    self.panel.Size = UDim2.fromOffset(560, 190)
    self.panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    self.panel.BackgroundTransparency = 0.04
    self.panel.BorderSizePixel = 0
    self.panel.Visible = false
    self.panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.panel

    local title = createLabel(
        self.panel,
        "ChampionSelectTitle",
        UDim2.fromOffset(20, 16),
        UDim2.fromOffset(300, 30),
        "SELECT CHAMPION"
    )
    title.TextXAlignment = Enum.TextXAlignment.Left

    local hint = createLabel(
        self.panel,
        "ChampionSelectHint",
        UDim2.fromOffset(20, 48),
        UDim2.fromOffset(360, 20),
        "Choose a class to respawn"
    )
    hint.TextXAlignment = Enum.TextXAlignment.Left

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseChampionSelectButton"
    closeButton.Position = UDim2.fromOffset(510, 14)
    closeButton.Size = UDim2.fromOffset(30, 30)
    closeButton.BackgroundColor3 = Color3.fromRGB(65, 45, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 220, 220)
    closeButton.TextScaled = true
    closeButton.Parent = self.panel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

    local buttons: { [string]: TextButton } = {}
    self.championSelectButtons = buttons

    local function createChampionButton(championId: string, position: UDim2)
        local button = Instance.new("TextButton")
        button.Name = championId
        button.Position = position
        button.Size = UDim2.fromOffset(96, 58)
        button.BackgroundColor3 = Color3.fromRGB(38, 48, 64)
        button.BackgroundTransparency = 0.05
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = championId
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Parent = self.panel

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        buttons[championId] = button
        button.MouseButton1Click:Connect(function()
            local remote = self.selectChampionRequest
            if not remote then
                return
            end
            remote:FireServer(championId)
            self:SetVisible(false)
        end)
        return button
    end

    createChampionButton("Tank", UDim2.fromOffset(20, 92))
    createChampionButton("Assassin", UDim2.fromOffset(128, 92))
    createChampionButton("Mage", UDim2.fromOffset(236, 92))
    createChampionButton("Marksman", UDim2.fromOffset(344, 92))
    createChampionButton("Support", UDim2.fromOffset(452, 92))

    closeButton.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)

    return self
end

function ChampionSelectPanelController:SetVisible(visible: boolean)
    if self.panel then
        self.panel.Visible = visible
    end
end

function ChampionSelectPanelController:SetSelectChampionRequest(selectChampionRequest: RemoteEvent?)
    self.selectChampionRequest = if selectChampionRequest and selectChampionRequest:IsA("RemoteEvent") then selectChampionRequest else nil
end

function ChampionSelectPanelController:IsVisible(): boolean
    return self.panel and self.panel.Visible or false
end

function ChampionSelectPanelController:ToggleVisible()
    self:SetVisible(not self:IsVisible())
end

function ChampionSelectPanelController:UpdateSelection(championId: string?)
    for buttonChampionId, button in self.championSelectButtons do
        local isSelected = championId == buttonChampionId
        button.BackgroundColor3 = if isSelected
            then Color3.fromRGB(55, 95, 75)
            else Color3.fromRGB(38, 48, 64)
        button.TextColor3 = if isSelected
            then Color3.fromRGB(220, 255, 225)
            else Color3.fromRGB(255, 255, 255)
    end
end

return ChampionSelectPanelController
