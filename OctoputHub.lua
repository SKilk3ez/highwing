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
    playerGui:FindFirstChild("XT_Hub_UI"):Destroy()
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
TitleLabel.Text = "Anime Adventures / XT Hub v0.4.8"
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

local State = {
    AutoPlace = false,
    AutoUpgrade = false,
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
        TabButton.BackgroundColor3 = Color3.fromRGB(210, 70, 170) -- สีไฮไลต์ชมพูสไตล์ XTHub
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
    SwitchBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    SwitchBtn.Text = ""
    SwitchBtn.Parent = ToggleContainer
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBtn
    
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = UDim2.new(0, 3, 0.5, -8)
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

-- เพิ่มปุ่มในหมวด Auto Play
CreateToggle(AutoPlayPage, "Auto Place Units", "AutoPlace", 1)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 2)

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

-- ระบบ Background Loop สำหรับจัดการ Event Automation ทั้งหมด
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

print("XT Hub UI Loaded Successfully! Event Matchmaking ready for Summer Hunt.")
