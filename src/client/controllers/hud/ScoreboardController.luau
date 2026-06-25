--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer

local ScoreboardController = {}
ScoreboardController.__index = ScoreboardController

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

local function createScoreboardRow(parent: Instance, text: string, isLocalPlayer: boolean?): TextLabel
    local row = Instance.new("TextLabel")
    row.Name = "ScoreboardRow"
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 0.08
    row.BackgroundColor3 = if isLocalPlayer == true
        then Color3.fromRGB(42, 58, 82)
        else Color3.fromRGB(12, 18, 28)
    row.BorderSizePixel = 0
    row.ZIndex = 202
    row.Font = Enum.Font.Gotham
    row.TextColor3 = if isLocalPlayer == true
        then Color3.fromRGB(255, 235, 160)
        else Color3.fromRGB(255, 255, 255)
    row.TextTransparency = 0
    row.TextStrokeTransparency = if isLocalPlayer == true then 0.15 else 0.25
    row.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    row.TextSize = 16
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextYAlignment = Enum.TextYAlignment.Center
    row.Text = text
    row.ClipsDescendants = true
    row.Parent = parent
    return row
end

function ScoreboardController.new(gui: Instance, scoreboardRequest: Instance?, scoreboardUpdate: Instance?)
    local self = setmetatable({}, ScoreboardController)
    self.gui = gui
    self.scoreboardRequest = nil
    self.scoreboardUpdate = nil
    self.scoreboardPanel = nil
    self.scoreboardBlueRows = nil
    self.scoreboardRedRows = nil
    self.scoreboardHeld = false

    self:createScoreboardPanel()
    self:SetRemotes(scoreboardRequest, scoreboardUpdate)

    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end

        if gameProcessed and input.KeyCode ~= Enum.KeyCode.Tab then
            return
        end

        if input.KeyCode == Enum.KeyCode.Tab then
            self.scoreboardHeld = true
            if self.scoreboardPanel then
                self.scoreboardPanel.Visible = true
            end

            if self.scoreboardRequest then
                self.scoreboardRequest:FireServer()
            end

            return
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Tab then
            self.scoreboardHeld = false
            if self.scoreboardPanel then
                self.scoreboardPanel.Visible = false
            end
            return
        end
    end)

    task.spawn(function()
        while self.scoreboardPanel and self.scoreboardPanel.Parent do
            if self.scoreboardHeld and self.scoreboardRequest then
                self.scoreboardRequest:FireServer()
            end
            task.wait(0.5)
        end
    end)

    return self
end

function ScoreboardController:SetRemotes(scoreboardRequest: Instance?, scoreboardUpdate: Instance?)
    self.scoreboardRequest = if scoreboardRequest and scoreboardRequest:IsA("RemoteEvent") then scoreboardRequest else nil
    self.scoreboardUpdate = if scoreboardUpdate and scoreboardUpdate:IsA("RemoteEvent") then scoreboardUpdate else nil

    if self.scoreboardUpdate then
        self.scoreboardUpdate.OnClientEvent:Connect(function(payload)
            if typeof(payload) ~= "table" then
                return
            end
            self:renderScoreboard(payload)
        end)
    elseif scoreboardUpdate ~= nil then
        warn("[MOBA] ScoreboardUpdate exists but is not a RemoteEvent.")
    end
end

function ScoreboardController:clearScoreboardRows()
    if self.scoreboardBlueRows then
        for _, child in ipairs(self.scoreboardBlueRows:GetChildren()) do
            if child.Name == "ScoreboardRow" then
                child:Destroy()
            end
        end
    end
    if self.scoreboardRedRows then
        for _, child in ipairs(self.scoreboardRedRows:GetChildren()) do
            if child.Name == "ScoreboardRow" then
                child:Destroy()
            end
        end
    end
end

function ScoreboardController:renderScoreboard(payload: table)
    self:clearScoreboardRows()

    local blueCount = if typeof(payload.Blue) == "table" then #payload.Blue else 0
    local redCount = if typeof(payload.Red) == "table" then #payload.Red else 0
    print(string.format(
        "[MOBA][SCOREBOARD][CLIENT] Render Blue=%d Red=%d",
        blueCount,
        redCount
    ))

    if self.scoreboardBlueRows and blueCount > 0 then
        for _, entry in ipairs(payload.Blue) do
            local text = string.format(
                "%s | %s | LVL %d | %d/%d/%d | CS %d | %dg",
                tostring(entry.PlayerName or "Unknown"),
                tostring(entry.ChampionId or "None"),
                if typeof(entry.Level) == "number" then entry.Level else 1,
                if typeof(entry.Kills) == "number" then entry.Kills else 0,
                if typeof(entry.Deaths) == "number" then entry.Deaths else 0,
                if typeof(entry.Assists) == "number" then entry.Assists else 0,
                if typeof(entry.CS) == "number" then entry.CS else 0,
                if typeof(entry.Gold) == "number" then entry.Gold else 0
            )
            local isLocalPlayer = localPlayer and entry.PlayerName == localPlayer.Name
            createScoreboardRow(self.scoreboardBlueRows, text, isLocalPlayer)
        end
    end

    if self.scoreboardRedRows and redCount > 0 then
        for _, entry in ipairs(payload.Red) do
            local text = string.format(
                "%s | %s | LVL %d | %d/%d/%d | CS %d | %dg",
                tostring(entry.PlayerName or "Unknown"),
                tostring(entry.ChampionId or "None"),
                if typeof(entry.Level) == "number" then entry.Level else 1,
                if typeof(entry.Kills) == "number" then entry.Kills else 0,
                if typeof(entry.Deaths) == "number" then entry.Deaths else 0,
                if typeof(entry.Assists) == "number" then entry.Assists else 0,
                if typeof(entry.CS) == "number" then entry.CS else 0,
                if typeof(entry.Gold) == "number" then entry.Gold else 0
            )
            local isLocalPlayer = localPlayer and entry.PlayerName == localPlayer.Name
            createScoreboardRow(self.scoreboardRedRows, text, isLocalPlayer)
        end
    end

    if blueCount == 0 and redCount == 0 and self.scoreboardBlueRows then
        createScoreboardRow(self.scoreboardBlueRows, "No scoreboard entries received", false)
    end
end

function ScoreboardController:createScoreboardPanel()
    local scoreboardPanel = Instance.new("Frame")
    scoreboardPanel.Name = "ScoreboardPanel"
    scoreboardPanel.AnchorPoint = Vector2.new(0.5, 0)
    scoreboardPanel.Position = UDim2.fromScale(0.5, 0.08)
    scoreboardPanel.Size = UDim2.fromOffset(760, 360)
    scoreboardPanel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    scoreboardPanel.BackgroundTransparency = 0.02
    scoreboardPanel.BorderSizePixel = 0
    scoreboardPanel.ZIndex = 200
    scoreboardPanel.Visible = false
    scoreboardPanel.Parent = self.gui
    self.scoreboardPanel = scoreboardPanel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = scoreboardPanel

    local title = createLabel(scoreboardPanel, "ScoreboardTitle", UDim2.fromOffset(20, 16), UDim2.fromOffset(220, 28), "SCOREBOARD")
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.ZIndex = 201

    local hint = createLabel(scoreboardPanel, "ScoreboardHint", UDim2.fromOffset(20, 44), UDim2.fromOffset(320, 18), "Release TAB to hide")
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 14
    hint.ZIndex = 201

    local blueTitle = createLabel(scoreboardPanel, "BlueTeamTitle", UDim2.fromOffset(20, 74), UDim2.fromOffset(180, 22), "Blue Team")
    blueTitle.TextColor3 = Color3.fromRGB(120, 180, 255)
    blueTitle.Font = Enum.Font.GothamBold
    blueTitle.TextSize = 18
    blueTitle.ZIndex = 201

    local scoreboardBlueRows = Instance.new("Frame")
    scoreboardBlueRows.Name = "BlueTeamRows"
    scoreboardBlueRows.Position = UDim2.fromOffset(20, 102)
    scoreboardBlueRows.Size = UDim2.fromOffset(360, 220)
    scoreboardBlueRows.BackgroundTransparency = 1
    scoreboardBlueRows.ZIndex = 201
    scoreboardBlueRows.Parent = scoreboardPanel
    self.scoreboardBlueRows = scoreboardBlueRows

    local blueLayout = Instance.new("UIListLayout")
    blueLayout.FillDirection = Enum.FillDirection.Vertical
    blueLayout.SortOrder = Enum.SortOrder.LayoutOrder
    blueLayout.Padding = UDim.new(0, 4)
    blueLayout.Parent = scoreboardBlueRows

    local redTitle = createLabel(scoreboardPanel, "RedTeamTitle", UDim2.fromOffset(380, 74), UDim2.fromOffset(180, 22), "Red Team")
    redTitle.TextColor3 = Color3.fromRGB(255, 120, 120)
    redTitle.Font = Enum.Font.GothamBold
    redTitle.TextSize = 18
    redTitle.ZIndex = 201

    local scoreboardRedRows = Instance.new("Frame")
    scoreboardRedRows.Name = "RedTeamRows"
    scoreboardRedRows.Position = UDim2.fromOffset(380, 102)
    scoreboardRedRows.Size = UDim2.fromOffset(360, 220)
    scoreboardRedRows.BackgroundTransparency = 1
    scoreboardRedRows.ZIndex = 201
    scoreboardRedRows.Parent = scoreboardPanel
    self.scoreboardRedRows = scoreboardRedRows

    local redLayout = Instance.new("UIListLayout")
    redLayout.FillDirection = Enum.FillDirection.Vertical
    redLayout.SortOrder = Enum.SortOrder.LayoutOrder
    redLayout.Padding = UDim.new(0, 4)
    redLayout.Parent = scoreboardRedRows
end

return ScoreboardController
