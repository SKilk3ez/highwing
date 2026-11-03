-- [[ XT Hub Style GUI Script for Executor ]] --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("XT_Hub_UI") then
    playerGui:FindFirstChild("XT_Hub_UI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XT_Hub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 120
ScreenGui.Parent = playerGui

local BlackOverlay = Instance.new("Frame")
BlackOverlay.Name = "BlackScreenOverlay"
BlackOverlay.Size = UDim2.new(1, 0, 1, 0)
BlackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
BlackOverlay.BorderSizePixel = 0
BlackOverlay.Visible = false
BlackOverlay.ZIndex = 1
BlackOverlay.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 780, 0, 480)
MainFrame.Position = UDim2.new(0.5, -390, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
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

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 4)
SidebarList.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -185, 1, -45)
ContentArea.Position = UDim2.new(0, 175, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 11
ContentArea.Parent = MainFrame

local State = {
    AutoPlace = false,
    AutoUpgrade = false,
    AutoUpgradeFarmFirst = true,
    AutoUseAbility = false,
    AutoBuffChain = false,
    AutoBuffGriffith = false,
    PlaceRangeMin = 0,
    PlaceRangeMax = 100,
    AutoFindMatch = false,
    AutoEventQuests = false,
    AutoPickCards = false,
    AutoReplay = true,
    WebhookURL = "",
    WebhookOnEnd = false,
    BlackScreen = false,
}

local EVENT_LEVEL_ID = "summer2_event"

local function InvokeEndpoint(endpointName, ...)
    local ok, res = pcall(function(...)
        local loaderModule = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("Loader")
        if loaderModule then
            local Loader = require(loaderModule)
            local EndpointsClient = Loader.load_client_service(game, "EndpointsClient")
            if EndpointsClient and EndpointsClient.invoke_server then
                return EndpointsClient.invoke_server(endpointName, ...)
            end
        end
    end, ...)
    if ok and res ~= nil then
        return res
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

local function IsInLobby()
    return workspace:FindFirstChild("_LOBBIES") ~= nil
        or workspace:FindFirstChild("enel_ship") ~= nil
        or game.PlaceId == 8304191830
end

local function IsMatchmaking()
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

local function NormalizeName(text)
    return tostring(text or ""):lower():gsub("[%.%s_%-]", "")
end

local function IsFarmName(text)
    local id = NormalizeName(text)
    if id == "" then
        return false
    end
    return id:find("speedwagon", 1, true)
        or id:find("ceo", 1, true)
        or id:find("bulma", 1, true)
        or id:find("bulby", 1, true)
        or id:find("bulmy", 1, true)
        or id:find("nami", 1, true)
        or id:find("weathergirl", 1, true)
        or id:find("weathering", 1, true)
        or id:find("weather", 1, true)
end

local function IsGriffithName(text)
    local id = NormalizeName(text)
    if id == "" then
        return false
    end
    return id:find("griffith", 1, true)
        or id:find("griffin", 1, true)
        or id:find("femto", 1, true)
end

local function IsBuffName(text)
    local id = NormalizeName(text)
    if id == "" then
        return false
    end
    return id:find("erwin", 1, true)
        or id:find("commander", 1, true)
        or id:find("wendy", 1, true)
        or id:find("wanda", 1, true)
        or id:find("leafa", 1, true)
        or id:find("elfy", 1, true)
end

local function GetUnitId(unit)
    if not unit or not unit:FindFirstChild("_stats") then
        return ""
    end
    local idVal = unit._stats:FindFirstChild("id")
    if not idVal then
        return NormalizeName(unit.Name)
    end
    return NormalizeName(idVal.Value)
end

local function GetPlayerUnits()
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

local function IsFarmUnit(unit)
    if not unit then
        return false
    end
    if unit:FindFirstChild("_stats") then
        if unit._stats:FindFirstChild("farm_amount") then
            return true
        end
        local showFarm = unit._stats:FindFirstChild("_show_as_farm_unit")
        if showFarm and showFarm.Value == true then
            return true
        end
    end
    return IsFarmName(GetUnitId(unit)) or IsFarmName(unit.Name)
end

local function GetBuffChainGroup(unit)
    local id = GetUnitId(unit)
    if id:find("erwin", 1, true) or id:find("commander", 1, true) then
        return "erwin"
    elseif id:find("wendy", 1, true) or id:find("wanda", 1, true) then
        return "wendy"
    elseif id:find("leafa", 1, true) or id:find("elfy", 1, true) then
        return "elfy"
    end
    return nil
end

local function IsGriffithUnit(unit)
    return IsGriffithName(GetUnitId(unit)) or IsGriffithName(unit and unit.Name)
end

local function CanUseActiveAttack(unit)
    if not unit or not unit:FindFirstChild("_stats") then
        return false
    end
    local stats = unit._stats

    local isQueued = stats:FindFirstChild("active_queued_or_using")
    if isQueued and isQueued.Value == true then
        return false
    end

    local lastCast = stats:FindFirstChild("last_active_cast")
    local cd = stats:FindFirstChild("active_attack_cooldown")
    if lastCast and cd then
        return (tick() - lastCast.Value) >= cd.Value
    end
    return true
end

local function GetEquippedUnitList()
    local unitsList = {}

    local spawnGui = playerGui:FindFirstChild("spawn_units")
    local frame = spawnGui and spawnGui:FindFirstChild("Lives") and spawnGui.Lives:FindFirstChild("Frame")
    local unitsGrid = frame and frame:FindFirstChild("Units")
    if unitsGrid then
        for _, slotFrame in ipairs(unitsGrid:GetChildren()) do
            local uuid = slotFrame:GetAttribute("_equipped_frame_unit_uuid")
            if uuid then
                local cost = 0
                if slotFrame:FindFirstChild("Cost") and slotFrame.Cost:FindFirstChild("text") then
                    cost = tonumber(slotFrame.Cost.text.Text) or 0
                end
                local unitName = slotFrame:FindFirstChild("name") and slotFrame.name.Text or "Unit"
                table.insert(unitsList, {
                    uuid = uuid,
                    cost = cost,
                    name = unitName,
                    slot = slotFrame.Name
                })
            end
        end
    end

    if #unitsList == 0 then
        pcall(function()
            local Loader = require(ReplicatedStorage.src.Loader)
            local ucs = Loader.load_client_service(game, "UnitCollectionServiceClient")
            if ucs and ucs.get_equipped_units then
                for slot, uuid in pairs(ucs.get_equipped_units()) do
                    table.insert(unitsList, {
                        uuid = uuid,
                        cost = 0,
                        name = "Unit",
                        slot = tostring(slot)
                    })
                end
            end
        end)
    end

    return unitsList
end

local function GetPath1Lane()
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

local function GetPathPoints(lane)
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

local function GetPointOnPolyline(points, alpha)
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

local function GetPlacementCFrame(index)
    local lane = GetPath1Lane()
    local points = lane and GetPathPoints(lane) or {}
    local minP = math.clamp(tonumber(State.PlaceRangeMin) or 0, 0, 100)
    local maxP = math.clamp(tonumber(State.PlaceRangeMax) or 100, 0, 100)
    if minP > maxP then
        minP, maxP = maxP, minP
    end

    local alpha
    if maxP <= minP then
        alpha = minP / 100
    else
        local spread = ((index - 1) % 8) / 7
        alpha = (minP + (maxP - minP) * spread) / 100
    end

    local pos, look
    if #points >= 2 then
        pos, look = GetPointOnPolyline(points, alpha)
        local right = look:Cross(Vector3.new(0, 1, 0))
        if right.Magnitude < 0.01 then
            right = Vector3.new(1, 0, 0)
        else
            right = right.Unit
        end
        local side = (index % 2 == 0) and 1 or -1
        local row = math.floor((index - 1) / 8)
        pos = pos + right * (6 + row * 3) * side + Vector3.new(0, 0.5, 0)
    else
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return nil
        end
        local angle = (index * 45) * (math.pi / 180)
        local distance = 6 + math.floor(index / 8) * 5
        pos = hrp.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        look = hrp.CFrame.LookVector
    end

    local rayOrigin = pos + Vector3.new(0, 12, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, workspace:FindFirstChild("_UNITS") }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -40, 0), rayParams)
    local finalPos = hit and hit.Position or pos
    return CFrame.new(finalPos, finalPos + Vector3.new(look.X, 0, look.Z))
end

local function ReadNumberValue(container, keywords)
    if not container then
        return nil
    end
    for _, child in ipairs(container:GetChildren()) do
        local name = NormalizeName(child.Name)
        for _, key in ipairs(keywords) do
            if name:find(key, 1, true) then
                if child:IsA("NumberValue") or child:IsA("IntValue") or child:IsA("StringValue") then
                    local n = tonumber(child.Value)
                    if n then
                        return n
                    end
                end
            end
        end
    end
    return nil
end

local function GetGriffithSacrificePercent(unit)
    if not unit then
        return 0
    end
    local id = GetUnitId(unit)
    if id == "femto" or id:find("femtoegg", 1, true) then
        return 100
    end

    local keys = { "sacrifice", "eclipse", "unique", "charge", "meter", "percent", "stack" }
    local fromStats = ReadNumberValue(unit:FindFirstChild("_stats"), keys)
    if fromStats then
        if fromStats <= 1 then
            return fromStats * 100
        end
        return math.clamp(fromStats, 0, 100)
    end
    local fromBuffs = ReadNumberValue(unit:FindFirstChild("_buffs"), keys)
    if fromBuffs then
        if fromBuffs <= 1 then
            return fromBuffs * 100
        end
        return math.clamp(fromBuffs, 0, 100)
    end

    for _, gui in ipairs(unit:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = tostring(gui.Text or "")
            local pct = text:match("(%d+)%s*%%")
            if pct then
                return math.clamp(tonumber(pct) or 0, 0, 100)
            end
        end
    end
    return 0
end

local function CountCategory(myUnits, pred)
    local n = 0
    for _, u in ipairs(myUnits) do
        if pred(u) then
            n = n + 1
        end
    end
    return n
end

local function HttpPost(url, body)
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

local function SendEndWebhook()
    local url = tostring(State.WebhookURL or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" or not url:find("discord", 1, true) then
        return
    end

    local data = workspace:FindFirstChild("_DATA")
    local result = "Ended"
    if data then
        local won = data:FindFirstChild("Won") or data:FindFirstChild("Victory") or data:FindFirstChild("GameWon")
        if won then
            result = (won.Value == true) and "Victory" or "Defeat"
        end
        local wave = data:FindFirstChild("Wave") or data:FindFirstChild("CurrentWave")
        if wave then
            result = result .. " | Wave " .. tostring(wave.Value)
        end
    end

    local body = HttpService:JSONEncode({
        username = "Octoput Hub",
        embeds = {{
            title = "Stage Ended",
            description = string.format("**Player:** %s\n**Result:** %s", player.Name, result),
            color = 5814783,
            timestamp = DateTime.now():ToIsoDate(),
        }},
    })
    pcall(HttpPost, url, body)
end

local blackscreenConn
local savedQuality
local function SetInstanceHidden(inst, hidden)
    if inst:IsA("BasePart") then
        inst.LocalTransparencyModifier = hidden and 1 or 0
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        inst.Transparency = hidden and 1 or 0
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
        inst.Enabled = not hidden
    end
end

local function ApplyBlackScreen(enabled)
    BlackOverlay.Visible = enabled
    if blackscreenConn then
        blackscreenConn:Disconnect()
        blackscreenConn = nil
    end

    pcall(function()
        if enabled then
            savedQuality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            local gs = UserSettings():GetService("UserGameSettings")
            gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        elseif savedQuality then
            settings().Rendering.QualityLevel = savedQuality
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

local function SuppressErrorNotifications()
    local msg = playerGui:FindFirstChild("MessageGui")
    if msg then
        for _, folderName in ipairs({ "messages", "messages_quick", "top_messages" }) do
            local folder = msg:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("GuiObject") and child.Name ~= "Configuration" and child.Name ~= "message_templates" then
                        child:Destroy()
                    end
                end
            end
        end
    end

    local notifWindows = playerGui:FindFirstChild("NotificationWindows")
    if notifWindows then
        local list = notifWindows:FindFirstChild("List")
        if list then
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "Notifications" then
                    child:Destroy()
                end
            end
        end
    end
end

local tabs = {}
local function CreateTab(name, layoutOrder)
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

local function CreateToggle(parent, title, stateKey, layoutOrder, callback)
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
    SwitchBtn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(210, 70, 170) or Color3.fromRGB(45, 45, 58)
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
            TweenService:Create(SwitchBtn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(210, 70, 170) }):Play()
            TweenService:Create(Indicator, tweenInfo, { Position = UDim2.new(1, -19, 0.5, -8) }):Play()
        else
            TweenService:Create(SwitchBtn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(45, 45, 58) }):Play()
            TweenService:Create(Indicator, tweenInfo, { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
        end

        if callback then
            task.spawn(callback, isON)
        end
    end)

    return ToggleContainer
end

local function CreateTextBox(parent, title, placeholder, layoutOrder, onChanged)
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
    Input.Text = ""
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

local function CreateRangeSlider(parent, layoutOrder)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -10, 0, 92)
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
    Label.Text = "Place Range (Path 1)"
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = Card

    local Bar = Instance.new("Frame")
    Bar.Name = "Bar"
    Bar.Size = UDim2.new(1, -24, 0, 8)
    Bar.Position = UDim2.new(0, 12, 0, 38)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 13
    Bar.Parent = Card

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 14
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local function MakeHandle()
        local handle = Instance.new("TextButton")
        handle.Size = UDim2.new(0, 16, 0, 16)
        handle.AnchorPoint = Vector2.new(0.5, 0.5)
        handle.Position = UDim2.new(0, 0, 0.5, 0)
        handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        handle.Text = ""
        handle.AutoButtonColor = false
        handle.ZIndex = 15
        handle.Parent = Bar
        local hc = Instance.new("UICorner")
        hc.CornerRadius = UDim.new(1, 0)
        hc.Parent = handle
        return handle
    end

    local MinHandle = MakeHandle()
    local MaxHandle = MakeHandle()

    local MinBox = Instance.new("TextBox")
    MinBox.Size = UDim2.new(0, 56, 0, 24)
    MinBox.Position = UDim2.new(0, 12, 1, -30)
    MinBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    MinBox.Text = "0"
    MinBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    MinBox.TextSize = 12
    MinBox.Font = Enum.Font.Gotham
    MinBox.ClearTextOnFocus = false
    MinBox.ZIndex = 13
    MinBox.Parent = Card

    local MaxBox = Instance.new("TextBox")
    MaxBox.Size = UDim2.new(0, 56, 0, 24)
    MaxBox.Position = UDim2.new(1, -68, 1, -30)
    MaxBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    MaxBox.Text = "100"
    MaxBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    MaxBox.TextSize = 12
    MaxBox.Font = Enum.Font.Gotham
    MaxBox.ClearTextOnFocus = false
    MaxBox.ZIndex = 13
    MaxBox.Parent = Card

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 4)
    MinCorner.Parent = MinBox
    local MaxCorner = Instance.new("UICorner")
    MaxCorner.CornerRadius = UDim.new(0, 4)
    MaxCorner.Parent = MaxBox

    local Hint = Instance.new("TextLabel")
    Hint.Size = UDim2.new(1, -140, 0, 24)
    Hint.Position = UDim2.new(0, 76, 1, -30)
    Hint.BackgroundTransparency = 1
    Hint.Text = "0% spawn  →  100% base"
    Hint.TextColor3 = Color3.fromRGB(140, 140, 160)
    Hint.TextSize = 11
    Hint.Font = Enum.Font.Gotham
    Hint.ZIndex = 13
    Hint.Parent = Card

    local dragging = nil

    local function Refresh()
        local minP = math.clamp(State.PlaceRangeMin, 0, 100)
        local maxP = math.clamp(State.PlaceRangeMax, 0, 100)
        if minP > maxP then
            minP, maxP = maxP, minP
            State.PlaceRangeMin, State.PlaceRangeMax = minP, maxP
        end
        MinHandle.Position = UDim2.new(minP / 100, 0, 0.5, 0)
        MaxHandle.Position = UDim2.new(maxP / 100, 0, 0.5, 0)
        Fill.Position = UDim2.new(minP / 100, 0, 0, 0)
        Fill.Size = UDim2.new((maxP - minP) / 100, 0, 1, 0)
        if not MinBox:IsFocused() then
            MinBox.Text = tostring(math.floor(minP + 0.5))
        end
        if not MaxBox:IsFocused() then
            MaxBox.Text = tostring(math.floor(maxP + 0.5))
        end
    end

    local function PercentFromX(x)
        local absPos = Bar.AbsolutePosition.X
        local absSize = math.max(Bar.AbsoluteSize.X, 1)
        return math.clamp(math.floor(((x - absPos) / absSize) * 100 + 0.5), 0, 100)
    end

    MinHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = "min"
        end
    end)
    MaxHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = "max"
        end
    end)
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pct = PercentFromX(input.Position.X)
            if math.abs(pct - State.PlaceRangeMin) <= math.abs(pct - State.PlaceRangeMax) then
                State.PlaceRangeMin = pct
                dragging = "min"
            else
                State.PlaceRangeMax = pct
                dragging = "max"
            end
            Refresh()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local pct = PercentFromX(input.Position.X)
            if dragging == "min" then
                State.PlaceRangeMin = math.min(pct, State.PlaceRangeMax)
            else
                State.PlaceRangeMax = math.max(pct, State.PlaceRangeMin)
            end
            Refresh()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = nil
        end
    end)

    local function ApplyBox(box, isMin)
        local n = tonumber(box.Text)
        if not n then
            Refresh()
            return
        end
        n = math.clamp(math.floor(n + 0.5), 0, 100)
        if isMin then
            State.PlaceRangeMin = n
        else
            State.PlaceRangeMax = n
        end
        Refresh()
    end

    MinBox.FocusLost:Connect(function()
        ApplyBox(MinBox, true)
    end)
    MaxBox.FocusLost:Connect(function()
        ApplyBox(MaxBox, false)
    end)

    Refresh()
    return Card
end

local AutoPlayPage = CreateTab("Auto Play", 1)
local EventPage = CreateTab("Event", 2)
local WebhookPage = CreateTab("Webhook", 3)
local MiscPage = CreateTab("Misc", 4)

tabs["Auto Play"].Page.Visible = true
tabs["Auto Play"].Button.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
tabs["Auto Play"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

local AutoPlayStatusCard = Instance.new("Frame")
AutoPlayStatusCard.Size = UDim2.new(1, -10, 0, 38)
AutoPlayStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
AutoPlayStatusCard.LayoutOrder = 0
AutoPlayStatusCard.ZIndex = 12
AutoPlayStatusCard.Parent = AutoPlayPage

local AutoPlayStatusCorner = Instance.new("UICorner")
AutoPlayStatusCorner.CornerRadius = UDim.new(0, 6)
AutoPlayStatusCorner.Parent = AutoPlayStatusCard

local AutoPlayStatusLabel = Instance.new("TextLabel")
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

local function UpdateAutoPlayStatus(text, color)
    if AutoPlayStatusLabel then
        AutoPlayStatusLabel.Text = "Auto Play: " .. text
        if color then
            AutoPlayStatusLabel.TextColor3 = color
        end
    end
end

CreateToggle(AutoPlayPage, "Auto Place Units", "AutoPlace", 1)
CreateRangeSlider(AutoPlayPage, 2)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 3)
CreateToggle(AutoPlayPage, "Auto Upgrade Farm First", "AutoUpgradeFarmFirst", 4)
CreateToggle(AutoPlayPage, "Auto Use Ability", "AutoUseAbility", 5)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Erwin / Wanda / Elfy)", "AutoBuffChain", 6)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Griffith)", "AutoBuffGriffith", 7)

local EventStatusCard = Instance.new("Frame")
EventStatusCard.Size = UDim2.new(1, -10, 0, 38)
EventStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
EventStatusCard.LayoutOrder = 0
EventStatusCard.ZIndex = 12
EventStatusCard.Parent = EventPage

local EventStatusCorner = Instance.new("UICorner")
EventStatusCorner.CornerRadius = UDim.new(0, 6)
EventStatusCorner.Parent = EventStatusCard

local EventStatusLabel = Instance.new("TextLabel")
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

local function UpdateEventStatus(text, color)
    if EventStatusLabel then
        EventStatusLabel.Text = "Target: Summer Hunt | " .. text
        if color then
            EventStatusLabel.TextColor3 = color
        end
    end
end

local function HandlePopups()
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
            if mmBtn and mmBtn.Visible then
                if typeof(firesignal) == "function" then
                    firesignal(mmBtn.MouseButton1Click)
                elseif typeof(getconnections) == "function" then
                    for _, c in ipairs(getconnections(mmBtn.MouseButton1Click)) do
                        c:Fire()
                    end
                else
                    InvokeEndpoint("request_matchmaking", EVENT_LEVEL_ID)
                end
            end
        end
    end
end

CreateToggle(EventPage, "Auto Find Match (Summer Hunt)", "AutoFindMatch", 1, function(isON)
    if isON then
        UpdateEventStatus("Starting Matchmaking...", Color3.fromRGB(255, 200, 70))
        if IsInLobby() and not IsMatchmaking() then
            InvokeEndpoint("request_matchmaking", EVENT_LEVEL_ID)
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
CreateToggle(EventPage, "Auto Replay Match", "AutoReplay", 4)

CreateTextBox(WebhookPage, "Discord Webhook URL", "https://discord.com/api/webhooks/...", 1, function(text)
    State.WebhookURL = text
end)
CreateToggle(WebhookPage, "Send webhook when ending", "WebhookOnEnd", 2)

CreateToggle(MiscPage, "Blackscreen (reduce 3D render)", "BlackScreen", 1, function(isON)
    ApplyBlackScreen(isON)
end)

local BuffChains = {
    erwin = { lastCast = 0 },
    wendy = { lastCast = 0 },
    elfy = { lastCast = 0 },
}

local farmStall = { count = 0, lastChange = 0 }

task.spawn(function()
    while true do
        task.wait(0.5)
        SuppressErrorNotifications()

        if not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
            local myUnits = GetPlayerUnits()

            if State.AutoPlace then
                local equipped = GetEquippedUnitList()
                if #equipped > 0 then
                    local partyHasGriffith = false
                    local partyHasFarm = false
                    for _, info in ipairs(equipped) do
                        if IsGriffithName(info.name) then
                            partyHasGriffith = true
                        end
                        if IsFarmName(info.name) then
                            partyHasFarm = true
                        end
                    end

                    local useGriffithOrder = State.AutoBuffGriffith and partyHasGriffith
                    local farmCount = CountCategory(myUnits, IsFarmUnit)
                    local griffithCount = CountCategory(myUnits, IsGriffithUnit)
                    local sacrifice = 0
                    for _, u in ipairs(myUnits) do
                        if IsGriffithUnit(u) then
                            sacrifice = math.max(sacrifice, GetGriffithSacrificePercent(u))
                        end
                    end

                    if farmCount ~= farmStall.count then
                        farmStall.count = farmCount
                        farmStall.lastChange = tick()
                    elseif farmStall.lastChange == 0 then
                        farmStall.lastChange = tick()
                    end
                    local farmElapsed = tick() - farmStall.lastChange
                    local farmComplete = (farmCount > 0 and farmElapsed >= 4) or farmElapsed >= 15

                    local function CanPlaceInfo(info)
                        if not useGriffithOrder then
                            return true
                        end
                        local isFarm = IsFarmName(info.name)
                        local isGriff = IsGriffithName(info.name)
                        local isBuff = IsBuffName(info.name)

                        if partyHasFarm and not farmComplete then
                            return isFarm
                        end
                        if griffithCount < 1 then
                            return isGriff
                        end
                        if sacrifice < 100 then
                            return isBuff
                        end
                        return not isGriff
                    end

                    local placeIndex = #myUnits
                    for _, unitInfo in ipairs(equipped) do
                        if CanPlaceInfo(unitInfo) then
                            if not (useGriffithOrder and IsGriffithName(unitInfo.name) and griffithCount >= 1) then
                                placeIndex = placeIndex + 1
                                local cframe = GetPlacementCFrame(placeIndex)
                                if cframe then
                                    InvokeEndpoint("spawn_unit", unitInfo.uuid, cframe)
                                end
                                if useGriffithOrder and IsGriffithName(unitInfo.name) then
                                    break
                                end
                            end
                        end
                    end
                end
            else
                farmStall = { count = 0, lastChange = 0 }
            end

            if State.AutoUpgrade and #myUnits > 0 then
                local upgradable = {}
                for _, u in ipairs(myUnits) do
                    if u._stats:FindFirstChild("upgrade") and u._stats:FindFirstChild("max_upgrade") then
                        if u._stats.upgrade.Value < u._stats.max_upgrade.Value then
                            table.insert(upgradable, u)
                        end
                    end
                end

                if #upgradable > 0 then
                    if State.AutoUpgradeFarmFirst then
                        table.sort(upgradable, function(a, b)
                            local aFarm = IsFarmUnit(a)
                            local bFarm = IsFarmUnit(b)
                            if aFarm and not bFarm then
                                return true
                            elseif not aFarm and bFarm then
                                return false
                            end
                            return a._stats.upgrade.Value < b._stats.upgrade.Value
                        end)
                    end
                    InvokeEndpoint("upgrade_unit_ingame", upgradable[1])
                end
            end

            if State.AutoBuffChain and #myUnits > 0 then
                local groups = {
                    erwin = {},
                    wendy = {},
                    elfy = {},
                }

                for _, u in ipairs(myUnits) do
                    local g = GetBuffChainGroup(u)
                    if g and groups[g] then
                        table.insert(groups[g], u)
                    end
                end

                local now = tick()
                for groupName, units in pairs(groups) do
                    if #units > 0 then
                        local chain = BuffChains[groupName]
                        if now - chain.lastCast >= 29.5 then
                            for _, u in ipairs(units) do
                                if CanUseActiveAttack(u) then
                                    InvokeEndpoint("use_active_attack", u)
                                    chain.lastCast = now
                                    UpdateAutoPlayStatus("Buff 100%: Activated " .. groupName, Color3.fromRGB(100, 255, 100))
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if State.AutoBuffGriffith and #myUnits > 0 then
                for _, u in ipairs(myUnits) do
                    if IsGriffithUnit(u) and CanUseActiveAttack(u) then
                        InvokeEndpoint("use_active_attack", u)
                        UpdateAutoPlayStatus("Griffith Buff 100% Activated!", Color3.fromRGB(255, 215, 0))
                    end
                end
            end

            if State.AutoUseAbility and #myUnits > 0 then
                for _, u in ipairs(myUnits) do
                    local isChain = State.AutoBuffChain and (GetBuffChainGroup(u) ~= nil)
                    local isGriffith = State.AutoBuffGriffith and IsGriffithUnit(u)
                    if not isChain and not isGriffith then
                        if CanUseActiveAttack(u) then
                            InvokeEndpoint("use_active_attack", u)
                        end
                    end
                end
            end

            UpdateAutoPlayStatus("Active in Match", Color3.fromRGB(70, 200, 255))
        else
            farmStall = { count = 0, lastChange = 0 }
            UpdateAutoPlayStatus("Idle (Waiting for Match)", Color3.fromRGB(160, 160, 180))
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)

        if State.AutoFindMatch then
            if IsInLobby() then
                HandlePopups()

                if IsMatchmaking() then
                    UpdateEventStatus("In Queue (Summer Hunt)...", Color3.fromRGB(70, 200, 255))
                else
                    UpdateEventStatus("Requesting Matchmaking...", Color3.fromRGB(255, 200, 70))
                    InvokeEndpoint("request_matchmaking", EVENT_LEVEL_ID)
                end
            else
                UpdateEventStatus("In Match (Summer Hunt)", Color3.fromRGB(100, 255, 100))

                local dataFolder = workspace:FindFirstChild("_DATA")
                local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
                if gameFinished and gameFinished.Value == true then
                    if State.AutoReplay then
                        UpdateEventStatus("Match Finished! Voting Replay...", Color3.fromRGB(255, 170, 0))
                        task.wait(2.5)
                        InvokeEndpoint("set_game_finished_vote", "replay")

                        task.wait(8)
                        if gameFinished and gameFinished.Value == true then
                            UpdateEventStatus("Returning to Lobby for Next Match...", Color3.fromRGB(255, 100, 100))
                            InvokeEndpoint("teleport_back_to_lobby")
                        end
                    else
                        UpdateEventStatus("Returning to Lobby...", Color3.fromRGB(255, 100, 100))
                        task.wait(2.5)
                        InvokeEndpoint("teleport_back_to_lobby")
                    end
                end
            end
        end

        if State.AutoPickCards then
            local dataFolder = workspace:FindFirstChild("_DATA")
            local roguelike = dataFolder and dataFolder:FindFirstChild("Roguelike")
            if roguelike and roguelike:FindFirstChild("WaitingForRoguelikeChoice") and roguelike.WaitingForRoguelikeChoice.Value == true then
                local cardGui = playerGui:FindFirstChild("CardSelectRoguelike")
                if cardGui and cardGui.Enabled then
                    local pageUI = cardGui:FindFirstChild("main")
                        and cardGui.main:FindFirstChild("pick")
                        and cardGui.main.pick:FindFirstChild("inner")
                        and cardGui.main.pick.inner:FindFirstChild("PageUI")
                    if pageUI then
                        for _, card in ipairs(pageUI:GetChildren()) do
                            if card:IsA("GuiObject") and card.Visible and card.Name ~= "" then
                                InvokeEndpoint("select_roguelike_option", card.Name)
                                break
                            end
                        end
                    end
                end
            end
        end

        if State.AutoEventQuests then
            InvokeEndpoint("claim_summer2_map_board_lines")
        end
    end
end)

local webhookSent = false
task.spawn(function()
    while true do
        task.wait(1)
        local dataFolder = workspace:FindFirstChild("_DATA")
        local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
        if gameFinished and gameFinished.Value == true then
            if not webhookSent and State.WebhookOnEnd then
                webhookSent = true
                task.spawn(SendEndWebhook)
            end
        else
            webhookSent = false
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("XT Hub UI Loaded Successfully! Auto Play, Webhook & Misc are ready.")
