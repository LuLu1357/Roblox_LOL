--!strict

local SpellBarController = {}
SpellBarController.__index = SpellBarController

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

local function color3FromData(colorData: any): Color3
    if typeof(colorData) == "Color3" then
        return colorData
    end

    if typeof(colorData) == "table"
        and typeof(colorData.R) == "number"
        and typeof(colorData.G) == "number"
        and typeof(colorData.B) == "number"
    then
        return Color3.fromRGB(colorData.R, colorData.G, colorData.B)
    end

    return Color3.fromRGB(110, 110, 110)
end

local function formatSpellStatLine(label: string, value: any): string
    if typeof(value) ~= "number" then
        return ""
    end

    if label == "Cooldown" or label == "Duration" then
        return string.format("%s: %ss", label, tostring(value))
    end

    if label == "DashDistance" then
        return "Dash Distance: " .. tostring(value)
    end

    if label == "MaxHealthBonus" then
        return "Max Health Bonus: " .. tostring(value)
    end

    if label == "ExecuteBonusDamage" then
        return "Execute Bonus Damage: " .. tostring(value)
    end

    if label == "ExecuteThreshold" then
        return "Execute Threshold: " .. tostring(math.floor(value * 100)) .. "%"
    end

    return string.format("%s: %s", label, tostring(value))
end

local function buildSpellTooltipText(spell: table?, slot: number): string
    if typeof(spell) ~= "table" then
        return string.format("Slot %d\nNo spell available.", slot)
    end

    local lines: { string } = {}
    local name = if typeof(spell.DisplayName) == "string" then spell.DisplayName else "Spell"
    table.insert(lines, name)
    if typeof(spell.Type) == "string" then
        table.insert(lines, "Type: " .. spell.Type)
    end

    if typeof(spell.Damage) == "number" then
        table.insert(lines, formatSpellStatLine("Damage", spell.Damage))
    end
    if typeof(spell.Heal) == "number" then
        table.insert(lines, formatSpellStatLine("Heal", spell.Heal))
    end
    if typeof(spell.Range) == "number" then
        table.insert(lines, formatSpellStatLine("Range", spell.Range))
    end
    if typeof(spell.Radius) == "number" then
        table.insert(lines, formatSpellStatLine("Radius", spell.Radius))
    end
    if typeof(spell.Duration) == "number" then
        table.insert(lines, formatSpellStatLine("Duration", spell.Duration))
    end
    if typeof(spell.DashDistance) == "number" then
        table.insert(lines, formatSpellStatLine("DashDistance", spell.DashDistance))
    end
    if typeof(spell.MaxHealthBonus) == "number" then
        table.insert(lines, formatSpellStatLine("MaxHealthBonus", spell.MaxHealthBonus))
    end
    if typeof(spell.ExecuteThreshold) == "number" then
        table.insert(lines, formatSpellStatLine("ExecuteThreshold", spell.ExecuteThreshold))
    end
    if typeof(spell.ExecuteBonusDamage) == "number" then
        table.insert(lines, formatSpellStatLine("ExecuteBonusDamage", spell.ExecuteBonusDamage))
    end
    if typeof(spell.Cooldown) == "number" then
        table.insert(lines, formatSpellStatLine("Cooldown", spell.Cooldown))
    end

    if typeof(spell.Description) == "string" and spell.Description ~= "" then
        table.insert(lines, "")
        table.insert(lines, spell.Description)
    end

    return table.concat(lines, "\n")
end

function SpellBarController.new(parent: Instance, abilityRequest: RemoteEvent?, abilityFeedbackRemote: RemoteEvent?, abilityData: table, mouse: Mouse)
    local self = setmetatable({}, SpellBarController)
    self.abilityRequest = abilityRequest
    self.abilityFeedbackRemote = abilityFeedbackRemote
    self.AbilityData = abilityData
    self.mouse = mouse
    self.currentCharacter = nil
    self.spellButtons = {}
    self.spellInfo = {}
    self.spellCooldownEnds = {}
    self.hoveredSpellSlot = nil

    local spellBar = Instance.new("Frame")
    spellBar.Name = "SpellBar"
    spellBar.Position = UDim2.fromOffset(18, 70)
    spellBar.Size = UDim2.fromOffset(484, 52)
    spellBar.BackgroundTransparency = 1
    spellBar.Parent = parent
    self.spellBar = spellBar

    local spellTooltip = Instance.new("Frame")
    spellTooltip.Name = "SpellTooltip"
    spellTooltip.Size = UDim2.fromOffset(280, 190)
    spellTooltip.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    spellTooltip.BackgroundTransparency = 0.04
    spellTooltip.BorderSizePixel = 0
    spellTooltip.ZIndex = 100
    spellTooltip.Visible = false
    spellTooltip.Parent = parent.Parent or parent
    self.spellTooltip = spellTooltip

    local spellTooltipCorner = Instance.new("UICorner")
    spellTooltipCorner.CornerRadius = UDim.new(0, 10)
    spellTooltipCorner.Parent = spellTooltip

    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.Position = UDim2.fromOffset(10, 10)
    tooltipText.Size = UDim2.new(1, -20, 1, -20)
    tooltipText.BackgroundTransparency = 1
    tooltipText.ZIndex = 101
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.TextColor3 = Color3.fromRGB(235, 240, 250)
    tooltipText.TextSize = 14
    tooltipText.TextWrapped = true
    tooltipText.TextXAlignment = Enum.TextXAlignment.Left
    tooltipText.TextYAlignment = Enum.TextYAlignment.Top
    tooltipText.RichText = false
    tooltipText.TextTransparency = 0
    tooltipText.Visible = true
    tooltipText.Text = ""
    tooltipText.Parent = spellTooltip
    self.tooltipText = tooltipText

    local function updateSpellCooldownUI()
        for slot = 1, 4 do
            local button = self.spellButtons[slot]
            if not button then
                continue
            end

            local endsAt = self.spellCooldownEnds[slot] or 0
            local remaining = endsAt - os.clock()
            local overlay = button:FindFirstChild("CooldownOverlay")
            local label = button:FindFirstChild("CooldownLabel")
            if remaining > 0 then
                if overlay and overlay:IsA("Frame") then
                    overlay.Visible = true
                end
                if label and label:IsA("TextLabel") then
                    label.Visible = true
                    if remaining > 1 then
                        label.Text = tostring(math.ceil(remaining))
                    else
                        label.Text = string.format("%.1f", remaining)
                    end
                end
            else
                if overlay and overlay:IsA("Frame") then
                    overlay.Visible = false
                end
                if label and label:IsA("TextLabel") then
                    label.Visible = false
                end
            end
        end
    end

    function self:updateSpellCooldownUI()
        for slot = 1, 4 do
            local button = self.spellButtons[slot]
            if not button then
                continue
            end

            local endsAt = self.spellCooldownEnds[slot] or 0
            local remaining = endsAt - os.clock()
            local overlay = button:FindFirstChild("CooldownOverlay")
            local label = button:FindFirstChild("CooldownLabel")
            if remaining > 0 then
                if overlay and overlay:IsA("Frame") then
                    overlay.Visible = true
                end
                if label and label:IsA("TextLabel") then
                    label.Visible = true
                    if remaining > 1 then
                        label.Text = tostring(math.ceil(remaining))
                    else
                        label.Text = string.format("%.1f", remaining)
                    end
                end
            else
                if overlay and overlay:IsA("Frame") then
                    overlay.Visible = false
                end
                if label and label:IsA("TextLabel") then
                    label.Visible = false
                end
            end
        end
    end

    function self:hideSpellTooltip()
        self.hoveredSpellSlot = nil
        if self.spellTooltip then
            self.spellTooltip.Visible = false
        end
    end

    function self:showSpellTooltip(slot: number)
        local button = self.spellButtons[slot]
        if not button then
            self:hideSpellTooltip()
            return
        end

        local tooltip = buildSpellTooltipText(self.spellInfo[slot], slot)
        if tooltip == "" then
            tooltip = "Slot " .. tostring(slot) .. "\nNo tooltip data."
        end
        self.tooltipText.Text = tooltip

        local absolutePos = button.AbsolutePosition
        self.spellTooltip.Position = UDim2.fromOffset(absolutePos.X, absolutePos.Y - 158)
        self.spellTooltip.Visible = true
    end

    function self:updateSpellButton(slot: number)
        local button = self.spellButtons[slot]
        if not button then
            return
        end

        local spell = self.spellInfo[slot]
        local iconLabel = button:FindFirstChild("IconLabel") :: TextLabel?
        local keyLabel = button:FindFirstChild("KeyLabel") :: TextLabel?
        local bgColor = Color3.fromRGB(70, 70, 70)
        local text = "-"
        local textColor = Color3.fromRGB(255, 255, 255)

        if typeof(spell) == "table" then
            text = if typeof(spell.IconText) == "string" and spell.IconText ~= ""
                then spell.IconText
                else spell.DisplayName or "?"
            bgColor = color3FromData(spell.IconColor)
            textColor = Color3.fromRGB(20, 20, 20)
        else
            bgColor = Color3.fromRGB(45, 45, 45)
            textColor = Color3.fromRGB(180, 180, 180)
        end

        button.BackgroundColor3 = bgColor
        if iconLabel then
            iconLabel.Text = text
            iconLabel.TextColor3 = textColor
        end
        if keyLabel then
            keyLabel.Text = tostring(slot)
        end
    end

    function self:updateSpellButtons()
        local championId = self.currentCharacter and self.currentCharacter:GetAttribute("ChampionId")
        local championSpells = if typeof(championId) == "string" then self.AbilityData.Spells[championId] else nil
        self.spellCooldownEnds = {}
        for slot = 1, 4 do
            self.spellInfo[slot] = championSpells and championSpells[slot] or nil
            self:updateSpellButton(slot)
        end
        self:hideSpellTooltip()
    end

    local function createSpellButton(slot: number, position: UDim2)
        local button = Instance.new("TextButton")
        button.Name = "SpellButton" .. tostring(slot)
        button.Position = position
        button.Size = UDim2.fromOffset(48, 48)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = ""
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = false
        button.AutoButtonColor = true
        button.Parent = spellBar

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "IconLabel"
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.Position = UDim2.fromOffset(0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.TextScaled = true
        iconLabel.Text = "-"
        iconLabel.Parent = button

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "KeyLabel"
        keyLabel.Position = UDim2.fromOffset(4, 4)
        keyLabel.Size = UDim2.fromOffset(12, 14)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Font = Enum.Font.GothamBold
        keyLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        keyLabel.TextSize = 12
        keyLabel.Text = tostring(slot)
        keyLabel.TextScaled = false
        keyLabel.Parent = button

        local cooldownOverlay = Instance.new("Frame")
        cooldownOverlay.Name = "CooldownOverlay"
        cooldownOverlay.Size = UDim2.fromScale(1, 1)
        cooldownOverlay.Position = UDim2.fromOffset(0, 0)
        cooldownOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        cooldownOverlay.BackgroundTransparency = 0.55
        cooldownOverlay.Visible = false
        cooldownOverlay.BorderSizePixel = 0
        cooldownOverlay.Parent = button

        local cooldownLabel = Instance.new("TextLabel")
        cooldownLabel.Name = "CooldownLabel"
        cooldownLabel.Size = UDim2.fromScale(1, 1)
        cooldownLabel.Position = UDim2.fromOffset(0, 0)
        cooldownLabel.BackgroundTransparency = 1
        cooldownLabel.Font = Enum.Font.GothamBold
        cooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        cooldownLabel.TextScaled = true
        cooldownLabel.Text = ""
        cooldownLabel.Visible = false
        cooldownLabel.Parent = button

        button.MouseButton1Click:Connect(function()
            if self.abilityRequest then
                local mousePosition = self.mouse and self.mouse.Hit and self.mouse.Hit.Position or nil
                self.abilityRequest:FireServer(slot, nil, mousePosition)
            end
        end)

        button.MouseEnter:Connect(function()
            self.hoveredSpellSlot = slot
            task.delay(0.45, function()
                if self.hoveredSpellSlot == slot then
                    self:showSpellTooltip(slot)
                end
            end)
        end)

        button.MouseLeave:Connect(function()
            if self.hoveredSpellSlot == slot then
                self.hoveredSpellSlot = nil
            end
            self:hideSpellTooltip()
        end)

        self.spellButtons[slot] = button
        return button
    end

    for slot = 1, 4 do
        createSpellButton(slot, UDim2.fromOffset((slot - 1) * 56, 0))
    end

    task.spawn(function()
        while spellBar.Parent do
            updateSpellCooldownUI()
            task.wait(0.1)
        end
    end)

    return self
end

function SpellBarController:SetAbilityRequest(abilityRequest: RemoteEvent?)
    self.abilityRequest = abilityRequest
end

function SpellBarController:SetAbilityFeedbackRemote(abilityFeedbackRemote: RemoteEvent?)
    self.abilityFeedbackRemote = abilityFeedbackRemote
    if not self.abilityFeedbackRemote or not self.abilityFeedbackRemote:IsA("RemoteEvent") then
        return
    end

    self.abilityFeedbackRemote.OnClientEvent:Connect(function(state, displayName, slot, cooldown, remaining)
        if typeof(slot) ~= "number" or slot < 1 or slot > 4 then
            return
        end

        local now = os.clock()
        if state == "Cast" then
            if typeof(cooldown) == "number" and cooldown > 0 then
                self.spellCooldownEnds[slot] = now + cooldown
                self:updateSpellCooldownUI()
            end
        elseif state == "Cooldown" then
            local value = if typeof(remaining) == "number" and remaining > 0 then remaining else cooldown
            if typeof(value) == "number" and value > 0 then
                self.spellCooldownEnds[slot] = now + value
                self:updateSpellCooldownUI()
            end
        end
    end)
end

function SpellBarController:BindCharacter(character: Model)
    self.currentCharacter = character
    self:updateSpellButtons()
end

return SpellBarController
