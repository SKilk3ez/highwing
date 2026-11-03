-- [[ XT Hub Style GUI Script for Executor ]] --
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
TitleLabel.Text = "Anime Adventures / Hub v0.4.8"
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
}

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

local function CreateToggle(parent, title, stateKey, layoutOrder)
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
    end)
end

-- สร้างหน้าแท็บต่างๆ ตามภาพตัวอย่าง
local AutoPlayPage = CreateTab("Auto Play", 1)
local EventPage = CreateTab("Event", 2)

-- เปิดแท็บแรกเริ่มต้น
tabs["Auto Play"].Page.Visible = true
tabs["Auto Play"].Button.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
tabs["Auto Play"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

-- เพิ่มปุ่มในหมวด Auto Play
CreateToggle(AutoPlayPage, "Auto Place Units", "AutoPlace", 1)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 2)

-- เพิ่มปุ่มในหมวด Event (ตามรูปที่ 1 ของคุณ)
CreateToggle(EventPage, "Auto Find Match", "AutoFindMatch", 1)
CreateToggle(EventPage, "Auto Event Quests", "AutoEventQuests", 2)
CreateToggle(EventPage, "Auto Pick Cards", "AutoPickCards", 3)

-- ปุ่มลัดกดเปิด-ปิด UI ด้วย RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("XT Hub UI Loaded Successfully!")
