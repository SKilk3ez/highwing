-- [[ XT Hub Style GUI Script for Executor ]] --
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ป้องกันการสร้างซ้ำ
if playerGui:FindFirstChild("XT_Hub_UI") then
    playerGui:FindFirstChild("XT_HUB_UI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XT_Hub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- 1. Main Window (กรอบหลักสีเข้ม)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 780, 0, 480)
MainFrame.Position = UDim2.new(0.5, -390, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Header Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 0, 35)
TitleLabel.Position = UDim2.new(0, 15, 0, 8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Octoput_Hub"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- 2. Sidebar (แถบเมนูด้านซ้าย)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Sidebar.BorderSizePixel = 0
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

-- 3. Content Area (พื้นที่เนื้อหาฝั่งขวา)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -185, 1, -45)
ContentArea.Position = UDim2.new(0, 175, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- State จัดเก็บสถานะการเปิด-ปิดระบบทั้งหมด
local State = {
    -- Auto Play
    AutoPlace = false,
    AutoUpgrade = false,
    AutoUpgradeFarmFirst = true,
    AutoUseAbility = false,
    AutoBuffChain = false,
    AutoBuffGriffith = false,

    -- Event (Summer Hunt)
    AutoFindMatch = false,
    AutoEventQuests = false,
    AutoPickCards = false,
    AutoReplay = true,
}

-- ID ของ Event Summer Hunt ตามโครงสร้างของเกม Anime Adventures
local EVENT_LEVEL_ID = "summer2_event"

-- ฟังก์ชันสำหรับส่งคำสั่งผ่าน Endpoint ของเกม
local function InvokeEndpoint(endpointName, ...)
    -- วิธีที่ 1: เรียกผ่าน Loader / EndpointsClient (ระบบหลักของเกม)
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

    -- วิธีที่ 2: เรียกตรงผ่าน RemoteFunction / RemoteEvent ใน ReplicatedStorage.endpoints.client_to_server
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

-- เช็คว่าอยู่ใน Lobby หรือไม่
local function IsInLobby()
    return workspace:FindFirstChild("_LOBBIES") ~= nil 
        or workspace:FindFirstChild("enel_ship") ~= nil 
        or game.PlaceId == 8304191830
end

-- เช็คว่ากำลังค้นหาห้องอยู่หรือไม่
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

-- ดึงยูนิตทั้งหมดที่เป็นของผู้เล่นปัจจุบันในแมตช์
local function GetPlayerUnits()
    local myUnits = {}
    local unitsFolder = workspace:FindFirstChild("_UNITS")
    if not unitsFolder then return myUnits end

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

-- ตรวจสอบว่าเป็นยูนิตฟาร์มเงินหรือไม่ (Speedwagon, Bulma, Nami ฯลฯ)
local function IsFarmUnit(unit)
    if not unit or not unit:FindFirstChild("_stats") then return false end
    local idVal = unit._stats:FindFirstChild("id")
    if not idVal then return false end
    local id = tostring(idVal.Value):lower()
    
    if id:find("speedwagon") or id:find("bulma") or id:find("nami") then
        return true
    end
    return false
end

-- ตรวจสอบยูนิตประเภทบัฟต่อเนื่อง 100% (Erwin, Wanda/Wendy, Elfy)
local function GetBuffChainGroup(unit)
    if not unit or not unit:FindFirstChild("_stats") then return nil end
    local idVal = unit._stats:FindFirstChild("id")
    if not idVal then return nil end
    local id = tostring(idVal.Value):lower()
    
    if id:find("erwin") then
        return "erwin"
    elseif id:find("wendy") or id:find("wanda") then
        return "wendy"
    elseif id:find("leafa") or id:find("elfy") then
        return "elfy"
    end
    return nil
end

-- ตรวจสอบยูนิต Griffith / Femto
local function IsGriffithUnit(unit)
    if not unit or not unit:FindFirstChild("_stats") then return false end
    local idVal = unit._stats:FindFirstChild("id")
    if not idVal then return false end
    local id = tostring(idVal.Value):lower()
    
    if id:find("griffith") or id:find("femto") then
        return true
    end
    return false
end

-- ตรวจสอบว่าสามารถกดใช้สกิล (Active Attack) ได้หรือไม่
local function CanUseActiveAttack(unit)
    if not unit or not unit:FindFirstChild("_stats") then return false end
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

-- ดึงรายชื่อยูนิตที่สวมใส่ (Equipped Units)
local function GetEquippedUnitList()
    local unitsList = {}
    
    -- วิธีที่ 1: ดึงจาก spawn_units GUI
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
    
    -- วิธีที่ 2: ดึงผ่าน UnitCollectionServiceClient สำรอง
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

-- คำนวณพิกัด CFrame สำหรับวางยูนิตรอบตัวผู้เล่น
local function GetPlacementCFrame(index)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local basePos = hrp.Position
    local angle = (index * 45) * (math.pi / 180)
    local distance = 6 + math.floor(index / 8) * 5
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    local targetPos = basePos + Vector3.new(offsetX, 0, offsetZ)
    
    -- ยิง Raycast ลงพื้นเพื่อหาจุดวางที่ถูกต้อง
    local rayOrigin = targetPos + Vector3.new(0, 10, 0)
    local rayDir = Vector3.new(0, -30, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char, workspace:FindFirstChild("_UNITS") }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)
    local finalPos = hit and hit.Position or targetPos
    
    return CFrame.new(finalPos, finalPos + hrp.CFrame.LookVector)
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
    PageFrame.Parent = ContentArea
    
    local PageList = Instance.new("UIListLayout")
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Padding = UDim.new(0, 8)
    PageList.Parent = PageFrame
    
    tabs[name] = {Button = TabButton, Page = PageFrame}
    
    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            t.Button.TextColor3 = Color3.fromRGB(170, 170, 190)
        end
        PageFrame.Visible = true
        TabButton.BackgroundColor3 = Color3.fromRGB(0, 168, 255) -- สีไฮไลต์ชมพูสไตล์ XTHub
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    return PageFrame
end

local function CreateToggle(parent, title, stateKey, layoutOrder, callback)
    local ToggleContainer = Instance.new("Frame")
    ToggleContainer.Size = UDim2.new(1, -10, 0, 42)
    ToggleContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    ToggleContainer.LayoutOrder = layoutOrder
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
    Label.Parent = ToggleContainer
    
    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Size = UDim2.new(0, 44, 0, 22)
    SwitchBtn.Position = UDim2.new(1, -54, 0.5, -11)
    SwitchBtn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(210, 70, 170) or Color3.fromRGB(45, 45, 58)
    SwitchBtn.Text = ""
    SwitchBtn.Parent = ToggleContainer
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBtn
    
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = State[stateKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = SwitchBtn
    
    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(1, 0)
    IndicatorCorner.Parent = Indicator
    
    SwitchBtn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        local isON = State[stateKey]
        
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if isON then
            TweenService:Create(SwitchBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(210, 70, 170)}):Play()
            TweenService:Create(Indicator, tweenInfo, {Position = UDim2.new(1, -19, 0.5, -8)}):Play()
        else
            TweenService:Create(SwitchBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(45, 45, 58)}):Play()
            TweenService:Create(Indicator, tweenInfo, {Position = UDim2.new(0, 3, 0.5, -8)}):Play()
        end

        if callback then
            task.spawn(callback, isON)
        end
    end)

    return ToggleContainer
end

-- สร้างหน้าแท็บต่างๆ
local AutoPlayPage = CreateTab("Auto Play", 1)
local EventPage = CreateTab("Event", 2)

-- เปิดแท็บแรกเริ่มต้น
tabs["Auto Play"].Page.Visible = true
tabs["Auto Play"].Button.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
tabs["Auto Play"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

-- ========================================================
-- 1. หมวด AUTO PLAY
-- ========================================================

-- แถบแสดงสถานะ Auto Play
local AutoPlayStatusCard = Instance.new("Frame")
AutoPlayStatusCard.Size = UDim2.new(1, -10, 0, 38)
AutoPlayStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
AutoPlayStatusCard.LayoutOrder = 0
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
AutoPlayStatusLabel.Parent = AutoPlayStatusCard

local function UpdateAutoPlayStatus(text, color)
    if AutoPlayStatusLabel then
        AutoPlayStatusLabel.Text = "Auto Play: " .. text
        if color then
            AutoPlayStatusLabel.TextColor3 = color
        end
    end
end

-- เพิ่มปุ่มในหมวด Auto Play ตามที่ผู้ใช้ต้องการ
CreateToggle(AutoPlayPage, "Auto Place Units", "AutoPlace", 1)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 2)
CreateToggle(AutoPlayPage, "Auto Upgrade Farm First", "AutoUpgradeFarmFirst", 3)
CreateToggle(AutoPlayPage, "Auto Use Ability", "AutoUseAbility", 4)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Erwin / Wanda / Elfy)", "AutoBuffChain", 5)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Griffith)", "AutoBuffGriffith", 6)

-- ========================================================
-- 2. หมวด EVENT
-- ========================================================

-- แถบแสดงสถานะ Event Matchmaking
local EventStatusCard = Instance.new("Frame")
EventStatusCard.Size = UDim2.new(1, -10, 0, 38)
EventStatusCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
EventStatusCard.LayoutOrder = 0
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
EventStatusLabel.Parent = EventStatusCard

local function UpdateEventStatus(text, color)
    if EventStatusLabel then
        EventStatusLabel.Text = "Target: Summer Hunt | " .. text
        if color then
            EventStatusLabel.TextColor3 = color
        end
    end
end

-- ตรวจสอบและจัดการหน้าต่างแจ้งเตือน/Captcha ของเกม
local function HandlePopups()
    local notifWindows = playerGui:FindFirstChild("NotificationWindows")
    if not notifWindows then return end
    
    local popups = notifWindows:FindFirstChild("Popups")
    if not popups then return end
    
    for _, popup in ipairs(popups:GetChildren()) do
        if popup:IsA("GuiObject") and popup.Visible then
            -- 1. ตรวจสอบหน้าต่าง Captcha ของ Matchmaking และพิมพ์ตอบให้อัตโนมัติ
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
            
            -- 2. ยืนยันปุ่ม Matchmaking กรณีมีหน้าต่างยืนยันเปิดขึ้นมา
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

-- เพิ่มปุ่มในหมวด Event (ตั้งค่าให้ Match กับ Summer Hunt โดยตรง)
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

-- ========================================================
-- ระบบการทำงานเบื้องหลัง (Background Logic)
-- ========================================================

-- ตารางจัดเก็บเวลาบัฟล่าสุดเพื่อทำ Chain 100% Uptime (บัฟอยู่นาน 30 วินาที)
local BuffChains = {
    erwin = { lastCast = 0 },
    wendy = { lastCast = 0 },
    elfy = { lastCast = 0 },
}

-- 1. ลูปสำหรับ Auto Play (Place, Upgrade, Abilities, Buffs)
task.spawn(function()
    while true do
        task.wait(0.5)

        -- ทำงานเฉพาะตอนที่อยู่ในห้องแข่งขัน (Game Match)
        if not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
            local myUnits = GetPlayerUnits()

            -- [1] Auto Place Units
            if State.AutoPlace then
                local equipped = GetEquippedUnitList()
                if #equipped > 0 then
                    -- หากเปิด Auto Upgrade Farm First ให้เรียงวางยูนิตฟาร์มเงินก่อน
                    if State.AutoUpgradeFarmFirst then
                        table.sort(equipped, function(a, b)
                            local aFarm = a.name:lower():find("speedwagon") or a.name:lower():find("bulma") or a.name:lower():find("nami")
                            local bFarm = b.name:lower():find("speedwagon") or b.name:lower():find("bulma") or b.name:lower():find("nami")
                            if aFarm and not bFarm then return true end
                            if not aFarm and bFarm then return false end
                            return false
                        end)
                    end

                    for i, unitInfo in ipairs(equipped) do
                        local cframe = GetPlacementCFrame(#myUnits + i)
                        if cframe then
                            InvokeEndpoint("spawn_unit", unitInfo.uuid, cframe)
                        end
                    end
                end
            end

            -- [2] Auto Upgrade Units (พร้อมรองรับ Farm First)
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
                    -- หากเปิด Farm First ให้จัดลำดับยูนิตฟาร์มขึ้นมาก่อน
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

                    -- อัปเกรดยูนิตลำดับแรกสุดตาม Priority
                    InvokeEndpoint("upgrade_unit_ingame", upgradable[1])
                end
            end

            -- [3] Auto Buff 100% Chain (Erwin / Wanda / Elfy)
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
                        -- บัฟมีผล 30 วินาที หมุนเวียนที่ 29.5 วินาทีเพื่อให้บัฟทำงานต่อเนื่อง 100%
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

            -- [4] Auto Buff 100% Griffith
            if State.AutoBuffGriffith and #myUnits > 0 then
                for _, u in ipairs(myUnits) do
                    if IsGriffithUnit(u) and CanUseActiveAttack(u) then
                        InvokeEndpoint("use_active_attack", u)
                        UpdateAutoPlayStatus("Griffith Buff 100% Activated!", Color3.fromRGB(255, 215, 0))
                    end
                end
            end

            -- [5] Auto Use Ability ทั่วไป
            if State.AutoUseAbility and #myUnits > 0 then
                for _, u in ipairs(myUnits) do
                    -- ข้ามยูนิตที่เป็น Buff Chain หรือ Griffith เพื่อไม่ให้กวนระบบ 100% Buff
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
            UpdateAutoPlayStatus("Idle (Waiting for Match)", Color3.fromRGB(160, 160, 180))
        end
    end
end)

-- 2. ลูปสำหรับ Event Automation & Matchmaking
task.spawn(function()
    while true do
        task.wait(1.5)
        
        -- จัดการ Auto Find Match
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
                -- ผู้เล่นอยู่ในแมตช์การแข่งขัน Summer Hunt
                UpdateEventStatus("In Match (Summer Hunt)", Color3.fromRGB(100, 255, 100))
                
                -- ตรวจสอบเมื่อจบเกม (GameFinished) เพื่อ Replay หรือกลับ Lobby
                local dataFolder = workspace:FindFirstChild("_DATA")
                local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
                if gameFinished and gameFinished.Value == true then
                    if State.AutoReplay then
                        UpdateEventStatus("Match Finished! Voting Replay...", Color3.fromRGB(255, 170, 0))
                        task.wait(2.5)
                        InvokeEndpoint("set_game_finished_vote", "replay")
                        
                        -- หากไม่ Replay ภายใน 8 วินาที ให้พากลับ Lobby เพื่อค้นหาห้องใหม่
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
        
        -- จัดการ Auto Pick Cards ใน Event Roguelike
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
        
        -- จัดการ Auto Event Quests (เคลม Bingo Board Summer)
        if State.AutoEventQuests then
            InvokeEndpoint("claim_summer2_map_board_lines")
        end
    end
end)

-- ปุ่มลัดกดเปิด-ปิด UI ด้วย RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("XT Hub UI Loaded Successfully! Auto Play & Event Matchmaking are ready.")
