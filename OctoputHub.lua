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
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 780, 0, 480)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

local HubScale = Instance.new("UIScale")
HubScale.Name = "HubScale"
HubScale.Scale = 1
HubScale.Parent = MainFrame

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

local CONFIG_FILE = "OctoputHub/config.json"
local AllowSave = false

local State = {
    AutoPlace = false,
    AutoUpgrade = false,
    AutoUpgradeFarmFirst = true,
    AutoUseAbility = false,
    AutoBuffChain = false,
    AutoBuffGriffith = false,
    GriffithBuddyUnitIds = {},
    BuffDelays = {
        commander = { [2] = 3, [3] = 0.7, [4] = 0.7 },
        windsong = { [2] = 3.5, [3] = 0.7, [4] = 0.7 },
        elfy = { [2] = 3.5, [3] = 0.7, [4] = 0.7 },
    },
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
}

-- Names match GUIService._STAT_ID_TO_STAT_NAME and WaveModifiersServiceClient.is_effect_buff.
local BUFF_DEFS = {
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

local DEBUFF_DEFS = {
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

local function DefIdSet(defs)
    local set = {}
    for _, def in ipairs(defs) do
        set[def.id] = true
    end
    return set
end

local BUFF_IDS = DefIdSet(BUFF_DEFS)
local DEBUFF_IDS = DefIdSet(DEBUFF_DEFS)

local function SanitizeIdList(list, allowed)
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

local function CopyStateForSave()
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
        AutoUseAbility = State.AutoUseAbility,
        AutoBuffChain = State.AutoBuffChain,
        AutoBuffGriffith = State.AutoBuffGriffith,
        GriffithBuddyUnitIds = State.GriffithBuddyUnitIds,
        BuffDelays = State.BuffDelays,
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
    }
end

local function SaveConfig()
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

local function ApplySavedTable(saved)
    if type(saved) ~= "table" then
        return
    end
    local boolKeys = {
        "AutoPlace", "AutoUpgrade", "AutoUpgradeFarmFirst", "AutoUseAbility", "AutoBuffChain", "AutoBuffGriffith",
        "AutoFindMatch", "AutoEventQuests", "AutoPickCards", "AutoReplay", "WebhookOnEnd", "BlackScreen", "AutoHideGUIOnExecute",
        "PlaceHybridGround", "PlaceHybridHill", "AutoStart", "MainAutoReplay", "AutoNext", "AutoLeave",
    }
    for _, key in ipairs(boolKeys) do
        if type(saved[key]) == "boolean" then
            State[key] = saved[key]
        end
    end
    -- Multi-select list; migrate the previous single-selection config automatically.
    State.GriffithBuddyUnitIds = {}
    local savedBuddyIds = saved.GriffithBuddyUnitIds
    if type(savedBuddyIds) == "table" then
        local seenBuddyIds = {}
        for _, id in ipairs(savedBuddyIds) do
            if type(id) == "string" and id ~= "" and not seenBuddyIds[id] then
                seenBuddyIds[id] = true
                table.insert(State.GriffithBuddyUnitIds, id)
            end
        end
    elseif type(saved.GriffithBuddyUnitId) == "string" and saved.GriffithBuddyUnitId ~= "" then
        table.insert(State.GriffithBuddyUnitIds, saved.GriffithBuddyUnitId)
    end
    if type(saved.BuffDelays) == "table" then
        for _, group in ipairs({ "commander", "windsong", "elfy" }) do
            if type(saved.BuffDelays[group]) == "table" then
                for _, index in ipairs({ 2, 3, 4 }) do
                    local value = tonumber(saved.BuffDelays[group][index] or saved.BuffDelays[group][tostring(index)])
                    if value and value >= 0 and value <= 30 then
                        State.BuffDelays[group][index] = value
                    end
                end
            end
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

local function LoadConfig()
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
HubScale.Scale = State.UIScale

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
    return id:find("commander", 1, true)
        or id:find("erwin", 1, true) -- legacy alias
        or id:find("windsong", 1, true)
        or id:find("wenda", 1, true) -- legacy alias
        or id:find("elfy", 1, true)
        or id:find("sylph", 1, true) -- evolution/name alias
end

local UnitsDataCache
local function GetUnitsData()
    if UnitsDataCache then
        return UnitsDataCache
    end
    local ok, data = pcall(function()
        return require(ReplicatedStorage.src.Data.Units)
    end)
    if ok and type(data) == "table" then
        UnitsDataCache = data
    else
        UnitsDataCache = {}
    end
    return UnitsDataCache
end

local function LookupUnitData(unitId)
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

local function GetRawUnitId(unit)
    if not unit or not unit:FindFirstChild("_stats") then
        return ""
    end
    local idVal = unit._stats:FindFirstChild("id")
    if idVal and tostring(idVal.Value) ~= "" then
        return tostring(idVal.Value)
    end
    return unit.Name
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

local function GetBuffChainGroupFromText(...)
    -- Match canonical IDs and displayed/evolved names across game versions.
    local text = ""
    for i = 1, select("#", ...) do
        text = text .. NormalizeName(select(i, ...))
    end
    if text:find("commander", 1, true) or text:find("erwin", 1, true) then
        return "commander"
    elseif text:find("windsong", 1, true) or text:find("wenda", 1, true)
        or text:find("winddragon", 1, true) then
        return "windsong"
    elseif text:find("elfy", 1, true) or text:find("sylph", 1, true) then
        return "elfy"
    end
    return nil
end

local function GetBuffChainGroup(unit)
    if not unit then return nil end
    local statsId = ""
    if unit:FindFirstChild("_stats") then
        local idValue = unit._stats:FindFirstChild("id")
        statsId = idValue and tostring(idValue.Value) or ""
    end
    return GetBuffChainGroupFromText(GetUnitId(unit), statsId, unit.Name)
end

local IsGriffithReincarnation
local function IsGriffithUnit(unit)
    -- Count the evolved form as the same Griffith placement, even if its ID changed.
    return IsGriffithName(GetUnitId(unit))
        or IsGriffithName(unit and unit.Name)
        or (IsGriffithReincarnation and IsGriffithReincarnation(unit))
end

-- Detect the evolved Griffith unit by its actual unit id/name.
-- This is the definitive signal that the sacrifice phase has completed.
IsGriffithReincarnation = function(unit)
    if not unit then
        return false
    end

    local id = GetUnitId(unit)
    local modelName = NormalizeName(unit.Name)
    local reincarnated = function(value)
        local name = NormalizeName(value)
        return (name:find("griffith", 1, true)
                or name:find("griffin", 1, true)
                or name:find("femto", 1, true))
            and name:find("reincarnation", 1, true) ~= nil
    end

    if reincarnated(id) or reincarnated(modelName) then
        return true
    end

    -- Some game versions expose the display name in stats instead of the model name.
    local stats = unit:FindFirstChild("_stats")
    if stats then
        for _, key in ipairs({ "name", "display_name", "unit_name" }) do
            local value = stats:FindFirstChild(key)
            if value and reincarnated(value.Value) then
                return true
            end
        end
    end

    return false
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

local function EnrichEquipped(list)
    for _, info in ipairs(list) do
        local unitId = info.unitId
        pcall(function()
            if info.uuid then
                local Loader = require(ReplicatedStorage.src.Loader)
                local ucs = Loader.load_client_service(game, "UnitCollectionServiceClient")
                if ucs and ucs.get_equipped_unit_by_uuid then
                    local owned = ucs.get_equipped_unit_by_uuid(info.uuid)
                    if owned and owned.unit_id then
                        unitId = owned.unit_id
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
            info.spawnCap = tonumber(data.spawn_cap)
            info.globalSpawnCap = tonumber(data.global_spawn_cap)
            info.maxUpgrade = type(data.upgrade) == "table" and #data.upgrade or nil
            info.hybrid = data.hybrid_placement == true
            info.hill = data.hill_unit == true
        end
        if info.name and info.name ~= "" and info.name ~= "Unit" then
            State.UnitNames[info.unitId] = info.name
        end
    end
    return list
end

-- Detect farm units from both their displayed name and unit database metadata.
-- Some equipped-unit records use an internal ID that does not contain the display name.
local function IsFarmInfo(info)
    if not info then
        return false
    end
    local farmText = NormalizeName(info.name) .. NormalizeName(info.displayName) .. NormalizeName(info.unitId)
    if IsFarmName(info.name) or IsFarmName(info.displayName) or IsFarmName(info.unitId)
        or farmText:find("farm", 1, true) then
        return true
    end
    local data = LookupUnitData(info.unitId)
    if type(data) == "table" then
        if data.farm_amount ~= nil or data.farm_income ~= nil or data.farm_generation ~= nil
            or data._show_as_farm_unit == true or data.show_as_farm_unit == true
            or data.is_farm_unit == true or data.farm_unit == true or data.farm == true then
            return true
        end
    end
    return false
end

local function GetCurrentWave()
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

local function GetUnitConfig(unitId)
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

local function CountPlacedUnit(unitId)
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
local function CountPlacedInfo(info)
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
local function CountGlobalPlacedInfo(info)
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

local function ResolvePlacementKind(unitId)
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

local function CanPlaceConfigured(info, wave)
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
        -- Griffith (Reincarnation) is an evolved state of the original placement.
        -- Count both forms together so Max Place = 1 cannot summon a second copy.
        local placedCount
        if IsGriffithName(info.name) or IsGriffithName(info.unitId) then
            placedCount = 0
            for _, placedUnit in ipairs(GetPlayerUnits()) do
                if IsGriffithUnit(placedUnit) then
                    placedCount = placedCount + 1
                end
            end
        else
            placedCount = CountPlacedUnit(info.unitId)
        end
        if placedCount >= localLimit then
            return false
        end
    end
    return true
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

local function HitAllowsPlacement(inst, kind)
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

local function PlacementIsClear(pos, kind)
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
                local pivot = unit:GetPivot().Position
                local flat = Vector3.new(hit.Position.X - pivot.X, 0, hit.Position.Z - pivot.Z)
                if flat.Magnitude < 3.4 then
                    return nil
                end
            end
        end
    end
    return hit.Position
end

local function GetPlacementCFrame(index, kind)
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

    if #points >= 2 then
        -- Keep the whole formation around one point on the actual path.
        -- GetPointOnPolyline uses total segment length, so different map/path
        -- lengths still place the cluster at the selected percentage.
        local center, look = GetPointOnPolyline(points, preferred)
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

        -- Hexagonal cluster: neighboring slots are 3.8 studs apart.
        -- PlacementIsClear still enforces the game's existing 3.4-stud
        -- minimum-distance check and terrain / road restrictions.
        local spacing = 3.8
        local offsets = { Vector2.new(0, 0) }
        local maxRing = 5
        for ring = 1, maxRing do
            local ringOffsets = {}
            for q = -ring, ring do
                for r = -ring, ring do
                    local s = -q - r
                    if math.max(math.abs(q), math.abs(r), math.abs(s)) == ring then
                        local x = spacing * (q + r * 0.5)
                        local z = spacing * (r * 0.8660254038)
                        table.insert(ringOffsets, Vector2.new(x, z))
                    end
                end
            end
            table.sort(ringOffsets, function(a, b)
                return math.atan2(a.Y, a.X) < math.atan2(b.Y, b.X)
            end)
            for _, offset in ipairs(ringOffsets) do
                table.insert(offsets, offset)
            end
        end

        -- Prefer this unit's stable slot. If terrain, road, or an existing
        -- unit blocks it, try the remaining nearby cluster slots.
        local preferredSlot = ((math.max(1, math.floor(index)) - 1) % #offsets) + 1
        for pass = 1, #offsets do
            local slot = ((preferredSlot + pass - 2) % #offsets) + 1
            local offset = offsets[slot]
            local candidate = center + right * offset.X + forward * offset.Y
            local finalPos = PlacementIsClear(candidate, kind)
            if finalPos then
                return Finish(finalPos, look)
            end
        end
        return nil
    end

    -- Preserve the previous fallback for maps where lane path points
    -- are not exposed by the client.
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local angle = (index * 45) * (math.pi / 180)
    local distance = 6 + math.floor(index / 8) * 5
    local pos = hrp.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
    local finalPos = PlacementIsClear(pos, kind) or pos
    return Finish(finalPos, hrp.CFrame.LookVector)
end

-- Farm units can be ground or hill units depending on the game's unit data.
-- If the unit database lookup misses an entry, try every valid placement surface
-- instead of silently skipping the farm because the guessed surface was wrong.
local function GetPlacementCFrameForInfo(index, info)
    local primary = ResolvePlacementKind(info and info.unitId)
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

local function IsGriffithBuddySelected(unitId)
    local wanted = tostring(unitId or "")
    if wanted == "" then return false end
    for _, selectedId in ipairs(State.GriffithBuddyUnitIds or {}) do
        if tostring(selectedId) == wanted then return true end
    end
    return false
end

local function GetPlacementCFrameNearGriffith(info, myUnits)
    if not info or not IsGriffithBuddySelected(info.unitId) then
        return nil
    end
    local griffith
    for _, unit in ipairs(myUnits or {}) do
        if IsGriffithUnit(unit) then
            griffith = unit
            break
        end
    end
    if not griffith then return nil end

    local ok, pivot = pcall(function() return griffith:GetPivot() end)
    if not ok or not pivot then return nil end
    local center = pivot.Position
    local look = pivot.LookVector
    local right = Vector3.new(look.Z, 0, -look.X)
    if right.Magnitude < 0.01 then right = Vector3.new(1, 0, 0) else right = right.Unit end
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < 0.01 then forward = Vector3.new(0, 0, -1) else forward = forward.Unit end

    local kind = ResolvePlacementKind(info.unitId)
    local offsets = {
        Vector2.new(4.2, 0), Vector2.new(-4.2, 0),
        Vector2.new(0, 4.2), Vector2.new(0, -4.2),
        Vector2.new(4.2, 4.2), Vector2.new(-4.2, 4.2),
        Vector2.new(4.2, -4.2), Vector2.new(-4.2, -4.2),
        Vector2.new(6.5, 0), Vector2.new(-6.5, 0),
        Vector2.new(0, 6.5), Vector2.new(0, -6.5),
    }
    for _, offset in ipairs(offsets) do
        local candidate = center + right * offset.X + forward * offset.Y
        local finalPos = PlacementIsClear(candidate, kind)
        if finalPos then
            local flatLook = Vector3.new(look.X, 0, look.Z)
            if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) else flatLook = flatLook.Unit end
            return CFrame.new(finalPos, finalPos + flatLook), kind
        end
    end
    return nil
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

local function NormalizeWebhookUrl(url)
    return tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function WebhookProblem(url)
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

local function DescribeWebhookResult(ok, result)
    if not ok then
        return false, tostring(result)
    end
    if type(result) == "table" then
        local code = tonumber(result.StatusCode or result.status_code or result.Status)
        if code and code >= 300 then
            local body = tostring(result.Body or result.body or "")
            if #body > 180 then
                body = body:sub(1, 180)
            end
            if body ~= "" then
                return false, "HTTP " .. tostring(code) .. ": " .. body
            end
            return false, "HTTP " .. tostring(code)
        end
    end
    return true, "Test message sent."
end

local function ReadPlayerCurrencies()
    local values = {}
    local stats = player:FindFirstChild("_stats")
    if not stats then
        return values
    end

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
                values[name:sub(10)] = child.Value
            end
        end
    end
    return values
end

local function FormatNumber(value)
    local n = tonumber(value) or 0
    local sign = n < 0 and "-" or ""
    local digits = tostring(math.floor(math.abs(n)))
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

local function BuildCurrencyLines(before, after)
    local lines = {}
    local names = {}
    for name in pairs(before or {}) do names[name] = true end
    for name in pairs(after or {}) do names[name] = true end

    local ordered = {"Gold", "Gems", "Trophies", "XP"}
    local used = {}
    for _, name in ipairs(ordered) do
        if names[name] then
            table.insert(lines, string.format("**%s:** %s → %s (%s%s)", name,
                FormatNumber(before[name] or 0), FormatNumber(after[name] or 0),
                ((after[name] or 0) - (before[name] or 0)) >= 0 and "+" or "",
                FormatNumber((after[name] or 0) - (before[name] or 0))))
            used[name] = true
        end
    end
    for name in pairs(names) do
        if not used[name] then
            local delta = (after[name] or 0) - (before[name] or 0)
            table.insert(lines, string.format("**%s:** %s → %s (%s%s)", name,
                FormatNumber(before[name] or 0), FormatNumber(after[name] or 0),
                delta >= 0 and "+" or "", FormatNumber(delta)))
        end
    end
    if #lines == 0 then
        table.insert(lines, "Currency data unavailable")
    end
    return table.concat(lines, "\n")
end

local function GetResultDetails()
    local details = {}
    local results = playerGui:FindFirstChild("ResultsUI")
    if not results then return details end

    local holder = results:FindFirstChild("Holder")
    if holder then
        local levelName = holder:FindFirstChild("LevelName")
        if levelName and levelName:IsA("TextLabel") then
            details.level = levelName.Text
        end
        local title = holder:FindFirstChild("Title")
        if title and title:IsA("TextLabel") then
            details.result = title.Text
        end
    end
    return details
end

local webhookCurrencyBefore = nil
local function CaptureWebhookCurrencyBaseline()
    webhookCurrencyBefore = ReadPlayerCurrencies()
end

local function SendEndWebhook()
    local url = NormalizeWebhookUrl(State.WebhookURL)
    if WebhookProblem(url) then
        return
    end

    -- Allow the game's result/reward updates to reach the player's stats first.
    task.wait(2)
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

    local currentCurrencies = ReadPlayerCurrencies()
    local currencyText = BuildCurrencyLines(webhookCurrencyBefore or currentCurrencies, currentCurrencies)
    local resultDetails = GetResultDetails()
    local level = resultDetails.level or "Unknown stage"
    if resultDetails.result and resultDetails.result ~= "" then
        result = resultDetails.result .. " | " .. result
    end

    local body = HttpService:JSONEncode({
        username = "Octoput Hub",
        embeds = {{
            title = "Stage Ended — " .. tostring(level),
            description = string.format("**Player:** %s\n**Result:** %s\n\n**Currency (Before → After | Change)**\n%s",
                player.Name, result, currencyText),
            color = result:find("Victory", 1, true) and 5763719 or 15548997,
            timestamp = DateTime.now():ToIsoDate(),
        }},
    })
    pcall(HttpPost, url, body)
end
local function IsGoodEffectColor(color)
    return color and color.G > 0.55 and color.R < 0.45 and color.B < 0.55
end

local function IsBadEffectColor(color)
    return color and color.R > 0.55 and color.G < 0.45 and color.B < 0.55
end

local function LineIsBuff(id, lower, good)
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

local function LineIsDebuff(id, lower, bad)
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

local function ScoreRoguelikeCard(card)
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

local function PickRoguelikeCard(pageUI)
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

local function CreateSection(parent, title, layoutOrder)
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

local function CreateHint(parent, text, layoutOrder, height)
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

        SaveConfig()
        if callback then
            task.spawn(callback, isON)
        end
    end)

    return ToggleContainer
end

local function CreateTextBox(parent, title, placeholder, layoutOrder, onChanged, initialText)
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

local function CreateButton(parent, title, layoutOrder, onClick)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 36)
    Button.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
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

local function CreateSingleSlider(parent, title, hint, layoutOrder, minValue, maxValue, getValue, setValue)
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
    Fill.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
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

local function CreatePriorityEditor(parent, title, hint, defs, stateKey, layoutOrder)
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
            Box.BackgroundColor3 = rank and Color3.fromRGB(210, 70, 170) or Color3.fromRGB(45, 45, 58)
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

local MainPage = CreateTab("Main", 1)
local AutoPlayPage = CreateTab("Auto Play", 2)
local EventPage = CreateTab("Event", 3)
local WebhookPage = CreateTab("Webhook", 4)
local MiscPage = CreateTab("Misc", 5)

tabs["Auto Play"].Page.Visible = true
tabs["Auto Play"].Button.BackgroundColor3 = Color3.fromRGB(210, 70, 170)
tabs["Auto Play"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

CreateHint(MainPage, "When a match ends: Next runs if it is enabled and a next stage is available. Otherwise Replay runs if it is enabled. Otherwise Leave runs if it is enabled.", 0, 44)
CreateToggle(MainPage, "Auto Start", "AutoStart", 1)
CreateToggle(MainPage, "Auto Replay", "MainAutoReplay", 2)
CreateToggle(MainPage, "Auto Next", "AutoNext", 3)
CreateToggle(MainPage, "Auto Leave", "AutoLeave", 4)

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
CreateSingleSlider(AutoPlayPage, "Cluster Position (Path)", "0% path start    100% path end", 2, 0, 100, function()
    return State.PlacePercent
end, function(value)
    State.PlacePercent = value
end)
CreateToggle(AutoPlayPage, "Auto Upgrade Units", "AutoUpgrade", 3)
CreateToggle(AutoPlayPage, "Auto Upgrade Farm First", "AutoUpgradeFarmFirst", 4)
CreateToggle(AutoPlayPage, "Auto Use Ability", "AutoUseAbility", 5)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Commander / Windsong / Elfy)", "AutoBuffChain", 6)
CreateToggle(AutoPlayPage, "Auto Buff 100% (Griffith)", "AutoBuffGriffith", 8)

-- Expandable selector: multi-select equipped unit types to place beside Griffith.
local BuddyContainer = Instance.new("Frame")
BuddyContainer.Name = "GriffithBuddySelector"
BuddyContainer.Size = UDim2.new(1, -10, 0, 30)
BuddyContainer.BackgroundTransparency = 1
BuddyContainer.LayoutOrder = 9
BuddyContainer.ZIndex = 12
BuddyContainer.Parent = AutoPlayPage

local BuddyToggle = Instance.new("TextButton")
BuddyToggle.Size = UDim2.new(1, 0, 0, 28)
BuddyToggle.BackgroundColor3 = Color3.fromRGB(30, 38, 52)
BuddyToggle.Text = "  Griffith Nearby Unit Selector  ▾"
BuddyToggle.TextColor3 = Color3.fromRGB(175, 205, 245)
BuddyToggle.TextSize = 11
BuddyToggle.Font = Enum.Font.GothamSemibold
BuddyToggle.TextXAlignment = Enum.TextXAlignment.Left
BuddyToggle.ZIndex = 13
BuddyToggle.Parent = BuddyContainer
Instance.new("UICorner", BuddyToggle).CornerRadius = UDim.new(0, 6)

local BuddyPanel = Instance.new("Frame")
BuddyPanel.Name = "GriffithBuddyPanel"
BuddyPanel.Position = UDim2.new(0, 0, 0, 34)
BuddyPanel.Size = UDim2.new(1, 0, 0, 164)
BuddyPanel.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
BuddyPanel.BorderSizePixel = 0
BuddyPanel.Visible = false
BuddyPanel.ZIndex = 13
BuddyPanel.Parent = BuddyContainer
Instance.new("UICorner", BuddyPanel).CornerRadius = UDim.new(0, 6)
local buddyStroke = Instance.new("UIStroke", BuddyPanel)
buddyStroke.Color = Color3.fromRGB(55, 70, 95)

local BuddyHint = Instance.new("TextLabel")
BuddyHint.Size = UDim2.new(1, -90, 0, 24)
BuddyHint.Position = UDim2.new(0, 8, 0, 3)
BuddyHint.BackgroundTransparency = 1
BuddyHint.Text = "เลือกยูนิตในทีมที่จะให้วางใกล้ Griffith"
BuddyHint.TextColor3 = Color3.fromRGB(155, 165, 185)
BuddyHint.TextSize = 10
BuddyHint.Font = Enum.Font.Gotham
BuddyHint.TextXAlignment = Enum.TextXAlignment.Left
BuddyHint.ZIndex = 14
BuddyHint.Parent = BuddyPanel

local BuddyRefresh = Instance.new("TextButton")
BuddyRefresh.Size = UDim2.new(0, 68, 0, 22)
BuddyRefresh.Position = UDim2.new(1, -76, 0, 4)
BuddyRefresh.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
BuddyRefresh.Text = "Refresh"
BuddyRefresh.TextColor3 = Color3.fromRGB(230, 235, 245)
BuddyRefresh.TextSize = 10
BuddyRefresh.Font = Enum.Font.GothamBold
BuddyRefresh.ZIndex = 15
BuddyRefresh.Parent = BuddyPanel
Instance.new("UICorner", BuddyRefresh).CornerRadius = UDim.new(0, 4)

local BuddyList = Instance.new("ScrollingFrame")
BuddyList.Size = UDim2.new(1, -12, 0, 126)
BuddyList.Position = UDim2.new(0, 6, 0, 31)
BuddyList.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
BuddyList.BorderSizePixel = 0
BuddyList.ScrollBarThickness = 4
BuddyList.AutomaticCanvasSize = Enum.AutomaticSize.Y
BuddyList.CanvasSize = UDim2.new(0, 0, 0, 0)
BuddyList.ZIndex = 14
BuddyList.Parent = BuddyPanel
Instance.new("UICorner", BuddyList).CornerRadius = UDim.new(0, 4)
local BuddyListLayout = Instance.new("UIListLayout", BuddyList)
BuddyListLayout.Padding = UDim.new(0, 3)
BuddyListLayout.SortOrder = Enum.SortOrder.LayoutOrder
local BuddyListPadding = Instance.new("UIPadding", BuddyList)
BuddyListPadding.PaddingTop = UDim.new(0, 4)
BuddyListPadding.PaddingBottom = UDim.new(0, 4)
BuddyListPadding.PaddingLeft = UDim.new(0, 4)
BuddyListPadding.PaddingRight = UDim.new(0, 4)

local function RefreshGriffithBuddyList()
    for _, child in ipairs(BuddyList:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    local equipped = EnrichEquipped(GetEquippedUnitList())
    local seen = {}
    local options = {}
    for _, info in ipairs(equipped) do
        local id = tostring(info.unitId or "")
        if id ~= "" and not IsGriffithName(id) and not seen[id] then
            seen[id] = true
            table.insert(options, { id = id, name = tostring(info.name or id) })
        end
    end
    table.sort(options, function(a, b) return a.name:lower() < b.name:lower() end)

    local function AddOption(label, id, selected)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -4, 0, 25)
        button.BackgroundColor3 = selected and Color3.fromRGB(80, 55, 105) or Color3.fromRGB(31, 35, 48)
        button.Text = (selected and "✓  " or "    ") .. label
        button.TextColor3 = Color3.fromRGB(225, 230, 242)
        button.TextSize = 10
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.ZIndex = 15
        button.Parent = BuddyList
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
        button.MouseButton1Click:Connect(function()
            if id == "" then
                table.clear(State.GriffithBuddyUnitIds)
            else
                local foundIndex
                for index, selectedId in ipairs(State.GriffithBuddyUnitIds) do
                    if selectedId == id then foundIndex = index break end
                end
                if foundIndex then
                    table.remove(State.GriffithBuddyUnitIds, foundIndex)
                else
                    table.insert(State.GriffithBuddyUnitIds, id)
                end
            end
            SaveConfig()
            RefreshGriffithBuddyList()
        end)
    end

    local selectedSet = {}
    for _, selectedId in ipairs(State.GriffithBuddyUnitIds or {}) do
        selectedSet[selectedId] = true
    end
    AddOption("None (ล้างการเลือกทั้งหมด)", "", next(selectedSet) == nil)
    for _, option in ipairs(options) do
        AddOption(option.name, option.id, selectedSet[option.id] == true)
    end
    if #options == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -4, 0, 24)
        empty.BackgroundTransparency = 1
        empty.Text = "ไม่พบ Unit ในทีม กด Refresh หลังเข้าเกม"
        empty.TextColor3 = Color3.fromRGB(145, 145, 160)
        empty.TextSize = 10
        empty.Font = Enum.Font.Gotham
        empty.ZIndex = 15
        empty.Parent = BuddyList
    end
end

BuddyToggle.MouseButton1Click:Connect(function()
    BuddyPanel.Visible = not BuddyPanel.Visible
    BuddyContainer.Size = UDim2.new(1, -10, 0, BuddyPanel.Visible and 202 or 30)
    BuddyToggle.Text = BuddyPanel.Visible and "  Griffith Nearby Unit Selector  ▴" or "  Griffith Nearby Unit Selector  ▾"
    if BuddyPanel.Visible then RefreshGriffithBuddyList() end
end)
BuddyRefresh.MouseButton1Click:Connect(RefreshGriffithBuddyList)

-- Compact inline Auto Buff Delay Settings (inside a small frame under Auto Buff 100%).
local function SetBuffDelay(group, index, value)
    local number = tonumber(value)
    if not number or number < 0 or number > 30 then return end
    State.BuffDelays[group][index] = number
    SaveConfig()
end

local DelayContainer = Instance.new("Frame")
DelayContainer.Name = "AutoBuffDelayContainer"
DelayContainer.Size = UDim2.new(1, -10, 0, 30)
DelayContainer.BackgroundTransparency = 1
DelayContainer.BorderSizePixel = 0
DelayContainer.LayoutOrder = 7
DelayContainer.ZIndex = 12
DelayContainer.Parent = AutoPlayPage

local DelayOpenButton = Instance.new("TextButton")
DelayOpenButton.Name = "AutoBuffDelaySettingsButton"
DelayOpenButton.Size = UDim2.new(1, 0, 0, 28)
DelayOpenButton.Position = UDim2.new(0, 0, 0, 0)
DelayOpenButton.BackgroundColor3 = Color3.fromRGB(30, 38, 52)
DelayOpenButton.Text = "⚙  Auto Buff Delay Settings  ▾"
DelayOpenButton.TextColor3 = Color3.fromRGB(175, 205, 245)
DelayOpenButton.TextSize = 11
DelayOpenButton.Font = Enum.Font.GothamSemibold
DelayOpenButton.ZIndex = 13
DelayOpenButton.Parent = DelayContainer
local DelayButtonCorner = Instance.new("UICorner")
DelayButtonCorner.CornerRadius = UDim.new(0, 6)
DelayButtonCorner.Parent = DelayOpenButton

-- This is an inline expandable frame, not a screen overlay or separate window.
local DelayInlineFrame = Instance.new("Frame")
DelayInlineFrame.Name = "AutoBuffDelayInlineFrame"
DelayInlineFrame.Position = UDim2.new(0, 0, 0, 34)
DelayInlineFrame.Size = UDim2.new(1, 0, 0, 154)
DelayInlineFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
DelayInlineFrame.BorderSizePixel = 0
DelayInlineFrame.Visible = false
DelayInlineFrame.ZIndex = 13
DelayInlineFrame.Parent = DelayContainer
local DelayInlineCorner = Instance.new("UICorner")
DelayInlineCorner.CornerRadius = UDim.new(0, 6)
DelayInlineCorner.Parent = DelayInlineFrame
local DelayInlineStroke = Instance.new("UIStroke")
DelayInlineStroke.Color = Color3.fromRGB(55, 70, 95)
DelayInlineStroke.Thickness = 1
DelayInlineStroke.Parent = DelayInlineFrame

local DelayInlineHint = Instance.new("TextLabel")
DelayInlineHint.Size = UDim2.new(1, -16, 0, 18)
DelayInlineHint.Position = UDim2.new(0, 8, 0, 4)
DelayInlineHint.BackgroundTransparency = 1
DelayInlineHint.Text = "Delay ก่อนใช้บัฟยูนิตถัดไป (วินาที)"
DelayInlineHint.TextColor3 = Color3.fromRGB(145, 155, 175)
DelayInlineHint.TextSize = 10
DelayInlineHint.Font = Enum.Font.Gotham
DelayInlineHint.TextXAlignment = Enum.TextXAlignment.Left
DelayInlineHint.ZIndex = 14
DelayInlineHint.Parent = DelayInlineFrame

local DelayRowsHolder = Instance.new("Frame")
DelayRowsHolder.Size = UDim2.new(1, -12, 0, 126)
DelayRowsHolder.Position = UDim2.new(0, 6, 0, 24)
DelayRowsHolder.BackgroundTransparency = 1
DelayRowsHolder.ZIndex = 14
DelayRowsHolder.Parent = DelayInlineFrame
local DelayRowsLayout = Instance.new("UIListLayout")
DelayRowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
DelayRowsLayout.Padding = UDim.new(0, 3)
DelayRowsLayout.Parent = DelayRowsHolder

local function CreateDelayGroupRow(groupKey, groupTitle, order)
    local Row = Instance.new("Frame")
    Row.Name = groupKey .. "DelayRow"
    Row.Size = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = Color3.fromRGB(29, 33, 46)
    Row.BorderSizePixel = 0
    Row.LayoutOrder = order
    Row.ZIndex = 14
    Row.Parent = DelayRowsHolder
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 5)
    RowCorner.Parent = Row

    local GroupLabel = Instance.new("TextLabel")
    GroupLabel.Size = UDim2.new(0, 94, 1, 0)
    GroupLabel.Position = UDim2.new(0, 8, 0, 0)
    GroupLabel.BackgroundTransparency = 1
    GroupLabel.Text = groupTitle
    GroupLabel.TextColor3 = Color3.fromRGB(160, 195, 245)
    GroupLabel.TextSize = 10
    GroupLabel.Font = Enum.Font.GothamBold
    GroupLabel.TextXAlignment = Enum.TextXAlignment.Left
    GroupLabel.ZIndex = 15
    GroupLabel.Parent = Row

    for unitIndex = 2, 4 do
        local column = unitIndex - 2
        local Cell = Instance.new("Frame")
        Cell.Size = UDim2.new(0, 66, 0, 36)
        Cell.Position = UDim2.new(0, 104 + column * 72, 0, 2)
        Cell.BackgroundTransparency = 1
        Cell.ZIndex = 15
        Cell.Parent = Row

        local CellLabel = Instance.new("TextLabel")
        CellLabel.Size = UDim2.new(1, 0, 0, 13)
        CellLabel.BackgroundTransparency = 1
        CellLabel.Text = "Unit " .. unitIndex
        CellLabel.TextColor3 = Color3.fromRGB(165, 165, 185)
        CellLabel.TextSize = 9
        CellLabel.Font = Enum.Font.Gotham
        CellLabel.ZIndex = 16
        CellLabel.Parent = Cell

        local Input = Instance.new("TextBox")
        Input.Size = UDim2.new(1, 0, 0, 21)
        Input.Position = UDim2.new(0, 0, 0, 14)
        Input.BackgroundColor3 = Color3.fromRGB(39, 43, 57)
        Input.Text = tostring(State.BuffDelays[groupKey][unitIndex])
        Input.PlaceholderText = "sec"
        Input.TextColor3 = Color3.fromRGB(240, 240, 250)
        Input.TextSize = 10
        Input.Font = Enum.Font.Gotham
        Input.ClearTextOnFocus = false
        Input.ZIndex = 16
        Input.Parent = Cell
        local InputCorner = Instance.new("UICorner")
        InputCorner.CornerRadius = UDim.new(0, 4)
        InputCorner.Parent = Input
        Input.FocusLost:Connect(function()
            local value = tonumber(Input.Text)
            if value and value >= 0 and value <= 30 then
                SetBuffDelay(groupKey, unitIndex, value)
                Input.Text = tostring(value)
            else
                Input.Text = tostring(State.BuffDelays[groupKey][unitIndex])
            end
        end)
    end
end

CreateDelayGroupRow("commander", "Commander", 1)
CreateDelayGroupRow("windsong", "Windsong", 2)
CreateDelayGroupRow("elfy", "Elfy (Sylph)", 3)

local DelayInlineFooter = Instance.new("TextLabel")
DelayInlineFooter.Size = UDim2.new(1, -16, 0, 14)
DelayInlineFooter.Position = UDim2.new(0, 8, 1, -16)
DelayInlineFooter.BackgroundTransparency = 1
DelayInlineFooter.Text = "บันทึกอัตโนมัติเมื่อกด Enter หรือคลิกออกจากช่อง"
DelayInlineFooter.TextColor3 = Color3.fromRGB(115, 125, 145)
DelayInlineFooter.TextSize = 9
DelayInlineFooter.Font = Enum.Font.Gotham
DelayInlineFooter.TextXAlignment = Enum.TextXAlignment.Left
DelayInlineFooter.ZIndex = 14
DelayInlineFooter.Parent = DelayInlineFrame

local DelaySettingsExpanded = false
local function SetDelaySettingsExpanded(expanded)
    DelaySettingsExpanded = expanded
    DelayInlineFrame.Visible = expanded
    DelayContainer.Size = UDim2.new(1, -10, 0, expanded and 192 or 30)
    DelayOpenButton.Text = expanded and "⚙  Auto Buff Delay Settings  ▴" or "⚙  Auto Buff Delay Settings  ▾"
end
DelayOpenButton.MouseButton1Click:Connect(function()
    SetDelaySettingsExpanded(not DelaySettingsExpanded)
end)

CreateSection(AutoPlayPage, "Hybrid Units", 22)
CreateHint(AutoPlayPage, "Hybrid units can stand on Ground or Hill. Both options keep the current placement behavior.", 23, 28)
CreateToggle(AutoPlayPage, "Place on Ground", "PlaceHybridGround", 24)
CreateToggle(AutoPlayPage, "Place on Hill", "PlaceHybridHill", 25)
local HybridInfo = CreateHint(AutoPlayPage, "No hybrid units in the equipped squad.", 26, 32)

CreateSection(AutoPlayPage, "Unit Configuration", 27)
CreateHint(AutoPlayPage, "Leave a field empty to keep the current Auto Play behavior for that unit.", 28, 28)

local UnitConfigHolder = Instance.new("Frame")
UnitConfigHolder.Name = "UnitConfigHolder"
UnitConfigHolder.Size = UDim2.new(1, -10, 0, 0)
UnitConfigHolder.AutomaticSize = Enum.AutomaticSize.Y
UnitConfigHolder.BackgroundTransparency = 1
UnitConfigHolder.LayoutOrder = 29
UnitConfigHolder.ZIndex = 12
UnitConfigHolder.Parent = AutoPlayPage
local UnitConfigList = Instance.new("UIListLayout")
UnitConfigList.SortOrder = Enum.SortOrder.LayoutOrder
UnitConfigList.Padding = UDim.new(0, 6)
UnitConfigList.Parent = UnitConfigHolder

local unitExpanded = {}
local lastUnitKey = nil

local function SetUnitField(unitId, displayName, field, value)
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

local function AddConfigBox(parent, label, placeholder, order, getter, setter)
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

local function RefreshUnitConfigUI()
    local equipped = EnrichEquipped(GetEquippedUnitList())
    local hybridNames = {}
    local byId = {}
    local ordered = {}
    for _, info in ipairs(equipped) do
        if info.unitId and not byId[info.unitId] then
            byId[info.unitId] = info
            table.insert(ordered, info)
            if info.hybrid then
                table.insert(hybridNames, info.name)
            end
        end
    end
    for id, cfg in pairs(State.UnitConfigs or {}) do
        if not byId[id] then
            local data = LookupUnitData(id)
            local info = {
                unitId = id,
                name = (cfg and cfg.displayName) or State.UnitNames[id] or (data and data.name) or id,
                spawnCap = data and tonumber(data.spawn_cap) or nil,
                maxUpgrade = data and type(data.upgrade) == "table" and #data.upgrade or nil,
                hybrid = data and data.hybrid_placement == true or false,
                hill = data and data.hill_unit == true or false,
            }
            byId[id] = info
            table.insert(ordered, info)
        end
    end
    table.sort(ordered, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)

    if #hybridNames > 0 then
        HybridInfo.Text = "Equipped hybrid: " .. table.concat(hybridNames, ", ")
    else
        HybridInfo.Text = "No hybrid units in the equipped squad."
    end

    local keyParts = {}
    for _, info in ipairs(ordered) do
        table.insert(keyParts, info.unitId .. ":" .. tostring(info.spawnCap) .. ":" .. tostring(info.maxUpgrade))
    end
    local key = table.concat(keyParts, "|")
    if key == lastUnitKey then
        return
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
        return
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
        local capText = info.spawnCap and ("cap " .. tostring(info.spawnCap)) or "cap ?"
        local upText = info.maxUpgrade and ("upgrades " .. tostring(info.maxUpgrade)) or "upgrades ?"

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
end

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

local eventAutomationStopped = false

CreateToggle(EventPage, "Auto Find Match (Summer Hunt)", "AutoFindMatch", 1, function(isON)
    -- Manually toggling Auto Find Match back on resumes event automation.
    eventAutomationStopped = false
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
CreateSection(EventPage, "Pick Card", 4)
CreatePriorityEditor(EventPage, "Buff Card Selection", "Checked buffs are preferred, from top to bottom. Leave all unchecked to keep automatic selection.", BUFF_DEFS, "BuffPriority", 5)
CreatePriorityEditor(EventPage, "Debuff Card Selection", "Checked debuffs are avoided, from top to bottom. Leave all unchecked to keep automatic selection.", DEBUFF_DEFS, "DebuffAvoid", 8)
CreateToggle(EventPage, "Auto Replay Match", "AutoReplay", 11)

local WebhookStatus
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
            description = string.format("**Player:** %s\nTest message from Octoput Hub.", player.Name),
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

CreateToggle(MiscPage, "Blackscreen (reduce 3D render)", "BlackScreen", 1, function(isON)
    ApplyBlackScreen(isON)
end)
CreateToggle(MiscPage, "Auto Hide GUI on Execute", "AutoHideGUIOnExecute", 2, function(isON)
    -- This setting is saved and takes effect on the next script execution.
end)
CreateHint(MiscPage, "When enabled, the hub runs normally but its window starts hidden. Press Right Shift to show or hide it.", 3, 34)
CreateSingleSlider(MiscPage, "UI Scale", "50% smaller    150% larger", 4, 50, 150, function()
    return math.floor(State.UIScale * 100 + 0.5)
end, function(value)
    State.UIScale = math.clamp(value / 100, 0.5, 1.5)
    HubScale.Scale = State.UIScale
end)

local BuffChains = {
    commander = { phase = 1, cycleStart = 0, nextCastAt = 0, unitOrder = {} },
    windsong = { phase = 1, cycleStart = 0, nextCastAt = 0, unitOrder = {} },
    elfy = { phase = 1, cycleStart = 0, nextCastAt = 0, unitOrder = {} },
}

local function GetBuffChainCooldown(units, index)
    local unit = units and units[index or 1]
    if unit and unit:FindFirstChild("_stats") then
        local value = unit._stats:FindFirstChild("active_attack_cooldown")
        if value and tonumber(value.Value) then
            return math.max(1, tonumber(value.Value))
        end
    end
    return 60
end

local function GetBuffChainCurseOffset(units)
    -- Legacy SPA-derived offset retained as a fallback/reference for diagnostics.
    local unit = units and units[1]
    local stats = unit and unit:FindFirstChild("_stats")
    if stats then
        local candidates = {
            "attack_cooldown", "base_attack_cooldown",
            "cooldown", "spa", "base_spa"
        }
        for _, name in ipairs(candidates) do
            local value = stats:FindFirstChild(name)
            local number = value and tonumber(value.Value)
            if number and number > 0 then
                return math.clamp(math.floor(number) % 10, 3, 7)
            end
        end
        -- Some versions expose only the active cooldown. Do not derive SPA
        -- from that value; use a conservative 5s offset if SPA is unavailable.
    end
    return 5
end

local function GetConfiguredBuffDelay(groupName, nextUnitIndex)
    local group = State.BuffDelays and State.BuffDelays[groupName]
    local value = group and tonumber(group[nextUnitIndex])
    if value == nil then return 0.7 end
    return math.clamp(value, 0, 30)
end

local function ResetBuffChain(chain, units)
    chain.unitOrder = table.clone(units)
    chain.phase = 1
    chain.cycleStart = 0
    chain.nextCastAt = 0
end

local farmStall = { count = 0, lastChange = 0 }
local matchEndHandled = false

-- Farm-first means all placed farm units must reach their configured upgrade
-- target before Auto Place spends resources on Griffith, buffers, or attackers.
-- The upgrade worker above remains responsible for performing the upgrades.
local function HasPendingFarmUpgrade(myUnits)
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
local votedStart = false
local lobbyStartSent = false
local lastLobbyStartAttempt = 0
local unitRefreshClock = 0

local function ResultsButtons()
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

local function ButtonText(button)
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

local function NextActionAvailable()
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

local function FireGuiButton(button)
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

local function GetCurrentLobbyId()
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

local function RequestLobbyStart(lobbyId)
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

local function TryAutoStart()
    if not State.AutoStart then
        votedStart = false
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
    local open = voteGui and voteGui.Enabled and (not finished or finished.Value == false)
    if open then
        if not votedStart then
            votedStart = true
            local yes = voteGui:FindFirstChild("Holder")
                and voteGui.Holder:FindFirstChild("ButtonHolder")
                and voteGui.Holder.ButtonHolder:FindFirstChild("Yes")
            if yes then
                FireGuiButton(yes)
            else
                InvokeEndpoint("vote_start")
            end
        end
    else
        votedStart = false
    end
end

local function HandleMatchEnd(gameFinished)
    if not gameFinished or gameFinished.Value ~= true then
        matchEndHandled = false
        return
    end
    if matchEndHandled then
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

AllowSave = true
if State.BlackScreen then
    ApplyBlackScreen(true)
end
RefreshUnitConfigUI()

-- Estimate the next upgrade price from live unit stats first, then unit data.
-- Unknown prices sort last instead of being mistaken for free upgrades.
local function GetNextUpgradeCost(unit)
    if not unit or not unit:FindFirstChild("_stats") then return math.huge end
    local stats = unit._stats
    local keys = { "next_upgrade_cost", "upgrade_cost", "next_cost", "upgrade_price" }
    local best = nil
    for _, child in ipairs(stats:GetDescendants()) do
        local name = NormalizeName(child.Name)
        local isCost = false
        for _, key in ipairs(keys) do
            if name == NormalizeName(key) or name:find("upgradecost", 1, true) then
                isCost = true break
            end
        end
        if isCost and (child:IsA("NumberValue") or child:IsA("IntValue") or child:IsA("StringValue")) then
            local value = tonumber(child.Value)
            if value and value >= 0 then best = value break end
        end
    end
    if best ~= nil then return best end

    local current = stats:FindFirstChild("upgrade")
    local data = LookupUnitData(GetRawUnitId(unit))
    local upgrades = type(data) == "table" and data.upgrade or nil
    if current and type(upgrades) == "table" then
        local nextInfo = upgrades[(tonumber(current.Value) or 0) + 1]
        if type(nextInfo) == "table" then
            local value = tonumber(nextInfo.cost or nextInfo.upgrade_cost or nextInfo.price)
            if value then return value end
        end
    end
    return math.huge
end

local pendingUpgradeRequests = {}
local pendingSpawnRequests = {}
local abilityCursor = 1

-- Run upgrades in their own worker so a slow upgrade request cannot stall Auto Place.
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoUpgrade and not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
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

            for _, unit in ipairs(units) do
                local stats = unit:FindFirstChild("_stats")
                local level = stats and stats:FindFirstChild("upgrade")
                local maximum = stats and stats:FindFirstChild("max_upgrade")
                if level and maximum and level.Value < maximum.Value and not pendingUpgradeRequests[unit] then
                    local cfg = GetUnitConfig(GetRawUnitId(unit))
                    local allowed = true
                    local wave = GetCurrentWave()
                    if cfg then
                        if cfg.upgradeStartWave ~= nil and wave < cfg.upgradeStartWave then allowed = false end
                        if cfg.upgradeTarget ~= nil and level.Value >= cfg.upgradeTarget then allowed = false end
                    end
                    if allowed then
                        table.insert(candidates, { unit = unit, cost = GetNextUpgradeCost(unit), farm = IsFarmUnit(unit) })
                    end
                end
            end

            if #candidates > 0 then
                local farmPriority = State.AutoUpgradeFarmFirst or State.AutoBuffGriffith
                table.sort(candidates, function(a, b)
                    if farmPriority and a.farm ~= b.farm then return a.farm end
                    if a.cost ~= b.cost then return a.cost < b.cost end
                    local aLevel = a.unit._stats.upgrade.Value
                    local bLevel = b.unit._stats.upgrade.Value
                    if aLevel ~= bLevel then return aLevel < bLevel end
                    return tostring(a.unit) < tostring(b.unit)
                end)
                local target = candidates[1].unit
                InvokeEndpoint("upgrade_unit_ingame", target)
                pendingUpgradeRequests[target] = { level = target._stats.upgrade.Value, time = now }
            end
        else
            table.clear(pendingUpgradeRequests)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local workerOk, workerError = pcall(function()
        SuppressErrorNotifications()
        unitRefreshClock = unitRefreshClock + 0.5
        if unitRefreshClock >= 2 then
            unitRefreshClock = 0
            pcall(RefreshUnitConfigUI)
        end

        if not IsInLobby() and workspace:FindFirstChild("_UNITS") ~= nil then
            local myUnits = GetPlayerUnits()
            local wave = GetCurrentWave()

            if State.AutoPlace then
                local equipped = EnrichEquipped(GetEquippedUnitList())
                if #equipped > 0 then
                    local partyHasGriffith = false
                    local partyHasFarm = false
                    for _, info in ipairs(equipped) do
                        if IsGriffithName(info.name) or IsGriffithName(info.unitId) then
                            partyHasGriffith = true
                        end
                        if IsFarmInfo(info) then
                            partyHasFarm = true
                        end
                    end

                    -- Griffith-specific placement order runs only when Auto Buff 100% (Griffith) is enabled.
                    local useGriffithOrder = State.AutoBuffGriffith and partyHasGriffith
                    local griffithCount = CountCategory(myUnits, IsGriffithUnit)
                    local griffithReincarnated = false
                    for _, u in ipairs(myUnits) do
                        if IsGriffithReincarnation(u) then
                            griffithReincarnated = true
                            break
                        end
                    end

                    -- Require every equipped farm type to be placed once. The previous
                    -- farmCount > 0 check advanced after only Bulby/C.E.O and skipped
                    -- Weathering Girl for the rest of the match.
                    local farmRequirements = {}
                    for _, info in ipairs(equipped) do
                        if IsFarmInfo(info) then
                            local key = NormalizeName(info.unitId or info.name)
                            if key ~= "" then farmRequirements[key] = info end
                        end
                    end
                    local farmsReady = true
                    for key, info in pairs(farmRequirements) do
                        if CountPlacedInfo(info) < 1 then
                            farmsReady = false
                            break
                        end
                    end

                    -- During farm setup, skip farm types that are already placed.
                    -- Without this check the first farm in the equipped list (e.g. Bulby)
                    -- can be selected repeatedly and block the next farm (Weathering Girl).
                    local function FarmNeedsPlacement(info)
                        if not IsFarmInfo(info) then return false end
                        return CountPlacedInfo(info) < 1
                    end

                    local farmCount = CountCategory(myUnits, IsFarmUnit)
                    if farmCount ~= farmStall.count then
                        farmStall.count = farmCount
                        farmStall.lastChange = tick()
                    elseif farmStall.lastChange == 0 then
                        farmStall.lastChange = tick()
                    end

                    -- Buffs remain eligible after Griffith evolves. Count equipped copies
                    -- (up to the four required by the cursed rotation) per buff group.
                    local buffRequired = { commander = 0, windsong = 0, elfy = 0 }
                    local buffPlaced = { commander = 0, windsong = 0, elfy = 0 }
                    for _, info in ipairs(equipped) do
                        local group = GetBuffChainGroupFromText(info.unitId, info.name)
                        if group then buffRequired[group] = 1 end
                    end
                    -- A present buff group must reach four placed copies for the curse loop.
                    -- Respect a lower configured/spawn cap if the game data defines one.
                    for group, present in pairs(buffRequired) do
                        if present > 0 then
                            local target = 4
                            for _, info in ipairs(equipped) do
                                local matches = GetBuffChainGroupFromText(info.unitId, info.name) == group
                                if matches then
                                    local cap = tonumber(info.spawnCap)
                                    local cfg = GetUnitConfig(info.unitId)
                                    if cfg and tonumber(cfg.maxPlace) then cap = cap and math.min(cap, cfg.maxPlace) or cfg.maxPlace end
                                    if cap then target = math.min(target, cap) end

                                    -- If teammates already consumed the shared cap, count
                                    -- this buff group as complete for placement sequencing.
                                    local globalCap = tonumber(info.globalSpawnCap)
                                    if not globalCap then
                                        local data = LookupUnitData(info.unitId)
                                        globalCap = type(data) == "table" and tonumber(data.global_spawn_cap) or nil
                                    end
                                    if globalCap then
                                        local globalCount = CountGlobalPlacedInfo(info)
                                        local remainingGlobal = math.max(0, globalCap - globalCount)
                                        target = math.min(target, buffPlaced[group] + remainingGlobal)
                                    end
                                    break
                                end
                            end
                            buffRequired[group] = target
                        end
                    end
                    for _, unit in ipairs(myUnits) do
                        local group = GetBuffChainGroup(unit)
                        if group then buffPlaced[group] = buffPlaced[group] + 1 end
                    end
                    local buffsReady = true
                    for group, required in pairs(buffRequired) do
                        if required > 0 and buffPlaced[group] < required then
                            buffsReady = false
                            break
                        end
                    end

                    local function CanPlaceInfo(info)
                        if not useGriffithOrder then return true end
                        local isFarm = IsFarmInfo(info)
                        local isGriff = IsGriffithName(info.name) or IsGriffithName(info.unitId)
                        local isBuff = IsBuffName(info.name) or IsBuffName(info.unitId)

                        -- Once Griffith has evolved, stop the sacrifice/farm phase,
                        -- but continue placing the required support/buff units first.
                        -- Only release regular attackers after the buff setup is complete.
                        if griffithReincarnated then
                            if not buffsReady then
                                return isBuff
                            end
                            return not isGriff and not isFarm and not isBuff
                        end

                        -- Phase 1: every equipped farm type at least once.
                        -- Only the farm types still missing a placement are eligible.
                        if partyHasFarm and not farmsReady then return isFarm and FarmNeedsPlacement(info) end
                        -- Phase 2: Griffith only after the farm setup is complete.
                        if griffithCount < 1 then return isGriff end
                        -- Phase 3: finish the required cursed support copies before attackers.
                        if not buffsReady then return isBuff end
                        -- Phase 4: release regular attack units.
                        return not isGriff and not isFarm and not isBuff
                    end

                    -- In Griffith mode, explicitly prioritize farms regardless of the
                    -- equipped-list order (which may put Griffith at index 1).
                    if useGriffithOrder and partyHasFarm then
                        table.sort(equipped, function(a, b)
                            local aFarm = FarmNeedsPlacement(a)
                            local bFarm = FarmNeedsPlacement(b)
                            if aFarm ~= bFarm then
                                return aFarm
                            end
                            return false
                        end)
                    end

                    -- When Auto Upgrade Farm First is enabled, do not spend money
                    -- on non-farm placements while any placed farm is still below
                    -- its configured upgrade target. This also holds Griffith until
                    -- farm upgrades are complete, preserving the farm-first economy.
                    local farmUpgradePending = useGriffithOrder and HasPendingFarmUpgrade(myUnits)
                    if farmUpgradePending then
                        UpdateAutoPlayStatus("Farm upgrades first - saving for farm upgrades", Color3.fromRGB(255, 200, 80))
                    end

                    local eligible = {}
                    local now = tick()
                    for uuid, pending in pairs(pendingSpawnRequests) do
                        local info = nil
                        for _, equippedInfo in ipairs(equipped) do
                            if tostring(equippedInfo.uuid or "") == uuid then info = equippedInfo break end
                        end
                        local observed = info and CountPlacedInfo(info) or 0
                        if (pending.countBefore and observed > pending.countBefore) or now - pending.time > 8 then
                            pendingSpawnRequests[uuid] = nil
                        end
                    end
                    local missingFirst = {}
                    for _, unitInfo in ipairs(equipped) do
                        local uuidKey = tostring(unitInfo.uuid or "")
                        local farmUpgradeAllowsPlacement = not farmUpgradePending or IsFarmInfo(unitInfo)
                        local isSecondGriffith = useGriffithOrder
                            and (IsGriffithName(unitInfo.name) or IsGriffithName(unitInfo.unitId))
                            and griffithCount >= 1
                        if uuidKey ~= "" and not pendingSpawnRequests[uuidKey]
                            and not isSecondGriffith and farmUpgradeAllowsPlacement
                            and CanPlaceInfo(unitInfo) and CanPlaceConfigured(unitInfo, wave) then
                            table.insert(eligible, unitInfo)
                            if CountPlacedInfo(unitInfo) < 1 then
                                table.insert(missingFirst, unitInfo)
                            end
                        end
                    end

                    -- First guarantee one placement for every equipped unit type; after
                    -- that, randomly fill remaining allowed copies until each cap is met.
                    if #missingFirst > 0 then eligible = missingFirst end
                    if #eligible > 0 then
                        local chosen = eligible[math.random(1, #eligible)]
                        local placeIndex = #myUnits + math.random(1, 12)
                        local cframe, kind
                        if IsGriffithBuddySelected(chosen.unitId) then
                            cframe, kind = GetPlacementCFrameNearGriffith(chosen, myUnits)
                        end
                        if not cframe then cframe, kind = GetPlacementCFrameForInfo(placeIndex, chosen) end
                        if cframe then
                            local countBefore = CountPlacedInfo(chosen)
                            InvokeEndpoint("spawn_unit", chosen.uuid, cframe)
                            pendingSpawnRequests[tostring(chosen.uuid)] = {
                                time = now,
                                unitId = chosen.unitId,
                                countBefore = countBefore,
                            }
                        end
                    end
                end
            else
                farmStall = { count = 0, lastChange = 0 }
                table.clear(pendingSpawnRequests)
            end

            if State.AutoBuffChain and #myUnits > 0 then
                local groups = {
                    commander = {},
                    windsong = {},
                    elfy = {},
                }

                for _, u in ipairs(myUnits) do
                    local g = GetBuffChainGroup(u)
                    if g and groups[g] then
                        table.insert(groups[g], u)
                    end
                end

                -- Activate buffs only for equipped groups, and wait until each
                -- equipped group has four placed copies. Groups not equipped by the
                -- player are ignored completely and cannot block the rotation.
                local requiredBuffGroups = {}
                local equippedBuffs = EnrichEquipped(GetEquippedUnitList())
                for _, info in ipairs(equippedBuffs) do
                    local group = GetBuffChainGroupFromText(info.unitId, info.name)
                    if group then requiredBuffGroups[group] = true end
                end

                local allRequiredBuffGroupsReady = true
                for groupName in pairs(requiredBuffGroups) do
                    if #groups[groupName] < 4 then
                        allRequiredBuffGroupsReady = false
                        break
                    end
                end

                local now = tick()
                if allRequiredBuffGroupsReady and next(requiredBuffGroups) ~= nil then
                    -- Rotate ONLY buff groups that are currently equipped by this player.
                    -- A disabled/unowned group must never be treated as a requirement or
                    -- receive casts just because four matching units happen to be present.
                    for groupName in pairs(requiredBuffGroups) do
                        local allUnits = groups[groupName] or {}
                        -- Cursed 100% method uses four copies of the SAME buffer.
                        -- Extra copies are left untouched by this rotation.
                        local units = {}
                        for i = 1, math.min(4, #allUnits) do
                            table.insert(units, allUnits[i])
                        end

                        local chain = BuffChains[groupName]
                        if #units == 4 then
                            local changed = #chain.unitOrder ~= 4
                            if not changed then
                                for i, unit in ipairs(units) do
                                    if chain.unitOrder[i] ~= unit then
                                        changed = true
                                        break
                                    end
                                end
                            end

                            if changed then
                                ResetBuffChain(chain, units)
                            end

                            if now >= chain.nextCastAt then
                                local phase = chain.phase
                                local unit = units[phase]
                                if unit and CanUseActiveAttack(unit) then
                                    InvokeEndpoint("use_active_attack", unit)

                                    if phase == 1 then
                                        chain.cycleStart = now
                                        chain.nextCastAt = now + GetConfiguredBuffDelay(groupName, 2)
                                        chain.phase = 2
                                    elseif phase == 2 then
                                        chain.nextCastAt = now + GetConfiguredBuffDelay(groupName, 3)
                                        chain.phase = 3
                                    elseif phase == 3 then
                                        chain.nextCastAt = now + GetConfiguredBuffDelay(groupName, 4)
                                        chain.phase = 4
                                    else
                                        -- Start the next cycle when unit 1 is genuinely ready again.
                                        chain.nextCastAt = chain.cycleStart
                                            + GetBuffChainCooldown(units, 1)
                                        chain.phase = 1
                                    end

                                    UpdateAutoPlayStatus(
                                        "Cursed Buff Rotation: " .. groupName
                                            .. " " .. tostring(phase) .. "/4",
                                        Color3.fromRGB(100, 255, 100)
                                    )
                                end
                            end
                        else
                            chain.unitOrder = {}
                            chain.phase = 1
                            chain.cycleStart = 0
                            chain.nextCastAt = 0
                        end
                    end
                else
                    -- Keep every rotation idle until all required groups reach 4 units.
                    for _, chain in pairs(BuffChains) do
                        chain.unitOrder = {}
                        chain.phase = 1
                        chain.cycleStart = 0
                        chain.nextCastAt = 0
                    end
                    if next(requiredBuffGroups) ~= nil then
                        UpdateAutoPlayStatus(
                            "Waiting for equipped buff groups (4 each)",
                            Color3.fromRGB(255, 190, 80)
                        )
                    end
                end
            end

            if State.AutoBuffGriffith and #myUnits > 0 then
                for _, u in ipairs(myUnits) do
                    if IsGriffithUnit(u) and not IsGriffithReincarnation(u) and CanUseActiveAttack(u) then
                        InvokeEndpoint("use_active_attack", u)
                        UpdateAutoPlayStatus("Griffith Buff 100% Activated!", Color3.fromRGB(255, 215, 0))
                    end
                end
            end

            if State.AutoUseAbility and #myUnits > 0 then
                local abilityUnits = {}
                for _, unit in ipairs(myUnits) do
                    local isChain = State.AutoBuffChain and (GetBuffChainGroup(unit) ~= nil)
                    local isGriffithBuff = State.AutoBuffGriffith and IsGriffithUnit(unit)
                    if not isChain and not isGriffithBuff then table.insert(abilityUnits, unit) end
                end
                if #abilityUnits > 0 then
                    abilityCursor = ((abilityCursor - 1) % #abilityUnits) + 1
                    -- Cast at most one ability per scan, advancing the cursor so a 3-unit
                    -- or 4-unit squad receives a complete, even rotation without burst casts.
                    for offset = 0, #abilityUnits - 1 do
                        local index = ((abilityCursor + offset - 1) % #abilityUnits) + 1
                        local unit = abilityUnits[index]
                        if CanUseActiveAttack(unit) then
                            InvokeEndpoint("use_active_attack", unit)
                            abilityCursor = (index % #abilityUnits) + 1
                            break
                        end
                    end
                else
                    abilityCursor = 1
                end
            else
                abilityCursor = 1
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

task.spawn(function()
    while true do
        task.wait(1.5)

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
                    InvokeEndpoint("request_matchmaking", EVENT_LEVEL_ID)
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

        if State.AutoEventQuests then
            InvokeEndpoint("claim_summer2_map_board_lines")
        end
    end
end)

local webhookSent = false
local webhookGameWasActive = false
task.spawn(function()
    while true do
        task.wait(1)
        local dataFolder = workspace:FindFirstChild("_DATA")
        local gameFinished = dataFolder and dataFolder:FindFirstChild("GameFinished")
        local inGame = dataFolder ~= nil and gameFinished ~= nil

        if inGame and gameFinished.Value ~= true then
            if not webhookGameWasActive then
                CaptureWebhookCurrencyBaseline()
                webhookGameWasActive = true
            end
            webhookSent = false
        elseif gameFinished and gameFinished.Value == true then
            if not webhookSent and State.WebhookOnEnd then
                webhookSent = true
                task.spawn(SendEndWebhook)
            end
        else
            webhookGameWasActive = false
            webhookSent = false
            webhookCurrencyBefore = nil
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

print("XT Hub UI Loaded Successfully! Auto Play, Webhook & Misc are ready.")
