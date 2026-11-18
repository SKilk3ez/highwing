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
