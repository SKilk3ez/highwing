-- Keep script-level state in a private environment so large feature sets do not
-- exceed Lua/Luau's 200 active-local limit. Executor globals remain readable.
local _octoputBaseEnv = (type(getfenv) == "function" and getfenv(1)) or _G
local _octoputPrivateEnv = setmetatable({}, { __index = _octoputBaseEnv })
if type(setfenv) == "function" then
    -- setfenv is invoked by pcall: level 1 is pcall and level 2 is this chunk.
    local _octoputEnvSetOk = pcall(setfenv, 2, _octoputPrivateEnv)
    if not _octoputEnvSetOk then
        _octoputPrivateEnv = _octoputBaseEnv
    end
else
    -- Compatibility fallback for runtimes without setfenv; names remain global.
    _octoputPrivateEnv = _octoputBaseEnv
end

-- [[ XT Hub Style GUI Script for Executor ]] --
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
RunService = game:GetService("RunService")
HttpService = game:GetService("HttpService")

player = Players.LocalPlayer
playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("XT_Hub_UI") then
    playerGui:FindFirstChild("XT_Hub_UI"):Destroy()
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XT_Hub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
-- Keep the hub above game HUDs such as Player Stats, even if they use a
-- higher DisplayOrder or are recreated while BlackScreen is active.
ScreenGui.DisplayOrder = 10000
ScreenGui.Parent = playerGui

BlackOverlay = Instance.new("Frame")
BlackOverlay.Name = "BlackScreenOverlay"
BlackOverlay.Size = UDim2.new(1, 0, 1, 0)
BlackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
BlackOverlay.BorderSizePixel = 0
BlackOverlay.Visible = false
BlackOverlay.ZIndex = 1
BlackOverlay.Parent = ScreenGui

MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 780, 0, 480)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
-- Keep the complete control window above the BlackScreen Live Match panel.
-- Use Global ZIndex and lift every child together so nested controls stay visible.
MainFrame.ZIndex = 300
MainFrame.Parent = ScreenGui

local function LiftHubGuiObject(guiObject)
    if guiObject and guiObject:IsA("GuiObject") and guiObject ~= MainFrame then
        guiObject.ZIndex = math.max(guiObject.ZIndex, 1) + 300
    end
end

for _, descendant in ipairs(MainFrame:GetDescendants()) do
    LiftHubGuiObject(descendant)
end
MainFrame.DescendantAdded:Connect(function(descendant)
    LiftHubGuiObject(descendant)
end)

HubScale = Instance.new("UIScale")
HubScale.Name = "HubScale"
HubScale.Scale = 1
HubScale.Parent = MainFrame

-- Mobile-friendly floating launcher. The image is cached locally through the executor
-- because Roblox ImageLabel cannot display an arbitrary https URL directly.
FLOATING_LOGO_URL = "https://raw.githubusercontent.com/SKilk3ez/highwing/refs/heads/main/Untitled-2.png"
FLOATING_LOGO_FILE = "OctoputHub/floating_logo.png"
FloatingButton = Instance.new("ImageButton")
FloatingButton.Name = "FloatingOpenButton"
FloatingButton.Size = UDim2.fromOffset(58, 58)
FloatingButton.Position = UDim2.new(1, -78, 0.55, -29)
FloatingButton.AnchorPoint = Vector2.new(0, 0)
FloatingButton.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
FloatingButton.BackgroundTransparency = 0.08
FloatingButton.BorderSizePixel = 0
FloatingButton.AutoButtonColor = true
FloatingButton.Active = true
FloatingButton.Visible = true
FloatingButton.ZIndex = 200
FloatingButton.Image = ""
FloatingButton.ScaleType = Enum.ScaleType.Fit
FloatingButton.Parent = ScreenGui

FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 16)
FloatingCorner.Parent = FloatingButton
FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(110, 115, 145)
FloatingStroke.Transparency = 0.2
FloatingStroke.Thickness = 1.5
FloatingStroke.Parent = FloatingButton

-- Mythic-style aura: layered soft borders with the same animated rainbow treatment
-- used by the game's Mythic GUI gradient effects. The aura is only shown on hover.
FloatingAuraLayers = {}
MythicColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(75, 235, 255)),
    ColorSequenceKeypoint.new(0.20, Color3.fromRGB(90, 125, 255)),
    ColorSequenceKeypoint.new(0.42, Color3.fromRGB(190, 90, 255)),
    ColorSequenceKeypoint.new(0.62, Color3.fromRGB(255, 95, 190)),
    ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 190, 90)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(75, 235, 255)),
})
for index = 1, 3 do
    local aura = Instance.new("Frame")
    aura.Name = "MythicAura" .. index
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.Size = UDim2.new(1, 8 + index * 7, 1, 8 + index * 7)
    aura.BackgroundTransparency = 1
    aura.BorderSizePixel = 0
    aura.Visible = false
    aura.ZIndex = FloatingButton.ZIndex - 1
    aura.Parent = FloatingButton
    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(0, 19 + index * 3)
    auraCorner.Parent = aura
    local auraStroke = Instance.new("UIStroke")
    auraStroke.Name = "AuraStroke"
    auraStroke.Thickness = index == 1 and 3 or (index == 2 and 5 or 7)
    auraStroke.Transparency = index == 1 and 0.08 or (index == 2 and 0.32 or 0.58)
    auraStroke.Parent = aura
    local auraGradient = Instance.new("UIGradient")
    auraGradient.Color = MythicColorSequence
    auraGradient.Rotation = 0
    auraGradient.Parent = auraStroke
    table.insert(FloatingAuraLayers, { frame = aura, stroke = auraStroke, gradient = auraGradient })
end
FloatingButtonScale = Instance.new("UIScale")
FloatingButtonScale.Name = "PressScale"
FloatingButtonScale.Scale = 1
FloatingButtonScale.Parent = FloatingButton
FloatingStrokeGradient = Instance.new("UIGradient")
FloatingStrokeGradient.Color = MythicColorSequence
FloatingStrokeGradient.Parent = FloatingStroke
FloatingFallback = Instance.new("TextLabel")
FloatingFallback.Name = "FallbackText"
FloatingFallback.Size = UDim2.fromScale(1, 1)
FloatingFallback.BackgroundTransparency = 1
FloatingFallback.Text = "O"
FloatingFallback.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingFallback.Font = Enum.Font.GothamBlack
FloatingFallback.TextSize = 30
FloatingFallback.ZIndex = 201
FloatingFallback.Parent = FloatingButton

-- Promotional match overlay: remains visible above the black render-reduction layer.
MatchInfoPanel = Instance.new("Frame")
MatchInfoPanel.Name = "BlackScreenMatchInfo"
MatchInfoPanel.AnchorPoint = Vector2.new(0.5, 0.5)
MatchInfoPanel.Position = UDim2.fromScale(0.5, 0.5)
MatchInfoPanel.Size = UDim2.new(0.84, 0, 0, 286)
MatchPanelConstraint = Instance.new("UISizeConstraint")
MatchPanelConstraint.MinSize = Vector2.new(280, 250)
MatchPanelConstraint.MaxSize = Vector2.new(520, 286)
MatchPanelConstraint.Parent = MatchInfoPanel
MatchInfoPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
MatchInfoPanel.BackgroundTransparency = 0.08
MatchInfoPanel.BorderSizePixel = 0
MatchInfoPanel.Visible = false
MatchInfoPanel.ZIndex = 2
MatchInfoPanel.Parent = ScreenGui
MatchPanelCorner = Instance.new("UICorner")
MatchPanelCorner.CornerRadius = UDim.new(0, 18)
MatchPanelCorner.Parent = MatchInfoPanel
MatchPanelStroke = Instance.new("UIStroke")
MatchPanelStroke.Color = Color3.fromRGB(105, 125, 190)
MatchPanelStroke.Thickness = 2
MatchPanelStroke.Transparency = 0.12
MatchPanelStroke.Parent = MatchInfoPanel

PromoLogo = Instance.new("ImageLabel")
PromoLogo.Name = "PromoLogo"
PromoLogo.Position = UDim2.fromOffset(18, 18)
PromoLogo.Size = UDim2.fromOffset(82, 82)
PromoLogo.BackgroundColor3 = Color3.fromRGB(25, 29, 43)
PromoLogo.BackgroundTransparency = 0.05
PromoLogo.BorderSizePixel = 0
PromoLogo.ScaleType = Enum.ScaleType.Fit
PromoLogo.ZIndex = 3
PromoLogo.Parent = MatchInfoPanel
PromoLogoCorner = Instance.new("UICorner")
PromoLogoCorner.CornerRadius = UDim.new(0, 14)
PromoLogoCorner.Parent = PromoLogo
PromoLogoFallback = Instance.new("TextLabel")
PromoLogoFallback.Size = UDim2.fromScale(1, 1)
PromoLogoFallback.BackgroundTransparency = 1
PromoLogoFallback.Text = "OCTOPUT HUB"
PromoLogoFallback.TextColor3 = Color3.new(1, 1, 1)
PromoLogoFallback.Font = Enum.Font.GothamBlack
PromoLogoFallback.TextSize = 12
PromoLogoFallback.ZIndex = 4
PromoLogoFallback.Parent = PromoLogo

function MakeMatchLabel(name, position, size, text, textSize, color, font)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(235, 239, 255)
    label.TextSize = textSize or 16
    label.Font = font or Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 3
    label.Parent = MatchInfoPanel
    return label
end

MakeMatchLabel("PromoTitle", UDim2.fromOffset(116, 18), UDim2.new(1, -134, 0, 30), "OCTOPUT HUB  |  LIVE MATCH", 19, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack)
MatchStageLabel = MakeMatchLabel("Stage", UDim2.fromOffset(116, 53), UDim2.new(1, -134, 0, 25), "STAGE: Loading...", 15, Color3.fromRGB(190, 205, 255), Enum.Font.GothamBold)
MatchTimerLabel = MakeMatchLabel("ElapsedTime", UDim2.fromOffset(18, 119), UDim2.new(0.5, -25, 0, 32), "TIME  00:00:00", 21, Color3.fromRGB(120, 235, 180), Enum.Font.GothamBlack)
MatchWaveLabel = MakeMatchLabel("Wave", UDim2.new(0.5, 7, 0, 119), UDim2.new(0.5, -25, 0, 32), "WAVE  0", 21, Color3.fromRGB(255, 210, 120), Enum.Font.GothamBlack)
MatchStatsLabel = MakeMatchLabel("PlayerStats", UDim2.fromOffset(18, 166), UDim2.new(1, -36, 0, 98), "PLAYER STATS  |  Loading...", 15, Color3.fromRGB(225, 230, 245), Enum.Font.GothamMedium)
MatchStatsLabel.TextYAlignment = Enum.TextYAlignment.Top
MatchStatsLabel.TextWrapped = true

-- Download/cache the GitHub image when the executor exposes file + custom-asset APIs.
task.spawn(function()
    local ok, asset = pcall(function()
        local assetLoader = getcustomasset or getsynasset
        if type(assetLoader) ~= "function" or type(writefile) ~= "function" then
            error("Executor does not expose getcustomasset/getsynasset and writefile")
        end
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("OctoputHub") then
            pcall(makefolder, "OctoputHub")
        end
        local imageBytes = game:HttpGet(FLOATING_LOGO_URL)
        assert(type(imageBytes) == "string" and #imageBytes > 0, "Logo download returned empty data")
        writefile(FLOATING_LOGO_FILE, imageBytes)
        return assetLoader(FLOATING_LOGO_FILE)
    end)
    if ok and type(asset) == "string" then
        -- Keep the existing floating launcher behavior unchanged.
        FloatingButton.Image = asset
        FloatingFallback.Visible = false
    else
        warn("[OctoputHub] Floating logo could not load; using fallback icon. " .. tostring(asset))
    end
end)

-- The logo displayed in the center BlackScreen promotion panel uses the requested image.
task.spawn(function()
    local ok, asset = pcall(function()
        local assetLoader = getcustomasset or getsynasset
        if type(assetLoader) ~= "function" or type(writefile) ~= "function" then
            error("Executor does not expose getcustomasset/getsynasset and writefile")
        end
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("OctoputHub") then
            pcall(makefolder, "OctoputHub")
        end
        local imageBytes = game:HttpGet("https://raw.githubusercontent.com/SKilk3ez/highwing/refs/heads/main/Untitled-2.png")
        assert(type(imageBytes) == "string" and #imageBytes > 0, "BlackScreen logo download returned empty data")
        writefile("OctoputHub/blackscreen_promo_logo.png", imageBytes)
        return assetLoader("OctoputHub/blackscreen_promo_logo.png")
    end)
    if ok and type(asset) == "string" then
        PromoLogo.Image = asset
        PromoLogoFallback.Visible = false
    else
        warn("[OctoputHub] BlackScreen promotional logo could not load; using panel fallback. " .. tostring(asset))
    end
end)

-- Drag with mouse or touch; tap/click toggles the hub window.
floatingDragging = false
floatingDragInput = nil
floatingDragStart = nil
floatingStartPosition = nil
floatingMoved = false
suppressFloatingClick = false
FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragging = true
        floatingMoved = false
        floatingDragStart = input.Position
        floatingStartPosition = FloatingButton.Position
        floatingDragInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
    end
end)
FloatingButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if floatingDragging and floatingDragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input == floatingDragInput) then
        local delta = input.Position - floatingDragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            floatingMoved = true
        end
        FloatingButton.Position = UDim2.new(
            floatingStartPosition.X.Scale, floatingStartPosition.X.Offset + delta.X,
            floatingStartPosition.Y.Scale, floatingStartPosition.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if floatingDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        floatingDragging = false
        if floatingMoved then
            suppressFloatingClick = true
            task.delay(0.2, function() suppressFloatingClick = false end)
        end
        floatingDragStart = nil
        floatingDragInput = nil
    end
end)
floatingHover = false
floatingStrokeRotationTween = nil
function SetFloatingAura(visible)
    floatingHover = visible
    for _, layer in ipairs(FloatingAuraLayers) do
        if visible then layer.frame.Visible = true end
        TweenService:Create(layer.stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = visible and (layer == FloatingAuraLayers[1] and 0.08 or (layer == FloatingAuraLayers[2] and 0.32 or 0.58)) or 1
        }):Play()
    end
    TweenService:Create(FloatingStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = visible and 0 or 0.2,
        Thickness = visible and 2.2 or 1.5
    }):Play()
    if visible then
        if floatingStrokeRotationTween then floatingStrokeRotationTween:Cancel() end
        FloatingStrokeGradient.Rotation = 0
        floatingStrokeRotationTween = TweenService:Create(FloatingStrokeGradient, TweenInfo.new(3.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
        floatingStrokeRotationTween:Play()
        for _, layer in ipairs(FloatingAuraLayers) do
            if layer.rotationTween then layer.rotationTween:Cancel() end
            layer.gradient.Rotation = 0
            local rotationTween = TweenService:Create(layer.gradient, TweenInfo.new(3.2 + (#FloatingAuraLayers * 0.25), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
            rotationTween:Play()
            layer.rotationTween = rotationTween
        end
    else
        if floatingStrokeRotationTween then floatingStrokeRotationTween:Cancel(); floatingStrokeRotationTween = nil end
        for _, layer in ipairs(FloatingAuraLayers) do
            if layer.rotationTween then layer.rotationTween:Cancel(); layer.rotationTween = nil end
        end
        task.delay(0.2, function()
            if not floatingHover then
                for _, layer in ipairs(FloatingAuraLayers) do layer.frame.Visible = false end
            end
        end)
    end
end

FloatingButton.MouseEnter:Connect(function()
    SetFloatingAura(true)
end)
FloatingButton.MouseLeave:Connect(function()
    SetFloatingAura(false)
end)
FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(FloatingButtonScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.9 }):Play()
    end
end)
FloatingButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(FloatingButtonScale, TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    end
end)
FloatingButton.Activated:Connect(function()
    if suppressFloatingClick then
        suppressFloatingClick = false
        return
    end
    -- A short physical press/release animation, then toggle the hub.
    TweenService:Create(FloatingButtonScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.9 }):Play()
    task.delay(0.08, function()
        if FloatingButton and FloatingButton.Parent then
            TweenService:Create(FloatingButtonScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
    end)
    MainFrame.Visible = not MainFrame.Visible
end)

MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 0, 35)
TitleLabel.Position = UDim2.new(0, 15, 0, 8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Octoput_Hub"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 11
TitleLabel.Parent = MainFrame

Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = MainFrame

SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 4)
SidebarList.Parent = Sidebar

SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -185, 1, -45)
ContentArea.Position = UDim2.new(0, 175, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 11
ContentArea.Parent = MainFrame

CONFIG_FILE = "OctoputHub/config.json"
AllowSave = false

State = {
    AutoPlace = false,
    AutoUpgrade = false,
    AutoUpgradeFarmFirst = true,
    AutoBuffRotation = false,
    PlacePercent = 0,
    PlaceRangeMin = 0,
    PlaceRangeMax = 100,
    AutoFindMatch = false,
    AutoEventQuests = false,
    AutoPickCards = false,
    AutoReplay = true,
    WebhookURL = "",
    WebhookOnEnd = false,
    BlackScreen = false,
    AutoHideGUIOnExecute = false,
    UIScale = 1,
    PlaceHybridGround = true,
    PlaceHybridHill = true,
    BuffPriority = {},
    DebuffAvoid = {},
    UnitConfigs = {},
    UnitNames = {},
    AutoStart = false,
    MainAutoReplay = false,
    AutoNext = false,
    AutoLeave = false,
    AntiAFK = true,
    AutoOpenPortal = false,
    AutoNextPortal = false,
    SelectedPortalTypes = {},
    SelectedPortalTiers = {},
    SelectedPortalModifiers = {},
    SnipeBanner = "",
    SnipeTargets = {},
    SnipeGemLimit = 0,
    SnipeSummonCount = 10,
}

-- Names match GUIService._STAT_ID_TO_STAT_NAME and WaveModifiersServiceClient.is_effect_buff.
BUFF_DEFS = {
    { id = "attack", label = "Attack" },
    { id = "range", label = "Range" },
    { id = "cooldown", label = "Cooldown" },
    { id = "active_cooldown", label = "Active Cooldown" },
    { id = "phys_crit", label = "Phys Crit Chance" },
    { id = "magic_crit", label = "Magic Crit Chance" },
    { id = "phys_damage", label = "Phys Damage" },
    { id = "magic_damage", label = "Magic Damage" },
    { id = "true_damage", label = "True Damage" },
    { id = "boss_damage", label = "Boss Damage" },
    { id = "flying_damage", label = "Damage vs Flying" },
    { id = "enemy_health", label = "Enemy Health" },
    { id = "enemy_speed", label = "Enemy Speed" },
    { id = "enemy_regen", label = "Enemy Regen" },
    { id = "enemy_shield", label = "Enemy Shield" },
    { id = "cost", label = "Placement/Upgrade Cost" },
    { id = "secret", label = "Secret Drop Rate" },
    { id = "blessing", label = "Blessings" },
}

DEBUFF_DEFS = {
    { id = "enemy_health", label = "Enemy Health" },
    { id = "enemy_speed", label = "Enemy Speed" },
    { id = "enemy_regen", label = "Enemy Regen" },
    { id = "enemy_shield", label = "Enemy Shield" },
    { id = "explosive", label = "Explosive Deaths" },
    { id = "resist", label = "Enemy Resist" },
    { id = "attack", label = "Attack" },
    { id = "range", label = "Range" },
    { id = "cooldown", label = "Cooldown" },
    { id = "active_cooldown", label = "Active Cooldown" },
    { id = "cost", label = "Placement/Upgrade Cost" },
    { id = "new_path", label = "New Paths" },
    { id = "flying_chance", label = "Enemy Flying Chance" },
    { id = "burst_speed", label = "Burst Enemy Speed" },
    { id = "lightning", label = "Lightning Strikes" },
    { id = "curse", label = "Curses" },
}

function DefIdSet(defs)
    local set = {}
    for _, def in ipairs(defs) do
        set[def.id] = true
    end
    return set
end

BUFF_IDS = DefIdSet(BUFF_DEFS)
DEBUFF_IDS = DefIdSet(DEBUFF_DEFS)

function SanitizeIdList(list, allowed)
    local out = {}
    local seen = {}
    if type(list) ~= "table" then
        return out
    end
    for _, id in ipairs(list) do
        if type(id) == "string" and allowed[id] and not seen[id] then
            seen[id] = true
            table.insert(out, id)
        end
    end
    return out
end

function CopyStateForSave()
    local unitConfigs = {}
    for id, cfg in pairs(State.UnitConfigs or {}) do
        if type(id) == "string" and type(cfg) == "table" then
            local packed = {}
            if type(cfg.maxPlace) == "number" then
                packed.maxPlace = cfg.maxPlace
            end
            if type(cfg.upgradeTarget) == "number" then
                packed.upgradeTarget = cfg.upgradeTarget
            end
            if type(cfg.placeStartWave) == "number" then
                packed.placeStartWave = cfg.placeStartWave
            end
            if type(cfg.upgradeStartWave) == "number" then
                packed.upgradeStartWave = cfg.upgradeStartWave
            end
            if type(cfg.displayName) == "string" and cfg.displayName ~= "" then
                packed.displayName = cfg.displayName
            end
            if next(packed) ~= nil then
                unitConfigs[id] = packed
            end
        end
    end

    return {
        AutoPlace = State.AutoPlace,
        AutoUpgrade = State.AutoUpgrade,
        AutoUpgradeFarmFirst = State.AutoUpgradeFarmFirst,
        AutoBuffRotation = State.AutoBuffRotation,
        PlacePercent = State.PlacePercent,
        AutoFindMatch = State.AutoFindMatch,
        AutoEventQuests = State.AutoEventQuests,
        AutoPickCards = State.AutoPickCards,
        AutoReplay = State.AutoReplay,
        WebhookURL = State.WebhookURL,
        WebhookOnEnd = State.WebhookOnEnd,
        BlackScreen = State.BlackScreen,
        AutoHideGUIOnExecute = State.AutoHideGUIOnExecute,
        UIScale = State.UIScale,
        PlaceHybridGround = State.PlaceHybridGround,
        PlaceHybridHill = State.PlaceHybridHill,
        BuffPriority = State.BuffPriority,
        DebuffAvoid = State.DebuffAvoid,
        UnitConfigs = unitConfigs,
        UnitNames = State.UnitNames,
        AutoStart = State.AutoStart,
        MainAutoReplay = State.MainAutoReplay,
        AutoNext = State.AutoNext,
        AutoLeave = State.AutoLeave,
        AntiAFK = State.AntiAFK,
        AutoNextPortal = State.AutoNextPortal,
        SelectedPortalTypes = State.SelectedPortalTypes,
        SelectedPortalTiers = State.SelectedPortalTiers,
        SelectedPortalModifiers = State.SelectedPortalModifiers,
        SnipeBanner = State.SnipeBanner,
        SnipeTargets = State.SnipeTargets,
        SnipeGemLimit = State.SnipeGemLimit,
        SnipeSummonCount = State.SnipeSummonCount,
    }
end

function SaveConfig()
    if not AllowSave then
        return
    end
    if type(writefile) ~= "function" then
        return
    end
    local ok, payload = pcall(function()
        return HttpService:JSONEncode(CopyStateForSave())
    end)
    if not ok then
        return
    end
    if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("OctoputHub") then
        pcall(makefolder, "OctoputHub")
    end
    pcall(writefile, CONFIG_FILE, payload)
end

function ApplySavedTable(saved)
    if type(saved) ~= "table" then
        return
    end
    local boolKeys = {
        "AutoPlace", "AutoUpgrade", "AutoUpgradeFarmFirst", "AutoBuffRotation",
        "AutoFindMatch", "AutoEventQuests", "AutoPickCards", "AutoReplay", "WebhookOnEnd", "BlackScreen", "AutoHideGUIOnExecute",
        "PlaceHybridGround", "PlaceHybridHill", "AutoStart", "MainAutoReplay", "AutoNext", "AutoLeave", "AntiAFK",
    }
    for _, key in ipairs(boolKeys) do
        if type(saved[key]) == "boolean" then
            State[key] = saved[key]
        end
    end
    if type(saved.PlacePercent) == "number" then
        State.PlacePercent = math.clamp(saved.PlacePercent, 0, 100)
    elseif type(saved.PlaceRangeMin) == "number" and type(saved.PlaceRangeMax) == "number" then
        State.PlacePercent = 0
    end
    if type(saved.UIScale) == "number" then
        State.UIScale = math.clamp(saved.UIScale, 0.5, 1.5)
    end
    if type(saved.WebhookURL) == "string" then
        State.WebhookURL = saved.WebhookURL
    end
    if type(saved.BuffPriority) == "table" then
        State.BuffPriority = SanitizeIdList(saved.BuffPriority, BUFF_IDS)
    end
    if type(saved.DebuffAvoid) == "table" then
        State.DebuffAvoid = SanitizeIdList(saved.DebuffAvoid, DEBUFF_IDS)
    end
    if type(saved.AutoNextPortal) == "boolean" then
        State.AutoNextPortal = saved.AutoNextPortal
    end
    if type(saved.SelectedPortalTypes) == "table" then
        local selected = {}
        for key, value in pairs(saved.SelectedPortalTypes) do
            local id = type(key) == "string" and key or (type(value) == "string" and value or nil)
            if id and (value == true or type(key) == "number") then selected[id] = true end
        end
        State.SelectedPortalTypes = selected
    end
    if type(saved.SelectedPortalTiers) == "table" then
        local selected = {}
        for key, value in pairs(saved.SelectedPortalTiers) do
            local tier = type(key) == "string" and key or value
            local n = tonumber(tier)
            if n and n >= 0 and n <= 99 and (value == true or type(key) == "number") then
                selected[tostring(math.floor(n))] = true
            end
        end
        State.SelectedPortalTiers = selected
    end
    if type(saved.SelectedPortalModifiers) == "table" then
        local selected = {}
        for key, value in pairs(saved.SelectedPortalModifiers) do
            if type(key) == "string" and value == true then selected[key] = true end
        end
        State.SelectedPortalModifiers = selected
    end
    if type(saved.SnipeBanner) == "string" then State.SnipeBanner = saved.SnipeBanner end
    if type(saved.SnipeTargets) == "table" then
        local targets = {}
        for id, enabled in pairs(saved.SnipeTargets) do
            if type(id) == "string" and enabled == true then targets[id] = true end
        end
        State.SnipeTargets = targets
    end
    if type(saved.SnipeGemLimit) == "number" then State.SnipeGemLimit = math.max(0, math.floor(saved.SnipeGemLimit)) end
    if saved.SnipeSummonCount == 1 or saved.SnipeSummonCount == 10 then State.SnipeSummonCount = saved.SnipeSummonCount end
    if type(saved.UnitNames) == "table" then
        local names = {}
        for id, name in pairs(saved.UnitNames) do
            if type(id) == "string" and type(name) == "string" then
                names[id] = name
            end
        end
        State.UnitNames = names
    end
    if type(saved.UnitConfigs) == "table" then
        local configs = {}
        for id, cfg in pairs(saved.UnitConfigs) do
            if type(id) == "string" and type(cfg) == "table" then
                local clean = {}
                if type(cfg.maxPlace) == "number" then
                    clean.maxPlace = math.clamp(math.floor(cfg.maxPlace), 1, 50)
                end
                if type(cfg.upgradeTarget) == "number" then
                    clean.upgradeTarget = math.clamp(math.floor(cfg.upgradeTarget), 0, 30)
                end
                if type(cfg.placeStartWave) == "number" then
                    clean.placeStartWave = math.clamp(math.floor(cfg.placeStartWave), 1, 999)
                end
                if type(cfg.upgradeStartWave) == "number" then
                    clean.upgradeStartWave = math.clamp(math.floor(cfg.upgradeStartWave), 1, 999)
                end
                if type(cfg.displayName) == "string" then
                    clean.displayName = cfg.displayName
                    State.UnitNames[id] = cfg.displayName
                end
                configs[id] = clean
            end
        end
        State.UnitConfigs = configs
    end
end

function LoadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        return
    end
    local exists = false
    pcall(function()
        exists = isfile(CONFIG_FILE)
    end)
    if not exists then
        return
    end
    local ok, saved = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok then
        ApplySavedTable(saved)
    end
end

LoadConfig()
-- Auto Open Portal is intentionally session-only and always starts disabled.
State.AutoOpenPortal = false
-- Free Cam is also session-only; never restore a Scriptable camera automatically.
State.FreeCam = false

-- Keep the hub inside the available screen area at large UI scales.
-- The user's selected scale remains saved; only the effective display scale is clamped.
function ApplyHubScale()
    local effectiveScale = State.UIScale
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        local widthLimit = math.max(0.5, (viewport.X - 24) / 780)
        local heightLimit = math.max(0.5, (viewport.Y - 24) / 480)
        effectiveScale = math.min(effectiveScale, widthLimit, heightLimit)
    end
    HubScale.Scale = effectiveScale
    if type(ApplyResponsiveGuiSizing) == "function" then
        ApplyResponsiveGuiSizing()
    end
end

local viewportConnection = nil
local function BindViewportScale()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyHubScale)
    end
    ApplyHubScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindViewportScale)
BindViewportScale()

EVENT_LEVEL_ID = "summer2_event"

function InvokeEndpoint(endpointName, ...)
    -- Only fall back to the raw remote when the client service was not usable.
    -- A nil return from a successful call must not trigger a second request.
    local attempted = false
    local ok, res = pcall(function(...)
        local loaderModule = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("Loader")
        if loaderModule then
            local Loader = require(loaderModule)
            local EndpointsClient = Loader.load_client_service(game, "EndpointsClient")
            if EndpointsClient and EndpointsClient.invoke_server then
                attempted = true
                return EndpointsClient.invoke_server(endpointName, ...)
            end
        end
    end, ...)
    if attempted then
        if ok then
            return res
        end
        return nil
    end

    local endpoints = ReplicatedStorage:FindFirstChild("endpoints")
    local client_to_server = endpoints and endpoints:FindFirstChild("client_to_server")
    if client_to_server then
        local remote = client_to_server:FindFirstChild(endpointName)
        if remote then
            if remote:IsA("RemoteFunction") then
                return remote:InvokeServer(...)
            elseif remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                return remote:FireServer(...)
            end
        end
    end
end

function IsInLobby()
    return workspace:FindFirstChild("_LOBBIES") ~= nil
        or workspace:FindFirstChild("enel_ship") ~= nil
        or game.PlaceId == 8304191830
end

function IsMatchmaking()
    local mmUI = playerGui:FindFirstChild("MatchmakingUI")
    if mmUI and mmUI.Enabled then
        return true
    end
    local alreadyInLobby = player:FindFirstChild("AlreadyInLobby")
    if alreadyInLobby and alreadyInLobby.Value == true then
        return true
    end
    return false
end

function NormalizeName(text)
    return (tostring(text or ""):lower():gsub("[%.%s_%-]", ""))
end

function IsFarmName(text)
    local id = NormalizeName(text)
    if id == "" then
        return false
    end
    return (id:find("speedwagon", 1, true)
        or id:find("ceo", 1, true)
        or id:find("bulma", 1, true)
        or id:find("bulby", 1, true)
        or id:find("bulmy", 1, true)
        or id:find("nami", 1, true)
        or id:find("weathergirl", 1, true)
        or id:find("weathering", 1, true)
        or id:find("weather", 1, true)) ~= nil
end

ReplicatedGameDataSyncedJobId = nil
ReplicatedGameDataSyncing = false
ReplicatedGameDataLastAttempt = 0

function SyncReplicatedGameData()
    if IsInLobby() then
        return
    end
    local jobId = tostring(game.JobId or "")
    if ReplicatedGameDataSyncedJobId == jobId
        and type(UnitsDataCache) == "table"
        and type(UnitsDataCache["leafa_evolved"]) == "table"
        and type(UnitsDataCache["leafa_evolved"].upgrade) == "table" then
        return
    end
    local now = tick()
    if ReplicatedGameDataSyncing or (now - ReplicatedGameDataLastAttempt) < 4 then
        return
    end
    ReplicatedGameDataLastAttempt = now
    ReplicatedGameDataSyncing = true

    task.spawn(function()
        pcall(function()
            local Loader = require(ReplicatedStorage.src.Loader)
            local loaderUnits = Loader.load_data(game, "Units")
            local loaderAttacks = Loader.load_data(game, "Attacks")
            if type(loaderUnits) == "table" then
                UnitsDataCache = UnitsDataCache or loaderUnits
                for k, v in pairs(loaderUnits) do
                    if type(v) == "table" then
                        UnitsDataCache[k] = v
                    end
                end
            end
            if type(loaderAttacks) == "table" then
                AttacksDataCache = AttacksDataCache or loaderAttacks
                for k, v in pairs(loaderAttacks) do
                    if type(v) == "table" then
                        AttacksDataCache[k] = v
                    end
                end
            end

            if type(UnitsDataCache) == "table"
                and type(UnitsDataCache["leafa_evolved"]) == "table"
                and type(UnitsDataCache["leafa_evolved"].upgrade) == "table" then
                ReplicatedGameDataSyncedJobId = jobId
                return
            end

            local rep = InvokeEndpoint("get_unit_game_replicator_data")
            if type(rep) == "table" then
                if type(rep.units) == "table" then
                    UnitsDataCache = UnitsDataCache or {}
                    for unitId, unitDef in pairs(rep.units) do
                        if type(unitDef) == "table" then
                            unitDef.id = unitDef.id or unitId
                            UnitsDataCache[unitId] = unitDef
                            if type(loaderUnits) == "table" then
                                loaderUnits[unitId] = unitDef
                            end
                        end
                    end
                end
                if type(rep.attacks) == "table" then
                    AttacksDataCache = AttacksDataCache or {}
                    for attackId, attackDef in pairs(rep.attacks) do
                        if type(attackDef) == "table" then
                            AttacksDataCache[attackId] = attackDef
                            if type(loaderAttacks) == "table" then
                                loaderAttacks[attackId] = attackDef
                            end
                        end
                    end
                end
                ReplicatedGameDataSyncedJobId = jobId
            end
        end)
        ReplicatedGameDataSyncing = false
    end)
end

function GetUnitsData(forceRefresh)
    if not IsInLobby() then
        SyncReplicatedGameData()
    end

    -- game.lua's ReplicatedStorage.src.Data.Units module is the canonical
    -- aggregate: it walks every descendant ModuleScript and merges every unit
    -- definition. Prefer it over a possibly partial Loader/cache snapshot.
    local merged = {}
    local hasData = false
    local okCanonical, canonicalData = pcall(function()
        local src = ReplicatedStorage:FindFirstChild("src")
        local dataFolder = src and src:FindFirstChild("Data")
        local unitsModule = dataFolder and dataFolder:FindFirstChild("Units")
        if not unitsModule then error("ReplicatedStorage.src.Data.Units not found") end
        return require(unitsModule)
    end)
    if okCanonical and type(canonicalData) == "table" then
        for id, definition in pairs(canonicalData) do
            if type(definition) == "table" then
                merged[id] = definition
                hasData = true
            end
        end
    end

    -- Merge Loader data as a supplement, never replacing a complete canonical
    -- definition with a partial/stale entry.
    local okLoader, loaderData = pcall(function()
        local src = ReplicatedStorage:FindFirstChild("src")
        local loaderModule = src and src:FindFirstChild("Loader")
        if not loaderModule then error("Loader not found") end
        local Loader = require(loaderModule)
        return Loader.load_data(game, "Units")
    end)
    if okLoader and type(loaderData) == "table" then
        for id, definition in pairs(loaderData) do
            if type(definition) == "table" then
                if type(merged[id]) ~= "table" then
                    merged[id] = definition
                else
                    for field, value in pairs(definition) do
                        if merged[id][field] == nil and value ~= nil then
                            merged[id][field] = value
                        end
                    end
                end
                hasData = true
            end
        end
    end

    if hasData then
        UnitsDataCache = merged
        return UnitsDataCache
    end

    -- Keep the last known good snapshot only if both live sources temporarily fail.
    if type(UnitsDataCache) == "table" and next(UnitsDataCache) ~= nil then
        return UnitsDataCache
    end
    return {}
end

function GetUnitUpgradeCount(data)
    if type(data) ~= "table" or type(data.upgrade) ~= "table" then
        return 0
    end
    local maxIndex = 0
    for key, value in pairs(data.upgrade) do
        local index = tonumber(key)
        if index and index > maxIndex and type(value) == "table" then
            maxIndex = math.floor(index)
        end
    end
    return maxIndex
end

function LookupUnitData(unitId)
    if not unitId or unitId == "" then
        return nil
    end
    local units = GetUnitsData()
    if type(units[unitId]) == "table" then
        return units[unitId], unitId
    end
    local want = NormalizeName(unitId)
    for id, data in pairs(units) do
        if type(data) == "table" and (NormalizeName(id) == want or NormalizeName(data.name) == want) then
            return data, id
        end
    end
    return nil
end

function GetUnitId(unit)
    if not unit or not unit:FindFirstChild("_stats") then
        return ""
    end
    local idVal = unit._stats:FindFirstChild("id")
    if not idVal then
        return NormalizeName(unit.Name)
    end
    return NormalizeName(idVal.Value)
end

function GetRawUnitId(unit)
    if not unit or not unit:FindFirstChild("_stats") then
        return ""
    end
    local idVal = unit._stats:FindFirstChild("id")
    if idVal and tostring(idVal.Value) ~= "" then
        return tostring(idVal.Value)
    end
    return unit.Name
end

function GetPlayerUnits()
    local myUnits = {}
    local unitsFolder = workspace:FindFirstChild("_UNITS")
    if not unitsFolder then
        return myUnits
    end

    for _, u in ipairs(unitsFolder:GetChildren()) do
        if u:IsA("Model") and u:FindFirstChild("_stats") then
            local pVal = u._stats:FindFirstChild("player")
            if pVal and pVal.Value == player then
                table.insert(myUnits, u)
            end
        end
    end
    return myUnits
end

function IsFarmUnit(unit)
    if not unit then return false end

    -- Match the game's unit_static_is_farm() implementation:
    -- Units[unitId].tags must contain the exact "Farm" tag.
    -- LookupUnitData reads the same canonical ReplicatedStorage unit database.
    local ids = {
        GetRawUnitId(unit),
        GetUnitId(unit),
    }

    for _, id in ipairs(ids) do
        if id and id ~= "" then
            local data = LookupUnitData(id)
            if type(data) == "table" and type(data.tags) == "table" then
                for _, tag in pairs(data.tags) do
                    if tag == "Farm" then
                        return true
                    end
                end
            end
        end
    end

    return false
end
function GetEquippedUnitList()
    local unitsList = {}

    -- Unit Configuration must read ONLY the six actual equipped slots (1-6).
    -- Do not merge GUI leftovers or previously saved UnitConfigs into this list.
    local ok, err = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        local ucs = Loader.load_client_service(game, "UnitCollectionServiceClient")
        if not ucs or type(ucs.get_equipped_units) ~= "function" then
            return
        end

        local equipped = ucs.get_equipped_units()
        if type(equipped) ~= "table" then
            return
        end

        for slot = 1, 6 do
            local slotKey = tostring(slot)
            local uuid = equipped[slotKey]
            if uuid == nil then
                uuid = equipped[slot]
            end

            if uuid ~= nil then
                local item = nil
                if type(ucs.get_equipped_unit_by_uuid) == "function" then
                    item = ucs.get_equipped_unit_by_uuid(uuid)
                end

                local unitId = type(item) == "table"
                    and (item.unit_id or item.unitId or item.id)
                    or nil
                local data = unitId and LookupUnitData(unitId) or nil
                local displayName = type(item) == "table"
                    and (item.name or item.display_name or item.displayName)
                    or nil

                if (not displayName or displayName == "") and type(data) == "table" then
                    displayName = data.name
                end

                table.insert(unitsList, {
                    uuid = uuid,
                    cost = type(data) == "table" and tonumber(data.cost) or 0,
                    name = displayName or unitId or "Unit",
                    unitId = unitId,
                    slot = slotKey,
                })
            end
        end
    end)

    if not ok then
        warn("[OctoputHub] Could not read equipped slots 1-6: " .. tostring(err))
    end

    return unitsList
end

function EnrichEquipped(list)
    for _, info in ipairs(list) do
        local unitId = info.unitId
        pcall(function()
            if info.uuid then
                local Loader = require(ReplicatedStorage.src.Loader)
                local ucs = Loader.load_client_service(game, "UnitCollectionServiceClient")
                if ucs and ucs.get_equipped_unit_by_uuid then
                    local owned = ucs.get_equipped_unit_by_uuid(info.uuid)
                    if owned then
                        unitId = owned.unit_id or owned.unitId or owned.id or unitId
                    end
                end
            end
        end)
        if not unitId then
            local _, foundId = LookupUnitData(info.name)
            unitId = foundId or info.name
        end
        info.unitId = tostring(unitId or info.name or "unit")
        local data = LookupUnitData(info.unitId)
        if data then
            if type(data.name) == "string" and data.name ~= "" then
                info.name = data.name
            end
            -- Match game.lua placement rules: absent spawn_cap means cap 5.
            -- Units without an upgrade table legitimately have zero upgrades.
            info.spawnCap = tonumber(data.spawn_cap) or 5
            info.globalSpawnCap = tonumber(data.global_spawn_cap)
            info.maxUpgrade = GetUnitUpgradeCount(data)
            info.dataFound = true
            info.hybrid = data.hybrid_placement == true
            info.hill = data.hill_unit == true
        else
            info.dataFound = false
        end
        if info.name and info.name ~= "" and info.name ~= "Unit" then
            State.UnitNames[info.unitId] = info.name
        end
    end
    return list
end

-- Auto Buff Rotation: read the deployed unit's live active cooldown and its
-- matching owned-unit Curse data. Game.lua applies Curse cooldown modifiers
-- through further_modifiers.cursed and exposes the effective cooldown in
-- _stats.active_attack_cooldown on the deployed model.
--
-- Buff loop formula (game.lua):
--   active cooldown  C = active_attack_stats.attack_cooldown (60s for Commander/Windsong)
--                        * calculate_static_stat_multiplier(unit, xp, "active_attack_cooldown")
--                      = base * max(0.6, (1 + cursed attack_cooldown mods) * level/artifact mods)
--   buff duration    D = aoe[*].hit.buffs[*].time (30s for Commander/Windsong)
--   unit SPD         = 1 / C (casts per second); group rate R = sum(1 / C_i)
--   loop is seamless when R >= 1 / D, i.e. units needed = ceil(C / D)
-- The worker recasts one unit only when the group's current buff is about to
-- expire (lastGroupCast + D - lead), so casts are staggered instead of all
-- units firing together and leaving a gap afterwards.
BUFF_ROTATION_ATTACKS = {
    ["erwin:buff_units"] = { name = "Commander", duration = 30, buff = "Physical", unit = "commander", baseCooldown = 60 },
    ["wendy:buff_units"] = { name = "Windsong", duration = 30, buff = "Magic", unit = "windsong", baseCooldown = 60 },
}
BUFF_ROTATION_ELFY_DEFAULT = { name = "Elfy (Sylph) - Verdant Enchantment", duration = 30, buff = "Magic", unit = "elfy", baseCooldown = 60 }
BUFF_ROTATION_RUNTIME = { groups = {}, requestBusy = false, requestStarted = 0, ownCast = {} }
BUFF_ROTATION_CURSE_CACHE = {}
BUFF_ROTATION_MULT_CACHE = {}
BUFF_ROTATION_MIN_REQUEST_GAP = 0.5
BUFF_ROTATION_PENDING_TIMEOUT = 4.5
BUFF_ROTATION_SAFETY_MARGIN = 0.75
BUFF_ROTATION_REQUEST_TIMEOUT = 8
BUFF_ROTATION_DEFAULT_ACTIVE_COOLDOWN = 60

function GetOwnedUnitRecordForPlacedUnit(unit)
    if not unit or not unit:FindFirstChild("_stats") then return nil end
    local uuidValue = unit._stats:FindFirstChild("uuid")
    if not uuidValue then return nil end
    local uuid = tostring(uuidValue.Value or "")
    if uuid == "" then return nil end

    local ok, owned = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        local ucs = Loader.load_client_service(game, "UnitCollectionServiceClient")
        if ucs and type(ucs.get_equipped_unit_by_uuid) == "function" then
            return ucs.get_equipped_unit_by_uuid(uuid)
        end
    end)
    if ok and type(owned) == "table" then return owned end
    return nil
end

function GetUnitCurseCooldownInfo(unit)
    local stats = unit and unit:FindFirstChild("_stats")
    local uuidValue = stats and stats:FindFirstChild("uuid")
    local uuid = uuidValue and tostring(uuidValue.Value or "") or ""
    if uuid ~= "" then
        local cached = BUFF_ROTATION_CURSE_CACHE[uuid]
        if cached and tick() - cached.time < 5 then
            return cached.hasCurse, cached.reduction, cached.known, cached.factor
        end
    end

    local owned = GetOwnedUnitRecordForPlacedUnit(unit)
    if type(owned) ~= "table" then
        if uuid ~= "" then
            BUFF_ROTATION_CURSE_CACHE[uuid] = { time = tick(), hasCurse = false, reduction = 0, known = false, factor = 1 }
        end
        return false, 0, false, 1
    end

    local cursed = type(owned.further_modifiers) == "table" and owned.further_modifiers.cursed or nil
    if type(cursed) ~= "table" then
        if uuid ~= "" then
            BUFF_ROTATION_CURSE_CACHE[uuid] = { time = tick(), hasCurse = false, reduction = 0, known = true, factor = 1 }
        end
        return false, 0, true, 1
    end

    -- game.lua calculate_static_stat_multiplier() strips the "active_" prefix,
    -- then sums BOTH cursed.positive_buff and cursed.negative_buff for
    -- stat_id == "attack_cooldown". Keep positive and negative modifiers.
    local modifierSum = 0
    local hasCooldownModifier = false
    for _, key in ipairs({ "positive_buff", "negative_buff" }) do
        local mod = cursed[key]
        if type(mod) == "table" and mod.stat_id == "attack_cooldown" and tonumber(mod.stat_mod) then
            modifierSum = modifierSum + tonumber(mod.stat_mod)
            hasCooldownModifier = true
        end
    end
    local factor = math.max(0.0001, 1 + modifierSum)
    if uuid ~= "" then
        BUFF_ROTATION_CURSE_CACHE[uuid] = {
            time = tick(), hasCurse = hasCooldownModifier, reduction = modifierSum,
            known = true, factor = factor
        }
    end
    return hasCooldownModifier, modifierSum, true, factor
end

function GetAttacksData()
    if not IsInLobby() then
        SyncReplicatedGameData()
    end
    if AttacksDataCache and next(AttacksDataCache) ~= nil then
        return AttacksDataCache
    end
    local okLoader, loaderData = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        return Loader.load_data(game, "Attacks")
    end)
    if okLoader and type(loaderData) == "table" and next(loaderData) ~= nil then
        AttacksDataCache = loaderData
        return AttacksDataCache
    end
    local ok, data = pcall(function()
        return require(ReplicatedStorage.src.Data.Attacks)
    end)
    if ok and type(data) == "table" then
        AttacksDataCache = data
        return AttacksDataCache
    end
    return {}
end

-- Read the buff time from Attacks[attackId].aoe[*].hit.buffs[*].time
-- (erwin:buff_units / wendy:buff_units = 30s). Works for Elfy's runtime
-- Verdant Enchantment as well, because the live Attacks module contains it.
function GetAttackBuffDuration(attackId, fallback)
    local attack = attackId and GetAttacksData()[attackId] or nil
    local best = nil
    local function scanHit(hit)
        if type(hit) ~= "table" or type(hit.buffs) ~= "table" then return end
        for _, buff in pairs(hit.buffs) do
            local t = type(buff) == "table" and tonumber(buff.time) or nil
            if t and t > 0 and (not best or t > best) then
                best = t
            end
        end
    end
    if type(attack) == "table" then
        scanHit(attack.hit)
        if type(attack.hit) == "table" then
            for _, hit in pairs(attack.hit) do
                if type(hit) == "table" then scanHit(hit) end
            end
        end
        if type(attack.aoe) == "table" then
            for _, entry in pairs(attack.aoe) do
                if type(entry) == "table" then scanHit(entry.hit) end
            end
        end
    end
    return best or fallback or 30
end

function GetAttackDisplayName(attackId, fallback)
    local attack = attackId and GetAttacksData()[attackId] or nil
    if type(attack) == "table" and type(attack.name) == "string" and attack.name ~= "" then
        return attack.name
    end
    return fallback
end

-- Mirrors UnitServiceCore.get_active_stats_used(): unit active_attack_stats
-- first, otherwise the first upgrade that defines active_attack_stats.
function GetUnitActiveBaseCooldown(unitData, upgradeLevel)
    if type(unitData) ~= "table" then return nil end
    local stats = unitData.active_attack_stats
    if type(stats) == "table" and tonumber(stats.attack_cooldown) then
        return tonumber(stats.attack_cooldown)
    end
    if type(unitData.upgrade) == "table" then
        local lvl = math.min(tonumber(upgradeLevel) or #unitData.upgrade, #unitData.upgrade)
        local found = nil
        for i = 1, lvl do
            local upg = unitData.upgrade[i]
            if type(upg) == "table" and type(upg.active_attack_stats) == "table"
                and tonumber(upg.active_attack_stats.attack_cooldown) then
                found = tonumber(upg.active_attack_stats.attack_cooldown)
            end
        end
        if found then return found end
        for _, upg in pairs(unitData.upgrade) do
            if type(upg) == "table" and type(upg.active_attack_stats) == "table"
                and tonumber(upg.active_attack_stats.attack_cooldown) then
                return tonumber(upg.active_attack_stats.attack_cooldown)
            end
        end
    end
    return nil
end

-- Active cooldown multiplier exactly as game.lua computes it:
-- UnitServiceCore.calculate_static_stat_multiplier(unit, xp, "active_attack_cooldown").
-- For "active_" stats the game strips the prefix, skips trait multipliers, adds
-- cursed positive_buff + negative_buff attack_cooldown mods, applies level /
-- artifact modifiers and clamps the result to >= 0.6.
-- Fallback when the core service is unavailable: max(0.6, 1 + curseSum).
function GetActiveCooldownMultiplier(unit, curseSum)
    local stats = unit and unit:FindFirstChild("_stats")
    local uuidValue = stats and stats:FindFirstChild("uuid")
    local uuid = uuidValue and tostring(uuidValue.Value or "") or ""
    if uuid ~= "" then
        local cached = BUFF_ROTATION_MULT_CACHE[uuid]
        if cached and tick() - cached.time < 5 then
            return cached.mult, cached.source, cached.speedStat
        end
    end

    local owned = GetOwnedUnitRecordForPlacedUnit(unit)
    local mult, source = nil, "curse"
    local speedStat = nil
    if type(owned) == "table" then
        if type(owned.trait_stats) == "table" then
            speedStat = tonumber(owned.trait_stats.speed_stat)
        end
        local ok, value = pcall(function()
            local Loader = require(ReplicatedStorage.src.Loader)
            local core = Loader.load_core_service(game, "UnitServiceCore")
            if core and type(core.calculate_static_stat_multiplier) == "function" then
                return core.calculate_static_stat_multiplier(owned, owned.xp or 0, "active_attack_cooldown", nil)
            end
        end)
        if ok and tonumber(value) and tonumber(value) > 0 then
            mult = tonumber(value)
            source = "game"
        end
    end
    if not mult then
        mult = math.max(0.6, 1 + (tonumber(curseSum) or 0))
    end
    if not speedStat and unit then
        speedStat = tonumber(unit:GetAttribute("speed_stat"))
    end
    if uuid ~= "" then
        BUFF_ROTATION_MULT_CACHE[uuid] = { time = tick(), mult = mult, source = source, speedStat = speedStat }
    end
    return mult, source, speedStat
end

BUFF_ROTATION_ATTACKS_REPLICATE = nil
function GetAttacksReplicateService()
    if BUFF_ROTATION_ATTACKS_REPLICATE then
        return BUFF_ROTATION_ATTACKS_REPLICATE
    end
    local ok, service = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        return Loader.load_client_service(game, "AttacksReplicate")
    end)
    if ok and type(service) == "table" then
        BUFF_ROTATION_ATTACKS_REPLICATE = service
        return service
    end
    return nil
end

function GetUnitOverheadReadyAttribute(unit)
    if not unit then return nil end
    local ok, readyAttr = pcall(function()
        local hrp = unit:FindFirstChild("HumanoidRootPart")
        local overFrame = hrp and hrp:FindFirstChild("OverFrame")
        local activeCd = overFrame and overFrame:FindFirstChild("ActiveCooldown")
        local bar = activeCd and activeCd:FindFirstChild("Bar")
        local stroke = bar and bar:FindFirstChild("UIStroke")
        if stroke then
            return stroke:GetAttribute("_ready")
        end
        return nil
    end)
    if ok then return readyAttr end
    return nil
end

function GetActiveAttackCooldownState(entry, now)
    -- Mirror game.lua AttacksReplicate.get_current_active_attack_cooldown():
    -- busy while _stats.active_queued_or_using is true, otherwise ready when
    -- active_attack_cooldown - (tick() - last_active_cast) <= 0.
    if entry.queued then
        return true, false, entry.cooldown, entry.cooldown
    end
    local remaining = entry.cooldown - (now - entry.lastCast)
    local isReady = remaining <= 0
    if isReady and entry.lastCast <= 0 then
        local overheadReady = GetUnitOverheadReadyAttribute(entry.model)
        if overheadReady == false then
            isReady = false
            remaining = math.max(remaining, 1)
        end
    end
    return false, isReady, entry.cooldown, math.max(0, remaining)
end

function IsElfySylphUnit(rawId, unitData, unit)
    for _, value in ipairs({ rawId, unitData and unitData.id, unit and unit.Name }) do
        local id = NormalizeName(value)
        if id == "leafaevolved"
            or (id:find("leafa", 1, true) and id:find("evolved", 1, true))
            or id:find("sylph", 1, true) then
            return true
        end
    end
    -- NormalizeName keeps parentheses, so "Elfy (Sylph)" -> "elfy(sylph)".
    local name = NormalizeName(unitData and unitData.name)
    if name:find("sylph", 1, true) then
        return true
    end
    if type(unitData) == "table" and type(unitData.evolved) == "table" and unitData.evolved.from == "leafa" then
        return true
    end
    return false
end

function IsElfyFamilyUnit(rawId, unitData, unit)
    if IsElfySylphUnit(rawId, unitData, unit) then return true end
    local id = NormalizeName(rawId)
    local unitName = NormalizeName(unit and unit.Name)
    local name = NormalizeName(unitData and unitData.name)
    return id:find("leafa", 1, true) ~= nil
        or id:find("elfy", 1, true) ~= nil
        or unitName:find("leafa", 1, true) ~= nil
        or unitName:find("elfy", 1, true) ~= nil
        or name:find("elfy", 1, true) ~= nil
end

function ResolveUnitActiveAttackId(unit, stats, unitData, upgradeLevel)
    local activeValue = stats and stats:FindFirstChild("active_attack")
    local activeId = activeValue and tostring(activeValue.Value) or "nil"
    if activeId ~= "" and activeId ~= "nil" then
        return activeId
    end
    local okCore, coreActive = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        local core = Loader.load_core_service(game, "UnitServiceCore")
        if core and type(core.get_active_id) == "function" then
            return core.get_active_id(unit)
        end
        return nil
    end)
    if okCore and type(coreActive) == "string" and coreActive ~= "" and coreActive ~= "nil" then
        return coreActive
    end
    if type(unitData) == "table" then
        if type(unitData.active_attack) == "string" and unitData.active_attack ~= "" and unitData.active_attack ~= "nil" then
            return unitData.active_attack
        end
        if type(unitData.upgrade) == "table" then
            local lvl = math.min(tonumber(upgradeLevel) or 0, #unitData.upgrade)
            local resolved = nil
            for i = 1, lvl do
                local upg = unitData.upgrade[i]
                if type(upg) == "table" and type(upg.active_attack) == "string"
                    and upg.active_attack ~= "" and upg.active_attack ~= "nil" then
                    resolved = upg.active_attack
                end
            end
            if resolved then
                return resolved
            end
        end
    end
    return nil
end

function GetBuffRotationGroups(now)
    now = now or tick()
    SyncReplicatedGameData()
    local attacksReplicate = GetAttacksReplicateService()
    local globalCooldowns = attacksReplicate and type(attacksReplicate.GLOBAL_ATTACK_COOLDOWNS) == "table"
        and attacksReplicate.GLOBAL_ATTACK_COOLDOWNS or nil

    local groups = {}
    local elfyInfo = { total = 0, withoutActive = 0 }
    local liveModels = {}
    for _, unit in ipairs(GetPlayerUnits()) do
        local stats = unit:FindFirstChild("_stats")
        if stats then
            liveModels[unit] = true
            local rawId = GetRawUnitId(unit)
            local unitData = LookupUnitData(rawId)
            local upgradeValue = stats:FindFirstChild("upgrade")
            local upgradeLevel = upgradeValue and tonumber(upgradeValue.Value) or 0

            -- Same source as UnitServiceCore.get_active_id(): the live
            -- _stats.active_attack value, with fallbacks to UnitServiceCore
            -- and replicated unit upgrade data.
            local activeId = ResolveUnitActiveAttackId(unit, stats, unitData, upgradeLevel)

            local isElfy = IsElfyFamilyUnit(rawId, unitData, unit)
            if isElfy then
                elfyInfo.total = elfyInfo.total + 1
                if not activeId then
                    elfyInfo.withoutActive = elfyInfo.withoutActive + 1
                end
            end

            local definition = activeId and BUFF_ROTATION_ATTACKS[activeId] or nil
            if not definition and activeId then
                local lowerActive = activeId:lower()
                local isElfyActive = isElfy
                    or lowerActive:find("leafa", 1, true) ~= nil
                    or lowerActive:find("elfy", 1, true) ~= nil
                    or lowerActive:find("sylph", 1, true) ~= nil
                    or lowerActive:find("verdant", 1, true) ~= nil
                    or lowerActive:find("enchant", 1, true) ~= nil
                if isElfyActive then
                    definition = {
                        name = "Elfy (Sylph) - " .. tostring(GetAttackDisplayName(activeId, "Verdant Enchantment")),
                        duration = BUFF_ROTATION_ELFY_DEFAULT.duration,
                        buff = BUFF_ROTATION_ELFY_DEFAULT.buff,
                        unit = "elfy",
                        baseCooldown = BUFF_ROTATION_ELFY_DEFAULT.baseCooldown,
                    }
                    BUFF_ROTATION_ATTACKS[activeId] = definition
                elseif IsPlacedBuffUnit(unit) then
                    definition = {
                        name = tostring((unitData and unitData.name) or unit.Name) .. " - " .. tostring(GetAttackDisplayName(activeId, activeId)),
                        duration = 30,
                        buff = "Buff",
                        unit = NormalizeName(rawId),
                        baseCooldown = 60,
                    }
                    BUFF_ROTATION_ATTACKS[activeId] = definition
                end
            end

            if definition then
                local baseCooldown = GetUnitActiveBaseCooldown(unitData, upgradeLevel)
                if not baseCooldown and type(unitData) == "table" and type(unitData.evolved) == "table" then
                    baseCooldown = GetUnitActiveBaseCooldown(LookupUnitData(unitData.evolved.from), upgradeLevel)
                end
                baseCooldown = baseCooldown or definition.baseCooldown or BUFF_ROTATION_DEFAULT_ACTIVE_COOLDOWN

                local hasCurse, curseReduction, curseKnown, curseFactor = GetUnitCurseCooldownInfo(unit)
                local multiplier, multSource, speedStat = GetActiveCooldownMultiplier(unit, curseReduction)
                local expectedCooldown = baseCooldown and (baseCooldown * multiplier) or nil

                -- The live value is what the game itself uses for readiness, so
                -- it is authoritative. Fall back to the game formula when the
                -- unit does not expose active_attack_cooldown (Elfy runtime active).
                local cooldownValue = stats:FindFirstChild("active_attack_cooldown")
                local liveCooldown = cooldownValue and tonumber(cooldownValue.Value) or nil
                if liveCooldown and liveCooldown <= 0 then liveCooldown = nil end
                local globalEntry = globalCooldowns and globalCooldowns[activeId] or nil
                local globalCooldown = type(globalEntry) == "table" and tonumber(globalEntry.cooldown) or nil
                if globalCooldown and globalCooldown <= 0 then globalCooldown = nil end

                local cooldown = liveCooldown or globalCooldown or expectedCooldown or BUFF_ROTATION_DEFAULT_ACTIVE_COOLDOWN
                cooldown = math.max(0.1, cooldown)

                -- In Lua, 0 is truthy! last_active_cast.Value starts at 0 before
                -- the first cast, so treat <= 0 as nil so ownCast / globalCast work.
                local lastCastValue = stats:FindFirstChild("last_active_cast")
                local rawLiveLastCast = lastCastValue and tonumber(lastCastValue.Value) or nil
                local validLiveLastCast = (rawLiveLastCast and rawLiveLastCast > 0 and rawLiveLastCast <= now + 5)
                    and rawLiveLastCast or nil

                local globalLastCast = nil
                if type(globalEntry) == "table" and tonumber(globalEntry.last_cast) and tonumber(globalEntry.last_cast) > 0 then
                    globalLastCast = tonumber(globalEntry.last_cast)
                elseif tonumber(globalEntry) and tonumber(globalEntry) > 0 then
                    globalLastCast = tonumber(globalEntry)
                end
                if globalLastCast and globalLastCast > now + 5 then
                    globalLastCast = nil
                end

                local ownCast = BUFF_ROTATION_RUNTIME.ownCast[unit] or 0
                local lastCast = math.max(validLiveLastCast or 0, globalLastCast or 0, ownCast or 0)

                local queuedValue = stats:FindFirstChild("active_queued_or_using")
                local queued = queuedValue and queuedValue.Value == true or false

                local duration = GetAttackBuffDuration(activeId, definition.duration)

                local group = groups[activeId]
                if not group then
                    group = {
                        attackId = activeId,
                        name = definition.name,
                        buff = definition.buff,
                        duration = duration,
                        units = {},
                        curseCount = 0,
                        curseKnownCount = 0,
                        maxCooldown = 0,
                        baseCooldown = baseCooldown,
                        isElfy = definition.unit == "elfy",
                    }
                    groups[activeId] = group
                end
                group.duration = math.max(group.duration or 0, duration)

                table.insert(group.units, {
                    model = unit,
                    attackId = activeId,
                    uuid = stats:FindFirstChild("uuid") and tostring(stats.uuid.Value) or tostring(unit),
                    cooldown = cooldown,
                    liveCooldown = liveCooldown,
                    expectedCooldown = expectedCooldown,
                    baseCooldown = baseCooldown,
                    multiplier = multiplier,
                    multSource = multSource,
                    speedStat = speedStat,
                    lastCast = lastCast,
                    hasLiveCast = (validLiveLastCast ~= nil) or (globalLastCast ~= nil),
                    queued = queued,
                    hasCurse = hasCurse,
                    curseReduction = curseReduction,
                    curseFactor = curseFactor or 1,
                    curseKnown = curseKnown,
                    spd = 1 / cooldown,
                })
                if hasCurse then group.curseCount = group.curseCount + 1 end
                if curseKnown then group.curseKnownCount = group.curseKnownCount + 1 end
                group.maxCooldown = math.max(group.maxCooldown, cooldown)
            end
        end
    end

    for model in pairs(BUFF_ROTATION_RUNTIME.ownCast) do
        if not liveModels[model] then
            BUFF_ROTATION_RUNTIME.ownCast[model] = nil
        end
    end

    for _, group in pairs(groups) do
        table.sort(group.units, function(a, b)
            return tostring(a.uuid) < tostring(b.uuid)
        end)
        local totalRate = 0
        local multTotal = 0
        for _, entry in ipairs(group.units) do
            entry.spd = 1 / math.max(0.1, entry.cooldown)
            totalRate = totalRate + entry.spd
            multTotal = multTotal + (entry.multiplier or 1)
        end
        local n = #group.units
        group.totalRate = totalRate
        group.totalSPD = totalRate
        group.averageSPD = n > 0 and (totalRate / n) or 0
        group.averageMultiplier = n > 0 and (multTotal / n) or 1
        -- Average spacing between casts if every unit is used as soon as it is ready.
        group.interval = totalRate > 0 and (1 / totalRate) or math.huge
        group.averageCooldown = n > 0 and (n / math.max(totalRate, 0.000001)) or math.huge
        -- Seamless loop needs one cast every D seconds: R >= 1 / D.
        group.requiredUnitsEstimate = math.max(1, math.ceil(group.averageCooldown / math.max(1, group.duration)))
        group.sustainable = totalRate >= (1 / math.max(1, group.duration)) - 1e-6
        -- Recast lead before expiry. Using a lead shortens the effective cycle,
        -- so only use as much lead as the group's SPD can afford:
        --   sum((D - lead) / C_i) >= 1  ->  lead <= D - 1 / R
        local affordable = totalRate > 0 and (group.duration - 1 / totalRate) or 0
        group.lead = math.clamp(affordable, 0, BUFF_ROTATION_SAFETY_MARGIN)
    end
    return groups, elfyInfo
end

function SetBuffRotationStatus(message, color)
    if BuffRotationStatus then
        BuffRotationStatus.Text = message
        BuffRotationStatus.TextColor3 = color or Color3.fromRGB(160, 160, 180)
    end
end

function GetBuffRotationCurseMode(group)
    if group.curseKnownCount < #group.units then
        return "Cooldown Curse unknown"
    elseif group.curseCount == #group.units then
        return "Curse"
    elseif group.curseCount > 0 then
        return "Mixed Cooldown Curse"
    end
    return "No Cooldown Curse"
end

-- Detect farm units from both their displayed name and unit database metadata.
-- Some equipped-unit records use an internal ID that does not contain the display name.
function IsFarmInfo(info)
    if not info then return false end

    -- Match Anime Adventures' actual UnitServiceCore.unit_static_is_farm():
    -- Units[unitId].tags must contain the exact "Farm" tag.
    -- Do not infer Farm from display names or farm_amount fields.
    local ids = { info.unitId, info.name, info.displayName }
    for _, id in ipairs(ids) do
        if id and tostring(id) ~= "" then
            local data = LookupUnitData(id)
            if type(data) == "table" and type(data.tags) == "table" then
                for _, tag in pairs(data.tags) do
                    if tag == "Farm" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function GetCurrentWave()
    local waveNum = workspace:FindFirstChild("_wave_num")
    if waveNum and tonumber(waveNum.Value) then
        return tonumber(waveNum.Value)
    end
    local data = workspace:FindFirstChild("_DATA")
    if data then
        local wave = data:FindFirstChild("Wave") or data:FindFirstChild("CurrentWave")
        if wave and tonumber(wave.Value) then
            return tonumber(wave.Value)
        end
    end
    return 0
end

function GetUnitConfig(unitId)
    if not unitId then
        return nil
    end
    local configs = State.UnitConfigs or {}
    if type(configs[unitId]) == "table" then
        return configs[unitId]
    end
    local want = NormalizeName(unitId)
    for id, cfg in pairs(configs) do
        if NormalizeName(id) == want then
            return cfg
        end
    end
    return nil
end

function CountPlacedUnit(unitId)
    local want = NormalizeName(unitId)
    local n = 0
    for _, unit in ipairs(GetPlayerUnits()) do
        if GetUnitId(unit) == want or NormalizeName(GetRawUnitId(unit)) == want then
            n = n + 1
        end
    end
    return n
end

-- Match equipped units against the actual placed model using both internal IDs
-- and display names. Some units (notably farm units with renamed/evolved IDs)
-- do not expose the same identifier in the loadout and in workspace._UNITS.
function CountPlacedInfo(info)
    if not info then return 0 end

    -- Use exact normalized identities only. Partial substring matching can make
    -- one farm unit (e.g. Bulby) accidentally count as another equipped farm.
    local wanted = {}
    local function addWanted(value)
        local key = NormalizeName(value)
        if key ~= "" and key ~= "unit" then wanted[key] = true end
    end

    addWanted(info.unitId)
    addWanted(info.name)
    addWanted(info.displayName)
    local equippedData = LookupUnitData(info.unitId)
    if type(equippedData) == "table" then
        addWanted(equippedData.name)
        addWanted(equippedData.display_name)
        addWanted(equippedData.displayName)
    end

    if next(wanted) == nil then return 0 end

    local count = 0
    for _, unit in ipairs(GetPlayerUnits()) do
        local actual = {}
        local function addActual(value)
            local key = NormalizeName(value)
            if key ~= "" and key ~= "unit" then actual[key] = true end
        end

        local rawId = GetRawUnitId(unit)
        addActual(rawId)
        addActual(GetUnitId(unit))
        addActual(unit.Name)
        addActual(State.UnitNames[rawId])
        addActual(State.UnitNames[GetUnitId(unit)])

        local stats = unit:FindFirstChild("_stats")
        if stats then
            for _, fieldName in ipairs({ "name", "display_name", "unit_name" }) do
                local field = stats:FindFirstChild(fieldName)
                if field then addActual(field.Value) end
            end
        end

        local placedData = LookupUnitData(rawId)
        if type(placedData) == "table" then
            addActual(placedData.name)
            addActual(placedData.display_name)
            addActual(placedData.displayName)
        end

        for key in pairs(wanted) do
            if actual[key] then
                count = count + 1
                break
            end
        end
    end
    return count
end

-- Count a unit across the entire match, not just the local player.
-- Some units (e.g. Windsong) use global_spawn_cap shared by the whole party.
function CountGlobalPlacedInfo(info)
    if not info then return 0 end

    local wanted = {}
    local function addWanted(value)
        local key = NormalizeName(value)
        if key ~= "" and key ~= "unit" then wanted[key] = true end
    end

    addWanted(info.unitId)
    addWanted(info.name)
    addWanted(info.displayName)
    local equippedData = LookupUnitData(info.unitId)
    if type(equippedData) == "table" then
        addWanted(equippedData.name)
        addWanted(equippedData.display_name)
        addWanted(equippedData.displayName)
    end
    if next(wanted) == nil then return 0 end

    local unitsFolder = workspace:FindFirstChild("_UNITS")
    if not unitsFolder then return 0 end

    local count = 0
    for _, unit in ipairs(unitsFolder:GetChildren()) do
        if unit:IsA("Model") and unit:FindFirstChild("_stats") then
            local actual = {}
            local function addActual(value)
                local key = NormalizeName(value)
                if key ~= "" and key ~= "unit" then actual[key] = true end
            end

            local rawId = GetRawUnitId(unit)
            local normalizedId = GetUnitId(unit)
            addActual(rawId)
            addActual(normalizedId)
            addActual(unit.Name)
            addActual(State.UnitNames[rawId])
            addActual(State.UnitNames[normalizedId])

            local stats = unit:FindFirstChild("_stats")
            for _, fieldName in ipairs({ "name", "display_name", "unit_name" }) do
                local field = stats:FindFirstChild(fieldName)
                if field then addActual(field.Value) end
            end

            local placedData = LookupUnitData(rawId)
            if type(placedData) == "table" then
                addActual(placedData.name)
                addActual(placedData.display_name)
                addActual(placedData.displayName)
            end

            for key in pairs(wanted) do
                if actual[key] then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

function ResolvePlacementKind(unitId)
    local data = LookupUnitData(unitId)
    if data and data.hybrid_placement then
        local ground = State.PlaceHybridGround ~= false
        local hill = State.PlaceHybridHill ~= false
        if ground and hill then
            return "hybrid"
        elseif hill then
            return "hill"
        elseif ground then
            return "ground"
        end
        return "hybrid"
    end
    if data and data.hill_unit then
        return "hill"
    end
    return "ground"
end

function CanPlaceConfigured(info, wave)
    local cfg = GetUnitConfig(info.unitId)
    if cfg and cfg.placeStartWave ~= nil and wave < cfg.placeStartWave then
        return false
    end

    -- Enforce the game's shared party-wide cap before sending spawn_unit.
    -- Returning false lets the Auto Place loop continue to the next equipped unit.
    local data = LookupUnitData(info.unitId)
    local globalCap = tonumber(info.globalSpawnCap)
        or (type(data) == "table" and tonumber(data.global_spawn_cap))
    if globalCap and CountGlobalPlacedInfo(info) >= globalCap then
        return false
    end

    local localLimit = cfg and tonumber(cfg.maxPlace) or nil
    if info.spawnCap and localLimit then
        localLimit = math.min(localLimit, info.spawnCap)
    elseif info.spawnCap and not localLimit then
        localLimit = info.spawnCap
    end
    if localLimit then
        -- Use the same identity matching as placement confirmation. Farm units can
        -- expose a different runtime ID/name from their equipped collection record.
        local placedCount = CountPlacedInfo(info)
        if placedCount >= localLimit then
            return false
        end
    end
    return true
end

function GetPath1Lane()
    local bases = workspace:FindFirstChild("_BASES")
    if not bases then
        return nil
    end
    local owner = bases:FindFirstChild("pve") or bases:FindFirstChild("player")
    local lanes = owner and owner:FindFirstChild("LANES")
    if not lanes then
        return nil
    end
    return lanes:FindFirstChild("1") or lanes:FindFirstChild("01")
end

function GetPathPoints(lane)
    local points = {}
    local spawn = lane:FindFirstChild("spawn")
    if spawn and spawn:IsA("BasePart") then
        table.insert(points, spawn.Position)
    end

    local numbered = {}
    for _, child in ipairs(lane:GetChildren()) do
        local n = tonumber(child.Name)
        if n and child:IsA("BasePart") then
            table.insert(numbered, { n = n, pos = child.Position })
        end
    end
    table.sort(numbered, function(a, b)
        return a.n < b.n
    end)
    for _, item in ipairs(numbered) do
        table.insert(points, item.pos)
    end

    local final = lane:FindFirstChild("final")
    if final and final:IsA("BasePart") then
        table.insert(points, final.Position)
    end
    return points
end

function GetPointOnPolyline(points, alpha)
    if #points == 0 then
        return nil, Vector3.new(0, 0, -1)
    end
    if #points == 1 then
        return points[1], Vector3.new(0, 0, -1)
    end

    local segs = {}
    local total = 0
    for i = 1, #points - 1 do
        local dist = (points[i + 1] - points[i]).Magnitude
        table.insert(segs, { a = points[i], b = points[i + 1], dist = dist })
        total = total + dist
    end
    if total <= 0 then
        return points[1], Vector3.new(0, 0, -1)
    end

    local target = math.clamp(alpha, 0, 1) * total
    local walked = 0
    for _, seg in ipairs(segs) do
        if walked + seg.dist >= target or seg == segs[#segs] then
            local t = 0
            if seg.dist > 0 then
                t = math.clamp((target - walked) / seg.dist, 0, 1)
            end
            local pos = seg.a:Lerp(seg.b, t)
            local look = (seg.b - seg.a)
            if look.Magnitude < 0.01 then
                look = Vector3.new(0, 0, -1)
            else
                look = look.Unit
            end
            return pos, look
        end
        walked = walked + seg.dist
    end
    return points[#points], Vector3.new(0, 0, -1)
end

function HitAllowsPlacement(inst, kind)
    if not inst then
        return false
    end
    local cursor = inst
    while cursor and cursor ~= workspace do
        if cursor.Name == "_donotplace" then
            return false
        end
        cursor = cursor.Parent
    end
    local road = workspace:FindFirstChild("_road")
    if road and inst:IsDescendantOf(road) then
        return false
    end

    local terrain = workspace:FindFirstChild("_terrain")
    local ground = terrain and terrain:FindFirstChild("ground")
    local hill = terrain and terrain:FindFirstChild("hill")
    local onGround = ground and inst:IsDescendantOf(ground)
    local onHill = hill and inst:IsDescendantOf(hill)

    if kind == "hill" then
        if hill then
            return onHill
        end
        return true
    elseif kind == "hybrid" then
        if not ground and not hill then
            return true
        end
        return onGround or onHill
    end
    if ground then
        return onGround
    end
    return not onHill
end

function GetPlacedBuffUnitPosition(unit)
    if not unit then return nil end
    local stats = unit:FindFirstChild("_stats")
    local formation = stats and stats:FindFirstChild("formation_goal")
    if formation and formation.Value then
        local ok, pos = pcall(function() return formation.Value.Position end)
        if ok and pos then return pos end
    end
    local root = unit:FindFirstChild("_root") or (stats and stats:FindFirstChild("_root"))
    if root and root.Value then
        local ok, pos = pcall(function() return root.Value.Position end)
        if ok and pos then return pos end
    end
    local hrp = unit:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.Position
    end
    local ok, pivot = pcall(function() return unit:GetPivot().Position end)
    return ok and pivot or nil
end

function PlacementIsClear(pos, kind, minDistance)
    minDistance = minDistance or 2.45
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    if player.Character then
        table.insert(ignore, player.Character)
    end
    local unitsFolder = workspace:FindFirstChild("_UNITS")
    local deadFolder = workspace:FindFirstChild("_DEAD_UNITS")
    if unitsFolder then
        table.insert(ignore, unitsFolder)
    end
    if deadFolder then
        table.insert(ignore, deadFolder)
    end
    rayParams.FilterDescendantsInstances = ignore

    local hit = workspace:Raycast(pos + Vector3.new(0, 25, 0), Vector3.new(0, -80, 0), rayParams)
    if not hit or not HitAllowsPlacement(hit.Instance, kind) then
        return nil
    end

    if unitsFolder then
        for _, unit in ipairs(unitsFolder:GetChildren()) do
            if unit:IsA("Model") then
                local unitPos = GetPlacedBuffUnitPosition(unit)
                if unitPos then
                    local flat = Vector3.new(hit.Position.X - unitPos.X, 0, hit.Position.Z - unitPos.Z)
                    if flat.Magnitude < minDistance then
                        return nil
                    end
                end
            end
        end
    end
    return hit.Position
end

function BuildCompactHexOffsets(spacing, maxRing)
    spacing = spacing or 2.6
    maxRing = maxRing or 8
    local offsets = { Vector2.new(0, 0) }
    local allRingOffsets = {}
    for ring = 1, maxRing do
        for q = -ring, ring do
            for r = -ring, ring do
                local s = -q - r
                if math.max(math.abs(q), math.abs(r), math.abs(s)) == ring then
                    local x = spacing * (q + r * 0.5)
                    local z = spacing * (r * 0.8660254038)
                    table.insert(allRingOffsets, Vector2.new(x, z))
                end
            end
        end
    end
    table.sort(allRingOffsets, function(a, b)
        local da, db = a.Magnitude, b.Magnitude
        if math.abs(da - db) > 0.05 then
            return da < db
        end
        return math.atan2(a.Y, a.X) < math.atan2(b.Y, b.X)
    end)
    for _, offset in ipairs(allRingOffsets) do
        table.insert(offsets, offset)
    end
    return offsets
end

-- Farm units can be ground or hill units depending on the game's unit data.
-- If the unit database lookup misses an entry, try every valid placement surface
-- instead of silently skipping the farm because the guessed surface was wrong.
-- Buff units must stay together so their range-based buffs overlap.
-- game.lua marks Commander, Windsong and Elfy (Sylph) with
-- _show_as_buff_unit / _placement_highlight_buffed_units.
function IsBuffUnitInfo(info)
    if type(info) ~= "table" then return false end
    local rawId = info.unitId or info.name
    local data = LookupUnitData(rawId)
    if type(data) == "table"
        and (data._show_as_buff_unit == true or data._placement_highlight_buffed_units == true) then
        return true
    end
    if IsElfyFamilyUnit(rawId, data) then
        return true
    end
    local norm = NormalizeName(rawId)
    return norm:find("erwin", 1, true) ~= nil
        or norm:find("commander", 1, true) ~= nil
        or norm:find("wendy", 1, true) ~= nil
        or norm:find("windsong", 1, true) ~= nil
end

function IsPlacedBuffUnit(unit)
    if not unit then return false end
    local rawId = GetRawUnitId(unit)
    local data = LookupUnitData(rawId)
    if type(data) == "table"
        and (data._show_as_buff_unit == true or data._placement_highlight_buffed_units == true) then
        return true
    end
    if IsElfyFamilyUnit(rawId, data, unit) then
        return true
    end
    local norm = NormalizeName(rawId)
    return norm:find("erwin", 1, true) ~= nil
        or norm:find("commander", 1, true) ~= nil
        or norm:find("wendy", 1, true) ~= nil
        or norm:find("windsong", 1, true) ~= nil
end

function GetClusterAnchorPosition(kind)
    kind = kind or "ground"
    local buffPositions = {}
    local combatPositions = {}
    local farmPositions = {}

    for _, placed in ipairs(GetPlayerUnits()) do
        local placedKind = ResolvePlacementKind(GetRawUnitId(placed))
        local compatible = (kind == "hill" and (placedKind == "hill" or placedKind == "hybrid"))
            or (kind ~= "hill" and placedKind ~= "hill")
        if compatible then
            local pos = GetPlacedBuffUnitPosition(placed)
            if pos then
                if IsPlacedBuffUnit(placed) then
                    table.insert(buffPositions, pos)
                elseif IsFarmUnit(placed) then
                    table.insert(farmPositions, pos)
                else
                    table.insert(combatPositions, pos)
                end
            end
        end
    end

    local source = #buffPositions > 0 and buffPositions
        or (#combatPositions > 0 and combatPositions or farmPositions)
    if #source == 0 then
        return nil, buffPositions, combatPositions
    end

    local seed, bestNeighbors = source[1], -1
    for _, candidateSeed in ipairs(source) do
        local neighbors = 0
        for _, otherPos in ipairs(source) do
            if (candidateSeed - otherPos).Magnitude <= 14 then
                neighbors = neighbors + 1
            end
        end
        if neighbors > bestNeighbors then
            seed, bestNeighbors = candidateSeed, neighbors
        end
    end

    local clusterSum = Vector3.new(0, 0, 0)
    local clusterCount = 0
    for _, pos in ipairs(source) do
        if (seed - pos).Magnitude <= 14 then
            clusterSum = clusterSum + pos
            clusterCount = clusterCount + 1
        end
    end
    local anchor = clusterCount > 0 and (clusterSum / clusterCount) or seed
    return anchor, buffPositions, combatPositions
end

function GetPlacementCFrame(index, kind)
    kind = kind or "ground"

    local lane = GetPath1Lane()
    local points = lane and GetPathPoints(lane) or {}
    local preferred = math.clamp(tonumber(State.PlacePercent) or 0, 0, 100) / 100

    local function Finish(finalPos, look)
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.01 then
            flatLook = Vector3.new(0, 0, -1)
        else
            flatLook = flatLook.Unit
        end
        return CFrame.new(finalPos, finalPos + flatLook)
    end

    local clusterAnchor = GetClusterAnchorPosition(kind)

    if #points >= 2 then
        -- Keep the whole formation around one point on the actual path.
        -- Once the first unit is placed beside the road, anchor subsequent
        -- units to the existing cluster on the same side of the road so units
        -- stay tightly packed together.
        local pathCenter, look = GetPointOnPolyline(points, preferred)
        local center = clusterAnchor or pathCenter
        local right = look:Cross(Vector3.new(0, 1, 0))
        if right.Magnitude < 0.01 then
            right = Vector3.new(1, 0, 0)
        else
            right = right.Unit
        end
        local forward = Vector3.new(look.X, 0, look.Z)
        if forward.Magnitude < 0.01 then
            forward = Vector3.new(0, 0, -1)
        else
            forward = forward.Unit
        end

        local maxRing = (kind == "hill") and 16 or 9
        local offsets = BuildCompactHexOffsets(2.6, maxRing)

        -- Always search from the cluster center outward (slot 1 -> #offsets)
        -- so units pack tightly instead of scattering into outer rings.
        for slot = 1, #offsets do
            local offset = offsets[slot]
            local candidate = center + right * offset.X + forward * offset.Y
            local finalPos = PlacementIsClear(candidate, kind)
            if finalPos then
                return Finish(finalPos, look)
            end
        end
        if clusterAnchor then
            for slot = 1, #offsets do
                local offset = offsets[slot]
                local candidate = pathCenter + right * offset.X + forward * offset.Y
                local finalPos = PlacementIsClear(candidate, kind)
                if finalPos then
                    return Finish(finalPos, look)
                end
            end
        end
        return nil
    end

    -- Preserve the previous fallback for maps where lane path points
    -- are not exposed by the client, but pack tightly around the cluster.
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local center = clusterAnchor or hrp.Position
    local look = hrp.CFrame.LookVector
    local right = look:Cross(Vector3.new(0, 1, 0))
    if right.Magnitude < 0.01 then right = Vector3.new(1, 0, 0) else right = right.Unit end
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < 0.01 then forward = Vector3.new(0, 0, -1) else forward = forward.Unit end

    local maxFallbackRing = (kind == "hill") and 16 or 9
    local offsets = BuildCompactHexOffsets(2.6, maxFallbackRing)
    for slot = 1, #offsets do
        local offset = offsets[slot]
        local pos = center + right * offset.X + forward * offset.Y
        local finalPos = PlacementIsClear(pos, kind)
        if finalPos then
            return Finish(finalPos, look)
        end
    end
    return nil
end

function GetBuffPlacementCFrame(index, info, kind)
    kind = kind or ResolvePlacementKind(info and info.unitId)
    local anchor, buffPositions, combatPositions = GetClusterAnchorPosition(kind)

    local center, look
    local lane = GetPath1Lane()
    local points = lane and GetPathPoints(lane) or {}
    local preferred = math.clamp(tonumber(State.PlacePercent) or 0, 0, 100) / 100
    if #points >= 2 then
        local _, pathLook = GetPointOnPolyline(points, preferred)
        look = pathLook
    end

    if anchor then
        center = anchor
        if not look then
            local base = GetPlacementCFrame(1, kind)
            look = base and base.LookVector or Vector3.new(0, 0, -1)
        end
    else
        local base = GetPlacementCFrame(1, kind)
        if not base then return nil end
        center = base.Position
        look = look or base.LookVector
    end

    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end
    local right = flatLook:Cross(Vector3.new(0, 1, 0))
    if right.Magnitude < 0.01 then right = Vector3.new(1, 0, 0) else right = right.Unit end

    -- Compact 2.6-stud hex grid keeps all buff units and nearby combat units
    -- tightly grouped well inside Commander (15), Windsong (20), and Elfy (25)
    -- range circles.
    local offsets = BuildCompactHexOffsets(2.55, 7)
    local referencePositions = #buffPositions > 0 and buffPositions or combatPositions

    local bestCFrame, bestScore = nil, math.huge
    for _, offset in ipairs(offsets) do
        local candidate = center + right * offset.X + flatLook * offset.Y
        local finalPos = PlacementIsClear(candidate, kind)
        if finalPos then
            local maxRefDistance = 0
            local sumRefDistance = 0
            for _, existingPos in ipairs(referencePositions) do
                local d = (finalPos - existingPos).Magnitude
                maxRefDistance = math.max(maxRefDistance, d)
                sumRefDistance = sumRefDistance + d
            end
            local avgRefDistance = #referencePositions > 0 and (sumRefDistance / #referencePositions) or 0
            local score = offset.Magnitude + avgRefDistance * 0.6 + maxRefDistance * 0.4
            if (maxRefDistance <= 14.5 or bestCFrame == nil) and score < bestScore then
                bestScore = score
                bestCFrame = CFrame.new(finalPos, finalPos + flatLook)
                if maxRefDistance <= 6.5 and offset.Magnitude <= 5.5 then
                    break
                end
            end
        end
    end
    return bestCFrame
end

function GetPlacementCFrameForInfo(index, info)
    local primary = ResolvePlacementKind(info and info.unitId)
    if IsBuffUnitInfo(info) then
        local clustered = GetBuffPlacementCFrame(index, info, primary)
        if clustered then return clustered, primary end
    end
    local kinds = { primary }
    if IsFarmInfo(info) then
        for _, candidate in ipairs({ "ground", "hill", "hybrid" }) do
            local exists = false
            for _, current in ipairs(kinds) do
                if current == candidate then exists = true break end
            end
            if not exists then table.insert(kinds, candidate) end
        end
    end
    for _, kind in ipairs(kinds) do
        local cf = GetPlacementCFrame(index, kind)
        if cf then return cf, kind end
    end
    return nil, primary
end

function CountCategory(myUnits, pred)
    local n = 0
    for _, u in ipairs(myUnits) do
        if pred(u) then
            n = n + 1
        end
    end
    return n
end

function HttpPost(url, body)
    local payload = {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    }
    local fn = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
    if fn then
        return fn(payload)
    end
    return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
end

function NormalizeWebhookUrl(url)
    return (tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function WebhookProblem(url)
    if url == "" then
        return "Webhook URL is empty."
    end
    if not url:match("^https?://") then
        return "Webhook URL is invalid. It must start with http:// or https://."
    end
    if not url:find("discord.com/api/webhooks/", 1, true) and not url:find("discordapp.com/api/webhooks/", 1, true) then
        return "Webhook URL is invalid. Use a Discord webhook URL."
    end
    return nil
end

function DescribeWebhookResult(ok, result)
    if not ok then
        return false, tostring(result), nil
    end
    if type(result) == "table" then
        local code = tonumber(result.StatusCode or result.status_code or result.Status or result.status)
        local requestSucceeded = result.Success
        if requestSucceeded == nil then requestSucceeded = result.success end
        local body = tostring(result.Body or result.body or "")
        local headers = result.Headers or result.headers or {}
        local retryAfter
        for key, value in pairs(headers) do
            local lowerKey = string.lower(tostring(key))
            if lowerKey == "retry-after" or lowerKey == "x-ratelimit-reset-after" then
                retryAfter = tonumber(value)
                if retryAfter then break end
            end
        end
        if not retryAfter and type(result.Body or result.body) == "string" then
            local okJson, decoded = pcall(function()
                return HttpService:JSONDecode(result.Body or result.body)
            end)
            if okJson and type(decoded) == "table" then
                retryAfter = tonumber(decoded.retry_after)
            end
        end
        if retryAfter then retryAfter = math.clamp(retryAfter, 1, 120) end
        if #body > 180 then body = body:sub(1, 180) end

        if requestSucceeded == false then
            return false, (code and ("HTTP " .. tostring(code) .. ": ") or "Request failed: ") .. body, retryAfter
        end
        if code and (code < 200 or code >= 300) then
            if body ~= "" then
                return false, "HTTP " .. tostring(code) .. ": " .. body, retryAfter
            end
            return false, "HTTP " .. tostring(code), retryAfter
        end
    end
    -- Discord webhooks commonly answer with HTTP 204 and an empty body.
    return true, "Webhook request accepted.", nil
end


function ReadPlayerCurrencies()
    local values = {}
    local stats = player:FindFirstChild("_stats")
    if stats then
        for _, child in ipairs(stats:GetChildren()) do
            if child:IsA("ValueBase") and type(child.Value) == "number" then
                local name = child.Name
                if name == "gold_amount" then
                    values.Gold = child.Value
                elseif name == "gem_amount" then
                    values.Gems = child.Value
                elseif name == "trophies" then
                    values.Trophies = child.Value
                elseif name == "player_xp" then
                    values.XP = child.Value
                elseif name:sub(1, 9) == "_resource" then
                    local resourceName = name:sub(10):gsub("^_+", "")
                    values[resourceName] = child.Value
                    if resourceName:lower():find("summer", 1, true) and resourceName:lower():find("pearl", 1, true) then
                        values.SummerPearls = child.Value
                    end
                elseif name:lower():find("summerpearls", 1, true) then
                    values.SummerPearls = child.Value
                end
            end
        end
    end
    return values
end

function FormatNumber(value)
    local n = tonumber(value) or 0
    local sign = n < 0 and "-" or ""
    local digits = tostring(math.floor(math.abs(n)))
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

function FormatCompact(value)
    local n = tonumber(value) or 0
    local abs = math.abs(n)
    local suffix = ""
    local divisor = 1
    if abs >= 1e12 then suffix, divisor = "T", 1e12
    elseif abs >= 1e9 then suffix, divisor = "B", 1e9
    elseif abs >= 1e6 then suffix, divisor = "M", 1e6
    elseif abs >= 1e3 then suffix, divisor = "K", 1e3 end
    if divisor == 1 then return FormatNumber(n) end
    local valueText = string.format("%.2f", n / divisor):gsub("%.?0+$", "")
    return valueText .. suffix
end

function ReadTraitRerolls()
    local ok, amount = pcall(function()
        local Loader = require(ReplicatedStorage.src.Loader)
        local inventoryService = Loader.load_client_service(game, "ItemInventoryServiceClient")
        local session = inventoryService and inventoryService.session
        local profile = session and session.profile_data
        if profile and profile.trait_reroll_tokens ~= nil then
            return tonumber(profile.trait_reroll_tokens)
        end
        local inventory = session and session.inventory
        if inventory and type(inventory.get_number_of_owned_item) == "function" then
            return tonumber(inventory:get_number_of_owned_item("trait_reroll_tokens__MOCK"))
        end
        return nil
    end)
    return ok and tonumber(amount) or nil
end

function BuildPlayerStatsText(currencies)
    local traitCount = ReadTraitRerolls()
    local lines = {}
    local gemEmoji = "<:GemAA:1563613761544392794>"
    local goldEmoji = "<:GoldAA:1566642394412220508>"
    local summerEmoji = "<:SummerAA:1566642524636840128>"
    local traitEmoji = "<:TraitAA:1566642609479360642>"
    table.insert(lines, gemEmoji .. " **Gem:** " .. FormatNumber(currencies.Gems or 0))
    table.insert(lines, goldEmoji .. " **Gold:** " .. FormatNumber(currencies.Gold or 0))
    local summer = currencies.SummerPearls or currencies.summer_pearls or currencies.Summerpearls
    if summer == nil then
        for key, value in pairs(currencies) do
            if tostring(key):lower():find("summerpearls", 1, true) then summer = value break end
        end
    end
    table.insert(lines, summerEmoji .. " **Summer Pearls:** " .. FormatNumber(summer or 0))
    if traitCount ~= nil then
        table.insert(lines, traitEmoji .. " **Trait:** " .. FormatNumber(traitCount))
    end
    return table.concat(lines, "\n")
end

-- Live match information shown while Reduce 3D Render is active.
GetInGameCash = nil -- forward declaration; implementation is below the upgrade helpers.
matchStartedAt = nil
lastMatchInfoRefresh = 0
function FormatElapsed(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function ReadCurrentStageName()
    local liveName
    pcall(function()
        local loaderModule = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("Loader")
        if loaderModule then
            local Loader = require(loaderModule)
            local levelData = Loader and Loader.LevelData
            if type(levelData) == "table" and type(levelData.name) == "string" and levelData.name ~= "" then
                liveName = levelData.name
            end
        end
    end)
    if liveName then return liveName end

    local results = playerGui:FindFirstChild("ResultsUI")
    local holder = results and results:FindFirstChild("Holder")
    local resultName = holder and holder:FindFirstChild("LevelName")
    if resultName and resultName:IsA("TextLabel") and resultName.Text ~= "" then
        return resultName.Text
    end

    local data = workspace:FindFirstChild("_DATA")
    if data then
        for _, name in ipairs({"LevelName", "StageName", "MapName", "Level", "Stage"}) do
            local value = data:FindFirstChild(name)
            if value and value:IsA("ValueBase") and tostring(value.Value) ~= "" then
                return tostring(value.Value)
            end
        end
    end
    for _, name in ipairs({"_level_name", "_stage_name", "_map_name"}) do
        local value = workspace:FindFirstChild(name)
        if value and value:IsA("ValueBase") and tostring(value.Value) ~= "" then
            return tostring(value.Value)
        end
    end
    return "Unknown Stage"
end

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.25)

        if State.BlackScreen then
            local highestDisplayOrder = 9999
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui ~= ScreenGui then
                    highestDisplayOrder = math.max(highestDisplayOrder, gui.DisplayOrder)
                end
            end
            local targetDisplayOrder = math.min(highestDisplayOrder + 1, 2147483000)
            if ScreenGui.DisplayOrder ~= targetDisplayOrder then
                ScreenGui.DisplayOrder = targetDisplayOrder
            end
        elseif ScreenGui.DisplayOrder ~= 10000 then
            ScreenGui.DisplayOrder = 10000
        end

        local dataFolder = workspace:FindFirstChild("_DATA")
        local gameStarted = dataFolder and dataFolder:FindFirstChild("GameStarted")
        local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
        local matchStateKnown = gameStarted ~= nil
        local matchStateActive = gameStarted and gameStarted.Value == true
            and not (gameFinished and gameFinished.Value == true)
        local hasUnitsFolder = workspace:FindFirstChild("_UNITS") ~= nil
        local inMatch = hasUnitsFolder and (matchStateActive or (not matchStateKnown and not IsInLobby()))
        if inMatch then
            if not matchStartedAt then matchStartedAt = os.clock() end
        else
            matchStartedAt = nil
        end

        local showPanel = State.BlackScreen == true and inMatch
        MatchInfoPanel.Visible = showPanel
        if showPanel and os.clock() - lastMatchInfoRefresh >= 0.5 then
            lastMatchInfoRefresh = os.clock()
            MatchTimerLabel.Text = "TIME  " .. FormatElapsed(matchStartedAt and (os.clock() - matchStartedAt) or 0)
            MatchStageLabel.Text = "STAGE: " .. ReadCurrentStageName()
            MatchWaveLabel.Text = "WAVE  " .. tostring(GetCurrentWave())

            local currencies = ReadPlayerCurrencies()
            local cash = GetInGameCash()
            local statLines = {
                "PLAYER: " .. tostring(player.DisplayName or player.Name),
                "CASH: " .. (cash ~= nil and FormatCompact(cash) or "N/A"),
                "GEMS: " .. FormatCompact(currencies.Gems or 0) .. "     GOLD: " .. FormatCompact(currencies.Gold or 0),
                "SUMMER PEARLS: " .. FormatCompact(currencies.SummerPearls or currencies.summer_pearls or currencies.Summerpearls or 0),
                "XP: " .. FormatCompact(currencies.XP or 0) .. "     TROPHIES: " .. FormatCompact(currencies.Trophies or 0),
            }
            MatchStatsLabel.Text = table.concat(statLines, "\n")
        end
    end
end)

function ReadAuthoritativeResultSettings()
    -- game.lua ResultsUI.new() stores the ResultsUI ScreenGui in screenGUI,
    -- and ResultsUI.show_results(settings) stores the exact server result in .settings.
    local results = playerGui:FindFirstChild("ResultsUI")
    -- ResultsUI.settings is assigned before the GUI is enabled. Do not gate
    -- result access on ScreenGui.Enabled: rendering/BlackScreen can keep it hidden.
    if not results or type(getgc) ~= "function" then return nil end

    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end

    for _, object in ipairs(objects) do
        if type(object) == "table" and object.screenGUI == results then
            local settings = object.settings
            if type(settings) == "table" and type(settings.victory) == "boolean"
                and type(settings.stats) == "table" then
                return settings
            end
        end
    end
    return nil
end

function GetResultDetails()
    local details = {}
    local settings = ReadAuthoritativeResultSettings()
    if settings then
        details.authoritative = true
        details.settings = settings
        details.result = settings.victory and "VICTORY!!!" or "DEFEAT"
        details.level = tostring(settings.title or "Unknown stage")

        local stats = settings.stats or {}
        if tonumber(stats.time_taken) then
            local totalSeconds = math.ceil(tonumber(stats.time_taken))
            details.Timer = string.format("%02d:%02d", math.floor(totalSeconds / 60), totalSeconds % 60)
        end
        if tonumber(stats.waves_completed) then
            details.WavesCompleted = tostring(math.floor(tonumber(stats.waves_completed)))
        end
        return details
    end

    -- UI fallback for executors where the ResultsUI controller cannot be read.
    local results = playerGui:FindFirstChild("ResultsUI")
    local holder = results and results:FindFirstChild("Holder")
    if results and results.Enabled == true and holder and holder.Visible == true then
        local levelName = holder:FindFirstChild("LevelName")
        if levelName and levelName:IsA("TextLabel") then details.level = levelName.Text end
        local title = holder:FindFirstChild("Title")
        if title and title:IsA("TextLabel") then details.result = title.Text end
        local middle = holder:FindFirstChild("Middle")
        if middle then
            local timer = middle:FindFirstChild("Timer")
            if timer and timer:IsA("TextLabel") then
                details.Timer = tostring(timer.Text):gsub("^Total Time:%s*", "")
            end
            local waves = middle:FindFirstChild("WavesCompleted")
            if waves and waves:IsA("TextLabel") then
                details.WavesCompleted = tostring(waves.Text):gsub("^Waves Completed:%s*", "")
            end
        end
    end
    return details
end

-- ResultsUI is populated directly from ResultsUI.show_results(settings).
-- ResourceReward frames therefore provide the authoritative per-stage resource amounts.
-- Snapshot unique Secret rewards at match start so Webhook can report only
-- Secret Units / Secret Portals newly granted by this match.
function LoadGameDataModule(moduleName)
    local module = ReplicatedStorage:FindFirstChild(moduleName, true)
    if module and module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and type(data) == "table" then return data end
    end
    return nil
end

-- Snapshot all inventory rewards at match start/end. This includes stackable
-- normal_items, unique inventory items (Portals/Charms/materials/etc.), and units.
function ReadInventoryRewardSnapshot()
    local snapshot = {}
    local itemData = LoadGameDataModule("Items") or {}
    local unitData = LoadGameDataModule("Units") or {}
    local inventoryProfile, collectionProfile = nil, nil

    -- Always bind the snapshot to this client player's live GUIService session.
    -- Never take the last arbitrary inventory_profile_data found in getgc(): that
    -- can belong to another player/session and makes before/after reward diffs invalid.
    local localSession = type(FindLocalGameSession) == "function" and FindLocalGameSession() or nil
    if type(localSession) == "table" then
        local inventory = localSession.inventory
        local profile = type(inventory) == "table" and inventory.inventory_profile_data or nil
        if type(profile) == "table" and type(profile.unique_items) == "table" then
            inventoryProfile = profile
        end

        local collection = localSession.collection
        local ownedProfile = type(collection) == "table" and collection.collection_profile_data or nil
        if type(ownedProfile) == "table" and type(ownedProfile.owned_units) == "table" then
            collectionProfile = ownedProfile
        end
    end

    -- Executor fallback: only accept a session explicitly owned by LocalPlayer.
    if (not inventoryProfile or not collectionProfile) and type(getgc) == "function" then
        local ok, objects = pcall(getgc, true)
        if ok and type(objects) == "table" then
            for _, object in ipairs(objects) do
                if type(object) == "table" then
                    local candidates = { object, object.session }
                    for _, candidate in ipairs(candidates) do
                        if type(candidate) == "table" and candidate.player == player then
                            if not inventoryProfile then
                                local inventory = candidate.inventory
                                local profile = type(inventory) == "table" and inventory.inventory_profile_data or nil
                                if type(profile) == "table" and type(profile.unique_items) == "table" then
                                    inventoryProfile = profile
                                end
                            end
                            if not collectionProfile then
                                local collection = candidate.collection
                                local ownedProfile = type(collection) == "table" and collection.collection_profile_data or nil
                                if type(ownedProfile) == "table" and type(ownedProfile.owned_units) == "table" then
                                    collectionProfile = ownedProfile
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local portalNames = {
        portal_item__skypiea = "Sky Portal",
        portal_item__enel = "Sky God's Portal",
    }
    local portalRarities = {
        portal_item__skypiea = "Mythic",
        portal_item__enel = "Secret",
    }

    if inventoryProfile then
        -- Stackable drops are stored as item_id -> quantity.
        for itemId, amount in pairs(inventoryProfile.normal_items or {}) do
            local count = tonumber(amount) or 0
            if count > 0 then
                local id = tostring(itemId)
                local def = itemData[id] or {}
                snapshot["normal:" .. id] = {
                    itemId = id,
                    category = tostring(def.item_group or (portalNames[id] and "Portals") or "Item"),
                    name = tostring(portalNames[id] or def.name or id),
                    rarity = tostring(def.rarity or portalRarities[id] or "Unknown"),
                    tier = tonumber(def.tier),
                    amount = count,
                    secret = tostring(def.rarity or portalRarities[id] or ""):lower() == "secret",
                }
            end
        end

        -- Unique drops have their own UUID; use it to avoid confusing duplicates.
        for _, owned in pairs(inventoryProfile.unique_items or {}) do
            if type(owned) == "table" and type(owned.uuid) == "string" and type(owned.item_id) == "string" then
                local id = tostring(owned.item_id)
                local def = itemData[id] or {}
                local rarity = tostring(def.rarity or portalRarities[id] or "Unknown")
                snapshot["item:" .. owned.uuid] = {
                    uuid = owned.uuid,
                    itemId = id,
                    category = tostring(def.item_group or (portalNames[id] and "Portals") or "Item"),
                    name = tostring(portalNames[id] or def.name or id),
                    rarity = rarity,
                    tier = tonumber(def.tier),
                    amount = 1,
                    secret = rarity:lower() == "secret",
                }
            end
        end
    end

    if collectionProfile then
        for uuid, owned in pairs(collectionProfile.owned_units or {}) do
            if type(owned) == "table" and type(owned.unit_id) == "string" then
                local def = unitData[owned.unit_id] or {}
                snapshot["unit:" .. tostring(uuid)] = {
                    unitId = owned.unit_id,
                    category = "Unit",
                    name = tostring(def.name or owned.unit_id),
                    rarity = tostring(def.rarity or "Unknown"),
                    amount = 1,
                    secret = tostring(def.rarity or ""):lower() == "secret",
                }
            end
        end
    end
    -- Inventory availability must specifically mean the inventory profile was read.
    -- A collection-only session is not sufficient to diff portal/item rewards.
    return snapshot, inventoryProfile ~= nil
end

local WEBHOOK_PORTAL_ITEMS = {
    portal_item__skypiea = { name = "Sky Portal", rarity = "Mythic" },
    portal_item__enel = { name = "Sky God's Portal", rarity = "Secret" },
}

function GetWebhookPortalCounts(snapshot)
    local counts = { portal_item__skypiea = 0, portal_item__enel = 0 }
    for key, reward in pairs(snapshot or {}) do
        local itemId = tostring(reward and reward.itemId or "")
        if counts[itemId] ~= nil then
            if key:sub(1, 7) == "normal:" then
                counts[itemId] = counts[itemId] + math.max(0, tonumber(reward.amount) or 1)
            else
                counts[itemId] = counts[itemId] + 1
            end
        end
    end
    return counts
end

function BuildInventoryRewardLines(before, after, skipTrackedPortals)
    local normalEntries, secretEntries = {}, {}
    local beforePortals = GetWebhookPortalCounts(before)
    local afterPortals = GetWebhookPortalCounts(after)

    -- Aggregate stackable normal_items and UUID-based unique_items into one
    -- Portal delta, with the final owned quantity in square brackets.
    for itemId, portal in pairs(WEBHOOK_PORTAL_ITEMS) do
        local gained = math.max(0, (afterPortals[itemId] or 0) - (beforePortals[itemId] or 0))
        if gained > 0 then
            local line = string.format("• **+%s %s [%s]** — Portals · %s",
                FormatNumber(gained), portal.name, FormatNumber(afterPortals[itemId] or 0), portal.rarity)
            local entry = { sort = portal.name:lower(), line = line }
            if portal.rarity == "Secret" then
                table.insert(secretEntries, { sort = entry.sort, line = "🌟 " .. entry.line })
            else
                table.insert(normalEntries, entry)
            end
        end
    end

    for key, reward in pairs(after or {}) do
        local itemId = tostring(reward and reward.itemId or "")
        if not WEBHOOK_PORTAL_ITEMS[itemId] then
            local old = before and before[key]
            local amount = tonumber(reward.amount) or 1
            local gained = amount
            if key:sub(1, 7) == "normal:" then
                gained = math.max(0, amount - (old and tonumber(old.amount) or 0))
            elseif old then
                gained = 0
            end

            if gained > 0 then
                local category = tostring(reward.category or "Item")
                local name = tostring(reward.name or "Unknown")
                local rarity = tostring(reward.rarity or "")
                local tierText = reward.tier and (" · Tier " .. tostring(reward.tier)) or ""
                local rarityText = rarity ~= "" and rarity ~= "Unknown" and (" · " .. rarity) or ""
                local line = string.format("• **%s ×%s** — %s%s%s",
                    name, FormatNumber(gained), category, rarityText, tierText)
                if tostring(reward.rarity or ""):lower() == "secret" or reward.secret == true then
                    table.insert(secretEntries, { sort = name:lower(), line = "🌟 " .. line })
                else
                    table.insert(normalEntries, { sort = name:lower(), line = line })
                end
            end
        end
    end

    local function SortLines(entries)
        table.sort(entries, function(a, b) return a.sort < b.sort end)
        local lines = {}
        for _, entry in ipairs(entries) do table.insert(lines, entry.line) end
        return lines
    end
    local normalLines = SortLines(normalEntries)
    local secretLines = SortLines(secretEntries)
    return #normalLines > 0 and table.concat(normalLines, "\n") or nil,
        #secretLines > 0 and table.concat(secretLines, "\n") or nil
end

function BuildTrackedSkyPortalRewardLines(trackedPortals)
    local counts = { portal_item__skypiea = 0, portal_item__enel = 0 }
    for _, reward in pairs(trackedPortals or {}) do
        local itemId = tostring(reward and reward.itemId or "")
        if counts[itemId] ~= nil then counts[itemId] = counts[itemId] + 1 end
    end
    local normalLines, secretLines = {}, {}
    if counts.portal_item__skypiea > 0 then
        table.insert(normalLines, string.format("• **Sky Portal ×%s** — Portals · Mythic", FormatNumber(counts.portal_item__skypiea)))
    end
    if counts.portal_item__enel > 0 then
        local line = string.format("🌟 • **Sky God's Portal ×%s** — Portals · Secret", FormatNumber(counts.portal_item__enel))
        table.insert(normalLines, line)
        table.insert(secretLines, line)
    end
    return #normalLines > 0 and table.concat(normalLines, "\n") or nil,
        #secretLines > 0 and table.concat(secretLines, "\n") or nil
end

function BuildMatchRewardLines(resultDetails)
    local settings = resultDetails and resultDetails.settings
    local lines = {}
    if type(settings) == "table" then
        local rewardFields = {
            { key = "xp_reward", label = "Player XP" },
            { key = "gold_reward", label = "Gold" },
            { key = "gem_reward", label = "Gems" },
            { key = "trophy_reward", label = "Trophies" },
        }
        for _, entry in ipairs(rewardFields) do
            local amount = tonumber(settings[entry.key])
            if amount and amount > 0 then
                table.insert(lines, string.format("• **%s:** +%s", entry.label, FormatNumber(amount)))
            end
        end
        if type(settings.resource_reward) == "table" then
            local resourceEntries = {}
            for resourceName, amount in pairs(settings.resource_reward) do
                if tonumber(amount) and tonumber(amount) > 0 then
                    local rawName = tostring(resourceName)
                    local label = rawName:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):gsub("(%a)([%w']*)", function(first, rest)
                        return first:upper() .. rest
                    end)
                    table.insert(resourceEntries, { key = resourceName, label = label, amount = tonumber(amount) })
                end
            end
            table.sort(resourceEntries, function(a, b) return a.label < b.label end)
            for _, entry in ipairs(resourceEntries) do
                table.insert(lines, string.format("• **%s:** +%s", entry.label, FormatNumber(entry.amount)))
            end
        end
    end

    -- Fallback: read the exact visible reward amounts rendered by ResultsUI.
    if #lines == 0 then
        local results = playerGui:FindFirstChild("ResultsUI")
        local holder = results and results:FindFirstChild("Holder")
        local scroll = holder and holder:FindFirstChild("LevelRewards")
        scroll = scroll and scroll:FindFirstChild("ScrollingFrame")
        if scroll then
            local labels = {
                GoldReward = "Gold", GemReward = "Gems", TrophyReward = "Trophies", XPReward = "Player XP",
            }
            for _, frame in ipairs(scroll:GetChildren()) do
                if frame:IsA("GuiObject") and frame.Visible then
                    local main = frame:FindFirstChild("Main")
                    local amount = main and main:FindFirstChild("Amount")
                    if amount and amount:IsA("TextLabel") and amount.Text ~= "" then
                        local label = labels[frame.Name]
                        if frame.Name == "ResourceReward" then label = "Resource" end
                        if label then table.insert(lines, "• **" .. label .. ":** " .. amount.Text) end
                    end
                end
            end
        end
    end

    return #lines > 0 and table.concat(lines, "\n") or nil
end

-- First-completion bonuses are reported separately from the normal stage rewards.
function BuildFirstCompletionRewardLines(settings)
    if type(settings) ~= "table" or not settings.first_completion then return nil end
    local bonusLines = {}
    local gems = tonumber(settings.first_completion_gems)
    local trophies = tonumber(settings.first_completion_trophies)
    if gems and gems > 0 then
        table.insert(bonusLines, "• **Gems:** +" .. FormatNumber(gems))
    end
    if trophies and trophies > 0 then
        table.insert(bonusLines, "• **Trophies:** +" .. FormatNumber(trophies))
    end
    if #bonusLines == 0 then return nil end
    return "**⭐ First Completion Bonus**\n" .. table.concat(bonusLines, "\n")
end

webhookCurrencyBefore = nil
webhookSecretRewardBefore = nil
webhookSecretRewardBaselineAvailable = false
function CaptureWebhookCurrencyBaseline()
    webhookCurrencyBefore = ReadPlayerCurrencies()
    webhookSecretRewardBefore, webhookSecretRewardBaselineAvailable = ReadInventoryRewardSnapshot()
    -- Inventory profile data can initialize a moment after the match starts.
    -- Retry briefly so the end-of-match diff has a real player-owned baseline.
    for attempt = 1, 6 do
        if webhookSecretRewardBaselineAvailable then break end
        task.wait(0.35)
        webhookSecretRewardBefore, webhookSecretRewardBaselineAvailable = ReadInventoryRewardSnapshot()
    end
    return table.clone(webhookCurrencyBefore), webhookSecretRewardBefore, webhookSecretRewardBaselineAvailable
end

function ReadPlayerLevel()
    local stats = player:FindFirstChild("_stats")
    if stats then
        for _, name in ipairs({"player_level", "level"}) do
            local value = stats:FindFirstChild(name)
            if value and value:IsA("ValueBase") then
                local number = tonumber(value.Value)
                if number then return number end
            end
        end
    end
    -- Anime Adventures calculates player level from _stats.player_xp through LevelServiceCore.
    local ok, level = pcall(function()
        local statsFolder = player:FindFirstChild("_stats")
        local xpValue = statsFolder and statsFolder:FindFirstChild("player_xp")
        local xp = xpValue and tonumber(xpValue.Value)
        if xp == nil then return nil end
        local Loader = require(ReplicatedStorage.src.Loader)
        local service = Loader.load_core_service(game, "LevelServiceCore")
        if service and type(service.calculate_level) == "function" then
            return service.calculate_level(player, xp)
        end
        return nil
    end)
    return ok and tonumber(level) or nil
end

function ReadMatchUnitLines()
    -- Aggregate every placed copy of the same unit type. Anime Adventures exposes
    -- these exact per-instance values through unit._stats.total_damage/takedown_count.
    local units = GetPlayerUnits()
    local grouped = {}
    for _, unit in ipairs(units) do
        local stats = unit:FindFirstChild("_stats")
        if stats then
            local idValue = stats:FindFirstChild("id")
            local unitId = idValue and tostring(idValue.Value) or unit.Name
            local def = LookupUnitData(unitId)
            local displayName = tostring((def and def.name) or unitId)
            local damageValue = stats:FindFirstChild("total_damage")
            local takedownValue = stats:FindFirstChild("takedown_count")
            local damage = damageValue and tonumber(damageValue.Value) or 0
            local takedowns = takedownValue and tonumber(takedownValue.Value) or 0
            local key = NormalizeName(unitId)
            local entry = grouped[key]
            if not entry then
                entry = { name = displayName, damage = 0, takedowns = 0, copies = 0 }
                grouped[key] = entry
            end
            entry.damage = entry.damage + damage
            entry.takedowns = entry.takedowns + takedowns
            entry.copies = entry.copies + 1
        end
    end

    local entries = {}
    for _, entry in pairs(grouped) do
        table.insert(entries, {
            sort = entry.name:lower(),
            line = string.format("• **%s** ×%d — Damage: **%s** | Takedowns: **%s**",
                entry.name, entry.copies, FormatCompact(entry.damage), FormatNumber(entry.takedowns)),
        })
    end
    table.sort(entries, function(a, b) return a.sort < b.sort end)
    local lines = {}
    for _, entry in ipairs(entries) do table.insert(lines, entry.line) end
    return #lines > 0 and table.concat(lines, "\n") or "No placed unit stats captured."
end

function ResolveWebhookOutcome(resultDetails)
    -- Only trust the current ResultsUI controller settings / current result title.
    -- Never use generic _DATA Won/Victory flags: they can be stale across matches.
    local title = string.upper(tostring(resultDetails and resultDetails.result or ""))
    if title:find("DEFEAT", 1, true) then return "Defeat" end
    if title:find("VICTORY", 1, true) then return "Victory" end
    return "Unknown"
end

function SendEndWebhook(currencyBaseline, secretBaseline, secretBaselineAvailable, unitLinesSnapshot, trackedPortalSnapshot)
    local url = NormalizeWebhookUrl(State.WebhookURL)
    local problem = WebhookProblem(url)
    if problem then
        warn("[Octoput Hub Webhook] " .. problem)
        return false
    end

    -- Wait for this match's authoritative ResultsUI settings. game.lua calls
    -- ResultsUI.show_results(settings), where victory/title/stats/rewards live.
    local resultDetails
    for attempt = 1, 12 do
        local currentSettings = ReadAuthoritativeResultSettings()
        if currentSettings and currentSettings ~= webhookResultSettingsAtStart then
            resultDetails = GetResultDetails()
            if resultDetails.authoritative then break end
        end
        task.wait(0.5)
    end
    resultDetails = resultDetails or GetResultDetails()
    if not resultDetails.authoritative and resultDetails.result == webhookResultTitleAtStart then
        resultDetails.result = nil
    end
    local outcome = ResolveWebhookOutcome(resultDetails)

    local inventoryRewardsAfter, inventoryRewardsAvailable = nil, false
    local inventoryRewardText, secretRewardText
    if secretBaselineAvailable then
        -- Allow delayed server inventory grants to settle after ResultsUI appears.
        local previousPortalSignature = nil
        local stablePortalReads = 0
        for attempt = 1, 12 do
            local sampledSnapshot, sampledAvailable = ReadInventoryRewardSnapshot()
            if sampledAvailable then
                inventoryRewardsAfter = sampledSnapshot
                inventoryRewardsAvailable = true
                local portalCounts = GetWebhookPortalCounts(sampledSnapshot)
                local signature = string.format("%d|%d",
                    portalCounts.portal_item__skypiea or 0,
                    portalCounts.portal_item__enel or 0)
                if signature == previousPortalSignature then
                    stablePortalReads = stablePortalReads + 1
                else
                    stablePortalReads = 0
                    previousPortalSignature = signature
                end
                if stablePortalReads >= 2 and attempt >= 5 then break end
            end
            task.wait(0.5)
        end
        if inventoryRewardsAvailable then
            inventoryRewardText, secretRewardText = BuildInventoryRewardLines(secretBaseline, inventoryRewardsAfter, trackedPortalSnapshot)
        else
            warn("[Octoput Hub Webhook] Inventory snapshot unavailable after retries.")
        end
    else
        warn("[Octoput Hub Webhook] Inventory baseline unavailable; inventory drops cannot be diffed.")
    end

    -- Portal UUIDs observed during the live match are authoritative even if the
    -- inventory profile disappears during defeat / result-screen teardown.
    -- Only use live UUID tracking as a fallback when the final inventory read
    -- failed. When the final read succeeds, its before/after diff already includes
    -- both normal stack amounts and unique Portal UUIDs.
    if not inventoryRewardsAvailable then
        local trackedPortalNormal, trackedPortalSecret = BuildTrackedSkyPortalRewardLines(trackedPortalSnapshot)
        if trackedPortalNormal then
            inventoryRewardText = inventoryRewardText and (inventoryRewardText .. "\n" .. trackedPortalNormal) or trackedPortalNormal
        end
        if trackedPortalSecret then
            secretRewardText = secretRewardText and (secretRewardText .. "\n" .. trackedPortalSecret) or trackedPortalSecret
        end
    end

    local currentCurrencies = ReadPlayerCurrencies()
    local playerLevel = ReadPlayerLevel()
    local playerStatsText = BuildPlayerStatsText(currentCurrencies)
    local playerXP = currentCurrencies.XP or 0

    -- Rewards field combines authoritative stage rewards, first-clear bonuses,
    -- and every inventory delta (units/items/portals/charms/materials).
    local rewardSections = {}
    local resultRewardText = BuildMatchRewardLines(resultDetails)
    if resultRewardText then table.insert(rewardSections, resultRewardText) end

    local firstCompletionRewardText = BuildFirstCompletionRewardLines(resultDetails and resultDetails.settings)
    if firstCompletionRewardText then table.insert(rewardSections, firstCompletionRewardText) end
    if inventoryRewardText then table.insert(rewardSections, inventoryRewardText) end

    -- Fallback to currency deltas only for reward types absent from the ResultsUI
    -- payload, preventing the same reward from being reported twice.
    local settings = resultDetails and resultDetails.settings
    local before = currencyBaseline or {}
    local fallbackLines = {}
    local fallbackKeys = {
        { key = "XP", setting = "xp_reward", label = "Player XP" },
        { key = "Gold", setting = "gold_reward", label = "Gold" },
        { key = "Gems", setting = "gem_reward", label = "Gems" },
        { key = "Trophies", setting = "trophy_reward", label = "Trophies" },
    }
    for _, entry in ipairs(fallbackKeys) do
        local settingValue = type(settings) == "table" and tonumber(settings[entry.setting]) or nil
        local delta = (tonumber(currentCurrencies[entry.key]) or 0) - (tonumber(before[entry.key]) or 0)
        if (not settingValue or settingValue <= 0) and delta > 0 then
            table.insert(fallbackLines, string.format("• **%s:** +%s", entry.label, FormatNumber(delta)))
        end
    end
    local function NormalizeRewardKey(value)
        return tostring(value or ""):lower():gsub("[^%w]", "")
    end
    local reportedResourceKeys = {}
    if type(settings) == "table" and type(settings.resource_reward) == "table" then
        for resourceName in pairs(settings.resource_reward) do
            reportedResourceKeys[NormalizeRewardKey(resourceName)] = true
        end
    end
    local seenCurrencyAliases = {}
    for key, value in pairs(currentCurrencies) do
        if not ({ XP = true, Gold = true, Gems = true, Trophies = true })[key] then
            local normalizedKey = NormalizeRewardKey(key)
            if not seenCurrencyAliases[normalizedKey] then
                seenCurrencyAliases[normalizedKey] = true
                local delta = (tonumber(value) or 0) - (tonumber(before[key]) or 0)
                if delta > 0 and not reportedResourceKeys[normalizedKey] then
                    local label = tostring(key):gsub("_", " "):gsub("(%l)(%u)", "%1 %2")
                    table.insert(fallbackLines, "• **" .. label .. ":** +" .. FormatNumber(delta))
                end
            end
        end
    end
    if #fallbackLines > 0 then
        table.sort(fallbackLines)
        table.insert(rewardSections, table.concat(fallbackLines, "\n"))
    end
    local rewardsText = #rewardSections > 0 and table.concat(rewardSections, "\n\n")
        or "No additional rewards detected."

    local unitLines = unitLinesSnapshot or ReadMatchUnitLines()
    local matchTime = tostring(resultDetails.Timer or "Unknown")
    local waveText = tostring(resultDetails.WavesCompleted or "Unknown")
    local stageText = tostring(resultDetails.level or "Unknown stage")
    local outcomeLabel = outcome == "Victory" and "🟩 **VICTORY**"
        or (outcome == "Defeat" and "🟥 **DEFEAT**" or "⚪ **UNKNOWN RESULT**")
    local matchResultText = outcomeLabel .. " — Total Time: " .. matchTime
        .. " — Waves Completed: " .. waveText .. " — **" .. stageText .. "**"

    local function LimitEmbedText(value, limit)
        value = tostring(value or "")
        if #value <= limit then return value end
        return value:sub(1, math.max(1, limit - 22)) .. "\n… (truncated)"
    end

    local fields = {
        { name = "💰 Player Stats", value = LimitEmbedText(playerStatsText, 1024), inline = false },
    }
    local function AppendLineChunks(fieldName, value, maxLength)
        value = tostring(value or "")
        local current = {}
        local currentLength = 0
        for line in (value .. "\n"):gmatch("(.-)\n") do
            local extra = #line + (#current > 0 and 1 or 0)
            if #current > 0 and currentLength + extra > maxLength then
                table.insert(fields, { name = fieldName, value = table.concat(current, "\n"), inline = false })
                current, currentLength = {}, 0
                fieldName = fieldName .. " (continued)"
            end
            table.insert(current, line)
            currentLength = currentLength + #line + (#current > 1 and 1 or 0)
        end
        if #current > 0 then
            table.insert(fields, { name = fieldName, value = LimitEmbedText(table.concat(current, "\n"), maxLength), inline = false })
        end
    end
    AppendLineChunks("🎁 Rewards", rewardsText, 1000)
    AppendLineChunks("⚔️ Units — Damage & Takedowns", unitLines, 1000)
    table.insert(fields, { name = "🏁 Match Result", value = LimitEmbedText(matchResultText, 1024), inline = false })

    local embeds = {{
        title = outcome == "Victory" and "Anime Adventures — 🏆 VICTORY"
            or (outcome == "Defeat" and "Anime Adventures — 🟥 DEFEAT" or "Anime Adventures — MATCH RESULT"),
        description = string.format("**User:** %s **Level:** %s (XP: %s)\n\n[Octoput Hub Logo](https://raw.githubusercontent.com/SKilk3ez/highwing/refs/heads/main/Untitled-2.png)",
            player.Name, playerLevel and FormatNumber(playerLevel) or "Unknown", FormatNumber(playerXP)),
        color = outcome == "Victory" and 5763719
            or (outcome == "Defeat" and 15548997 or 9807270),
        thumbnail = { url = "https://raw.githubusercontent.com/SKilk3ez/highwing/refs/heads/main/Untitled-2.png" },
        fields = fields,
        timestamp = DateTime.now():ToIsoDate(),
    }}
    if secretRewardText then
        table.insert(embeds, {
            title = "🚨✨ SECRET REWARDS UNLOCKED ✨🚨",
            description = LimitEmbedText("━━━━━━━━━━━━━━━━━━━━\n🌈 **ULTRA RARE DROP!** 🌈\n\n"
                .. secretRewardText .. "\n\n━━━━━━━━━━━━━━━━━━━━", 4000),
            color = 16753920,
            thumbnail = { url = "https://raw.githubusercontent.com/SKilk3ez/highwing/refs/heads/main/Untitled-2.png" },
            timestamp = DateTime.now():ToIsoDate(),
        })
    end

    local body = HttpService:JSONEncode({
        username = "Octoput Hub",
        embeds = embeds,
    })

    local lastError = "Unknown HTTP error"
    local retryDelay
    for attempt = 1, 4 do
        local ok, response = pcall(HttpPost, url, body)
        local success, message, responseRetryAfter = DescribeWebhookResult(ok, response)
        if success then
            print("[Octoput Hub Webhook] End-of-match notification sent.")
            return true
        end
        lastError = message
        retryDelay = responseRetryAfter or math.min(attempt * 2, 10)
        warn("[Octoput Hub Webhook] Attempt " .. tostring(attempt) .. "/4 failed: " .. tostring(message))
        if attempt < 4 then task.wait(retryDelay) end
    end
    warn("[Octoput Hub Webhook] Giving up after 4 attempts: " .. tostring(lastError))
    return false, lastError, retryDelay
end

function IsGoodEffectColor(color)
    return color and color.G > 0.55 and color.R < 0.45 and color.B < 0.55
end

function IsBadEffectColor(color)
    return color and color.R > 0.55 and color.G < 0.45 and color.B < 0.55
end

function LineIsBuff(id, lower, good)
    if not good then
        return false
    end
    if id == "attack" then
        return lower:find("attack", 1, true) ~= nil and lower:find("cooldown", 1, true) == nil
    elseif id == "range" then
        return lower:find("range", 1, true) ~= nil and lower:find("explosive", 1, true) == nil and lower:find("death", 1, true) == nil
    elseif id == "cooldown" then
        return lower:find("cooldown", 1, true) ~= nil and lower:find("active", 1, true) == nil
    elseif id == "active_cooldown" then
        return lower:find("active cooldown", 1, true) ~= nil
    elseif id == "phys_crit" then
        return lower:find("phys crit", 1, true) ~= nil
    elseif id == "magic_crit" then
        return lower:find("magic crit", 1, true) ~= nil
    elseif id == "phys_damage" then
        return lower:find("phys damage", 1, true) ~= nil
    elseif id == "magic_damage" then
        return lower:find("magic damage", 1, true) ~= nil
    elseif id == "true_damage" then
        return lower:find("true damage", 1, true) ~= nil
    elseif id == "boss_damage" then
        return lower:find("boss damage", 1, true) ~= nil
    elseif id == "flying_damage" then
        return lower:find("damage vs flying", 1, true) ~= nil or (lower:find("flying", 1, true) and lower:find("damage", 1, true) and lower:find("chance", 1, true) == nil and lower:find("soaring", 1, true) == nil)
    elseif id == "enemy_health" then
        return lower:find("enemy", 1, true) ~= nil and lower:find("health", 1, true) ~= nil
    elseif id == "enemy_speed" then
        return lower:find("enemy speed", 1, true) ~= nil and lower:find("burst", 1, true) == nil
    elseif id == "enemy_regen" then
        return lower:find("regen", 1, true) ~= nil
    elseif id == "enemy_shield" then
        return lower:find("shield", 1, true) ~= nil
    elseif id == "cost" then
        return lower:find("placement/upgrade cost", 1, true) ~= nil or lower:find("placement", 1, true) ~= nil and lower:find("cost", 1, true) ~= nil
    elseif id == "secret" then
        return lower:find("secret drop", 1, true) ~= nil
    elseif id == "blessing" then
        return lower:find("blessing", 1, true) ~= nil
    end
    return false
end

function LineIsDebuff(id, lower, bad)
    if id == "new_path" then
        return lower:find("new path", 1, true) ~= nil
    end
    if id == "curse" then
        return lower:find("curse", 1, true) ~= nil
    end
    if not bad then
        return false
    end
    if id == "enemy_health" then
        return lower:find("health", 1, true) ~= nil
    elseif id == "enemy_speed" then
        return lower:find("enemy speed", 1, true) ~= nil and lower:find("burst", 1, true) == nil
    elseif id == "enemy_regen" then
        return lower:find("regen", 1, true) ~= nil
    elseif id == "enemy_shield" then
        return lower:find("shield", 1, true) ~= nil
    elseif id == "explosive" then
        return lower:find("explosive", 1, true) ~= nil
    elseif id == "resist" then
        return lower:find("resist", 1, true) ~= nil
    elseif id == "attack" then
        return lower:find("attack", 1, true) ~= nil and lower:find("cooldown", 1, true) == nil
    elseif id == "range" then
        return lower:find("range", 1, true) ~= nil and lower:find("explosive", 1, true) == nil
    elseif id == "cooldown" then
        return lower:find("cooldown", 1, true) ~= nil and lower:find("active", 1, true) == nil
    elseif id == "active_cooldown" then
        return lower:find("active cooldown", 1, true) ~= nil
    elseif id == "cost" then
        return lower:find("cost", 1, true) ~= nil
    elseif id == "flying_chance" then
        return lower:find("flying chance", 1, true) ~= nil or lower:find("soaring", 1, true) ~= nil
    elseif id == "burst_speed" then
        return lower:find("burst", 1, true) ~= nil
    elseif id == "lightning" then
        return lower:find("lightning", 1, true) ~= nil
    end
    return false
end

function ScoreRoguelikeCard(card)
    local buffs = State.BuffPriority or {}
    local debuffs = State.DebuffAvoid or {}
    if #buffs == 0 and #debuffs == 0 then
        return nil
    end
    local score = 0
    for _, label in ipairs(card:GetDescendants()) do
        if label:IsA("TextLabel") then
            local text = tostring(label.Text or "")
            local lower = text:lower()
            if text ~= "" and not text:match("^%d+$") then
                local good = IsGoodEffectColor(label.TextColor3)
                local bad = IsBadEffectColor(label.TextColor3)
                for index, id in ipairs(buffs) do
                    if LineIsBuff(id, lower, good) then
                        score = score + (#buffs - index + 1) * 100
                    end
                end
                for index, id in ipairs(debuffs) do
                    if LineIsDebuff(id, lower, bad) then
                        score = score - (#debuffs - index + 1) * 1000
                    end
                end
            end
        end
    end
    return score
end

function PickRoguelikeCard(pageUI)
    local cards = {}
    for _, card in ipairs(pageUI:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and card.Name ~= "" and card.Name ~= "Configuration" then
            table.insert(cards, card)
        end
    end
    if #cards == 0 then
        return nil
    end
    if #(State.BuffPriority or {}) == 0 and #(State.DebuffAvoid or {}) == 0 then
        return cards[1]
    end
    table.sort(cards, function(a, b)
        return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
    end)
    local best = cards[1]
    local bestScore = ScoreRoguelikeCard(best) or 0
    for i = 2, #cards do
        local score = ScoreRoguelikeCard(cards[i]) or 0
        if score > bestScore then
            best = cards[i]
            bestScore = score
        end
    end
    return best
end

blackscreenConn = nil
savedQuality = nil
savedSavedQuality = nil
hiddenOriginals = setmetatable({}, { __mode = "k" })

function SetInstanceHidden(inst, hidden)
    if inst:IsA("BasePart") then
        inst.LocalTransparencyModifier = hidden and 1 or 0
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        if hidden then
            if hiddenOriginals[inst] == nil then hiddenOriginals[inst] = inst.Transparency end
            inst.Transparency = 1
        elseif hiddenOriginals[inst] ~= nil then
            inst.Transparency = hiddenOriginals[inst]
            hiddenOriginals[inst] = nil
        end
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
        if hidden then
            if hiddenOriginals[inst] == nil then hiddenOriginals[inst] = inst.Enabled end
            inst.Enabled = false
        elseif hiddenOriginals[inst] ~= nil then
            inst.Enabled = hiddenOriginals[inst]
            hiddenOriginals[inst] = nil
        end
    end
end

function ApplyBlackScreen(enabled)
    BlackOverlay.Visible = enabled
    if blackscreenConn then
        blackscreenConn:Disconnect()
        blackscreenConn = nil
    end

    pcall(function()
        if enabled then
            local gs = UserSettings():GetService("UserGameSettings")
            if savedQuality == nil then
                savedQuality = settings().Rendering.QualityLevel
                savedSavedQuality = gs.SavedQualityLevel
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        elseif savedQuality then
            local gs = UserSettings():GetService("UserGameSettings")
            settings().Rendering.QualityLevel = savedQuality
            if savedSavedQuality ~= nil then gs.SavedQualityLevel = savedSavedQuality end
            savedQuality = nil
            savedSavedQuality = nil
        end
    end)

    for _, inst in ipairs(workspace:GetDescendants()) do
        SetInstanceHidden(inst, enabled)
    end

    if enabled then
        blackscreenConn = workspace.DescendantAdded:Connect(function(inst)
            if State.BlackScreen then
                SetInstanceHidden(inst, true)
            end
        end)
    end
end

function SuppressErrorNotifications()
    -- Do not clear MessageGui or NotificationWindows.List.
    -- Anime Adventures uses these containers for legitimate item-drop messages;
    -- deleting every child here hid Sky Portal drops as soon as they appeared.
    return
end

tabs = {}
function CreateTab(name, layoutOrder)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 36)
    TabButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    TabButton.Text = "   " .. name
    TabButton.TextColor3 = Color3.fromRGB(170, 170, 190)
    TabButton.TextSize = 13
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.LayoutOrder = layoutOrder
    TabButton.ZIndex = 12
    TabButton.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton

    local PageFrame = Instance.new("ScrollingFrame")
    PageFrame.Name = name .. "Page"
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.BackgroundTransparency = 1
    PageFrame.BorderSizePixel = 0
    PageFrame.ScrollBarThickness = 3
    PageFrame.Visible = false
    PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PageFrame.ZIndex = 12
    PageFrame.Parent = ContentArea

    local PageList = Instance.new("UIListLayout")
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Padding = UDim.new(0, 8)
    PageList.Parent = PageFrame

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingBottom = UDim.new(0, 12)
    PagePadding.Parent = PageFrame

    tabs[name] = { Button = TabButton, Page = PageFrame }

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            t.Button.TextColor3 = Color3.fromRGB(170, 170, 190)
        end
        PageFrame.Visible = true
        TabButton.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return PageFrame
end

function CreateSection(parent, title, layoutOrder)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(140, 190, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.LayoutOrder = layoutOrder
    Label.ZIndex = 12
    Label.Parent = parent
    return Label
end

function CreateHint(parent, text, layoutOrder, height)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, height or 32)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(140, 140, 160)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Top
    Label.TextWrapped = true
    Label.LayoutOrder = layoutOrder
    Label.ZIndex = 12
    Label.Parent = parent
    return Label
end

function CreateToggle(parent, title, stateKey, layoutOrder, callback)
    local ToggleContainer = Instance.new("Frame")
    ToggleContainer.Size = UDim2.new(1, -10, 0, 42)
    ToggleContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    ToggleContainer.LayoutOrder = layoutOrder
    ToggleContainer.ZIndex = 12
    ToggleContainer.Parent = parent

    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 6)
    ContainerCorner.Parent = ToggleContainer

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = ToggleContainer

    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Size = UDim2.new(0, 44, 0, 22)
    SwitchBtn.Position = UDim2.new(1, -54, 0.5, -11)
    SwitchBtn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(0, 168, 255) or Color3.fromRGB(45, 45, 58)
    SwitchBtn.Text = ""
    SwitchBtn.ZIndex = 13
    SwitchBtn.Parent = ToggleContainer

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBtn

    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = State[stateKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.ZIndex = 14
    Indicator.Parent = SwitchBtn

    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(1, 0)
    IndicatorCorner.Parent = Indicator

    SwitchBtn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        local isON = State[stateKey]

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if isON then
            TweenService:Create(SwitchBtn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(0, 168, 255) }):Play()
            TweenService:Create(Indicator, tweenInfo, { Position = UDim2.new(1, -19, 0.5, -8) }):Play()
        else
            TweenService:Create(SwitchBtn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(45, 45, 58) }):Play()
            TweenService:Create(Indicator, tweenInfo, { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
        end

        SaveConfig()
        if callback then
            task.spawn(callback, isON)
        end
    end)

    return ToggleContainer
end

function CreateTextBox(parent, title, placeholder, layoutOrder, onChanged, initialText)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -10, 0, 64)
    Box.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Box.LayoutOrder = layoutOrder
    Box.ZIndex = 12
    Box.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Box

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = Box

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -24, 0, 26)
    Input.Position = UDim2.new(0, 12, 0, 30)
    Input.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    Input.Text = initialText or ""
    Input.PlaceholderText = placeholder
    Input.TextColor3 = Color3.fromRGB(230, 230, 240)
    Input.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    Input.TextSize = 12
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ZIndex = 13
    Input.Parent = Box

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = Input

    local InputPad = Instance.new("UIPadding")
    InputPad.PaddingLeft = UDim.new(0, 8)
    InputPad.Parent = Input

    Input.FocusLost:Connect(function()
        if onChanged then
            onChanged(Input.Text)
        end
    end)

    return Input
end

function CreateButton(parent, title, layoutOrder, onClick)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 36)
    Button.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
    Button.Text = title
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.LayoutOrder = layoutOrder
    Button.ZIndex = 12
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        if onClick then
            task.spawn(onClick)
        end
    end)
    return Button
end

function CreateSingleSlider(parent, title, hint, layoutOrder, minValue, maxValue, getValue, setValue)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -10, 0, 78)
    Card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Card.LayoutOrder = layoutOrder
    Card.ZIndex = 12
    Card.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Card

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = Card

    local Bar = Instance.new("Frame")
    Bar.Name = "Bar"
    Bar.Size = UDim2.new(1, -90, 0, 8)
    Bar.Position = UDim2.new(0, 12, 0, 36)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 13
    Bar.Parent = Card

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 14
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Handle = Instance.new("TextButton")
    Handle.Size = UDim2.new(0, 16, 0, 16)
    Handle.AnchorPoint = Vector2.new(0.5, 0.5)
    Handle.Position = UDim2.new(0, 0, 0.5, 0)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Text = ""
    Handle.AutoButtonColor = false
    Handle.ZIndex = 15
    Handle.Parent = Bar
    local HandleCorner = Instance.new("UICorner")
    HandleCorner.CornerRadius = UDim.new(1, 0)
    HandleCorner.Parent = Handle

    local ValueBox = Instance.new("TextBox")
    ValueBox.Size = UDim2.new(0, 52, 0, 24)
    ValueBox.Position = UDim2.new(1, -64, 0, 28)
    ValueBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    ValueBox.Text = tostring(getValue())
    ValueBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    ValueBox.TextSize = 12
    ValueBox.Font = Enum.Font.Gotham
    ValueBox.ClearTextOnFocus = false
    ValueBox.ZIndex = 13
    ValueBox.Parent = Card
    local ValueCorner = Instance.new("UICorner")
    ValueCorner.CornerRadius = UDim.new(0, 4)
    ValueCorner.Parent = ValueBox

    local Hint = Instance.new("TextLabel")
    Hint.Size = UDim2.new(1, -24, 0, 18)
    Hint.Position = UDim2.new(0, 12, 1, -22)
    Hint.BackgroundTransparency = 1
    Hint.Text = hint
    Hint.TextColor3 = Color3.fromRGB(140, 140, 160)
    Hint.TextSize = 11
    Hint.Font = Enum.Font.Gotham
    Hint.TextXAlignment = Enum.TextXAlignment.Left
    Hint.ZIndex = 13
    Hint.Parent = Card

    local dragging = false
    local span = math.max(maxValue - minValue, 1)

    local function Refresh()
        local value = math.clamp(getValue(), minValue, maxValue)
        local alpha = (value - minValue) / span
        Handle.Position = UDim2.new(alpha, 0, 0.5, 0)
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        if not ValueBox:IsFocused() then
            ValueBox.Text = tostring(math.floor(value + 0.5))
        end
    end

    local function ValueFromX(x)
        local absPos = Bar.AbsolutePosition.X
        local absSize = math.max(Bar.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - absPos) / absSize, 0, 1)
        return math.clamp(math.floor(minValue + alpha * span + 0.5), minValue, maxValue)
    end

    local function Commit(value, saveNow)
        setValue(math.clamp(value, minValue, maxValue))
        Refresh()
        if saveNow then
            SaveConfig()
        end
    end

    Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Commit(ValueFromX(input.Position.X), false)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Commit(ValueFromX(input.Position.X), false)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            SaveConfig()
        end
    end)
    ValueBox.FocusLost:Connect(function()
        local n = tonumber(ValueBox.Text)
        if not n then
            Refresh()
            return
        end
        Commit(math.floor(n + 0.5), true)
    end)

    Refresh()
    return Card
end

function CreatePriorityEditor(parent, title, hint, defs, stateKey, layoutOrder)
    CreateSection(parent, title, layoutOrder)
    CreateHint(parent, hint, layoutOrder + 1, 28)

    local Scroller = Instance.new("ScrollingFrame")
    Scroller.Size = UDim2.new(1, -10, 0, 236)
    Scroller.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    Scroller.BorderSizePixel = 0
    Scroller.ScrollBarThickness = 4
    Scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroller.LayoutOrder = layoutOrder + 2
    Scroller.ZIndex = 12
    Scroller.Parent = parent
    local ScrollerCorner = Instance.new("UICorner")
    ScrollerCorner.CornerRadius = UDim.new(0, 6)
    ScrollerCorner.Parent = Scroller
    local List = Instance.new("UIListLayout")
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 4)
    List.Parent = Scroller
    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 6)
    Pad.PaddingBottom = UDim.new(0, 6)
    Pad.PaddingLeft = UDim.new(0, 6)
    Pad.PaddingRight = UDim.new(0, 6)
    Pad.Parent = Scroller

    local function RankOf(id)
        for index, value in ipairs(State[stateKey]) do
            if value == id then
                return index
            end
        end
        return nil
    end

    local function Rebuild()
        for _, child in ipairs(Scroller:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        for index, def in ipairs(defs) do
            local rank = RankOf(def.id)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, -8, 0, 32)
            Row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Row.LayoutOrder = rank or (100 + index)
            Row.ZIndex = 13
            Row.Parent = Scroller
            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 4)
            RowCorner.Parent = Row

            local Box = Instance.new("TextButton")
            Box.Size = UDim2.new(0, 18, 0, 18)
            Box.Position = UDim2.new(0, 8, 0.5, -9)
            Box.BackgroundColor3 = rank and Color3.fromRGB(0, 168, 255) or Color3.fromRGB(45, 45, 58)
            Box.Text = rank and "✓" or ""
            Box.TextColor3 = Color3.fromRGB(255, 255, 255)
            Box.TextSize = 12
            Box.Font = Enum.Font.GothamBold
            Box.ZIndex = 14
            Box.Parent = Row
            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 3)
            BoxCorner.Parent = Box

            local Name = Instance.new("TextLabel")
            Name.Size = UDim2.new(1, -150, 1, 0)
            Name.Position = UDim2.new(0, 34, 0, 0)
            Name.BackgroundTransparency = 1
            Name.Text = (rank and (tostring(rank) .. ". ") or "") .. def.label
            Name.TextColor3 = Color3.fromRGB(220, 220, 235)
            Name.TextSize = 12
            Name.Font = Enum.Font.Gotham
            Name.TextXAlignment = Enum.TextXAlignment.Left
            Name.ZIndex = 14
            Name.Parent = Row

            local function MakeMini(text, x, callback)
                local Mini = Instance.new("TextButton")
                Mini.Size = UDim2.new(0, 36, 0, 20)
                Mini.Position = UDim2.new(1, x, 0.5, -10)
                Mini.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
                Mini.Text = text
                Mini.TextColor3 = Color3.fromRGB(220, 220, 235)
                Mini.TextSize = 11
                Mini.Font = Enum.Font.GothamBold
                Mini.Visible = rank ~= nil
                Mini.ZIndex = 14
                Mini.Parent = Row
                local MiniCorner = Instance.new("UICorner")
                MiniCorner.CornerRadius = UDim.new(0, 4)
                MiniCorner.Parent = Mini
                Mini.MouseButton1Click:Connect(callback)
            end

            MakeMini("Up", -84, function()
                local current = RankOf(def.id)
                if current and current > 1 then
                    local list = State[stateKey]
                    list[current], list[current - 1] = list[current - 1], list[current]
                    SaveConfig()
                    Rebuild()
                end
            end)
            MakeMini("Down", -44, function()
                local current = RankOf(def.id)
                local list = State[stateKey]
                if current and current < #list then
                    list[current], list[current + 1] = list[current + 1], list[current]
                    SaveConfig()
                    Rebuild()
                end
            end)

            Box.MouseButton1Click:Connect(function()
                local list = State[stateKey]
                local current = RankOf(def.id)
                if current then
                    table.remove(list, current)
                else
                    table.insert(list, def.id)
                end
                SaveConfig()
                Rebuild()
            end)
        end
    end

    Rebuild()
    return Scroller
end

MainPage = CreateTab("Main", 1)
AutoPlayPage = CreateTab("Auto Play", 2)
PortalPage = CreateTab("Portal", 3)
EventPage = CreateTab("Event", 4)
WebhookPage = CreateTab("Webhook", 5)
MiscPage = CreateTab("Misc", 6)
SummonPage = CreateTab("Summon", 7)

tabs["Auto Play"].Page.Visible = true
tabs["Auto Play"].Button.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
tabs["Auto Play"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

CreateHint(MainPage, "When a match ends: Next runs if it is enabled and a next stage is available. Otherwise Replay runs if it is enabled. Otherwise Leave runs if it is enabled.", 0, 44)
CreateToggle(MainPage, "Auto Start", "AutoStart", 1)
CreateToggle(MainPage, "Auto Replay", "MainAutoReplay", 2)
CreateToggle(MainPage, "Auto Next", "AutoNext", 3)
CreateToggle(MainPage, "Auto Leave", "AutoLeave", 4)

-- Manual Return to Lobby button, using the game's own flow (party confirmation
-- and private-server destination prompt are handled by TeleportServiceClient).
returningToLobby = false
CreateButton(MainPage, "Return to Lobby", 5, function()
    if returningToLobby then
        return
    end
    returningToLobby = true

    local ok, err = pcall(function()
        local srcFolder = ReplicatedStorage:FindFirstChild("src")
        local loaderModule = srcFolder and srcFolder:FindFirstChild("Loader")
        if not loaderModule then
            error("Anime Adventures Loader module is unavailable")
        end

        local Loader = require(loaderModule)
        local TeleportServiceClient = Loader.load_client_service(game, "TeleportServiceClient")
        if not TeleportServiceClient or type(TeleportServiceClient.back_to_lobby) ~= "function" then
            error("TeleportServiceClient.back_to_lobby is unavailable")
        end

        TeleportServiceClient.back_to_lobby()
    end)

    if not ok then
        returningToLobby = false
        warn("[OctoputHub] Return to Lobby failed: " .. tostring(err))
    else
        task.delay(5, function()
            returningToLobby = false
        end)
    end
end)

AutoPlayStatusCard = Instance.new("Frame")
AutoPlayStatusCard.Size = UDim2.new(1, -10, 0, 38)
AutoPlayStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
AutoPlayStatusCard.LayoutOrder = 0
AutoPlayStatusCard.ZIndex = 12
AutoPlayStatusCard.Parent = AutoPlayPage

AutoPlayStatusCorner = Instance.new("UICorner")
AutoPlayStatusCorner.CornerRadius = UDim.new(0, 6)
AutoPlayStatusCorner.Parent = AutoPlayStatusCard

AutoPlayStatusLabel = Instance.new("TextLabel")
AutoPlayStatusLabel.Size = UDim2.new(1, -20, 1, 0)
AutoPlayStatusLabel.Position = UDim2.new(0, 10, 0, 0)
AutoPlayStatusLabel.BackgroundTransparency = 1
AutoPlayStatusLabel.Text = "Auto Play Status: Idle"
AutoPlayStatusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
AutoPlayStatusLabel.TextSize = 12
AutoPlayStatusLabel.Font = Enum.Font.GothamMedium
AutoPlayStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoPlayStatusLabel.ZIndex = 13
AutoPlayStatusLabel.Parent = AutoPlayStatusCard

function UpdateAutoPlayStatus(text, color)
    if AutoPlayStatusLabel then
        AutoPlayStatusLabel.Text = "Auto Play: " .. text
        if color then
            AutoPlayStatusLabel.TextColor3 = color
        end
    end
end

CreateToggle(AutoPlayPage, "Auto Place Units", "AutoPlace", 1)
CreateSingleSlider(AutoPlayPage, "Cluster Position (Path)", "0% path start    100% path end", 2, 0, 100, function()
    return State.PlacePercent
end, function(value)
    State.PlacePercent = value
end)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 3)
CreateToggle(AutoPlayPage, "Auto Upgrade Farm First", "AutoUpgradeFarmFirst", 4)
CreateSection(AutoPlayPage, "Buff Rotation", 5)
CreateHint(AutoPlayPage, "Commander / Windsong / Elfy (Sylph) buff loop: each unit's cooldown C = base active CD (60s) x Curse/level multiplier (min 0.6), SPD = 1/C. One unit is cast only when the current buff (D = 30s) is about to expire, so buffs chain without overlap. Seamless when sum(1/C) >= 1/D (units needed = ceil(C/D)). Elfy's Verdant Enchantment is read from its live _stats. All buff units are auto-placed in one nearby cluster.", 6, 42)
BuffRotationStatus = CreateHint(AutoPlayPage, "Auto Buff: Disabled", 7, 36)
CreateToggle(AutoPlayPage, "Auto Buff Rotation", "AutoBuffRotation", 8, function(enabled)
    if not enabled then
        BUFF_ROTATION_RUNTIME.groups = {}
        SetBuffRotationStatus("Auto Buff: Disabled", Color3.fromRGB(160, 160, 180))
    else
        SetBuffRotationStatus("Auto Buff: Detecting placed buff units...", Color3.fromRGB(100, 190, 255))
    end
end)
CreateSection(AutoPlayPage, "Hybrid Units", 22)
CreateHint(AutoPlayPage, "Hybrid units can stand on Ground or Hill. Both options keep the current placement behavior.", 23, 28)
CreateToggle(AutoPlayPage, "Place on Ground", "PlaceHybridGround", 24)
CreateToggle(AutoPlayPage, "Place on Hill", "PlaceHybridHill", 25)
HybridInfo = CreateHint(AutoPlayPage, "No hybrid units in the equipped squad.", 26, 32)

CreateSection(AutoPlayPage, "Unit Configuration", 27)
CreateHint(AutoPlayPage, "Leave a field empty to keep the current Auto Play behavior for that unit.", 28, 28)

-- Manual refresh for transient/missing equipped-unit metadata.
UnitRefreshBar = Instance.new("Frame")
UnitRefreshBar.Name = "UnitRefreshBar"
UnitRefreshBar.Size = UDim2.new(1, -10, 0, 30)
UnitRefreshBar.BackgroundTransparency = 1
UnitRefreshBar.LayoutOrder = 29
UnitRefreshBar.ZIndex = 13
UnitRefreshBar.Parent = AutoPlayPage

UnitRefreshButton = Instance.new("TextButton")
UnitRefreshButton.Name = "RefreshUnitsButton"
UnitRefreshButton.Size = UDim2.new(0, 112, 1, 0)
UnitRefreshButton.Position = UDim2.new(0, 0, 0, 0)
UnitRefreshButton.BackgroundColor3 = Color3.fromRGB(42, 75, 115)
UnitRefreshButton.BorderSizePixel = 0
UnitRefreshButton.Text = "↻ Refresh Units"
UnitRefreshButton.TextColor3 = Color3.fromRGB(240, 245, 255)
UnitRefreshButton.TextSize = 12
UnitRefreshButton.Font = Enum.Font.GothamBold
UnitRefreshButton.ZIndex = 14
UnitRefreshButton.Parent = UnitRefreshBar
local UnitRefreshCorner = Instance.new("UICorner")
UnitRefreshCorner.CornerRadius = UDim.new(0, 5)
UnitRefreshCorner.Parent = UnitRefreshButton

UnitRefreshStatus = Instance.new("TextLabel")
UnitRefreshStatus.Name = "RefreshStatus"
UnitRefreshStatus.Size = UDim2.new(1, -122, 1, 0)
UnitRefreshStatus.Position = UDim2.new(0, 122, 0, 0)
UnitRefreshStatus.BackgroundTransparency = 1
UnitRefreshStatus.Text = "Auto refresh enabled"
UnitRefreshStatus.TextColor3 = Color3.fromRGB(145, 155, 175)
UnitRefreshStatus.TextSize = 11
UnitRefreshStatus.Font = Enum.Font.Gotham
UnitRefreshStatus.TextXAlignment = Enum.TextXAlignment.Left
UnitRefreshStatus.ZIndex = 14
UnitRefreshStatus.Parent = UnitRefreshBar

UnitConfigHolder = Instance.new("Frame")
UnitConfigHolder.Name = "UnitConfigHolder"
UnitConfigHolder.Size = UDim2.new(1, -10, 0, 0)
UnitConfigHolder.AutomaticSize = Enum.AutomaticSize.Y
UnitConfigHolder.BackgroundTransparency = 1
UnitConfigHolder.LayoutOrder = 30
UnitConfigHolder.ZIndex = 12
UnitConfigHolder.Parent = AutoPlayPage
UnitConfigList = Instance.new("UIListLayout")
UnitConfigList.SortOrder = Enum.SortOrder.LayoutOrder
UnitConfigList.Padding = UDim.new(0, 6)
UnitConfigList.Parent = UnitConfigHolder

unitExpanded = {}
lastUnitKey = nil

function SetUnitField(unitId, displayName, field, value)
    local cfg = State.UnitConfigs[unitId]
    if type(cfg) ~= "table" then
        cfg = {}
        State.UnitConfigs[unitId] = cfg
    end
    cfg[field] = value
    if displayName and displayName ~= "" then
        cfg.displayName = displayName
        State.UnitNames[unitId] = displayName
    end
    if cfg.maxPlace == nil and cfg.upgradeTarget == nil and cfg.placeStartWave == nil and cfg.upgradeStartWave == nil then
        State.UnitConfigs[unitId] = nil
    end
    SaveConfig()
end

function AddConfigBox(parent, label, placeholder, order, getter, setter)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -16, 0, 32)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = order
    Row.ZIndex = 14
    Row.Parent = parent

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.new(0.62, 0, 1, 0)
    Name.BackgroundTransparency = 1
    Name.Text = label
    Name.TextColor3 = Color3.fromRGB(200, 200, 215)
    Name.TextSize = 12
    Name.Font = Enum.Font.Gotham
    Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.ZIndex = 15
    Name.Parent = Row

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0.38, -8, 0, 24)
    Input.Position = UDim2.new(0.62, 0, 0.5, -12)
    Input.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    Input.Text = getter()
    Input.PlaceholderText = placeholder
    Input.TextColor3 = Color3.fromRGB(230, 230, 240)
    Input.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    Input.TextSize = 12
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.ZIndex = 15
    Input.Parent = Row
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = Input

    Input.FocusLost:Connect(function()
        local text = Input.Text:gsub("%s+", "")
        if text == "" then
            setter(nil)
            Input.Text = ""
            return
        end
        local n = tonumber(text)
        if not n then
            Input.Text = getter()
            return
        end
        setter(math.floor(n + 0.5))
        Input.Text = getter()
    end)
end

function RefreshUnitConfigUI()
    local equipped = EnrichEquipped(GetEquippedUnitList())
    local hybridNames = {}
    local byId = {}
    local ordered = {}
    local missingMetadata = 0
    for _, info in ipairs(equipped) do
        if info.unitId and not byId[info.unitId] then
            byId[info.unitId] = info
            table.insert(ordered, info)
            if info.hybrid then
                table.insert(hybridNames, info.name)
            end
            if info.dataFound ~= true then
                missingMetadata += 1
            end
        end
    end
    -- Do not append saved configs here. Only equipped slots 1-6 are shown.
    -- Keep the game's slot order rather than sorting by display name.

    if #hybridNames > 0 then
        HybridInfo.Text = "Equipped hybrid: " .. table.concat(hybridNames, ", ")
    else
        HybridInfo.Text = "No hybrid units in the equipped squad."
    end

    local keyParts = {}
    for _, info in ipairs(ordered) do
        table.insert(keyParts, table.concat({
            tostring(info.unitId), tostring(info.uuid), tostring(info.name),
            tostring(info.spawnCap), tostring(info.maxUpgrade), tostring(info.dataFound), tostring(info.hybrid), tostring(info.hill)
        }, ":"))
    end
    local key = table.concat(keyParts, "|")
    if key == lastUnitKey then
        return #ordered, missingMetadata
    end
    lastUnitKey = key

    for _, child in ipairs(UnitConfigHolder:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    if #ordered == 0 then
        local Empty = Instance.new("TextLabel")
        Empty.Size = UDim2.new(1, 0, 0, 28)
        Empty.BackgroundTransparency = 1
        Empty.Text = "Equip a unit to configure it."
        Empty.TextColor3 = Color3.fromRGB(140, 140, 160)
        Empty.TextSize = 12
        Empty.Font = Enum.Font.Gotham
        Empty.TextXAlignment = Enum.TextXAlignment.Left
        Empty.ZIndex = 13
        Empty.Parent = UnitConfigHolder
        return 0, 0
    end

    for index, info in ipairs(ordered) do
        local cfg = GetUnitConfig(info.unitId)
        if unitExpanded[info.unitId] == nil then
            unitExpanded[info.unitId] = cfg ~= nil and (cfg.maxPlace ~= nil or cfg.upgradeTarget ~= nil or cfg.placeStartWave ~= nil or cfg.upgradeStartWave ~= nil)
        end

        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 0)
        Card.AutomaticSize = Enum.AutomaticSize.Y
        Card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        Card.LayoutOrder = index
        Card.ZIndex = 13
        Card.Parent = UnitConfigHolder
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 6)
        CardCorner.Parent = Card
        local CardList = Instance.new("UIListLayout")
        CardList.SortOrder = Enum.SortOrder.LayoutOrder
        CardList.Padding = UDim.new(0, 4)
        CardList.Parent = Card
        local CardPad = Instance.new("UIPadding")
        CardPad.PaddingTop = UDim.new(0, 6)
        CardPad.PaddingBottom = UDim.new(0, 6)
        CardPad.PaddingLeft = UDim.new(0, 8)
        CardPad.PaddingRight = UDim.new(0, 8)
        CardPad.Parent = Card

        local kindText = info.hybrid and "Hybrid" or (info.hill and "Hill" or "Ground")
        local capText = info.dataFound and ("cap " .. tostring(info.spawnCap or 5)) or "data missing"
        local upText = info.dataFound and ("upgrades " .. tostring(info.maxUpgrade or 0)) or "check Unit ID"

        local Header = Instance.new("TextButton")
        Header.Size = UDim2.new(1, 0, 0, 28)
        Header.BackgroundTransparency = 1
        Header.Text = (unitExpanded[info.unitId] and "▼ " or "► ") .. info.name .. "   " .. kindText .. "  |  " .. capText .. "  |  " .. upText
        Header.TextColor3 = Color3.fromRGB(230, 230, 240)
        Header.TextSize = 12
        Header.Font = Enum.Font.GothamMedium
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.LayoutOrder = 1
        Header.ZIndex = 14
        Header.Parent = Card

        local Body = Instance.new("Frame")
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.AutomaticSize = Enum.AutomaticSize.Y
        Body.BackgroundTransparency = 1
        Body.Visible = unitExpanded[info.unitId] == true
        Body.LayoutOrder = 2
        Body.ZIndex = 14
        Body.Parent = Card
        local BodyList = Instance.new("UIListLayout")
        BodyList.SortOrder = Enum.SortOrder.LayoutOrder
        BodyList.Padding = UDim.new(0, 2)
        BodyList.Parent = Body

        local function Current(field)
            local current = GetUnitConfig(info.unitId)
            if current and current[field] ~= nil then
                return tostring(current[field])
            end
            return ""
        end

        AddConfigBox(Body, "Max Place", "no limit", 1, function()
            return Current("maxPlace")
        end, function(value)
            if value ~= nil then
                value = math.clamp(value, 1, info.spawnCap or 50)
            end
            SetUnitField(info.unitId, info.name, "maxPlace", value)
        end)
        AddConfigBox(Body, "Upgrade Target", "max", 2, function()
            return Current("upgradeTarget")
        end, function(value)
            if value ~= nil then
                value = math.clamp(value, 0, info.maxUpgrade or 30)
            end
            SetUnitField(info.unitId, info.name, "upgradeTarget", value)
        end)
        AddConfigBox(Body, "Place Start Wave", "any wave", 3, function()
            return Current("placeStartWave")
        end, function(value)
            if value ~= nil then
                value = math.clamp(value, 1, 999)
            end
            SetUnitField(info.unitId, info.name, "placeStartWave", value)
        end)
        AddConfigBox(Body, "Upgrade Start Wave", "any wave", 4, function()
            return Current("upgradeStartWave")
        end, function(value)
            if value ~= nil then
                value = math.clamp(value, 1, 999)
            end
            SetUnitField(info.unitId, info.name, "upgradeStartWave", value)
        end)

        Header.MouseButton1Click:Connect(function()
            unitExpanded[info.unitId] = not unitExpanded[info.unitId]
            Body.Visible = unitExpanded[info.unitId] == true
            Header.Text = (unitExpanded[info.unitId] and "▼ " or "► ") .. info.name .. "   " .. kindText .. "  |  " .. capText .. "  |  " .. upText
        end)
    end
    return #ordered, missingMetadata
end

unitRefreshBusy = false
UnitRefreshButton.Activated:Connect(function()
    if unitRefreshBusy then return end
    unitRefreshBusy = true
    UnitRefreshButton.Active = false
    UnitRefreshButton.AutoButtonColor = false
    UnitRefreshButton.Text = "Refreshing..."
    UnitRefreshStatus.TextColor3 = Color3.fromRGB(255, 205, 115)
    UnitRefreshStatus.Text = "Reloading equipped slots and unit data..."

    task.spawn(function()
        local count, missing = 0, 0
        local refreshError = nil
        for attempt = 1, 4 do
            if attempt == 1 then UnitsDataCache = nil end
            lastUnitKey = nil
            local ok, a, b = pcall(RefreshUnitConfigUI)
            if ok then
                count = tonumber(a) or 0
                missing = tonumber(b) or 0
                if count > 0 and missing == 0 then break end
            else
                refreshError = tostring(a)
            end
            if attempt < 4 then task.wait(0.45) end
        end

        if refreshError and count == 0 then
            UnitRefreshStatus.Text = "Refresh failed; check executor console"
            UnitRefreshStatus.TextColor3 = Color3.fromRGB(255, 115, 115)
            warn("[OctoputHub] Manual unit refresh failed: " .. refreshError)
        elseif count == 0 then
            UnitRefreshStatus.Text = "No equipped units detected; try again"
            UnitRefreshStatus.TextColor3 = Color3.fromRGB(255, 170, 110)
        elseif missing > 0 then
            UnitRefreshStatus.Text = string.format("Loaded %d units; %d still missing data (?)", count, missing)
            UnitRefreshStatus.TextColor3 = Color3.fromRGB(255, 190, 110)
        else
            UnitRefreshStatus.Text = string.format("Loaded %d equipped units successfully", count)
            UnitRefreshStatus.TextColor3 = Color3.fromRGB(115, 225, 165)
        end

        UnitRefreshButton.Text = "↻ Refresh Units"
        UnitRefreshButton.Active = true
        UnitRefreshButton.AutoButtonColor = true
        unitRefreshBusy = false
    end)
end)

-- Portal page: inventory-based portal types + game-defined tier selection.
PortalSelectionContainer = Instance.new("Frame")
PortalSelectionContainer.Name = "PortalSelectionContainer"
PortalSelectionContainer.Size = UDim2.new(1, -10, 0, 410)
PortalSelectionContainer.BackgroundTransparency = 1
PortalSelectionContainer.LayoutOrder = 1
PortalSelectionContainer.ZIndex = 12
PortalSelectionContainer.Parent = PortalPage

PortalColumnsLayout = Instance.new("UIListLayout")
PortalColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
PortalColumnsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
PortalColumnsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
PortalColumnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
PortalColumnsLayout.Padding = UDim.new(0, 8)
PortalColumnsLayout.Parent = PortalSelectionContainer

function CreatePortalSelectionColumn(name, title, hint, order)
    local column = Instance.new("Frame")
    column.Name = name
    column.Size = UDim2.new(0.5, -4, 1, 0)
    column.BackgroundTransparency = 1
    column.LayoutOrder = order
    column.ZIndex = 12
    column.Parent = PortalSelectionContainer

    local columnLayout = Instance.new("UIListLayout")
    columnLayout.FillDirection = Enum.FillDirection.Vertical
    columnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    columnLayout.Padding = UDim.new(0, 3)
    columnLayout.Parent = column

    local heading = CreateSection(column, title, 1)
    heading.Size = UDim2.new(1, -4, 0, 20)
    local description = CreateHint(column, hint, 2, 28)
    description.Size = UDim2.new(1, -4, 0, 28)

    local list = Instance.new("ScrollingFrame")
    list.Name = name .. "List"
    -- Preserve a useful physical viewing area when the whole hub is scaled.
    -- Tier list is tall enough to show every game-defined tier without clipping.
    local visibleHeight = name == "PortalTierColumn" and 350 or 160
    list.Size = UDim2.new(1, -4, 0, visibleHeight / math.max(HubScale.Scale, 0.01))
    list.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ScrollingEnabled = true
    list.Active = true
    list.ClipsDescendants = true
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.LayoutOrder = 3
    list.ZIndex = 12
    list.Parent = column

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = list

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
    end)

    return list
end

PortalInventoryList = CreatePortalSelectionColumn(
    "PortalInventoryColumn",
    "Select Portal",
    "เลือกประเภท Portal จาก Inventory",
    1
)
PortalTierList = CreatePortalSelectionColumn(
    "PortalTierColumn",
    "Select Tier",
    "เลือก Tier จาก T สูงสุดลงมาต่ำสุด",
    2
)

-- Recalculate the portal selector's physical height whenever UI Scale or the
-- game viewport changes. The Portal page itself remains scrollable on short screens.
function ApplyResponsiveGuiSizing()
    if not PortalSelectionContainer or not PortalInventoryList or not PortalTierList then
        return
    end
    local scale = math.max(HubScale.Scale, 0.01)
    -- Match the Event Buff/Debuff priority editor's scroll behavior.
    local inventoryHeight = 160 / scale
    local tierHeight = 350 / scale
    PortalInventoryList.Size = UDim2.new(1, -4, 0, inventoryHeight)
    PortalTierList.Size = UDim2.new(1, -4, 0, tierHeight)
    PortalSelectionContainer.Size = UDim2.new(1, -10, 0, math.max(inventoryHeight, tierHeight) + 54)
end
ApplyResponsiveGuiSizing()

-- Optional element filter: matches the damage types shown by the game's level modifier UI.
PortalModifierColumn = Instance.new("Frame")
PortalModifierColumn.Name = "PortalLevelModifiersColumn"
PortalModifierColumn.Size = UDim2.new(1, -10, 0, 150)
PortalModifierColumn.BackgroundTransparency = 1
PortalModifierColumn.LayoutOrder = 2
PortalModifierColumn.ZIndex = 12
PortalModifierColumn.Parent = PortalPage
local portalModifierLayout = Instance.new("UIListLayout")
portalModifierLayout.FillDirection = Enum.FillDirection.Vertical
portalModifierLayout.SortOrder = Enum.SortOrder.LayoutOrder
portalModifierLayout.Padding = UDim.new(0, 3)
portalModifierLayout.Parent = PortalModifierColumn
local portalModifierHeading = CreateSection(PortalModifierColumn, "Level Modifiers (Element)", 1)
portalModifierHeading.Size = UDim2.new(1, -4, 0, 20)
local portalModifierHint = CreateHint(PortalModifierColumn, "เลือกธาตุเพื่อกรอง Portal ที่มีธาตุนั้นใน Strong / Weak modifiers (เลือกหลายธาตุได้)", 2, 28)
portalModifierHint.Size = UDim2.new(1, -4, 0, 28)
PortalModifierList = Instance.new("ScrollingFrame")
PortalModifierList.Name = "PortalModifierList"
PortalModifierList.Size = UDim2.new(1, -4, 0, 95 / math.max(HubScale.Scale, 0.01))
PortalModifierList.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
PortalModifierList.BorderSizePixel = 0
PortalModifierList.ScrollBarThickness = 4
PortalModifierList.ScrollingDirection = Enum.ScrollingDirection.Y
PortalModifierList.ScrollingEnabled = true
PortalModifierList.Active = true
PortalModifierList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PortalModifierList.CanvasSize = UDim2.new(0, 0, 0, 0)
PortalModifierList.ZIndex = 12
PortalModifierList.LayoutOrder = 3
PortalModifierList.Parent = PortalModifierColumn
local portalModifierGrid = Instance.new("UIGridLayout")
portalModifierGrid.CellSize = UDim2.new(0.2, -4, 0, 26)
portalModifierGrid.CellPadding = UDim2.new(0, 4, 0, 3)
portalModifierGrid.SortOrder = Enum.SortOrder.LayoutOrder
portalModifierGrid.Parent = PortalModifierList
portalModifierGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PortalModifierList.CanvasSize = UDim2.new(0, 0, 0, portalModifierGrid.AbsoluteContentSize.Y + 6)
end)

-- IDs match DamageTypes.TYPES in game.lua. Display names follow the game's
-- actual labels (Aqua, Storm and Rose rather than Water, Lightning and Ice).
PORTAL_ELEMENT_FILTERS = {
    { id = "fire_damage", label = "Fire" },
    { id = "water_damage", label = "Aqua" },
    { id = "lightning_damage", label = "Storm" },
    { id = "air_damage", label = "Air" },
    { id = "ice_damage", label = "Rose" },
    { id = "light_damage", label = "Light" },
    { id = "dark_damage", label = "Dark" },
}
function RefreshPortalModifierUI()
    for _, child in ipairs(PortalModifierList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for index, info in ipairs(PORTAL_ELEMENT_FILTERS) do
        local selected = State.SelectedPortalModifiers[info.id] == true
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 0, 0, 26)
        button.BackgroundColor3 = selected and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(38, 38, 50)
        button.Text = (selected and "✓ " or "□ ") .. info.label
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 10
        button.Font = Enum.Font.Gotham
        button.LayoutOrder = index
        button.ZIndex = 13
        button.Parent = PortalModifierList
        button.MouseButton1Click:Connect(function()
            State.SelectedPortalModifiers[info.id] = not State.SelectedPortalModifiers[info.id] and true or nil
            SaveConfig()
            RefreshPortalModifierUI()
            RefreshPortalUI()
        end)
    end
end
RefreshPortalModifierUI()

PortalStatus = CreateHint(PortalPage, "Portal inventory: waiting for refresh.", 3, 30)
PortalRefreshButton = CreateButton(PortalPage, "Refresh Portal Inventory", 4, function() end)
PortalRefreshButton.BackgroundColor3 = Color3.fromRGB(0, 168, 255)

-- The game Session owns both services; this mirrors the structure in game.lua:
-- session.collection.collection_profile_data and session.inventory.inventory_profile_data.
function FindLocalGameSession()
    local ok, guiService = pcall(function()
        local src = ReplicatedStorage:FindFirstChild("src")
        local client = src and src:FindFirstChild("client")
        local services = client and client:FindFirstChild("Services")
        local module = services and services:FindFirstChild("GUIService")
        if module and module:IsA("ModuleScript") then return require(module) end
        return nil
    end)
    if ok and type(guiService) == "table" then
        local session = guiService.session
        if type(session) == "table" and session.player == player then
            return session
        end
    end

    if type(getgc) ~= "function" then return nil end
    local gcOk, objects = pcall(getgc, true)
    if not gcOk or type(objects) ~= "table" then return nil end
    for _, object in ipairs(objects) do
        if type(object) == "table" then
            local candidates = { object, object.session }
            for _, candidate in ipairs(candidates) do
                if type(candidate) == "table" and candidate.player == player
                    and type(candidate.collection) == "table"
                    and type(candidate.inventory) == "table" then
                    return candidate
                end
            end
        end
    end
    return nil
end

function FindLocalInventoryProfile()
    local session = FindLocalGameSession()
    if session and type(session.inventory) == "table" then
        local profile = session.inventory.inventory_profile_data
        if type(profile) == "table" and type(profile.unique_items) == "table" then
            return profile
        end
    end

    if type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end
    for _, object in ipairs(objects) do
        if type(object) == "table" then
            local candidates = { object, object.session }
            for _, candidate in ipairs(candidates) do
                if type(candidate) == "table" and candidate.player == player then
                    local inventory = candidate.inventory
                    local profile = type(inventory) == "table" and inventory.inventory_profile_data
                    if type(profile) == "table" and type(profile.unique_items) == "table" then
                        return profile
                    end
                end
            end
        end
    end
    return nil
end

-- Real-time detection for Summer Hunt Sky Portal drops.
-- The webhook baseline is captured at match start; this worker compares the
-- current LocalPlayer inventory against it and reports either Sky Portal item ID.
local skyPortalMonitorKnown = nil
local skyPortalMonitorWasInMatch = false
skyPortalMatchDrops = {}

function NotifySkyPortalDrop(itemId, gained, total)
    local portal = WEBHOOK_PORTAL_ITEMS[itemId]
    if not portal or gained <= 0 then return end
    local title = "☁️ PORTAL OBTAINED!"
    local message = string.format("+%s %s [%s]", FormatNumber(gained), portal.name, FormatNumber(total))

    print("[Octoput Hub] " .. title .. " " .. message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 10,
        })
    end)
end

task.spawn(function()
    while true do
        task.wait(1)
        local ok, err = pcall(function()
            local dataFolder = workspace:FindFirstChild("_DATA")
            local gameStarted = dataFolder and dataFolder:FindFirstChild("GameStarted")
            local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
            local inMatch = workspace:FindFirstChild("_UNITS") ~= nil
                and not IsInLobby()
                and not (gameFinished and gameFinished.Value == true)
                and (not gameStarted or gameStarted.Value == true)

            if not inMatch then
                skyPortalMonitorKnown = nil
                skyPortalMonitorWasInMatch = false
                return
            end

            local current, available = ReadInventoryRewardSnapshot()
            if not available then return end

            if not skyPortalMonitorWasInMatch then
                skyPortalMonitorWasInMatch = true
                if webhookGameWasActive and webhookSecretRewardBaselineAvailable
                    and type(webhookSecretRewardBefore) == "table" then
                    skyPortalMonitorKnown = table.clone(webhookSecretRewardBefore)
                else
                    -- If no reliable start baseline exists, establish one now rather
                    -- than falsely announcing portals already owned before monitoring.
                    skyPortalMonitorKnown = table.clone(current)
                    return
                end
            end

            local known = skyPortalMonitorKnown or {}
            local knownCounts = GetWebhookPortalCounts(known)
            local currentCounts = GetWebhookPortalCounts(current)
            for itemId in pairs(WEBHOOK_PORTAL_ITEMS) do
                local previousTotal = knownCounts[itemId] or 0
                local currentTotal = currentCounts[itemId] or 0
                local gained = math.max(0, currentTotal - previousTotal)
                if gained > 0 then
                    -- Preserve newly seen UUIDs for end-screen fallback if the
                    -- inventory profile disappears during match teardown.
                    for key, reward in pairs(current) do
                        if key:sub(1, 5) == "item:" and tostring(reward.itemId or "") == itemId
                            and not known[key] then
                            skyPortalMatchDrops = skyPortalMatchDrops or {}
                            skyPortalMatchDrops[key] = table.clone(reward)
                        end
                    end
                    NotifySkyPortalDrop(itemId, gained, currentTotal)
                end
            end
            skyPortalMonitorKnown = table.clone(current)
        end)
        if not ok then
            warn("[Octoput Hub] Sky Portal monitor error: " .. tostring(err))
        end
    end
end)

-- Shared damage-type normalization for portal data extraction and matching.
-- Canonical IDs are the keys used by DamageTypes.TYPES in game.lua.
function NormalizePortalDamageType(value)
    if type(value) ~= "string" then return nil end
    local key = string.lower(value):gsub("[%s%-]", "_")
    key = key:gsub("_damage$", "")
    local aliases = {
        fire = "fire_damage", fire_damage = "fire_damage",
        water = "water_damage", aqua = "water_damage", water_damage = "water_damage",
        lightning = "lightning_damage", storm = "lightning_damage", lightning_damage = "lightning_damage",
        air = "air_damage", air_damage = "air_damage",
        ice = "ice_damage", rose = "ice_damage", ice_damage = "ice_damage",
        light = "light_damage", light_damage = "light_damage",
        dark = "dark_damage", dark_damage = "dark_damage",
    }
    return aliases[key]
end

function GetOwnedPortals()
    local profile = FindLocalInventoryProfile()
    local portals, seen = {}, {}
    if not profile then return portals, "Inventory session not found (executor getgc support required)." end
    local itemData = LoadGameDataModule("Items")
    local levelsData = LoadGameDataModule("Levels")
    for _, owned in pairs(profile.unique_items) do
        if type(owned) == "table" and type(owned.uuid) == "string" and type(owned.item_id) == "string" then
            local def = itemData and itemData[owned.item_id]
            if def and def.item_group == "Portals" then
                local uniqueData = owned._unique_item_data
                local portalData = type(uniqueData) == "table" and uniqueData._unique_portal_data or nil
                local tier = tonumber(portalData and portalData.portal_depth) or 0
                local levelId = (type(portalData) == "table" and portalData.level_id)
                    or (type(def.usage) == "table" and def.usage.level_id)
                -- The game first resolves Levels[levelId], then builds static portal
                -- params from that level. Do not mistake static_portal_copy_to_level_params
                -- (which contains portal setup fields) for the actual Level definition.
                local levelData = type(levelId) == "string"
                    and type(levelsData) == "table" and levelsData[levelId] or nil
                local increasedDamageElements = {}
                local function addIncreasedDamageEntries(entries)
                    if type(entries) ~= "table" then return end
                    local function addModifier(modifier)
                        if type(modifier) ~= "table" then return end
                        local damageType = NormalizePortalDamageType(modifier.damage_type)
                        local amplification = tonumber(modifier.amplification)
                        if damageType and amplification ~= nil and amplification > 0 then
                            increasedDamageElements[damageType] = true
                        end
                    end
                    -- game.lua uses an array of { damage_type, amplification } records.
                    if entries.damage_type ~= nil then
                        addModifier(entries)
                    else
                        for _, modifier in pairs(entries) do
                            addModifier(modifier)
                        end
                    end
                end
                local function scanWeakAgainstFields(root, depth, visited)
                    if type(root) ~= "table" or depth > 5 or visited[root] then return end
                    visited[root] = true
                    -- Only inspect the game's actual weakness field. Do not read
                    -- _strong_against, daily challenge hints, or recommended types.
                    for key, value in pairs(root) do
                        if key == "_weak_against" then
                            addIncreasedDamageEntries(value)
                        elseif type(value) == "table" then
                            scanWeakAgainstFields(value, depth + 1, visited)
                        end
                    end
                end
                -- Mirror the portal preview's data sources: resolved Level data,
                -- static portal copy parameters, and the owned unique-portal data
                -- that add_portal_level_modifiers_1/2 copies onto the level.
                local visitedModifierSources = {}
                scanWeakAgainstFields(uniqueData, 0, visitedModifierSources)
                scanWeakAgainstFields(portalData, 0, visitedModifierSources)
                scanWeakAgainstFields(levelData, 0, visitedModifierSources)
                scanWeakAgainstFields(def.static_portal_copy_to_level_params, 0, visitedModifierSources)
                local key = owned.item_id
                if not seen[key] then
                    seen[key] = { id = key, name = tostring(def.name or key), count = 0, entries = {} }
                    table.insert(portals, seen[key])
                end
                seen[key].count = seen[key].count + 1
                table.insert(seen[key].entries, {
                    uuid = owned.uuid,
                    tier = tier,
                    increasedDamageElements = increasedDamageElements,
                })
            end
        end
    end
    table.sort(portals, function(a,b) return a.name:lower() < b.name:lower() end)
    return portals, nil
end

portalInventoryCache = {}
function RefreshPortalTierUI()
    PortalTierList.CanvasPosition = Vector2.new(0, 0)
    for _, child in ipairs(PortalTierList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- Tier definitions found in robloxgame.lua: Tier 1 through Tier 12.
    -- Show the full list regardless of what is currently owned in Inventory.
    for index, tier in ipairs({12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}) do
        local selected = State.SelectedPortalTiers[tostring(tier)] == true
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -8, 0, 25)
        button.BackgroundColor3 = selected and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(38, 38, 50)
        button.Text = (selected and "✓  " or "□  ") .. "T" .. tostring(tier)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 11
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.LayoutOrder = index
        button.ZIndex = 13
        button.Parent = PortalTierList
        button.MouseButton1Click:Connect(function()
            local key = tostring(tier)
            State.SelectedPortalTiers[key] = not State.SelectedPortalTiers[key] and true or nil
            SaveConfig()
            RefreshPortalTierUI()
        end)
    end
end

function RefreshPortalUI()
    PortalInventoryList.CanvasPosition = Vector2.new(0, 0)
    for _, child in ipairs(PortalInventoryList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local portals, err = GetOwnedPortals()
    portalInventoryCache = portals
    if err then
        PortalStatus.Text = err
        return
    end

    for index, portal in ipairs(portals) do
        local selected = State.SelectedPortalTypes[portal.id] == true
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -8, 0, 28)
        button.BackgroundColor3 = selected and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(38, 38, 50)
        button.Text = (selected and "✓  " or "□  ") .. portal.name .. "  x" .. tostring(portal.count)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 11
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.LayoutOrder = index
        button.ZIndex = 13
        button.Parent = PortalInventoryList
        button.MouseButton1Click:Connect(function()
            State.SelectedPortalTypes[portal.id] = not State.SelectedPortalTypes[portal.id] and true or nil
            SaveConfig()
            RefreshPortalUI()
        end)
    end
    PortalStatus.Text = string.format("Found %d portal type(s). Select portals and tiers, then enable Auto Open Portal.", #portals)
end
RefreshPortalTierUI()
PortalRefreshButton.MouseButton1Click:Connect(RefreshPortalUI)
CreateToggle(PortalPage, "Auto Open Portal", "AutoOpenPortal", 4)
CreateToggle(PortalPage, "Auto Next Portal (Win / Lose)", "AutoNextPortal", 5)

portalOpenBusy = false
portalLastRefresh = 0
portalOpenedUUIDs = {}
task.spawn(function()
    while task.wait(1) do
        if State.AutoOpenPortal and not portalOpenBusy and IsInLobby() then
            portalOpenBusy = true
            local ok, err = pcall(function()
                local now = os.clock()
                if now - portalLastRefresh >= 8 then
                    RefreshPortalUI()
                    portalLastRefresh = now
                end
                local portals = GetOwnedPortals()
                local candidates = {}
                local hasElementFilter = next(State.SelectedPortalModifiers) ~= nil
                for _, portal in ipairs(portals) do
                    -- Portal type is determined by the actual inventory item_id.
                    -- Secondary damage modifiers must never decide the portal identity.
                    if State.SelectedPortalTypes[portal.id] then
                        for _, entry in ipairs(portal.entries) do
                            if State.SelectedPortalTiers[tostring(entry.tier)]
                                and not portalOpenedUUIDs[entry.uuid] then
                                local elementMatch = false
                                if hasElementFilter and type(entry.increasedDamageElements) == "table" then
                                    -- Normalize selected IDs too, so Aqua/water aliases
                                    -- resolve to the same game damage type.
                                    for elementId, isSelected in pairs(State.SelectedPortalModifiers) do
                                        local normalizedId = NormalizePortalDamageType(elementId)
                                        if isSelected and normalizedId and entry.increasedDamageElements[normalizedId] then
                                            elementMatch = true
                                            break
                                        end
                                    end
                                end

                                -- A selected increased-damage modifier is a hard requirement.
                                -- Never open a portal that only resists that element or has no amplification.
                                if not hasElementFilter or elementMatch then
                                    table.insert(candidates, {
                                        uuid = entry.uuid,
                                        tier = entry.tier,
                                        name = portal.name,
                                        elementMatch = elementMatch,
                                    })
                                end
                            end
                        end
                    end
                end

                -- After all selected filters match, choose the highest Tier first.
                table.sort(candidates, function(a, b)
                    if a.tier ~= b.tier then return a.tier > b.tier end
                    return a.name < b.name
                end)
                local opened = false
                for _, entry in ipairs(candidates) do
                    if not State.AutoOpenPortal then break end
                    if IsInLobby() then
                        portalOpenedUUIDs[entry.uuid] = true
                        local result = InvokeEndpoint("use_portal", entry.uuid)
                        if result == false then portalOpenedUUIDs[entry.uuid] = nil end
                        PortalStatus.Text = string.format("Opening %s (Tier %d)...", entry.name, entry.tier)
                        opened = true
                        task.wait(3)
                        break
                    end
                end
                if not opened then
                    if #portals == 0 then
                        PortalStatus.Text = "No owned portals found."
                    elseif #candidates == 0 then
                        if hasElementFilter then
                            local selectedLabels = {}
                            for _, def in ipairs(PORTAL_ELEMENT_FILTERS) do
                                if State.SelectedPortalModifiers[def.id] then
                                    table.insert(selectedLabels, def.label)
                                end
                            end
                            PortalStatus.Text = "Waiting for portal with increased damage: " .. table.concat(selectedLabels, " / ")
                        else
                            PortalStatus.Text = "No owned portal matches the selected portal type and tier."
                        end
                    end
                end
            end)
            if not ok then warn("[Octoput Hub Auto Portal] " .. tostring(err)) end
            portalOpenBusy = false
        end
    end
end)


EventStatusCard = Instance.new("Frame")
EventStatusCard.Size = UDim2.new(1, -10, 0, 38)
EventStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
EventStatusCard.LayoutOrder = 0
EventStatusCard.ZIndex = 12
EventStatusCard.Parent = EventPage

EventStatusCorner = Instance.new("UICorner")
EventStatusCorner.CornerRadius = UDim.new(0, 6)
EventStatusCorner.Parent = EventStatusCard

EventStatusLabel = Instance.new("TextLabel")
EventStatusLabel.Size = UDim2.new(1, -20, 1, 0)
EventStatusLabel.Position = UDim2.new(0, 10, 0, 0)
EventStatusLabel.BackgroundTransparency = 1
EventStatusLabel.Text = "Target Event: Summer Hunt (summer2_event) | Status: Idle"
EventStatusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
EventStatusLabel.TextSize = 12
EventStatusLabel.Font = Enum.Font.GothamMedium
EventStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
EventStatusLabel.ZIndex = 13
EventStatusLabel.Parent = EventStatusCard

function UpdateEventStatus(text, color)
    if EventStatusLabel then
        EventStatusLabel.Text = "Target: Summer Hunt | " .. text
        if color then
            EventStatusLabel.TextColor3 = color
        end
    end
end

eventMatchmakingLastRequest = 0
eventMatchmakingBusy = false
EVENT_MATCHMAKING_COOLDOWN = 10

function RequestSummerHuntMatchmaking()
    if eventMatchmakingBusy or not IsInLobby() or IsMatchmaking() then
        return false
    end
    local now = os.clock()
    if now - eventMatchmakingLastRequest < EVENT_MATCHMAKING_COOLDOWN then
        return false
    end
    eventMatchmakingLastRequest = now
    eventMatchmakingBusy = true
    local ok, result = pcall(InvokeEndpoint, "request_matchmaking", EVENT_LEVEL_ID)
    eventMatchmakingBusy = false
    if not ok then
        warn("[Octoput Hub Summer Hunt] Matchmaking request failed: " .. tostring(result))
        return false
    end
    return result ~= false
end

function HandlePopups()
    local notifWindows = playerGui:FindFirstChild("NotificationWindows")
    if not notifWindows then
        return
    end

    local popups = notifWindows:FindFirstChild("Popups")
    if not popups then
        return
    end

    for _, popup in ipairs(popups:GetChildren()) do
        if popup:IsA("GuiObject") and popup.Visible then
            local captcha = popup:FindFirstChild("Captcha")
            local typeBox = popup:FindFirstChild("TypeBox")
            local btnHolder = popup:FindFirstChild("ButtonHolder")
            if captcha and typeBox and captcha.Text and captcha.Text ~= "" and typeBox.Text ~= captcha.Text then
                typeBox.Text = captcha.Text
                task.wait(0.15)
                if btnHolder and btnHolder:FindFirstChild("Yes") then
                    local yesBtn = btnHolder.Yes
                    if typeof(firesignal) == "function" then
                        firesignal(yesBtn.MouseButton1Click)
                    elseif typeof(getconnections) == "function" then
                        for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do
                            c:Fire()
                        end
                    end
                end
            end

            local main = popup:FindFirstChild("Main")
            local buttons = main and main:FindFirstChild("Buttons")
            local mmBtn = buttons and buttons:FindFirstChild("Matchmaking")
            if mmBtn and mmBtn.Visible and os.clock() - eventMatchmakingLastRequest >= EVENT_MATCHMAKING_COOLDOWN then
                -- The popup can remain visible across several worker ticks. Mark the
                -- request before firing the game's button so it cannot be spammed.
                eventMatchmakingLastRequest = os.clock()
                if typeof(firesignal) == "function" then
                    firesignal(mmBtn.MouseButton1Click)
                elseif typeof(getconnections) == "function" then
                    for _, c in ipairs(getconnections(mmBtn.MouseButton1Click)) do
                        c:Fire()
                    end
                else
                    eventMatchmakingLastRequest = 0
                    RequestSummerHuntMatchmaking()
                end
            end
        end
    end
end

eventAutomationStopped = false

CreateToggle(EventPage, "Auto Find Match (Summer Hunt)", "AutoFindMatch", 1, function(isON)
    -- Manually toggling Auto Find Match back on resumes event automation.
    eventAutomationStopped = false
    if isON then
        UpdateEventStatus("Starting Matchmaking...", Color3.fromRGB(255, 200, 70))
        if IsInLobby() and not IsMatchmaking() then
            RequestSummerHuntMatchmaking()
        end
    else
        UpdateEventStatus("Status: Idle", Color3.fromRGB(160, 160, 180))
        if IsInLobby() and IsMatchmaking() then
            InvokeEndpoint("leave_matchmaking")
        end
    end
end)

CreateToggle(EventPage, "Auto Event Quests", "AutoEventQuests", 2)
CreateToggle(EventPage, "Auto Pick Cards", "AutoPickCards", 3)
CreateSection(EventPage, "Pick Card", 4)
CreatePriorityEditor(EventPage, "Buff Card Selection", "Checked buffs are preferred, from top to bottom. Leave all unchecked to keep automatic selection.", BUFF_DEFS, "BuffPriority", 5)
CreatePriorityEditor(EventPage, "Debuff Card Selection", "Checked debuffs are avoided, from top to bottom. Leave all unchecked to keep automatic selection.", DEBUFF_DEFS, "DebuffAvoid", 8)
CreateToggle(EventPage, "Auto Replay Match", "AutoReplay", 11)

WebhookStatus = nil
CreateTextBox(WebhookPage, "Discord Webhook URL", "https://discord.com/api/webhooks/...", 1, function(text)
    State.WebhookURL = text
    SaveConfig()
end, State.WebhookURL)
CreateToggle(WebhookPage, "Send webhook when ending", "WebhookOnEnd", 2)
CreateSection(WebhookPage, "Test Webhook", 3)
CreateButton(WebhookPage, "Test Webhook", 4, function()
    local url = NormalizeWebhookUrl(State.WebhookURL)
    local problem = WebhookProblem(url)
    if problem then
        WebhookStatus.Text = "Failed: " .. problem
        WebhookStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end
    WebhookStatus.Text = "Sending test message..."
    WebhookStatus.TextColor3 = Color3.fromRGB(255, 200, 70)
    local body = HttpService:JSONEncode({
        username = "Octoput Hub",
        embeds = {{
            title = "Webhook Test",
            description = string.format("**Player:** %s\n\n**📊 PLAYER STATS**\n%s\n\nTest message from Octoput Hub.", player.Name, BuildPlayerStatsText(ReadPlayerCurrencies())),
            color = 5814783,
            timestamp = DateTime.now():ToIsoDate(),
        }},
    })
    local ok, result = pcall(HttpPost, url, body)
    local success, message = DescribeWebhookResult(ok, result)
    if success then
        WebhookStatus.Text = "Success: " .. message
        WebhookStatus.TextColor3 = Color3.fromRGB(100, 255, 140)
    else
        WebhookStatus.Text = "Failed: " .. message
        WebhookStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
    end
end)
WebhookStatus = CreateHint(WebhookPage, "Test result appears here.", 5, 48)

-- Free Cam: camera-only movement. The character remains at its real position.
local freeCamActive = false
local freeCamPosition = nil
local freeCamYaw = 0
local freeCamPitch = 0
local freeCamPreviousType = nil
local freeCamPreviousSubject = nil
local freeCamPreviousMouseBehavior = nil
local freeCamPreviousMouseIcon = nil
local FREECAM_RENDER_BIND = "OctoputHub_FreeCam"
local FREECAM_SPEED = 42
local FREECAM_SENSITIVITY = 0.0025

function SetFreeCam(enabled)
    enabled = enabled == true
    if enabled == freeCamActive then return end

    local camera = workspace.CurrentCamera
    if not camera then
        State.FreeCam = false
        return
    end

    if enabled then
        freeCamActive = true
        freeCamPreviousType = camera.CameraType
        freeCamPreviousSubject = camera.CameraSubject
        freeCamPreviousMouseBehavior = UserInputService.MouseBehavior
        freeCamPreviousMouseIcon = UserInputService.MouseIconEnabled

        local current = camera.CFrame
        freeCamPosition = current.Position
        local look = current.LookVector
        freeCamYaw = math.atan2(-look.X, -look.Z)
        freeCamPitch = math.asin(math.clamp(look.Y, -0.999, 0.999))

        camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        RunService:BindToRenderStep(FREECAM_RENDER_BIND, Enum.RenderPriority.Camera.Value + 1, function(dt)
            if not freeCamActive then return end
            local activeCamera = workspace.CurrentCamera
            if not activeCamera then return end

            local delta = UserInputService:GetMouseDelta()
            freeCamYaw = freeCamYaw - delta.X * FREECAM_SENSITIVITY
            freeCamPitch = math.clamp(freeCamPitch - delta.Y * FREECAM_SENSITIVITY, math.rad(-89), math.rad(89))

            local rotation = CFrame.fromOrientation(freeCamPitch, freeCamYaw, 0)
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += rotation.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= rotation.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += rotation.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= rotation.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                move -= Vector3.yAxis
            end

            if move.Magnitude > 0 then
                local speed = FREECAM_SPEED
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                    speed = speed * 3
                end
                freeCamPosition += move.Unit * speed * math.max(0, dt)
            end

            activeCamera.CameraType = Enum.CameraType.Scriptable
            activeCamera.CFrame = CFrame.new(freeCamPosition) * rotation
        end)
    else
        freeCamActive = false
        RunService:UnbindFromRenderStep(FREECAM_RENDER_BIND)

        local activeCamera = workspace.CurrentCamera
        if activeCamera then
            activeCamera.CameraType = freeCamPreviousType or Enum.CameraType.Custom
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            activeCamera.CameraSubject = (freeCamPreviousSubject and freeCamPreviousSubject.Parent)
                and freeCamPreviousSubject or humanoid
            if activeCamera.CameraType == Enum.CameraType.Scriptable then
                activeCamera.CameraType = Enum.CameraType.Custom
            end
        end

        UserInputService.MouseBehavior = freeCamPreviousMouseBehavior or Enum.MouseBehavior.Default
        if freeCamPreviousMouseIcon ~= nil then
            UserInputService.MouseIconEnabled = freeCamPreviousMouseIcon
        end
        freeCamPosition = nil
    end
end

-- Always release the camera if the character respawns or the hub is removed.
player.CharacterAdded:Connect(function()
    if freeCamActive then
        task.defer(function() SetFreeCam(false) end)
    end
end)

CreateToggle(MiscPage, "Blackscreen (reduce 3D render)", "BlackScreen", 1, function(isON)
    ApplyBlackScreen(isON)
end)
CreateToggle(MiscPage, "Auto Hide GUI on Execute", "AutoHideGUIOnExecute", 2, function(isON)
    -- This setting is saved and takes effect on the next script execution.
end)
CreateToggle(MiscPage, "Anti-AFK (Prevent 20-minute idle disconnect)", "AntiAFK", 3)
CreateToggle(MiscPage, "Free Cam", "FreeCam", 4, function(isON)
    SetFreeCam(isON)
end)
CreateHint(MiscPage, "Free Cam works anywhere. WASD = move, Space / Ctrl = up / down, Mouse = look, Shift = 3x speed. Your character does not move. Toggle off to restore the normal camera.", 5, 48)

CreateHint(MiscPage, "Anti-AFK responds to Roblox's Player.Idled event with a small virtual input. It does not move your character.", 4, 34)
CreateHint(MiscPage, "When enabled, the hub runs normally but its window starts hidden. Press Right Shift to show or hide it.", 5, 34)
CreateSingleSlider(MiscPage, "UI Scale", "50% smaller    150% larger", 8, 50, 150, function()
    return math.floor(State.UIScale * 100 + 0.5)
end, function(value)
    State.UIScale = math.clamp(value / 100, 0.5, 1.5)
    ApplyHubScale()
end)

farmStall = { count = 0, lastChange = 0 }
matchEndHandled = false

-- Farm-first keeps the next Farm upgrade affordable before Auto Place spends
-- remaining cash on other equipped units.
function HasPendingFarmUpgrade(myUnits)
    for _, unit in ipairs(myUnits or {}) do
        if IsFarmUnit(unit) and unit:FindFirstChild("_stats") then
            local stats = unit._stats
            local current = stats:FindFirstChild("upgrade")
            local maximum = stats:FindFirstChild("max_upgrade")
            if current and maximum then
                local target = tonumber(maximum.Value) or 0
                local cfg = GetUnitConfig(GetRawUnitId(unit))
                if cfg and tonumber(cfg.upgradeTarget) then
                    target = math.min(target, math.max(0, math.floor(cfg.upgradeTarget)))
                end
                if current.Value < target then
                    return true
                end
            end
        end
    end
    return false
end
votedStart = false
lastVoteAttempt = 0
lobbyStartSent = false
lastLobbyStartAttempt = 0
unitRefreshClock = 0

function ResultsButtons()
    local results = playerGui:FindFirstChild("ResultsUI")
    if not results then
        return nil, nil, nil
    end
    local finished = results:FindFirstChild("Finished")
    if not finished then
        return nil, nil, nil
    end
    return finished:FindFirstChild("Next"), finished:FindFirstChild("NextRetry"), finished:FindFirstChild("NextLevel")
end

function ButtonText(button)
    if not button then
        return ""
    end
    local main = button:FindFirstChild("Main")
    local text = main and main:FindFirstChild("text")
    if text and text:IsA("TextLabel") then
        return tostring(text.Text or "")
    end
    return tostring(button.Text or "")
end

function NextActionAvailable()
    local _, nextRetry, nextLevel = ResultsButtons()
    if nextLevel and nextLevel.Visible then
        return "story"
    end
    local retryText = ButtonText(nextRetry)
    if nextRetry and nextRetry.Visible and retryText == "Next Room" then
        return "room"
    end
    return nil
end

function FireGuiButton(button)
    if not button then
        return
    end
    if typeof(firesignal) == "function" then
        firesignal(button.MouseButton1Click)
    elseif typeof(getconnections) == "function" then
        for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
        end
    end
end

function GetCurrentLobbyId()
    local lobbyId = nil
    pcall(function()
        local loaderModule = ReplicatedStorage:FindFirstChild("src")
            and ReplicatedStorage.src:FindFirstChild("Loader")
        if not loaderModule then return end
        local Loader = require(loaderModule)
        local lobbyService = Loader.load_client_service(game, "LobbyServiceClient")
        if lobbyService then
            lobbyId = lobbyService.current_lobby
            if (lobbyId == nil or lobbyId == "") and lobbyService.current_lobby_model then
                lobbyId = lobbyService.current_lobby_model.Name
            end
        end
    end)
    return lobbyId
end

function RequestLobbyStart(lobbyId)
    if lobbyId == nil or lobbyId == "" then
        return false
    end

    -- Match the game's own Start button handler:
    -- EndpointsClient.invoke_server("request_start_game", LobbyServiceClient.current_lobby)
    local ok, result = pcall(function()
        local loaderModule = ReplicatedStorage:FindFirstChild("src")
            and ReplicatedStorage.src:FindFirstChild("Loader")
        if not loaderModule then error("Loader module not found") end
        local Loader = require(loaderModule)
        local endpointsClient = Loader.load_client_service(game, "EndpointsClient")
        if not endpointsClient or type(endpointsClient.invoke_server) ~= "function" then
            error("EndpointsClient unavailable")
        end
        return endpointsClient.invoke_server("request_start_game", lobbyId)
    end)

    if ok then
        return result ~= false
    end

    -- Fallback to the game's client-to-server endpoint if the service wrapper is unavailable.
    local endpoints = ReplicatedStorage:FindFirstChild("endpoints")
    local clientToServer = endpoints and endpoints:FindFirstChild("client_to_server")
    local remote = clientToServer and clientToServer:FindFirstChild("request_start_game")
    if remote then
        local fallbackOk, fallbackResult = pcall(function()
            if remote:IsA("RemoteFunction") then
                return remote:InvokeServer(lobbyId)
            elseif remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                remote:FireServer(lobbyId)
                return true
            end
            return false
        end)
        return fallbackOk and fallbackResult ~= false
    end
    return false
end

function TryAutoStart()
    if not State.AutoStart then
        votedStart = false
        lastVoteAttempt = 0
        lobbyStartSent = false
        lastLobbyStartAttempt = 0
        return
    end

    -- The game's MapSelectGui Start button is the authoritative lobby-start state.
    -- Do not rely on workspace lobby markers, which can be present outside the active lobby UI.
    local mapGui = playerGui:FindFirstChild("MapSelectGui")
    local buttons = mapGui and mapGui:FindFirstChild("Buttons")
    local startBtn = buttons and buttons:FindFirstChild("Start")
    if mapGui and mapGui.Enabled and buttons and buttons.Visible and startBtn and startBtn.Visible then
        votedStart = false
        if lobbyStartSent then
            return
        end
        if os.clock() - lastLobbyStartAttempt < 3 then
            return
        end

        local lobbyId = GetCurrentLobbyId()
        if not lobbyId then
            UpdateAutoPlayStatus("Auto Start: Waiting for Lobby ID", Color3.fromRGB(255, 200, 70))
            return
        end

        lastLobbyStartAttempt = os.clock()
        local sent = RequestLobbyStart(lobbyId)
        if sent then
            lobbyStartSent = true
            UpdateAutoPlayStatus("Auto Start: Start Request Sent", Color3.fromRGB(70, 200, 255))
        else
            lobbyStartSent = false
            UpdateAutoPlayStatus("Auto Start: Start Request Failed - Retrying", Color3.fromRGB(255, 100, 100))
        end
        return
    end

    lobbyStartSent = false
    lastLobbyStartAttempt = 0

    if IsInLobby() then
        votedStart = false
        return
    end

    local voteGui = playerGui:FindFirstChild("VoteStart")
    local data = workspace:FindFirstChild("_DATA")
    local voteFolder = data and data:FindFirstChild("VoteStart")
    local finished = voteFolder and voteFolder:FindFirstChild("VotingFinished")

    -- The vote is open while the server says VotingFinished == false. The Yes button
    -- GUI can be hidden or its signal not hookable by the executor, so do not depend on it.
    local open
    if finished then
        open = finished.Value == false
    else
        open = voteGui ~= nil and voteGui.Enabled == true
    end

    if open then
        -- The game's own Yes button only calls EndpointsClient.invoke_server("vote_start"),
        -- so send that directly and retry every 2s until the vote closes.
        if os.clock() - lastVoteAttempt >= 2 then
            lastVoteAttempt = os.clock()
            InvokeEndpoint("vote_start")
            votedStart = true
            UpdateAutoPlayStatus("Auto Start: Vote Sent", Color3.fromRGB(70, 200, 255))
        end
    else
        votedStart = false
        lastVoteAttempt = 0
    end
end


-- Auto Next Portal follows the game's ResultsUI replay flow. For portal levels,
-- the official NextRetry button sends set_game_finished_vote("replay", {item_uuid})
-- after LevelServiceCore validates that the replacement portal belongs to the same group.
function GetAutoNextPortalCandidate()
    local session = FindLocalGameSession()
    local profile = session and session.inventory and session.inventory.inventory_profile_data
    local uniqueItems = profile and profile.unique_items
    if type(uniqueItems) ~= "table" then
        return nil, "Inventory session not found", false
    end

    local loaderModule
    local loaderOk = pcall(function()
        loaderModule = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("Loader"))
    end)
    local levelData = loaderOk and type(loaderModule) == "table" and loaderModule.LevelData or nil
    if type(levelData) ~= "table" or levelData._is_map_or_portal_level ~= true then
        return nil, "Current stage is not a portal", false
    end
    if tonumber(levelData._owner_player_userid) ~= player.UserId then
        return nil, "Only the portal owner can choose the next portal", true
    end

    local portalGroup = levelData.portal_group
    if type(portalGroup) ~= "string" or portalGroup == "" then
        return nil, "Current portal group could not be identified", true
    end

    local items = LoadGameDataModule("Items")
    local levels = LoadGameDataModule("Levels")
    if type(items) ~= "table" or type(levels) ~= "table" then
        return nil, "Portal game data unavailable", true
    end

    local currentUUID = levelData._portal_item_uuid or levelData._portal_uuid
    local candidates = {}
    for _, owned in pairs(uniqueItems) do
        if type(owned) ~= "table" or type(owned.uuid) ~= "string"
            or owned.uuid == currentUUID or portalOpenedUUIDs[owned.uuid] then
            continue
        end

        local def = type(owned.item_id) == "string" and items[owned.item_id] or nil
        if not def or def.item_group ~= "Portals" then
            continue
        end

        local itemGroup
        if type(def.static_portal_copy_to_level_params) == "table" then
            itemGroup = def.static_portal_copy_to_level_params.portal_group
        else
            local usage = def.usage
            local levelId = type(usage) == "table" and usage.level_id or nil
            local uniqueData = owned._unique_item_data
            if def._unique_portal and type(uniqueData) == "table"
                and type(uniqueData._unique_portal_data) == "table" then
                levelId = uniqueData._unique_portal_data.level_id or levelId
            end
            local portalLevel = levelId and levels[levelId]
            itemGroup = portalLevel and portalLevel.portal_group
        end
        if itemGroup ~= portalGroup then
            continue
        end

        local uniqueData = owned._unique_item_data
        local tries = type(uniqueData) == "table" and tonumber(uniqueData._portal_tries) or nil
        local maxTries = type(uniqueData) == "table" and tonumber(uniqueData._portal_max_tries) or tonumber(def._portal_max_tries)
        local hasRemainingTries = def._portal_infinite_lives == true
            or (tries ~= nil and maxTries ~= nil and tries < maxTries)
        if not hasRemainingTries then
            continue
        end

        local portalData = type(uniqueData) == "table" and uniqueData._unique_portal_data or nil
        local tier = tonumber(portalData and portalData.portal_depth) or 0
        if State.SelectedPortalTypes[owned.item_id] and State.SelectedPortalTiers[tostring(tier)] then
            table.insert(candidates, {
                uuid = owned.uuid,
                itemId = owned.item_id,
                tier = tier,
                name = tostring(def.name or owned.item_id),
            })
        end
    end

    table.sort(candidates, function(a, b)
        if a.tier == b.tier then return a.name < b.name end
        return a.tier > b.tier
    end)
    return candidates[1], #candidates == 0 and "No other matching portal is available" or nil, true
end

function HandleMatchEnd(gameFinished)
    if not gameFinished or gameFinished.Value ~= true then
        matchEndHandled = false
        return
    end
    if matchEndHandled then
        return
    end

    -- Portal Auto Next uses the same result-screen replay flow as the game itself.
    -- It works after both Victory and Defeat and only for the portal owner.
    local nextPortal, nextPortalReason, isPortalLevel
    if State.AutoNextPortal then
        nextPortal, nextPortalReason, isPortalLevel = GetAutoNextPortalCandidate()
    end
    if State.AutoNextPortal and isPortalLevel then
        matchEndHandled = true
        task.spawn(function()
            task.wait(2.5)
            if not gameFinished.Parent or gameFinished.Value ~= true then return end
            if nextPortal then
                portalOpenedUUIDs[nextPortal.uuid] = true
                local ok, result = pcall(function()
                    return InvokeEndpoint("set_game_finished_vote", "replay", { item_uuid = nextPortal.uuid })
                end)
                if not ok or result == false then
                    portalOpenedUUIDs[nextPortal.uuid] = nil
                    UpdateEventStatus("Auto Next Portal: Replay request failed", Color3.fromRGB(255, 100, 100))
                else
                    UpdateEventStatus(string.format("Auto Next Portal: Selecting %s (T%d)...", nextPortal.name, nextPortal.tier), Color3.fromRGB(70, 200, 255))
                end
            elseif nextPortalReason == "No other matching portal is available" and State.AutoOpenPortal then
                UpdateEventStatus("Auto Next Portal: No matching portal; returning to Lobby for Auto Open Portal...", Color3.fromRGB(255, 170, 0))
                InvokeEndpoint("teleport_back_to_lobby")
            else
                UpdateEventStatus("Auto Next Portal: " .. tostring(nextPortalReason or "No valid portal found"), Color3.fromRGB(255, 170, 0))
            end
        end)
        return
    end

    -- Priority: Main tab controls always win over Event tab automation.
    -- Main order: Next (when available) > Main Replay > Main Leave.
    -- Event Replay is only a fallback when no Main action is selected.
    local nextKind = State.AutoNext and NextActionAvailable() or nil
    local mainActionSelected = State.AutoNext or State.MainAutoReplay or State.AutoLeave
    local action = nil

    if nextKind then
        action = "next"
    elseif State.MainAutoReplay then
        action = "replay"
    elseif State.AutoLeave then
        action = "leave"
    elseif not mainActionSelected and State.AutoFindMatch and State.AutoReplay then
        action = "replay"
    elseif not mainActionSelected and State.AutoFindMatch and not State.AutoReplay then
        action = "leave"
    end
    if not action then
        return
    end

    matchEndHandled = true
    task.spawn(function()
        task.wait(2.5)
        if not gameFinished.Parent or gameFinished.Value ~= true then
            return
        end
        if action == "next" then
            if nextKind == "room" then
                InvokeEndpoint("request_start_infinite_tower_from_game")
                UpdateEventStatus("Match Finished! Starting Next Room...", Color3.fromRGB(255, 170, 0))
            else
                InvokeEndpoint("set_game_finished_vote", "next_story")
                UpdateEventStatus("Match Finished! Voting Next...", Color3.fromRGB(255, 170, 0))
            end
        elseif action == "replay" then
            UpdateEventStatus("Match Finished! Voting Replay...", Color3.fromRGB(255, 170, 0))
            InvokeEndpoint("set_game_finished_vote", "replay")
            if State.AutoFindMatch then
                task.wait(8)
                if gameFinished.Parent and gameFinished.Value == true then
                    UpdateEventStatus("Returning to Lobby for Next Match...", Color3.fromRGB(255, 100, 100))
                    InvokeEndpoint("teleport_back_to_lobby")
                end
            end
        elseif action == "leave" then
            -- Leave the finished Event match, but keep Auto Find Match enabled.
            -- Once the player is back in the lobby, the matchmaking worker below
            -- will detect the lobby state and queue the next Event automatically.
            eventAutomationStopped = false
            UpdateEventStatus("Leaving Match... (Auto Queue Will Resume In Lobby)", Color3.fromRGB(255, 100, 100))

            -- Retry the leave request in case the first endpoint call is ignored.
            for attempt = 1, 3 do
                if not gameFinished.Parent or gameFinished.Value ~= true then
                    break
                end
                InvokeEndpoint("teleport_back_to_lobby")
                if attempt < 3 then
                    task.wait(2)
                end
            end
        end
    end)
end

-- Roblox's standard idle timeout is around 20 minutes. The game source
-- does not implement a separate AFK timer; handle the Player.Idled event here.
antiAfkConnection = nil
pcall(function()
    antiAfkConnection = player.Idled:Connect(function()
        if not State.AntiAFK then
            return
        end

        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end)

-- [[ SUMMON ]] --
-- Watches the selected live banner and stops as soon as a newly obtained target unit is detected.
SnipeRuntime = { Running = false, StopReason = "Idle", LastAction = "" }
SnipeBannerOptions = {}
SnipeUnitOptions = {}
SnipeBannerList = nil
SnipeUnitList = nil
SnipeStatusLabel = nil
SnipeBannerSelectedLabel = nil
SnipeTargetCountLabel = nil
SnipeStartButton = nil
SnipeRefreshButton = nil
SnipeModeButton = nil

local function SnipeMakeLabel(parent, text, order, height, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, height or 22)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(220, 220, 235)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.LayoutOrder = order
    label.ZIndex = 13
    label.Parent = parent
    return label
end

local function SnipeGetGameData()
    local ok, bannersData, unitsData = pcall(function()
        local loader = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("Loader"))
        local dataPath = loader.DATA_PATH
        assert(dataPath, "Game DATA_PATH is not ready")
        local bannerModule = dataPath:FindFirstChild("Banners", true)
        local unitModule = dataPath:FindFirstChild("Units", true)
        assert(bannerModule and unitModule, "Banner/Unit data modules not found")
        return require(bannerModule), require(unitModule)
    end)
    if ok then return bannersData, unitsData end
    return nil, nil, tostring(bannersData)
end

local function SnipeGetBannerUnitData(bannerId)
    local ok, bannerUnits = pcall(function()
        local remote = ReplicatedStorage:WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("get_hatch_setup_data")
        return remote:InvokeServer()
    end)
    if not ok or type(bannerUnits) ~= "table" then return nil end
    -- The endpoint's first return value is the BANNER_UNITS table.
    return bannerUnits[bannerId], bannerUnits
end

local function SnipeGetLiveBannerIds()
    -- The physical objects under workspace._shop._banners are display stands,
    -- not the authoritative banner IDs. Use ReplicatedStorage.src.Data.Banners,
    -- exactly as the game's SummonServiceClient does.
    local bannersData = SnipeGetGameData()
    local ids = {}
    if type(bannersData) ~= "table" then return ids end
    for bannerId, config in pairs(bannersData) do
        if type(bannerId) == "string" and type(config) == "table"
            and config.active ~= false and config.type == "rateup" then
            table.insert(ids, bannerId)
        end
    end
    table.sort(ids)
    return ids
end

local function SnipeGetBannerDisplayName(bannerId, config)
    local names = {
        Legacy = "Legacy Banner",
        EventClover = "New / Event Banner",
        Summer2026 = "Summer 2026 Capsule Banner",
    }
    local name = names[bannerId] or bannerId
    local currency = config and config.resource_cost
    if config and config.gem_cost then
        return name .. "  |  Gems x" .. tostring(config.gem_cost)
    elseif type(currency) == "table" then
        return name .. "  |  " .. tostring(currency.id or "Special Currency") .. " x" .. tostring(currency.amount or "?")
    end
    return name
end

local function SnipeResolveUnitIds(raw, unitsData)
    local ids, seen = {}, {}
    local function add(id)
        if type(id) == "string" and unitsData[id] and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    local function walk(value, depth)
        if depth > 8 then return end
        if type(value) == "string" then
            add(value)
        elseif type(value) == "table" then
            for key, child in pairs(value) do
                if type(key) == "string" then add(key) end
                walk(child, depth + 1)
            end
        end
    end
    walk(raw, 0)
    table.sort(ids, function(a, b)
        local an = (unitsData[a] and unitsData[a].name) or a
        local bn = (unitsData[b] and unitsData[b].name) or b
        return tostring(an):lower() < tostring(bn):lower()
    end)
    return ids
end

local function SnipeClearList(frame)
    if not frame then return end
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
end

local function SnipeBuildBannerList()
    local bannersData = SnipeGetGameData()
    SnipeBannerOptions = SnipeGetLiveBannerIds()
    SnipeClearList(SnipeBannerList)
    if not SnipeBannerList then return end
    for index, bannerId in ipairs(SnipeBannerOptions) do
        local config = bannersData and bannersData[bannerId]
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -6, 0, 30)
        button.BackgroundColor3 = State.SnipeBanner == bannerId and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(31, 31, 43)
        button.TextColor3 = Color3.fromRGB(235, 235, 245)
        button.TextSize = 11
        button.Font = Enum.Font.GothamMedium
        button.Text = SnipeGetBannerDisplayName(bannerId, config)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.LayoutOrder = index
        button.ZIndex = 14
        button.Parent = SnipeBannerList
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = button
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button
        button.MouseButton1Click:Connect(function()
            State.SnipeBanner = bannerId
            State.SnipeTargets = {}
            SaveConfig()
            if SnipeBannerSelectedLabel then SnipeBannerSelectedLabel.Text = "Selected Banner: " .. SnipeGetBannerDisplayName(bannerId, config) end
            SnipeBuildBannerList()
            SnipeBuildUnitList()
        end)
    end
    if #SnipeBannerOptions == 0 then
        SnipeMakeLabel(SnipeBannerList, "No active rate-up banners were found in Data.Banners.", 1, 28, Color3.fromRGB(235, 170, 100))
    end
    if State.SnipeBanner ~= "" and bannersData and bannersData[State.SnipeBanner] and SnipeBannerSelectedLabel then
        SnipeBannerSelectedLabel.Text = "Selected Banner: " .. SnipeGetBannerDisplayName(State.SnipeBanner, bannersData[State.SnipeBanner])
    end
end

function SnipeBuildUnitList()
    SnipeClearList(SnipeUnitList)
    SnipeUnitOptions = {}
    if not SnipeUnitList then return end
    local bannersData, unitsData = SnipeGetGameData()
    if not bannersData or not unitsData then
        SnipeMakeLabel(SnipeUnitList, "Unable to load game unit data. Press Refresh.", 1, 30, Color3.fromRGB(235, 170, 100))
        return
    end
    if State.SnipeBanner == "" or not bannersData[State.SnipeBanner] then
        SnipeMakeLabel(SnipeUnitList, "Select a banner first.", 1, 26)
        return
    end
    local bannerUnitData = SnipeGetBannerUnitData(State.SnipeBanner)
    if not bannerUnitData then
        SnipeMakeLabel(SnipeUnitList, "This banner has no active unit data right now. Try Refresh later.", 1, 38, Color3.fromRGB(235, 170, 100))
        return
    end
    local ids = SnipeResolveUnitIds(bannerUnitData, unitsData)
    SnipeUnitOptions = ids
    for index, unitId in ipairs(ids) do
        local unitInfo = unitsData[unitId]
        local unitName = (unitInfo and unitInfo.name) or unitId
        local selected = State.SnipeTargets[unitId] == true
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -6, 0, 30)
        button.BackgroundColor3 = selected and Color3.fromRGB(0, 115, 95) or Color3.fromRGB(31, 31, 43)
        button.TextColor3 = Color3.fromRGB(235, 235, 245)
        button.TextSize = 11
        button.Font = Enum.Font.GothamMedium
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = (selected and "[✓]  " or "[ ]  ") .. tostring(unitName) .. "  (" .. unitId .. ")"
        button.LayoutOrder = index
        button.ZIndex = 14
        button.Parent = SnipeUnitList
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = button
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button
        button.MouseButton1Click:Connect(function()
            if State.SnipeTargets[unitId] == true then
                State.SnipeTargets[unitId] = nil
            else
                State.SnipeTargets[unitId] = true
            end
            SaveConfig()
            SnipeBuildUnitList()
        end)
    end
    if #ids == 0 then
        SnipeMakeLabel(SnipeUnitList, "No unit IDs were found in this banner's data.", 1, 30, Color3.fromRGB(235, 170, 100))
    end
    local count = 0
    for _, enabled in pairs(State.SnipeTargets) do if enabled then count += 1 end end
    if SnipeTargetCountLabel then SnipeTargetCountLabel.Text = "Selected targets: " .. count end
end

local function SnipeFindOwnedUnits()
    local session = FindLocalGameSession()
    if session then
        local collection = session.collection
        local profile = type(collection) == "table" and collection.collection_profile_data
        if type(profile) == "table" and type(profile.owned_units) == "table" then
            return profile.owned_units
        end
    end

    -- Fallback for executor environments where the GUIService session is not exposed.
    if type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end
    for _, object in ipairs(objects) do
        if type(object) == "table" then
            local candidates = { object, object.session }
            for _, candidate in ipairs(candidates) do
                if type(candidate) == "table" and candidate.player == player then
                    local collection = candidate.collection
                    local profile = type(collection) == "table" and collection.collection_profile_data
                    if type(profile) == "table" and type(profile.owned_units) == "table" then
                        return profile.owned_units
                    end
                    profile = candidate.collection_profile_data
                    if type(profile) == "table" and type(profile.owned_units) == "table" then
                        return profile.owned_units
                    end
                end
            end
        end
    end
    return nil
end

local function SnipeCountTargets(owned, targets)
    local counts = {}
    for _, unit in pairs(owned) do
        if type(unit) == "table" and type(unit.unit_id) == "string" and targets[unit.unit_id] then
            counts[unit.unit_id] = (counts[unit.unit_id] or 0) + 1
        end
    end
    return counts
end

local function SnipeHasNewTarget(owned, before, targets)
    local after = SnipeCountTargets(owned, targets)
    for unitId, count in pairs(after) do
        if count > (before[unitId] or 0) then return true, unitId end
    end
    return false
end

local function SnipeSetStatus(message, color)
    SnipeRuntime.LastAction = message
    if SnipeStatusLabel then
        SnipeStatusLabel.Text = "Status: " .. message
        SnipeStatusLabel.TextColor3 = color or Color3.fromRGB(190, 210, 230)
    end
end

local function SnipeStop(reason)
    SnipeRuntime.Running = false
    SnipeRuntime.StopReason = reason or "Stopped"
    SnipeSetStatus(SnipeRuntime.StopReason, Color3.fromRGB(235, 180, 100))
    if SnipeStartButton then SnipeStartButton.Text = "Start Summon" end
end

local function SnipeStart()
    if SnipeRuntime.Running then SnipeStop("Stopped by user") return end
    if State.SnipeBanner == "" then SnipeSetStatus("Select a banner first", Color3.fromRGB(235, 100, 100)) return end
    if not workspace:FindFirstChild("_shop") then SnipeSetStatus("Summon is available in the lobby only", Color3.fromRGB(235, 100, 100)) return end

    local selectedBanner = State.SnipeBanner
    local targetCount = 0
    for _, enabled in pairs(State.SnipeTargets) do if enabled then targetCount += 1 end end
    if targetCount == 0 then SnipeSetStatus("Select at least one target unit", Color3.fromRGB(235, 100, 100)) return end

    local owned = SnipeFindOwnedUnits()
    if not owned then
        SnipeSetStatus("Cannot access owned-unit data; stopped safely", Color3.fromRGB(235, 100, 100))
        return
    end

    local bannersData = SnipeGetGameData()
    local config = bannersData and bannersData[selectedBanner]
    if type(config) ~= "table" or config.active == false then
        SnipeSetStatus("Selected banner is not active in game data", Color3.fromRGB(235, 100, 100))
        return
    end

    -- Read the exact currency and price from Data.Banners:
    -- gem_cost -> _stats.gem_amount; resource_cost.id -> _stats["_resource" .. id].
    local currencyId, currencyStatName, currencyLabel, unitCost
    if tonumber(config.gem_cost) and config.gem_cost > 0 then
        currencyId = "Gems"
        currencyStatName = "gem_amount"
        currencyLabel = "Gems"
        unitCost = tonumber(config.gem_cost)
    elseif type(config.resource_cost) == "table"
        and type(config.resource_cost.id) == "string"
        and tonumber(config.resource_cost.amount)
        and config.resource_cost.amount > 0 then
        currencyId = config.resource_cost.id
        currencyStatName = "_resource" .. currencyId
        currencyLabel = currencyId
        unitCost = tonumber(config.resource_cost.amount)
    else
        SnipeSetStatus("Banner currency / cost is not defined in Data.Banners", Color3.fromRGB(235, 100, 100))
        return
    end

    local remote
    local remoteOk = pcall(function()
        remote = ReplicatedStorage:WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("buy_from_banner")
        assert(remote:IsA("RemoteFunction"), "buy_from_banner is not a RemoteFunction")
    end)
    if not remoteOk or not remote then SnipeSetStatus("Summon endpoint not found", Color3.fromRGB(235, 100, 100)) return end

    local stats = player:FindFirstChild("_stats")
    local currencyStat = stats and stats:FindFirstChild(currencyStatName)
    if not currencyStat then
        SnipeSetStatus("Currency balance stat not found: " .. currencyStatName, Color3.fromRGB(235, 100, 100))
        return
    end

    local targetSnapshot = SnipeCountTargets(owned, State.SnipeTargets)
    local startingBalance = tonumber(currencyStat.Value) or 0
    local currencyLimit = math.max(0, tonumber(State.SnipeGemLimit) or 0)
    local summonCount = State.SnipeSummonCount == 1 and 1 or 10
    local estimatedCost = unitCost * summonCount
    local summonMode = summonCount == 10 and "gems10" or "gems"

    SnipeRuntime.Running = true
    SnipeRuntime.StopReason = "Running"
    if SnipeStartButton then SnipeStartButton.Text = "Stop Summon" end
    SnipeSetStatus("Watching " .. selectedBanner .. " | " .. currencyLabel .. " | Targets: " .. targetCount, Color3.fromRGB(100, 220, 160))

    task.spawn(function()
        local launchedSummons = 0
        while SnipeRuntime.Running do
            if not player.Parent then SnipeStop("Player unavailable") break end

            local liveUnits = SnipeGetBannerUnitData(selectedBanner)
            if not liveUnits then
                SnipeSetStatus("Waiting for selected banner data...", Color3.fromRGB(235, 180, 100))
                task.wait(2)
            else
                -- Reserve each launched request so parallel calls cannot exceed
                -- the starting balance or the configured Currency Limit.
                local currentBalance = tonumber(currencyStat.Value) or 0
                local reservedCost = launchedSummons * estimatedCost
                local safeBalance = math.min(currentBalance, math.max(0, startingBalance - reservedCost))
                local safeLimit = currencyLimit > 0 and math.max(0, currencyLimit - reservedCost) or math.huge
                local batchSize = math.min(5, math.floor(safeBalance / estimatedCost), math.floor(safeLimit / estimatedCost))

                if batchSize <= 0 then
                    if currencyLimit > 0 and reservedCost >= currencyLimit then
                        SnipeStop(currencyLabel .. " limit reached (reserved " .. reservedCost .. ")")
                    else
                        SnipeStop("Not enough " .. currencyLabel .. " for next summon")
                    end
                    break
                end

                local batch = { done = 0, failed = nil }
                for requestIndex = 1, batchSize do
                    launchedSummons += 1
                    task.spawn(function()
                        local ok, result = pcall(function()
                            -- Match the game's BuyOne / BuyTen modes, dispatched
                            -- as five independent requests running concurrently.
                            return remote:InvokeServer(selectedBanner, summonMode)
                        end)
                        if not ok and not batch.failed then
                            batch.failed = tostring(result)
                        end
                        batch.done += 1
                    end)
                end

                SnipeSetStatus("Sending " .. batchSize .. " parallel summon request(s) | " ..
                    currencyLabel .. " reserved: " .. (launchedSummons * estimatedCost),
                    Color3.fromRGB(100, 190, 255))

                local foundUnitId = nil
                while batch.done < batchSize do
                    task.wait(0.2)
                    local liveOwned = SnipeFindOwnedUnits() or owned
                    local hasTarget, unitId = SnipeHasNewTarget(liveOwned, targetSnapshot, State.SnipeTargets)
                    if hasTarget and not foundUnitId then foundUnitId = unitId end
                    -- A user stop prevents another batch; in-flight calls finish safely.
                end

                -- Recheck collection after every request in the batch has returned.
                local liveOwned = SnipeFindOwnedUnits() or owned
                local hasTarget, unitId = SnipeHasNewTarget(liveOwned, targetSnapshot, State.SnipeTargets)
                if hasTarget then foundUnitId = unitId end

                if foundUnitId then
                    local _, unitsData = SnipeGetGameData()
                    local unitName = unitsData and unitsData[foundUnitId] and unitsData[foundUnitId].name or foundUnitId
                    SnipeStop("TARGET OBTAINED: " .. tostring(unitName))
                    break
                end
                if batch.failed then
                    SnipeStop("Summon request failed: " .. batch.failed)
                    break
                end
                if not SnipeRuntime.Running then break end

                local spent = math.max(
                    math.max(0, startingBalance - (tonumber(currencyStat.Value) or 0)),
                    launchedSummons * estimatedCost
                )
                SnipeSetStatus("Batch complete | " .. currencyLabel .. " spent/reserved: " .. spent,
                    Color3.fromRGB(100, 220, 160))
            end
        end
    end)
end

CreateSection(SummonPage, "SUMMON", 1)
CreateHint(SummonPage, "Choose a banner and one or more target units. The system sends summons only to the selected banner and stops when a new target unit appears in your collection.", 2, 42)
SnipeBannerSelectedLabel = SnipeMakeLabel(SummonPage, "Selected Banner: " .. (State.SnipeBanner ~= "" and State.SnipeBanner or "None"), 3, 22, Color3.fromRGB(120, 190, 255))
CreateSection(SummonPage, "1. SELECT BANNER", 4)
SnipeBannerList = Instance.new("ScrollingFrame")
SnipeBannerList.Size = UDim2.new(1, -10, 0, 104)
SnipeBannerList.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
SnipeBannerList.BorderSizePixel = 0
SnipeBannerList.ScrollBarThickness = 3
SnipeBannerList.CanvasSize = UDim2.new(0, 0, 0, 0)
SnipeBannerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SnipeBannerList.LayoutOrder = 5
SnipeBannerList.ZIndex = 13
SnipeBannerList.Parent = SummonPage
local bannerLayout = Instance.new("UIListLayout")
bannerLayout.Padding = UDim.new(0, 4)
bannerLayout.SortOrder = Enum.SortOrder.LayoutOrder
bannerLayout.Parent = SnipeBannerList
local bannerPadding = Instance.new("UIPadding")
bannerPadding.PaddingTop = UDim.new(0, 4)
bannerPadding.PaddingBottom = UDim.new(0, 4)
bannerPadding.PaddingLeft = UDim.new(0, 4)
bannerPadding.PaddingRight = UDim.new(0, 4)
bannerPadding.Parent = SnipeBannerList
CreateSection(SummonPage, "2. SELECT TARGET UNITS (MULTI-SELECT)", 6)
SnipeTargetCountLabel = SnipeMakeLabel(SummonPage, "Selected targets: 0", 7, 20, Color3.fromRGB(120, 190, 255))
SnipeUnitList = Instance.new("ScrollingFrame")
SnipeUnitList.Size = UDim2.new(1, -10, 0, 154)
SnipeUnitList.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
SnipeUnitList.BorderSizePixel = 0
SnipeUnitList.ScrollBarThickness = 3
SnipeUnitList.CanvasSize = UDim2.new(0, 0, 0, 0)
SnipeUnitList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SnipeUnitList.LayoutOrder = 8
SnipeUnitList.ZIndex = 13
SnipeUnitList.Parent = SummonPage
local unitLayout = Instance.new("UIListLayout")
unitLayout.Padding = UDim.new(0, 4)
unitLayout.SortOrder = Enum.SortOrder.LayoutOrder
unitLayout.Parent = SnipeUnitList
local unitPadding = Instance.new("UIPadding")
unitPadding.PaddingTop = UDim.new(0, 4)
unitPadding.PaddingBottom = UDim.new(0, 4)
unitPadding.PaddingLeft = UDim.new(0, 4)
unitPadding.PaddingRight = UDim.new(0, 4)
unitPadding.Parent = SnipeUnitList
CreateTextBox(SummonPage, "Currency Limit (0 = unlimited)", "Example: 5000", 9, function(value)
    State.SnipeGemLimit = math.max(0, math.floor(tonumber(value) or 0))
    SaveConfig()
end, tostring(State.SnipeGemLimit or 0))
SnipeModeButton = CreateButton(SummonPage, "Summon Mode: 10x (click to switch)", 10, function()
    State.SnipeSummonCount = State.SnipeSummonCount == 10 and 1 or 10
    SnipeModeButton.Text = "Summon Mode: " .. (State.SnipeSummonCount == 10 and "10x" or "1x") .. " (click to switch)"
    SaveConfig()
end)
SnipeRefreshButton = CreateButton(SummonPage, "Refresh Banners / Units", 11, function()
    SnipeBuildBannerList()
    SnipeBuildUnitList()
    SnipeSetStatus("Lists refreshed", Color3.fromRGB(100, 220, 160))
end)
SnipeStatusLabel = SnipeMakeLabel(SummonPage, "Status: Idle", 12, 34, Color3.fromRGB(190, 210, 230))
SnipeStartButton = CreateButton(SummonPage, "Start Summon", 13, SnipeStart)
SnipeBuildBannerList()
SnipeBuildUnitList()
SnipeModeButton.Text = "Summon Mode: " .. (State.SnipeSummonCount == 10 and "10x" or "1x") .. " (click to switch)"

AllowSave = true
if State.BlackScreen then
    ApplyBlackScreen(true)
end
RefreshUnitConfigUI()

-- Estimate the next upgrade price from live unit stats first, then unit data.
-- Unknown prices for non-maxed units fall back to 0 instead of math.huge so
-- runtime-replicated units like Elfy (Sylph) are never skipped by AutoUpgrade.
function GetNextUpgradeCost(unit)
    if not unit or not unit:FindFirstChild("_stats") then return math.huge end
    local stats = unit._stats
    local current = stats:FindFirstChild("upgrade")
    if not current then return math.huge end
    local curLvl = tonumber(current.Value) or 0
    local maxVal = stats:FindFirstChild("max_upgrade")
    if maxVal and tonumber(maxVal.Value) and curLvl >= tonumber(maxVal.Value) then
        return math.huge
    end

    SyncReplicatedGameData()

    -- Match the game's own pricing path:
    -- ceil(upgrade data cost * player_cost_scale * unit upgrade_cost_multiplier),
    -- with the _negate_high_cost cap applied by UnitServiceCore.
    local data = LookupUnitData(GetRawUnitId(unit))
    local upgrades = type(data) == "table" and data.upgrade or nil
    local nextInfo = type(upgrades) == "table" and upgrades[curLvl + 1] or nil
    local baseCost = type(nextInfo) == "table"
        and tonumber(nextInfo.cost or nextInfo.upgrade_cost or nextInfo.price)
        or nil

    if not baseCost then
        local okGui, guiCost = pcall(function()
            local pgui = player:FindFirstChild("PlayerGui")
            local overview = pgui and pgui:FindFirstChild("UnitOverview")
            local ref = overview and overview:FindFirstChild("_unit_char_ref")
            if ref and ref.Value == unit then
                local textObj = overview:FindFirstChild("Outer")
                    and overview.Outer:FindFirstChild("buttons")
                    and overview.Outer.buttons:FindFirstChild("Upgrade")
                    and overview.Outer.buttons.Upgrade:FindFirstChild("Main")
                    and overview.Outer.buttons.Upgrade.Main:FindFirstChild("Text")
                local rawText = textObj and tostring(textObj.Text or "") or ""
                local digits = rawText:gsub("[^%d]", "")
                if digits ~= "" then
                    return tonumber(digits)
                end
            end
            return nil
        end)
        if okGui and tonumber(guiCost) then
            return tonumber(guiCost)
        end
        -- Allow AutoUpgrade to attempt upgrading when replicator data is still
        -- loading instead of permanently skipping Elfy (Sylph).
        return 0
    end

    local multiplier = 1
    local dataFolder = workspace:FindFirstChild("_DATA")
    local modifiers = dataFolder and dataFolder:FindFirstChild("GameModifiers")
    local playerCostScale = modifiers and modifiers:FindFirstChild("player_cost_scale")
    if playerCostScale and tonumber(playerCostScale.Value) then
        multiplier = tonumber(playerCostScale.Value)
    end

    local unitMultiplier = stats:FindFirstChild("upgrade_cost_multiplier")
    if unitMultiplier and tonumber(unitMultiplier.Value) then
        multiplier = multiplier * tonumber(unitMultiplier.Value)
    end

    local negateHighCost = tonumber(player:GetAttribute("_negate_high_cost")) or 0
    if negateHighCost > 0 then
        multiplier = math.min(multiplier, 1)
    end

    return math.ceil(baseCost * math.max(0, multiplier))
end

pendingUpgradeRequests = {}
pendingSpawnRequests = {}

-- In-game cash (same value the game HUD uses for upgrade/placement affordability).
GetInGameCash = function()
    local stats = player:FindFirstChild("_stats")
    local resource = stats and stats:FindFirstChild("resource")
    return resource and tonumber(resource.Value) or nil
end

-- Cheapest next upgrade among farm units that still have farm upgrades pending.
function GetNextFarmUpgradeCost(myUnits)
    local best = nil
    for _, unit in ipairs(myUnits or {}) do
        if IsFarmUnit(unit) and unit:FindFirstChild("_stats") then
            local stats = unit._stats
            local current = stats:FindFirstChild("upgrade")
            local maximum = stats:FindFirstChild("max_upgrade")
            if current and maximum then
                local target = tonumber(maximum.Value) or 0
                local cfg = GetUnitConfig(GetRawUnitId(unit))
                if cfg and tonumber(cfg.upgradeTarget) then
                    target = math.min(target, math.max(0, math.floor(cfg.upgradeTarget)))
                end
                if current.Value < target then
                    local cost = GetNextUpgradeCost(unit)
                    if cost ~= math.huge and (best == nil or cost < best) then best = cost end
                end
            end
        end
    end
    return best
end

-- Run upgrades in their own worker so a slow upgrade request cannot stall Auto Place.
task.spawn(function()
    while true do
        task.wait(0.5)
        local upgradeOk, upgradeErr = pcall(function()
        if State.AutoUpgrade and not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
            SyncReplicatedGameData()
            local units = GetPlayerUnits()
            local now = tick()
            local candidates = {}

            for unit, pending in pairs(pendingUpgradeRequests) do
                local stats = unit and unit.Parent and unit:FindFirstChild("_stats")
                local level = stats and stats:FindFirstChild("upgrade")
                if not level or level.Value > pending.level or now - pending.time > 5 then
                    pendingUpgradeRequests[unit] = nil
                end
            end

            local pendingFarmUpgradeRequest = false
            local wave = GetCurrentWave()
            for _, unit in ipairs(units) do
                local stats = unit:FindFirstChild("_stats")
                local level = stats and stats:FindFirstChild("upgrade")
                local maximum = stats and stats:FindFirstChild("max_upgrade")
                local isFarm = IsFarmUnit(unit)
                if level then
                    local rawId = GetRawUnitId(unit)
                    local data = LookupUnitData(rawId)
                    local dataMax = type(data) == "table" and type(data.upgrade) == "table" and #data.upgrade or 0
                    local targetLevel = tonumber(maximum and maximum.Value) or dataMax
                    local cfg = GetUnitConfig(rawId) or GetUnitConfig(GetUnitId(unit))
                    if cfg and tonumber(cfg.upgradeTarget) then
                        targetLevel = math.min(targetLevel, math.max(0, math.floor(tonumber(cfg.upgradeTarget))))
                    end
                    local pendingRequest = pendingUpgradeRequests[unit]
                    if isFarm and pendingRequest then
                        pendingFarmUpgradeRequest = true
                    end
                    if level.Value < targetLevel then
                        local allowed = not (cfg and cfg.upgradeStartWave ~= nil and wave < cfg.upgradeStartWave)
                        if allowed and not pendingRequest then
                            local cost = GetNextUpgradeCost(unit)
                            local cash = GetInGameCash()
                            local activeVal = stats:FindFirstChild("active_attack")
                            local hasActive = activeVal and tostring(activeVal.Value) ~= "" and tostring(activeVal.Value) ~= "nil"
                            local needsBuffUnlock = IsPlacedBuffUnit(unit) and not hasActive
                            -- Only upgrades affordable with the current cash enter the
                            -- queue. Farm candidates receive priority, but an unaffordable
                            -- Farm does not prevent affordable non-Farm upgrades.
                            if cash == nil or (cost ~= math.huge and cost <= cash) then
                                table.insert(candidates, {
                                    unit = unit,
                                    cost = cost,
                                    farm = isFarm,
                                    buffUnlock = needsBuffUnlock,
                                    level = level.Value,
                                })
                            end
                        end
                    end
                end
            end

            -- Farm First must never lock the upgrade worker during Farm placement.
            -- Existing Farm units remain eligible for upgrades at all times; when
            -- Auto Upgrade Farm First is enabled, affordable Farm upgrades are
            -- selected ahead of non-Farm upgrades below. The placement worker can
            -- continue prioritizing additional Farm copies independently.

            -- Farm First is a priority, not a placement-phase lock:
            -- 1) Wait briefly for an already-sent Farm upgrade to resolve.
            -- 2) Choose an affordable Farm upgrade before any other unit.
            -- 3) If no Farm upgrade is affordable, allow another affordable unit.
            -- Every cycle checks current cash again, so Farm regains priority as
            -- soon as income makes its next upgrade affordable.
            if State.AutoUpgradeFarmFirst and pendingFarmUpgradeRequest then
                candidates = {}
                UpdateAutoPlayStatus("Waiting for Farm Upgrade Result", Color3.fromRGB(255, 190, 80))
            end

            if #candidates > 0 then
                local farmCandidates = {}
                local buffUnlockCandidates = {}
                local otherCandidates = {}
                for _, candidate in ipairs(candidates) do
                    if State.AutoUpgradeFarmFirst and candidate.farm then
                        table.insert(farmCandidates, candidate)
                    elseif candidate.buffUnlock then
                        table.insert(buffUnlockCandidates, candidate)
                    else
                        table.insert(otherCandidates, candidate)
                    end
                end
                if #farmCandidates > 0 then
                    candidates = farmCandidates
                elseif #buffUnlockCandidates > 0 then
                    candidates = buffUnlockCandidates
                else
                    candidates = otherCandidates
                end

                -- Auto Upgrade randomly selects among all currently affordable
                -- candidates instead of always choosing the cheapest upgrade.
                for i = #candidates, 2, -1 do
                    local j = math.random(1, i)
                    candidates[i], candidates[j] = candidates[j], candidates[i]
                end

                local target = candidates[1].unit
                local targetStats = target:FindFirstChild("_stats")
                local targetLevel = targetStats and targetStats:FindFirstChild("upgrade")
                local levelBefore = targetLevel and targetLevel.Value or 0
                -- Record before yielding so the unit can disappear mid-request safely.
                pendingUpgradeRequests[target] = { level = levelBefore, time = now }
                InvokeEndpoint("upgrade_unit_ingame", target)
            end
        else
            table.clear(pendingUpgradeRequests)
        end
        end)
        if not upgradeOk then
            warn("[OctoputHub] Upgrade worker error: " .. tostring(upgradeErr))
            task.wait(1)
        end
    end
end)

-- Adaptive Commander / Windsong / Elfy (Sylph) buff loop.
-- Elfy's static Units record omits the Verdant Enchantment active, but its
-- live UnitUpgrade UI exposes the active through _stats.active_attack. Resolve
-- and rotate that runtime active just like Commander and Windsong.
--
-- Loop rule per buff type (attack id):
--   buffEnd = lastGroupCast + D
--   cast ONE ready unit when tick() >= buffEnd - lead
-- Each unit's readiness uses its own cooldown (SPD after Curse), so units with
-- different Curse modifiers rotate correctly without overlapping buffs.
function DidUnitStartActiveCast(unit, stats, beforeLastCast, beforeTrackId)
    if not unit or not stats then return false end
    local lastCastValue = stats:FindFirstChild("last_active_cast")
    local liveCast = lastCastValue and tonumber(lastCastValue.Value) or 0
    if liveCast > (beforeLastCast or 0) + 0.01 then
        return true
    end
    local queuedValue = stats:FindFirstChild("active_queued_or_using")
    if queuedValue and queuedValue.Value == true then
        return true
    end
    local trackId = tonumber(unit:GetAttribute("client_track_active_attack_id")) or 0
    if trackId > (beforeTrackId or 0) then
        return true
    end
    if GetUnitOverheadReadyAttribute(unit) == false then
        return true
    end
    return false
end

function SendBuffActiveRequest(runtime, entry, now)
    BUFF_ROTATION_RUNTIME.requestBusy = true
    BUFF_ROTATION_RUNTIME.requestStarted = now
    runtime.lastRequest[entry.model] = now
    runtime.pending = { model = entry.model, time = now, before = entry.lastCast }
    task.spawn(function()
        local ok, err = pcall(function()
            local unit = entry.model
            local stats = unit and unit:FindFirstChild("_stats")
            if not unit or not unit.Parent or not stats then
                error("Buff unit is no longer deployed")
            end
            local CollectionService = game:GetService("CollectionService")
            if CollectionService:HasTag(unit, "dying_units") then
                error("Buff unit is dying")
            end
            -- Same request path as the game's ActiveButton / Auto Active
            -- (_use_active_endpoint -> EndpointsClient "use_active_attack").
            -- Actives with _sets_aoe_point need { aoe_point = position }.
            local lastCastValue = stats:FindFirstChild("last_active_cast")
            local beforeLastCast = lastCastValue and tonumber(lastCastValue.Value) or 0
            local beforeTrackId = tonumber(unit:GetAttribute("client_track_active_attack_id")) or 0

            local attack = GetAttacksData()[runtime.attackId]
            local pos = GetPlacedBuffUnitPosition(unit)
            if not pos and unit:FindFirstChild("HumanoidRootPart") then
                pos = unit.HumanoidRootPart.Position
            end
            local aoeParam = pos and { aoe_point = pos } or nil
            local needsAoePoint = type(attack) == "table" and attack._sets_aoe_point == true

            if needsAoePoint and aoeParam then
                InvokeEndpoint("use_active_attack", unit, aoeParam)
            else
                InvokeEndpoint("use_active_attack", unit)
            end

            task.wait(0.2)
            if unit and unit.Parent and stats and not DidUnitStartActiveCast(unit, stats, beforeLastCast, beforeTrackId) then
                -- Fallback if attack metadata was not yet synced and the server
                -- expects the opposite parameter shape (aoe_point vs nil).
                if not needsAoePoint and aoeParam then
                    InvokeEndpoint("use_active_attack", unit, aoeParam)
                elseif needsAoePoint then
                    InvokeEndpoint("use_active_attack", unit)
                end
            end

            -- Always record our own cast timestamp so units using global
            -- cooldown tracking (or where last_active_cast stays 0) rotate cleanly.
            BUFF_ROTATION_RUNTIME.ownCast[unit] = tick()
        end)
        if not ok then
            warn("[OctoputHub] Buff request failed: " .. tostring(err))
            if runtime.pending and runtime.pending.model == entry.model then
                runtime.pending = nil
            end
        end
        BUFF_ROTATION_RUNTIME.requestBusy = false
    end)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        local rotationOk, rotationErr = pcall(function()
            if not State.AutoBuffRotation then
                SetBuffRotationStatus("Auto Buff: Disabled", Color3.fromRGB(160, 160, 180))
                BUFF_ROTATION_RUNTIME.groups = {}
                BUFF_ROTATION_RUNTIME.requestBusy = false
                return
            end
            if IsInLobby() or not workspace:FindFirstChild("_UNITS") then
                SetBuffRotationStatus("Auto Buff: Waiting for match...", Color3.fromRGB(160, 160, 180))
                BUFF_ROTATION_RUNTIME.groups = {}
                BUFF_ROTATION_RUNTIME.requestBusy = false
                return
            end

            local now = tick()
            if BUFF_ROTATION_RUNTIME.requestBusy
                and now - (BUFF_ROTATION_RUNTIME.requestStarted or 0) > BUFF_ROTATION_REQUEST_TIMEOUT then
                -- A request that never returned must not block every buff group.
                BUFF_ROTATION_RUNTIME.requestBusy = false
            end

            local liveGroups, elfyInfo = GetBuffRotationGroups(now)
            local nextRuntimeGroups = {}
            local statusParts = {}
            local hasActionableUnits = false

            local ordered = {}
            for attackId, group in pairs(liveGroups) do
                if group and #group.units > 0 then
                    table.insert(ordered, group)
                end
            end

            for _, group in ipairs(ordered) do
                local attackId = group.attackId
                hasActionableUnits = true
                local runtime = BUFF_ROTATION_RUNTIME.groups[attackId]
                    or { attackId = attackId, lastRequest = {}, pending = nil }
                runtime.attackId = attackId

                local liveSet = {}
                local groupLastCast = 0
                for _, entry in ipairs(group.units) do
                    liveSet[entry.model] = true
                    if entry.lastCast <= now + 1 and entry.lastCast > groupLastCast then
                        groupLastCast = entry.lastCast
                    end
                end
                for unit in pairs(runtime.lastRequest) do
                    if not liveSet[unit] then
                        runtime.lastRequest[unit] = nil
                    end
                end

                -- Resolve the outstanding request: confirmed when the unit's
                -- last_active_cast moves, dropped when it timed out.
                local pending = runtime.pending
                if pending then
                    local pendingEntry = nil
                    for _, entry in ipairs(group.units) do
                        if entry.model == pending.model then
                            pendingEntry = entry
                            break
                        end
                    end
                    if not pendingEntry then
                        runtime.pending = nil
                    elseif pendingEntry.lastCast > (pending.before or 0) + 0.05 then
                        runtime.pending = nil
                    elseif now - pending.time > BUFF_ROTATION_PENDING_TIMEOUT then
                        runtime.pending = nil
                    end
                    pending = runtime.pending
                end

                local effectiveLastCast = groupLastCast
                if pending then
                    effectiveLastCast = math.max(effectiveLastCast, pending.time)
                end
                local buffEnd = effectiveLastCast + group.duration
                local castAt = buffEnd - (group.lead or 0)

                local ready = {}
                local nextReadyIn = math.huge
                for _, entry in ipairs(group.units) do
                    local busy, isReady, _, remaining = GetActiveAttackCooldownState(entry, now)
                    local lastRequest = runtime.lastRequest[entry.model] or -math.huge
                    if not busy and isReady and now - lastRequest >= BUFF_ROTATION_MIN_REQUEST_GAP then
                        table.insert(ready, entry)
                        nextReadyIn = 0
                    elseif not busy then
                        nextReadyIn = math.min(nextReadyIn, remaining)
                    end
                end
                -- Oldest cast first keeps the rotation order stable (A, B, C, A ...).
                table.sort(ready, function(a, b)
                    if math.abs(a.lastCast - b.lastCast) < 0.05 then
                        return tostring(a.uuid) < tostring(b.uuid)
                    end
                    return a.lastCast < b.lastCast
                end)

                local curseMode = GetBuffRotationCurseMode(group)
                local avgCooldown = group.averageCooldown < math.huge and group.averageCooldown or 0
                local formulaText
                if group.baseCooldown then
                    formulaText = string.format("CD %.1fs (base %gs x%.2f)", avgCooldown, group.baseCooldown, group.averageMultiplier or 1)
                else
                    formulaText = string.format("CD %.1fs", avgCooldown)
                end
                local capacityText = group.sustainable and "Loop OK"
                    or ("Need " .. tostring(group.requiredUnitsEstimate) .. " units")
                local waitText
                if pending then
                    waitText = "casting..."
                elseif now >= castAt then
                    waitText = nextReadyIn < math.huge and string.format("gap, ready %.1fs", nextReadyIn) or "gap"
                else
                    waitText = string.format("next %.1fs", castAt - now)
                end
                table.insert(statusParts, string.format("%s: %d units | %s | %s | buff %gs | %s | %s",
                    group.name, #group.units, curseMode, formulaText, group.duration, capacityText, waitText))

                group.castAt = castAt
                group.runtime = runtime
                group.ready = ready
                group.pending = pending
                nextRuntimeGroups[attackId] = runtime
            end

            -- The game client serializes active requests (one at a time); keep
            -- that behaviour and give the slot to the group that is most overdue.
            if not BUFF_ROTATION_RUNTIME.requestBusy then
                local best = nil
                for _, group in ipairs(ordered) do
                    if not group.pending and #group.ready > 0 and now >= group.castAt then
                        if not best or group.castAt < best.castAt then
                            best = group
                        end
                    end
                end
                if best then
                    SendBuffActiveRequest(best.runtime, best.ready[1], now)
                end
            end

            BUFF_ROTATION_RUNTIME.groups = nextRuntimeGroups
            local elfySuffix = ""
            if elfyInfo.withoutActive > 0 then
                elfySuffix = string.format(" | Elfy x%d upgrading to unlock active", elfyInfo.withoutActive)
            end
            if not hasActionableUnits then
                if elfyInfo.withoutActive > 0 then
                    SetBuffRotationStatus("Auto Buff: Elfy (Sylph) placed, upgrading to unlock Verdant Enchantment..." .. elfySuffix, Color3.fromRGB(255, 190, 100))
                else
                    SetBuffRotationStatus("Auto Buff: No placed Commander / Windsong / Elfy (Sylph) buff units detected.", Color3.fromRGB(160, 160, 180))
                end
            else
                SetBuffRotationStatus("Auto Buff: " .. table.concat(statusParts, "  ||  ") .. elfySuffix, Color3.fromRGB(100, 220, 160))
            end
        end)
        if not rotationOk then
            warn("[OctoputHub] Auto Buff Rotation error: " .. tostring(rotationErr))
            SetBuffRotationStatus("Auto Buff: Worker error (see executor console)", Color3.fromRGB(255, 100, 100))
            task.wait(0.75)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local workerOk, workerError = pcall(function()
        SuppressErrorNotifications()
        unitRefreshClock = unitRefreshClock + 0.5
        if unitRefreshClock >= 1 then
            unitRefreshClock = 0
            pcall(RefreshUnitConfigUI)
        end

        if not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
            SyncReplicatedGameData()
            local myUnits = GetPlayerUnits()
            local wave = GetCurrentWave()

            if State.AutoPlace then
                local equipped = EnrichEquipped(GetEquippedUnitList())
                if #equipped > 0 then
                    -- Farm First prioritizes Farm placement first, then Farm upgrades.
                    -- Other units remain eligible whenever the next Farm placement or
                    -- Farm upgrade cannot currently use the available cash.

                    -- Only consider units we can currently afford, so an expensive unit
                    -- never blocks cheaper ones from being placed.
                    local cashNow = GetInGameCash()

                    -- Once every configured Farm copy is on the field, an affordable
                    -- Farm upgrade gets first claim on the cash. Pause non-Farm placement
                    -- until that upgrade request resolves; if it is not affordable,
                    -- Auto Place remains free to spend cash on other eligible units.
                    local holdOtherPlacementForFarmUpgrade = false
                    if State.AutoUpgradeFarmFirst and State.AutoUpgrade then
                        local farmPlacementIncomplete = false
                        for _, info in ipairs(equipped) do
                            if IsFarmInfo(info) and CanPlaceConfigured(info, wave) then
                                farmPlacementIncomplete = true
                                break
                            end
                        end
                        if not farmPlacementIncomplete then
                            for unit in pairs(pendingUpgradeRequests) do
                                if unit and unit.Parent and IsFarmUnit(unit) then
                                    holdOtherPlacementForFarmUpgrade = true
                                    break
                                end
                            end
                            if not holdOtherPlacementForFarmUpgrade then
                                local nextFarmCost = GetNextFarmUpgradeCost(myUnits)
                                if nextFarmCost and cashNow ~= nil and nextFarmCost <= cashNow then
                                    holdOtherPlacementForFarmUpgrade = true
                                end
                            end
                        end
                    end

                    local eligible = {}
                    local now = tick()
                    for uuid, pending in pairs(pendingSpawnRequests) do
                        local info = nil
                        for _, equippedInfo in ipairs(equipped) do
                            if tostring(equippedInfo.uuid or "") == uuid then info = equippedInfo break end
                        end
                        local observed = info and CountPlacedInfo(info) or 0
                        if (pending.countBefore and observed > pending.countBefore) or now - pending.time > 4 then
                            pendingSpawnRequests[uuid] = nil
                        end
                    end

                    -- Auto Place always considers every affordable configured unit.
                    -- Farm First changes candidate priority only: it never blocks other
                    -- placements when the next Farm is unaffordable or has reached its cap.
                    local farmEligible = {}
                    local buffEligible = {}
                    local otherEligible = {}
                    for _, unitInfo in ipairs(equipped) do
                        local uuidKey = tostring(unitInfo.uuid or "")
                        if uuidKey ~= "" and not pendingSpawnRequests[uuidKey]
                            and (cashNow == nil or (tonumber(unitInfo.cost) or 0) <= cashNow)
                            and CanPlaceConfigured(unitInfo, wave) then
                            if State.AutoUpgradeFarmFirst and IsFarmInfo(unitInfo) then
                                table.insert(farmEligible, unitInfo)
                            elseif not holdOtherPlacementForFarmUpgrade then
                                if IsBuffUnitInfo(unitInfo) then
                                    table.insert(buffEligible, unitInfo)
                                else
                                    table.insert(otherEligible, unitInfo)
                                end
                            end
                        end
                    end

                    -- Prefer placing Farm units early. Next, establish the buff
                    -- cluster so combat units and buff units form one tight group.
                    if State.AutoUpgradeFarmFirst and #farmEligible > 0 then
                        eligible = farmEligible
                    elseif #buffEligible > 0 then
                        eligible = buffEligible
                        for _, info in ipairs(otherEligible) do
                            table.insert(eligible, info)
                        end
                    else
                        eligible = otherEligible
                    end

                    if #eligible > 0 then
                        -- Shuffle within the non-buff pool only when no buff unit is
                        -- waiting; keep buff units at the front of the queue so they
                        -- anchor the cluster tightly.
                        if #buffEligible == 0 or (State.AutoUpgradeFarmFirst and #farmEligible > 0) then
                            for i = #eligible, 2, -1 do
                                local j = math.random(1, i)
                                eligible[i], eligible[j] = eligible[j], eligible[i]
                            end
                        end
                        for _, chosen in ipairs(eligible) do
                            local placeIndex = #myUnits + 1
                            local cframe, kind = GetPlacementCFrameForInfo(placeIndex, chosen)
                            if cframe then
                                local countBefore = CountPlacedInfo(chosen)
                                local ok = InvokeEndpoint("spawn_unit", chosen.uuid, cframe)
                                if ok ~= false then
                                    pendingSpawnRequests[tostring(chosen.uuid)] = {
                                        time = now,
                                        unitId = chosen.unitId,
                                        countBefore = countBefore,
                                    }
                                end
                                break
                            end
                        end
                    end
                end
            else
                farmStall = { count = 0, lastChange = 0 }
                table.clear(pendingSpawnRequests)
            end

            UpdateAutoPlayStatus("Active in Match", Color3.fromRGB(70, 200, 255))
        else
            farmStall = { count = 0, lastChange = 0 }
            UpdateAutoPlayStatus("Idle (Waiting for Match)", Color3.fromRGB(160, 160, 180))
        end
        end)
        if not workerOk then
            -- Keep the automation loop alive if one game-state read fails.
            pcall(function()
                UpdateAutoPlayStatus("Auto Place Worker Error: " .. tostring(workerError), Color3.fromRGB(255, 100, 100))
            end)
            task.wait(0.5)
        end
    end
end)

lastMatchmakingRequest = 0
lastQuestClaim = 0
task.spawn(function()
    while true do
        task.wait(1.5)
        local mmOk, mmErr = pcall(function()

        TryAutoStart()

        local dataFolder = workspace:FindFirstChild("_DATA")
        local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
        HandleMatchEnd(gameFinished)

        if State.AutoFindMatch and not eventAutomationStopped then
            if IsInLobby() then
                HandlePopups()

                if IsMatchmaking() then
                    UpdateEventStatus("In Queue (Summer Hunt)...", Color3.fromRGB(70, 200, 255))
                else
                    UpdateEventStatus("Requesting Matchmaking...", Color3.fromRGB(255, 200, 70))
                    if os.clock() - lastMatchmakingRequest >= 5 then
                        lastMatchmakingRequest = os.clock()
                        InvokeEndpoint("request_matchmaking", EVENT_LEVEL_ID)
                    end
                end
            elseif not matchEndHandled then
                UpdateEventStatus("In Match (Summer Hunt)", Color3.fromRGB(100, 255, 100))
            end
        end

        if State.AutoPickCards then
            local roguelike = dataFolder and dataFolder:FindFirstChild("Roguelike")
            if roguelike and roguelike:FindFirstChild("WaitingForRoguelikeChoice") and roguelike.WaitingForRoguelikeChoice.Value == true then
                local cardGui = playerGui:FindFirstChild("CardSelectRoguelike")
                if cardGui and cardGui.Enabled then
                    local pageUI = cardGui:FindFirstChild("main")
                        and cardGui.main:FindFirstChild("pick")
                        and cardGui.main.pick:FindFirstChild("inner")
                        and cardGui.main.pick.inner:FindFirstChild("PageUI")
                    if pageUI then
                        local card = PickRoguelikeCard(pageUI)
                        if card then
                            InvokeEndpoint("select_roguelike_option", card.Name)
                        end
                    end
                end
            end
        end

        if State.AutoEventQuests and os.clock() - lastQuestClaim >= 15 then
            lastQuestClaim = os.clock()
            InvokeEndpoint("claim_summer2_map_board_lines")
        end
        end)
        if not mmOk then
            warn("[OctoputHub] Match/Start worker error: " .. tostring(mmErr))
            task.wait(1)
        end
    end
end)

-- Webhook end detection: follow Anime Adventures' actual ResultsUI lifecycle.
-- game.lua assigns ResultsUI.settings = p22 before enabling ResultsUI, while the
-- game_finished endpoint calls ResultsUI.show_results(p22). GameFinished is an
-- additional signal; neither signal requires a guessed result from _DATA.
webhookSent = false
webhookSending = false
webhookGameWasActive = false
webhookEndDetected = false
webhookRetryAt = 0
webhookDataFolder = nil
webhookCurrencyBefore = nil
webhookSecretRewardBefore = nil
webhookSecretRewardBaselineAvailable = false
webhookUnitLinesSnapshot = nil
webhookResultTitleAtStart = nil
webhookResultsVisibleAtStart = false
webhookResultSettingsAtStart = nil
webhookNextResultReadAt = 0

local initialDataForWebhook = workspace:FindFirstChild("_DATA")
local initialFinishedForWebhook = initialDataForWebhook and initialDataForWebhook:FindFirstChild("GameFinished")
local initialResultsForWebhook = playerGui:FindFirstChild("ResultsUI")
webhookFinishedLastValue = initialFinishedForWebhook ~= nil and initialFinishedForWebhook.Value == true
webhookResultsVisibleLast = initialResultsForWebhook ~= nil and initialResultsForWebhook.Enabled == true
webhookLastSentSettings = nil
webhookBoundGameFinished = nil
webhookBoundResultsGui = nil
webhookBoundResultTitle = nil
webhookMatchToken = 0

function StartWebhookEndSend(reason)
    if not webhookEndDetected or not State.WebhookOnEnd or webhookSent or webhookSending then
        return false
    end

    webhookSending = true
    local sendToken = webhookMatchToken
    local currencyBaseline = webhookCurrencyBefore and table.clone(webhookCurrencyBefore) or nil
    local secretBaseline = webhookSecretRewardBefore
    local secretAvailable = webhookSecretRewardBaselineAvailable
    local unitLinesSnapshot = webhookUnitLinesSnapshot
    local trackedPortalSnapshot = table.clone(skyPortalMatchDrops or {})

    print("[Octoput Hub Webhook] Sending match result. Trigger: " .. tostring(reason or "result"))
    task.spawn(function()
        local callOk, sendResult, sendError, retryDelay = pcall(SendEndWebhook, currencyBaseline, secretBaseline, secretAvailable, unitLinesSnapshot, trackedPortalSnapshot)
        -- A previous match's HTTP request may finish after a new match has begun.
        -- Never let that old task mutate the new match's send/retry state.
        if webhookMatchToken ~= sendToken then
            print("[Octoput Hub Webhook] Ignoring completion from an older match.")
            return
        end
        webhookSending = false
        if callOk and sendResult == true then
            webhookSent = true
            local finalDetails = GetResultDetails()
            webhookLastSentSettings = finalDetails and finalDetails.settings or nil
            print("[Octoput Hub Webhook] Match-end webhook confirmed sent.")
        else
            local failure = callOk and tostring(sendError or "SendEndWebhook returned false") or tostring(sendResult)
            warn("[Octoput Hub Webhook] Send failed: " .. failure)
            webhookRetryAt = os.clock() + math.clamp(tonumber(retryDelay) or 8, 3, 120)
        end
    end)
    return true
end

function MarkWebhookEnd(reason)
    if not webhookEndDetected then
        -- Commit the end state first. Optional snapshot readers must never block
        -- the webhook trigger if a folder/module disappears during match teardown.
        webhookEndDetected = true
        webhookGameWasActive = false
        local snapshotOk, snapshot = pcall(ReadMatchUnitLines)
        webhookUnitLinesSnapshot = snapshotOk and snapshot or nil
        if not snapshotOk then
            warn("[Octoput Hub Webhook] Unit snapshot failed: " .. tostring(snapshot))
        end
        print("[Octoput Hub Webhook] END DETECTED by " .. tostring(reason or "game result") .. ".")
    end
    StartWebhookEndSend(reason)
end

task.spawn(function()
    while true do
        task.wait(0.2)
        local loopOk, loopError = pcall(function()
            local dataFolder = workspace:FindFirstChild("_DATA")
            if dataFolder ~= webhookDataFolder then
                local previousFolder = webhookDataFolder
                local unresolvedMatch = (webhookGameWasActive and not webhookEndDetected)
                    or (webhookEndDetected and not webhookSent)
                    or (webhookSending and not webhookSent)

                webhookDataFolder = dataFolder
                webhookBoundGameFinished = nil
                webhookBoundResultsGui = nil
                webhookNextResultReadAt = 0

                if unresolvedMatch then
                    -- _DATA can be replaced during match teardown/replay. Keep the
                    -- previous match's baseline, token and pending send state so a
                    -- folder swap cannot silently discard an unfinished result.
                    warn("[Octoput Hub Webhook] _DATA changed while a match was unresolved; preserving pending match state.")
                else
                    -- Start a clean tracking slot only after the previous match has
                    -- been sent (or when no match was active).
                    webhookMatchToken = webhookMatchToken + 1
                    webhookGameWasActive = false
                    webhookEndDetected = false
                    webhookSent = false
                    webhookSending = false
                    webhookRetryAt = 0
                    webhookCurrencyBefore = nil
                    webhookSecretRewardBefore = nil
                    webhookSecretRewardBaselineAvailable = false
                    webhookUnitLinesSnapshot = nil
                    skyPortalMatchDrops = {}
                    webhookResultSettingsAtStart = nil
                end

                -- Never seed this edge from the replacement object: if it is
                -- already true when first observed, the polling pass must still
                -- treat it as a completion signal.
                webhookFinishedLastValue = false
                print("[Octoput Hub Webhook] _DATA reference changed; previous="
                    .. tostring(previousFolder) .. " current=" .. tostring(dataFolder)
                    .. " unresolved=" .. tostring(unresolvedMatch))
            end

            local gameStarted = dataFolder and dataFolder:FindFirstChild("GameStarted")
            local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
            local unitsFolder = workspace:FindFirstChild("_UNITS")
            local resultsGui = playerGui:FindFirstChild("ResultsUI")

            -- Bind to the game's real completion signals as well as polling.
            -- ResultsUI.show_results assigns settings before Enabled becomes true.
            if gameFinished ~= webhookBoundGameFinished then
                webhookBoundGameFinished = gameFinished
                if gameFinished then
                    gameFinished.Changed:Connect(function()
                        if webhookBoundGameFinished == gameFinished
                            and workspace:FindFirstChild("_DATA") == webhookDataFolder
                            and gameFinished.Value == true then
                            task.spawn(function()
                                task.wait(0.15)
                                MarkWebhookEnd("GameFinished.Changed")
                            end)
                        end
                    end)
                end
            end
            if resultsGui ~= webhookBoundResultsGui then
                webhookBoundResultsGui = resultsGui
                webhookBoundResultTitle = nil
                if resultsGui then
                    -- Anime Adventures game.lua calls ResultsUI.show_results(settings):
                    -- it assigns controller.settings, then changes Holder.Title.Text,
                    -- then enables the ScreenGui. Enabled may already be true during
                    -- replay/rematch, so listen to the actual result title as well.
                    local holder = resultsGui:FindFirstChild("Holder")
                    local titleLabel = holder and holder:FindFirstChild("Title")
                    if titleLabel and titleLabel:IsA("TextLabel") then
                        webhookBoundResultTitle = titleLabel
                        titleLabel:GetPropertyChangedSignal("Text"):Connect(function()
                            if webhookBoundResultsGui ~= resultsGui
                                or webhookBoundResultTitle ~= titleLabel
                                or playerGui:FindFirstChild("ResultsUI") ~= resultsGui then
                                return
                            end
                            local title = string.upper(tostring(titleLabel.Text or ""))
                            if title:find("VICTORY", 1, true) or title:find("DEFEAT", 1, true) then
                                task.spawn(function()
                                    task.wait(0.15)
                                    if webhookBoundResultsGui == resultsGui
                                        and webhookBoundResultTitle == titleLabel
                                        and titleLabel.Parent
                                        and resultsGui:FindFirstChild("Holder") == holder then
                                        MarkWebhookEnd("ResultsUI.Title.Text")
                                    end
                                end)
                            end
                        end)
                        -- Also catch a result screen that was already visible when
                        -- this monitor attached (e.g. the executor started late).
                        local initialTitle = string.upper(tostring(titleLabel.Text or ""))
                        if resultsGui.Enabled and holder.Visible
                            and (initialTitle:find("VICTORY", 1, true) or initialTitle:find("DEFEAT", 1, true)) then
                            task.defer(function()
                                if webhookBoundResultsGui == resultsGui
                                    and webhookBoundResultTitle == titleLabel then
                                    MarkWebhookEnd("ResultsUI.InitialTitle")
                                end
                            end)
                        end
                    end
                    resultsGui:GetPropertyChangedSignal("Enabled"):Connect(function()
                        if webhookBoundResultsGui == resultsGui
                            and playerGui:FindFirstChild("ResultsUI") == resultsGui
                            and resultsGui.Enabled == true then
                            task.spawn(function()
                                task.wait(0.1)
                                local details = GetResultDetails()
                                local title = string.upper(tostring(details.result or ""))
                                if title:find("VICTORY", 1, true) or title:find("DEFEAT", 1, true) then
                                    MarkWebhookEnd("ResultsUI.Enabled")
                                else
                                    -- Executor getgc access can be unavailable; the UI
                                    -- title is still written by game.lua before Enabled.
                                    local currentHolder = resultsGui:FindFirstChild("Holder")
                                    local currentTitle = currentHolder and currentHolder:FindFirstChild("Title")
                                    local visibleTitle = string.upper(tostring(currentTitle and currentTitle.Text or ""))
                                    if currentTitle and (visibleTitle:find("VICTORY", 1, true) or visibleTitle:find("DEFEAT", 1, true)) then
                                        MarkWebhookEnd("ResultsUI.Enabled.TitleFallback")
                                    end
                                end
                            end)
                        end
                    end)
                end
            end

            local resultsVisible = resultsGui ~= nil and resultsGui.Enabled == true
            local finished = gameFinished ~= nil and gameFinished.Value == true
            local finishedRising = finished and not webhookFinishedLastValue
            webhookFinishedLastValue = finished

            -- Read the result controller even while its ScreenGui is disabled.
            -- In BlackScreen / low-render mode, waiting for the UI to become visible
            -- can delay the result edge until the client receives fresh input.
            local resultDetails = {}
            -- getgc(true) is an expensive executor scan. Only inspect result
            -- controller tables near completion, and throttle the scan.
            if (resultsVisible or finished or webhookEndDetected)
                and os.clock() >= (webhookNextResultReadAt or 0) then
                webhookNextResultReadAt = os.clock() + 0.75
                local readOk, details = pcall(GetResultDetails)
                if readOk and type(details) == "table" then
                    resultDetails = details
                elseif not readOk then
                    warn("[Octoput Hub Webhook] Result read failed: " .. tostring(details))
                end
            end
            local resultTitle = string.upper(tostring(resultDetails and resultDetails.result or ""))
            local currentSettings = resultDetails and resultDetails.settings or nil
            local resultsRising = resultsVisible and not webhookResultsVisibleLast
            webhookResultsVisibleLast = resultsVisible

            -- A new ResultsUI settings table is the strongest signal: game.lua
            -- assigns p21.settings = p22 before showing the results ScreenGui.
            local freshResultSettings = currentSettings ~= nil
                and currentSettings ~= webhookResultSettingsAtStart
                and currentSettings ~= webhookLastSentSettings
            local hasResultTitle = resultTitle:find("VICTORY", 1, true) ~= nil
                or resultTitle:find("DEFEAT", 1, true) ~= nil
            -- A fresh settings payload with a definitive result is enough to
            -- confirm completion; do not require ResultsUI.Enabled to flip first.
            local resultScreenConfirmed = hasResultTitle
                and (freshResultSettings or (resultsVisible and resultsRising))

            -- GameStarted is the normal baseline point. If the monitor misses
            -- that edge, a fresh ResultsUI transition / GameFinished edge still
            -- sends the webhook rather than silently requiring active=true.
            local startedByFlag = gameStarted ~= nil and gameStarted.Value == true
            local startedByWorld = unitsFolder ~= nil and not IsInLobby() and not finished
            local isActive = (startedByFlag or startedByWorld) and not finished
            if isActive and not webhookGameWasActive then
                webhookMatchToken = webhookMatchToken + 1
                -- A new match owns a fresh send slot; older requests are token-isolated.
                webhookSending = false
                -- Mark the match active before optional inventory readers run.
                -- A transient getgc/profile error must not prevent end detection.
                webhookGameWasActive = true
                local baselineOk, currencySnapshot, secretSnapshot, secretAvailable =
                    pcall(CaptureWebhookCurrencyBaseline)
                if baselineOk then
                    webhookCurrencyBefore = currencySnapshot
                    webhookSecretRewardBefore = secretSnapshot
                    webhookSecretRewardBaselineAvailable = secretAvailable == true
                else
                    webhookCurrencyBefore = ReadPlayerCurrencies()
                    webhookSecretRewardBefore = nil
                    webhookSecretRewardBaselineAvailable = false
                    warn("[Octoput Hub Webhook] Baseline capture failed: " .. tostring(currencySnapshot))
                end
                webhookEndDetected = false
                webhookSent = false
                webhookRetryAt = 0
                webhookUnitLinesSnapshot = nil
                skyPortalMatchDrops = {}
                webhookResultTitleAtStart = resultTitle
                webhookResultsVisibleAtStart = resultsVisible
                webhookResultSettingsAtStart = currentSettings
                print("[Octoput Hub Webhook] Match start detected; reward baseline captured.")
            end

            local hasEnded = finishedRising or (finished and webhookGameWasActive) or resultScreenConfirmed
            if hasEnded and not webhookEndDetected then
                MarkWebhookEnd(resultTitle ~= "" and resultTitle or (finished and "GameFinished" or "ResultsUI"))
            end

            if webhookEndDetected and State.WebhookOnEnd and not webhookSent
                and not webhookSending and os.clock() >= webhookRetryAt then
                StartWebhookEndSend(finished and "GameFinished" or "ResultsUI")
            end
        end)
        if not loopOk then
            warn("[Octoput Hub Webhook] Monitor error: " .. tostring(loopError))
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Hide only the hub window after every feature, connection and hotkey is initialized.
-- Automation continues running in the background; Right Shift reopens the GUI.
if State.AutoHideGUIOnExecute then
    MainFrame.Visible = false
end

print("Octoput Hub UI Loaded Successfully! Auto Play, Webhook & Misc are ready.")
