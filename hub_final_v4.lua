-- ═══════════════════════════════════════════════════════════
-- DELTA / LUAU COMPATIBILITY STUBS
-- ═══════════════════════════════════════════════════════════
local function _stub() end
local function _stubF(f) return f end
local function _stubB(a,b) return a end
local function _stubN() return nil end

if not isexecutorclosure  then isexecutorclosure  = function() return false end end
if not newcclosure         then newcclosure        = _stubF end
if not getconnections      then getconnections     = function() return {} end end
if not getupvalue          then getupvalue         = _stubN end
if not setfpscap           then setfpscap          = _stub end
if not checkcaller         then checkcaller        = function() return false end end
if not clonefunction       then clonefunction      = _stubF end
if not hookfunction        then hookfunction       = _stubB end
if not identifyexecutor    then identifyexecutor   = function() return "delta","1" end end
if not writefile           then writefile          = _stub end
if not readfile            then readfile           = function() return "" end end
if not isfile              then isfile             = function() return false end end
if not request             then request            = _stub end
if not fireproximityprompt then fireproximityprompt = _stub end
if not getscriptbytecode   then getscriptbytecode  = _stub end
if not decompile           then decompile          = _stub end

-- Safe debug patching (debug table exists in Luau but methods may be missing)
pcall(function()
    if not debug then debug = {} end
    if not debug.getupvalues then debug.getupvalues = function() return {} end end
    if not debug.setupvalue  then debug.setupvalue  = _stub end
    if not debug.getupvalue  then debug.getupvalue  = _stubN end
    if not debug.setconstant then debug.setconstant = _stub end
    if not debug.getconstants then debug.getconstants = function() return {} end end
end)

-- raknet stub
if not raknet then
    raknet = {
        add_send_hook    = _stub,
        remove_send_hook = _stub,
        desync           = _stub,
    }
end

-- buffer stub (missing in older Delta builds)
if not buffer then
    buffer = {
        writeu32 = _stub,
        writei32 = _stub,
        writeu8  = _stub,
        readu32  = function() return 0 end,
        readu8   = function() return 0 end,
    }
end
-- ═══════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end
pcall(function() game:GetService("Players").RespawnTime = 0 end)
pcall(function() if setfpscap then setfpscap(9999) end end)
local privateBuild = false

local SharedState = {
    ConveyorAnimals = {},
    BestConveyorGv = -1,
    SelectedPetData = nil,
    AllAnimalsCache = nil,
    DisableStealSpeed = nil,
    ListNeedsRedraw = true,
    AdminButtonCache = {},
    StealSpeedToggleFunc = nil,
    _ssUpdateBtn = nil,
    AdminProxBtn = nil,
    BalloonedPlayers = {},
    MobileScaleObjects = {},
    RefreshMobileScale = nil,
}

pcall(function()
    local Sync = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
    local patched = 0

    for name, fn in pairs(Sync) do
        if typeof(fn) ~= "function" then continue end
        if isexecutorclosure(fn) then continue end

        local ok, ups = pcall(debug.getupvalues, fn)
        if not ok then continue end

        for idx, val in pairs(ups) do
            if typeof(val) == "function" and not isexecutorclosure(val) then
                local ok2, innerUps = pcall(debug.getupvalues, val)
                if ok2 then
                    local hasBoolean = false
                    for _, v in pairs(innerUps) do
                        if typeof(v) == "boolean" then
                            hasBoolean = true
                            break
                        end
                    end
                    if hasBoolean then
                        debug.setupvalue(fn, idx, newcclosure(function() end))
                        patched += 1
                    end
                end
            end
        end
    end
    print("Hero Hub loaded")
end)

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    GuiService = game:GetService("GuiService"),
    TeleportService = game:GetService("TeleportService"),
}
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local Workspace = Services.Workspace
local Lighting = Services.Lighting
local VirtualInputManager = Services.VirtualInputManager
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ── HERO HUB INTRO ──────────────────────────────────────────────────────────
task.spawn(function()
    local themeColor   = Color3.fromRGB(170, 0, 255)
    local secondaryColor = Color3.fromRGB(200, 100, 255)

    if PlayerGui:FindFirstChild("HeroHubIntro") then
        PlayerGui.HeroHubIntro:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HeroHubIntro"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.2
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    for i = 1, 6 do
        local scanline = Instance.new("Frame")
        scanline.Size = UDim2.new(1, 0, 0, 2)
        scanline.Position = UDim2.new(0, 0, 0, -100 - (i * 80))
        scanline.BackgroundColor3 = themeColor
        scanline.BackgroundTransparency = 0.3
        scanline.BorderSizePixel = 0
        scanline.Parent = container
        task.spawn(function()
            while container.Visible do
                scanline.Position = UDim2.new(0, 0, 0, -100 - (i * 80))
                TweenService:Create(scanline,
                    TweenInfo.new(1.5, Enum.EasingStyle.Linear),
                    {Position = UDim2.new(0, 0, 1.2, 0)}
                ):Play()
                task.wait(1.5)
            end
        end)
    end

    local heroText = Instance.new("TextLabel")
    heroText.Size = UDim2.new(0, 500, 0, 180)
    heroText.Position = UDim2.new(0, -550, 0.5, -90)
    heroText.BackgroundTransparency = 1
    heroText.Text = "HERO"
    heroText.Font = Enum.Font.GothamBlack
    heroText.TextSize = 110
    heroText.TextColor3 = themeColor
    heroText.TextStrokeTransparency = 0.7
    heroText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    heroText.TextTransparency = 0
    heroText.Parent = container

    local hubText = Instance.new("TextLabel")
    hubText.Size = UDim2.new(0, 500, 0, 180)
    hubText.Position = UDim2.new(1, 50, 0.5, -90)
    hubText.BackgroundTransparency = 1
    hubText.Text = "HUB"
    hubText.Font = Enum.Font.GothamBlack
    hubText.TextSize = 110
    hubText.TextColor3 = Color3.fromRGB(0, 0, 0)
    hubText.TextStrokeTransparency = 0
    hubText.TextStrokeColor3 = themeColor
    hubText.TextTransparency = 0
    hubText.Parent = container

    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(0, 0, 0, 4)
    bottomBar.Position = UDim2.new(0.5, 0, 0.72, 0)
    bottomBar.AnchorPoint = Vector2.new(0.5, 0)
    bottomBar.BackgroundColor3 = themeColor
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = container

    local versionText = Instance.new("TextLabel")
    versionText.Size = UDim2.new(0, 400, 0, 30)
    versionText.Position = UDim2.new(0.5, -200, 0.74, 0)
    versionText.BackgroundTransparency = 1
    versionText.Text = "HERO HUB"
    versionText.Font = Enum.Font.GothamBold
    versionText.TextSize = 30
    versionText.TextColor3 = secondaryColor
    versionText.TextTransparency = 1
    versionText.Parent = container

    local function createBracket(xPos, yPos, isHorizontal, isFlipped)
        local bracket = Instance.new("Frame")
        if isHorizontal then
            bracket.Size = UDim2.new(0, 40, 0, 3)
        else
            bracket.Size = UDim2.new(0, 3, 0, 40)
        end
        bracket.Position = UDim2.new(xPos, isFlipped and (isHorizontal and -40 or -3) or 0, yPos, isFlipped and (isHorizontal and -3 or -40) or 0)
        bracket.BackgroundColor3 = themeColor
        bracket.BorderSizePixel = 0
        bracket.Parent = container
        return bracket
    end

    local brackets = {
        createBracket(0.2, 0.3, true,  false),
        createBracket(0.2, 0.3, false, false),
        createBracket(0.8, 0.3, true,  true),
        createBracket(0.8, 0.3, false, true),
        createBracket(0.2, 0.7, true,  true),
        createBracket(0.2, 0.7, false, true),
        createBracket(0.8, 0.7, true,  true),
        createBracket(0.8, 0.7, false, true),
    }

    task.wait(0.5)

    TweenService:Create(heroText, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -480, 0.5, -90)}):Play()
    task.wait(0.03)
    TweenService:Create(hubText, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 20, 0.5, -90)}):Play()
    task.wait(0.2)
    TweenService:Create(bottomBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 800, 0, 4)}):Play()
    TweenService:Create(versionText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
    task.wait(0.25)
    TweenService:Create(heroText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(0, -600, 0.5, -90), TextTransparency = 1}):Play()
    TweenService:Create(hubText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 100, 0.5, -90), TextTransparency = 1}):Play()
    TweenService:Create(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
    TweenService:Create(versionText, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
    for _, bracket in pairs(brackets) do
        TweenService:Create(bracket, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
    end
    task.wait(0.3)
    container:Destroy()
    overlay:Destroy()
    screenGui:Destroy()
end)
-- ── END INTRO ────────────────────────────────────────────────────────────────

-- ── ANTI LAG MINI GUI ────────────────────────────────────────────────────────
task.spawn(function()
    local antiLagGui = Instance.new("ScreenGui")
    antiLagGui.Name = "HeroAntiLagBtn"
    antiLagGui.ResetOnSpawn = false
    antiLagGui.DisplayOrder = 10
    antiLagGui.Parent = PlayerGui

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 32)
    btn.Position = UDim2.new(0, 12, 0, 12)
    btn.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
    btn.BorderSizePixel = 0
    btn.Text = "⚡ good anti lag"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(186, 120, 255)
    btn.AutoButtonColor = false
    btn.Parent = antiLagGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(136, 72, 230)
    btnStroke.Thickness = 1.2
    btnStroke.Transparency = 0.3

    local applied = false
    btn.MouseButton1Click:Connect(function()
        if applied then return end
        applied = true
        btn.Text = "✓ applied!"
        btn.TextColor3 = Color3.fromRGB(120, 255, 160)
        btnStroke.Color = Color3.fromRGB(80, 200, 120)

        -- Anti lag logic
        local Lighting = game.Lighting
        local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9000000000
        Lighting.FogStart = 9000000000
        for _, descendant in pairs(game:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CastShadow = false
                descendant.Material = "Plastic"
                descendant.Reflectance = 0
                descendant.BackSurface = "SmoothNoOutlines"
                descendant.BottomSurface = "SmoothNoOutlines"
                descendant.FrontSurface = "SmoothNoOutlines"
                descendant.LeftSurface = "SmoothNoOutlines"
                descendant.RightSurface = "SmoothNoOutlines"
                descendant.TopSurface = "SmoothNoOutlines"
            end
        end
        for _, effect in pairs(Lighting:GetDescendants()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
        RunService.Heartbeat:Connect(function()
            local Plots = workspace:FindFirstChild("Plots")
            if Plots then
                for _, Plot in ipairs(Plots:GetChildren()) do
                    if Plot:IsA("Model") and Plot:FindFirstChild("Decorations") then
                        for _, Part in ipairs(Plot.Decorations:GetDescendants()) do
                            if Part:IsA("BasePart") then Part.Transparency = 0.8 end
                        end
                    end
                end
            end
        end)
        workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ForceField") then
                RunService.Heartbeat:Wait()
                descendant:Destroy()
            end
        end)

        task.wait(2)
        btn.Parent = nil
        antiLagGui:Destroy()
    end)
end)
-- ── END ANTI LAG ─────────────────────────────────────────────────────────────


local Decrypted
Decrypted = setmetatable({}, {
    __index = function(S, ez)
        local Netty = ReplicatedStorage.Packages.Net
        local prefix, path
        if     ez:sub(1,3) == "RE/" then prefix = "RE/";  path = ez:sub(4)
        elseif ez:sub(1,3) == "RF/" then prefix = "RF/";  path = ez:sub(4)
        else return nil end
        local Remote
        for i, v in Netty:GetChildren() do
            if v.Name == ez then
                Remote = Netty:GetChildren()[i + 1]
                break
            end
        end
        if Remote and not rawget(Decrypted, ez) then rawset(Decrypted, ez, Remote) end
        return rawget(Decrypted, ez)
    end
})
local Utility = {}
function Utility:LarpNet(F) return Decrypted[F] end
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

local IS_MOBILE = isMobile()


local FileName = "XisPublic_v1.json" 
local DefaultConfig = {
    Positions = {
        AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
        StealSpeed = {X = 0.02, Y = 0.18}, 
        Settings = {X = 0.834375, Y = 0.43590998043052839}, 
        InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
        AutoSteal = {X = 0.02, Y = 0.35}, 
        MobileControls = {X = 0.9, Y = 0.4},
        MobileBtn_TP = {X = 0.5, Y = 0.4},
        MobileBtn_CL = {X = 0.5, Y = 0.4},
        MobileBtn_SP = {X = 0.5, Y = 0.4},
        MobileBtn_IV = {X = 0.5, Y = 0.4},
        MobileBtn_UI = {X = 0.5, Y = 0.4},
        JobJoiner = {X = 0.5, Y = 0.85},
        DesyncPanel = {X = 0.3, Y = 0.5},
        AutoBuy   = {X = 0.01, Y = 0.35},
    }, 
    TpSettings = {
        Tool           = "Flying Carpet",
        Speed          = 2, 
        TpKey          = "T",
        CloneKey       = "V",
        TpOnLoad       = false,
        MinGenForTp    = "",
        CarpetSpeedKey = "Q",
        InfiniteJump   = false,
    },
    StealSpeed   = 20,
    ShowStealSpeedPanel = true,
    MenuKey      = "LeftControl",
    MobileGuiScale = 0.5,
    XrayEnabled  = true,
    AntiRagdoll  = 0,
    AntiRagdollV2 = true,
    PlayerESP    = true,
    FPSBoost     = true,
    TracerEnabled = true,
    BrainrotESP = true,
    LineToBase = false,
    StealNearest = false,
    StealHighest = true,
    StealPriority = false,
    DefaultToNearest = false,
    DefaultToHighest = false,
    DefaultToPriority = false,
    ReturnToBrainrot = true,
    FloatEnabled = false,
    FloatKey = "F",
    ShowStealingHUD = true,
    DesyncVisualizer = false,
    ConveyorESP = false,
    AutoBackToBrainrot = false,
    PriorityList = {},
    DefaultToDisable = false,
    UILocked     = false,
    HideAdminPanel = false,
    HideAutoSteal = false,
    CompactAutoSteal = false,
    AutoKickOnSteal = false,
    InstantSteal = false,
    InvisStealAngle = 233,
    SinkSliderValue = 5,
    AutoRecoverLagback = true,
    AutoInvisDuringSteal = false,
    InvisToggleKey = "I",
    ClickToAP = false,
    ClickToAPKeybind = "L",
    DisableClickToAPOnMoby = false,
    ProximityAP = false,
    ProximityAPKeybind = "P",
    ProximityRange = 15,
    StealSpeedKey = "C",
    ShowInvisPanel = true,
    ResetKey = "X",
    AutoResetOnBalloon = false,
    AntiBeeDisco = false,
    AutoDestroyTurrets = false,
    AutoTurretOnBrainrot = false,
    FOV = 70,
    SubspaceMineESP = false,
    AutoUnlockOnSteal = false,
    ShowUnlockButtonsHUD = true,
    AutoTPOnFailedSteal = false,
    AutoTPPriority = true,
    KickKey = "",
    CleanErrorGUIs = false,
    ClickToAPSingleCommand = false,
    RagdollSelfKey = "",
    DuelBaseESP = true,
    AlertsEnabled = true,
    AlertSoundID = "rbxassetid://6518811702",
    DisableProximitySpamOnMoby = false,
    DisableClickToAPOnKawaifu = false,
    DisableProximitySpamOnKawaifu = false,
    HideKawaifuFromPanel = false,
    AutoStealSpeed = false,
    ShowJobJoiner = true,
    JobJoinerKey = "J",
    AutoDesyncOnSteal = false,
    DesyncKeybind = "F",
    ShowDesyncPanel = true,
    CurrentTheme = "roxo",
    ShowMiniActions = true,
    AutoHideMiniUI = false,
    MiniUIPos = {X = 0.01, Y = 0.35},
    MiniUILocked = false,
    Blacklist = {},
    BlacklistESP = true,
    BlacklistMsg = "BLOCKED",
    AutoBuyEnabled = false,
    AutoBuyKey = "K",
    AutoBuyRange = 17,
    AutoBuyColor = {R=186, G=120, B=255},
    HideAutoBuyUI = false,
    HideStealSpeedUI = false,
    HideStatusHUD = false,
    HideInvisPanel = false,
    HidePlatformUI = false,
    PlatformOffset = 12.5,
    PlatformTime = 10,
    UltraLightMode = false,
}


local Config = DefaultConfig

if isfile and isfile(FileName) then
    pcall(function()
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if not ok then return end
        for k, v in pairs(DefaultConfig) do
            if decoded[k] == nil then decoded[k] = v end
        end
        if decoded.TpSettings then
            for k, v in pairs(DefaultConfig.TpSettings) do
                if decoded.TpSettings[k] == nil then decoded.TpSettings[k] = v end
            end
        end
        if decoded.Positions then
            for k, v in pairs(DefaultConfig.Positions) do
                if decoded.Positions[k] == nil then decoded.Positions[k] = v end
            end
        end
        if type(decoded.Blacklist) ~= "table" then decoded.Blacklist = {} end
        Config = decoded
    end)
end
Config.ProximityAP = false

-- Aplica tema imediatamente nos valores da tabela Theme
-- (antes das UIs serem construidas, para que ja usem as cores certas)
if Config.CurrentTheme and THEMES and THEMES[Config.CurrentTheme] then
    for k, v in pairs(THEMES[Config.CurrentTheme]) do Theme[k] = v end
end

local function SaveConfig()
    if writefile then
        pcall(function()
            local toSave = {}
            for k, v in pairs(Config) do toSave[k] = v end
            toSave.ProximityAP = false
            writefile(FileName, HttpService:JSONEncode(toSave))
        end)
    end
end

local function isMobyUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild("_moby_highlight") ~= nil
end

local HighlightName = "KaWaifu_NeonHighlight"
local function isKawaifuUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild(HighlightName) ~= nil
end

_G.InvisStealAngle = Config.InvisStealAngle
_G.SinkSliderValue = Config.SinkSliderValue
_G.AutoRecoverLagback = Config.AutoRecoverLagback
_G.AutoInvisDuringSteal = Config.AutoInvisDuringSteal
    _G.INVISIBLE_STEAL_KEY = Enum.KeyCode[Config.InvisToggleKey] or Enum.KeyCode.I
_G.invisibleStealEnabled = false
_G.RecoveryInProgress = false

local function getControls()
	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	return playerModule:GetControls()
end

local Controls = getControls()

local function kickPlayer()
    pcall(function()
        TeleportService:Teleport(1818, LocalPlayer)
    end)
    pcall(function()
        LocalPlayer:Kick("HERO HUB")
    end)
end

local function walkForward(seconds)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local Controls = getControls()
    local lookVector = hrp.CFrame.LookVector
    Controls:Disable()
    local startTime = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if os.clock() - startTime >= seconds then
            conn:Disconnect()
            hum:Move(Vector3.zero, false)
            Controls:Enable()
            return
        end
        hum:Move(lookVector, false)
    end)
end


local function instantClone()
    if _G.isCloning then return end
    _G.isCloning = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not (char and hum and backpack) then error("Missing character, humanoid, or backpack") end

        local cloner = backpack:FindFirstChild("Quantum Cloner") or char:FindFirstChild("Quantum Cloner")
        if not cloner then error("Quantum Cloner not found") end

        -- Equip and HOLD the cloner out for a little
        hum:EquipTool(cloner)
        task.wait(0.65)

        -- Try normal activate first while tool is held
        pcall(function()
            cloner:Activate()
        end)
        task.wait(0.2)

        -- Then do the lower-middle click for reliability
        local viewport = workspace.CurrentCamera.ViewportSize
        local x, y = viewport.X * 0.5, viewport.Y * 0.88

        for i = 1, 3 do
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            task.wait(0.12)
        end

        -- Wait for clone UI to fully appear
        task.wait(0.35)

        local targetText = "Change With Clone"
        local clicked = false

        for i = 1, 120 do
            for _, v in pairs(PlayerGui:GetDescendants()) do
                if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text and v.Text:find(targetText) then
                    local btn = v:IsA("GuiButton") and v or v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton")
                    if btn and btn.Visible and btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.Y > 0 then
                        task.wait(0.18)
                        local p, s = btn.AbsolutePosition, btn.AbsoluteSize
                        local cx, cy = p.X + (s.X / 2), p.Y + (s.Y / 2) + 58

                        -- Click the button twice for consistency
                        for _ = 1, 2 do
                            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                            task.wait(0.08)
                        end

                        clicked = true
                        break
                    end
                end
            end
            if clicked then break end
            task.wait(0.05)
        end

        if not clicked then
            warn("Change With Clone button not found.")
        end
    end)

    if not ok then
        warn("instantClone failed:", err)
    end

    _G.isCloning = false
end

local function triggerClosestUnlock(yLevel, maxY)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local playerY = yLevel or hrp.Position.Y
    local Y_THRESHOLD = 5

    local bestPromptSameLevel = nil
    local shortestDistSameLevel = math.huge

    local bestPromptFallback = nil
    local shortestDistFallback = math.huge
    
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, obj in ipairs(plots:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                if maxY and part.Position.Y > maxY then
                else
                    local distance = (hrp.Position - part.Position).Magnitude
                    local yDifference = math.abs(playerY - part.Position.Y)

                    if distance < shortestDistFallback then
                        shortestDistFallback = distance
                        bestPromptFallback = obj
                    end

                    if yDifference <= Y_THRESHOLD then
                        if distance < shortestDistSameLevel then
                            shortestDistSameLevel = distance
                            bestPromptSameLevel = obj
                        end
                    end
                end
            end
        end
    end

    local targetPrompt = bestPromptSameLevel or bestPromptFallback

    if targetPrompt then
        if fireproximityprompt then
            fireproximityprompt(targetPrompt)
        else
            targetPrompt:InputBegan(Enum.UserInputType.MouseButton1)
            task.wait(0.05)
            targetPrompt:InputEnded(Enum.UserInputType.MouseButton1)
        end
    end
end

local Theme = {
    Background       = Color3.fromRGB(14, 10, 24),
    Surface          = Color3.fromRGB(24, 18, 40),
    SurfaceHighlight = Color3.fromRGB(38, 28, 62),

    Accent1          = Color3.fromRGB(186, 120, 255),
    Accent2          = Color3.fromRGB(136, 72, 230),

    TextPrimary      = Color3.fromRGB(245, 238, 255),
    TextSecondary    = Color3.fromRGB(190, 168, 220),

    Success          = Color3.fromRGB(186, 120, 255),
    Error            = Color3.fromRGB(255, 110, 150),
}

-- ============================================================
-- SISTEMA DE TEMAS - sem `local` no top-level para nao exceder 200 locals
-- ============================================================
THEMES = {
    rosa = {
        Background       = Color3.fromRGB(20, 15, 20),
        Surface          = Color3.fromRGB(35, 25, 35),
        SurfaceHighlight = Color3.fromRGB(50, 35, 50),
        Accent1          = Color3.fromRGB(255, 120, 200),
        Accent2          = Color3.fromRGB(255, 70, 170),
        TextPrimary      = Color3.fromRGB(255, 240, 250),
        TextSecondary    = Color3.fromRGB(200, 160, 190),
        Success          = Color3.fromRGB(255, 120, 200),
        Error            = Color3.fromRGB(255, 90, 140),
        GlowColor1       = Color3.fromRGB(255, 120, 200),
        GlowColor2       = Color3.fromRGB(255, 70, 170),
    },
    ciano = {
        Background       = Color3.fromRGB(5, 18, 25),
        Surface          = Color3.fromRGB(10, 30, 40),
        SurfaceHighlight = Color3.fromRGB(15, 45, 58),
        Accent1          = Color3.fromRGB(0, 220, 255),
        Accent2          = Color3.fromRGB(0, 170, 230),
        TextPrimary      = Color3.fromRGB(220, 248, 255),
        TextSecondary    = Color3.fromRGB(140, 210, 230),
        Success          = Color3.fromRGB(0, 220, 255),
        Error            = Color3.fromRGB(255, 80, 120),
        GlowColor1       = Color3.fromRGB(0, 220, 255),
        GlowColor2       = Color3.fromRGB(0, 170, 230),
    },
    dourado = {
        Background       = Color3.fromRGB(15, 12, 5),
        Surface          = Color3.fromRGB(28, 22, 8),
        SurfaceHighlight = Color3.fromRGB(42, 33, 12),
        Accent1          = Color3.fromRGB(255, 215, 0),
        Accent2          = Color3.fromRGB(218, 165, 32),
        TextPrimary      = Color3.fromRGB(255, 245, 210),
        TextSecondary    = Color3.fromRGB(200, 170, 100),
        Success          = Color3.fromRGB(255, 215, 0),
        Error            = Color3.fromRGB(255, 90, 80),
        GlowColor1       = Color3.fromRGB(255, 215, 0),
        GlowColor2       = Color3.fromRGB(218, 165, 32),
    },
    prata = {
        Background       = Color3.fromRGB(12, 12, 18),
        Surface          = Color3.fromRGB(24, 24, 34),
        SurfaceHighlight = Color3.fromRGB(36, 36, 50),
        Accent1          = Color3.fromRGB(210, 215, 235),
        Accent2          = Color3.fromRGB(150, 155, 175),
        TextPrimary      = Color3.fromRGB(240, 240, 255),
        TextSecondary    = Color3.fromRGB(170, 170, 195),
        Success          = Color3.fromRGB(210, 215, 235),
        Error            = Color3.fromRGB(255, 90, 110),
        GlowColor1       = Color3.fromRGB(210, 215, 235),
        GlowColor2       = Color3.fromRGB(150, 155, 175),
    },
    preto = {
        Background       = Color3.fromRGB(4, 4, 6),
        Surface          = Color3.fromRGB(12, 12, 16),
        SurfaceHighlight = Color3.fromRGB(22, 22, 28),
        Accent1          = Color3.fromRGB(200, 200, 210),
        Accent2          = Color3.fromRGB(110, 110, 125),
        TextPrimary      = Color3.fromRGB(230, 230, 240),
        TextSecondary    = Color3.fromRGB(140, 140, 155),
        Success          = Color3.fromRGB(200, 200, 210),
        Error            = Color3.fromRGB(255, 70, 90),
        GlowColor1       = Color3.fromRGB(200, 200, 210),
        GlowColor2       = Color3.fromRGB(110, 110, 125),
    },
    roxo = {
        Background       = Color3.fromRGB(14, 10, 24),
        Surface          = Color3.fromRGB(24, 18, 40),
        SurfaceHighlight = Color3.fromRGB(38, 28, 62),
        Accent1          = Color3.fromRGB(186, 120, 255),
        Accent2          = Color3.fromRGB(136, 72, 230),
        TextPrimary      = Color3.fromRGB(245, 238, 255),
        TextSecondary    = Color3.fromRGB(190, 168, 220),
        Success          = Color3.fromRGB(186, 120, 255),
        Error            = Color3.fromRGB(255, 110, 150),
        GlowColor1       = Color3.fromRGB(186, 120, 255),
        GlowColor2       = Color3.fromRGB(136, 72, 230),
    },
    verde = {
        Background       = Color3.fromRGB(5, 15, 8),
        Surface          = Color3.fromRGB(10, 28, 14),
        SurfaceHighlight = Color3.fromRGB(15, 42, 20),
        Accent1          = Color3.fromRGB(0, 220, 80),
        Accent2          = Color3.fromRGB(0, 170, 60),
        TextPrimary      = Color3.fromRGB(220, 255, 230),
        TextSecondary    = Color3.fromRGB(130, 200, 150),
        Success          = Color3.fromRGB(0, 220, 80),
        Error            = Color3.fromRGB(255, 80, 80),
        GlowColor1       = Color3.fromRGB(0, 220, 80),
        GlowColor2       = Color3.fromRGB(0, 170, 60),
    },
    laranja = {
        Background       = Color3.fromRGB(15, 8, 3),
        Surface          = Color3.fromRGB(28, 15, 6),
        SurfaceHighlight = Color3.fromRGB(42, 22, 8),
        Accent1          = Color3.fromRGB(255, 140, 0),
        Accent2          = Color3.fromRGB(220, 100, 0),
        TextPrimary      = Color3.fromRGB(255, 240, 220),
        TextSecondary    = Color3.fromRGB(200, 155, 100),
        Success          = Color3.fromRGB(255, 140, 0),
        Error            = Color3.fromRGB(255, 60, 60),
        GlowColor1       = Color3.fromRGB(255, 140, 0),
        GlowColor2       = Color3.fromRGB(220, 100, 0),
    },
    vermelho = {
        Background       = Color3.fromRGB(18, 5, 5),
        Surface          = Color3.fromRGB(32, 10, 10),
        SurfaceHighlight = Color3.fromRGB(50, 16, 16),
        Accent1          = Color3.fromRGB(255, 50, 50),
        Accent2          = Color3.fromRGB(200, 20, 20),
        TextPrimary      = Color3.fromRGB(255, 230, 230),
        TextSecondary    = Color3.fromRGB(200, 140, 140),
        Success          = Color3.fromRGB(255, 50, 50),
        Error            = Color3.fromRGB(255, 80, 80),
        GlowColor1       = Color3.fromRGB(255, 50, 50),
        GlowColor2       = Color3.fromRGB(200, 20, 20),
    },
    cinza = {
        Background       = Color3.fromRGB(15, 15, 18),
        Surface          = Color3.fromRGB(28, 28, 32),
        SurfaceHighlight = Color3.fromRGB(42, 42, 48),
        Accent1          = Color3.fromRGB(160, 160, 180),
        Accent2          = Color3.fromRGB(120, 120, 140),
        TextPrimary      = Color3.fromRGB(230, 230, 235),
        TextSecondary    = Color3.fromRGB(160, 160, 170),
        Success          = Color3.fromRGB(160, 160, 180),
        Error            = Color3.fromRGB(255, 80, 80),
        GlowColor1       = Color3.fromRGB(160, 160, 180),
        GlowColor2       = Color3.fromRGB(120, 120, 140),
    },
}

-- Registros para update ao vivo de cores
_themeRegistry = {}
function TrackColor(element, colorType)
    if not _themeRegistry[colorType] then _themeRegistry[colorType] = {} end
    table.insert(_themeRegistry[colorType], element)
end


function applyTheme(themeName)
    local t = THEMES[themeName]
    if not t then return end

    -- Mapa: cor antiga -> cor nova (para todas as 3 transicoes possiveis)
    -- Accent1 e Accent2 sao excluidos — sempre ficam roxo
    local colorMap = {}
    for k, oldColor in pairs(Theme) do
        if t[k] and k ~= "Accent1" and k ~= "Accent2" then
            colorMap[oldColor] = t[k]
        end
    end

    -- Atualiza tabela Theme in-place
    for k, v in pairs(t) do
        Theme[k] = v
    end
    -- Always force accent colors to purple regardless of theme
    Theme.Accent1 = Color3.fromRGB(186, 120, 255)
    Theme.Accent2 = Color3.fromRGB(136, 72, 230)
    Config.CurrentTheme = themeName
    SaveConfig()

    -- Percorre TODOS os descendentes de PlayerGui e substitui as cores
    local function matchColor(c1, c2)
        if not c1 or not c2 then return false end
        local dr = math.abs(c1.R - c2.R)
        local dg = math.abs(c1.G - c2.G)
        local db = math.abs(c1.B - c2.B)
        return (dr + dg + db) < 0.04
    end

    local function remapColor(c)
        if not c then return c end
        for oldC, newC in pairs(colorMap) do
            if matchColor(c, oldC) then return newC end
        end
        return c
    end

    local guiNames = {
        "AutoStealUI", "HeroAdminPanel", "SettingsUI", "StealSpeedUI",
        "HeroInvisPanel", "HeroStatusHUD", "HeroMobileControls", "HeroNotif",
        "HeroThemeUI", "PriorityListGUI", "HeroJobJoiner", "HeroPriorityAlert",
        "HeroSettings", "HeroPlatformUI"
    }

    for _, guiName in ipairs(guiNames) do
        local sg = PlayerGui:FindFirstChild(guiName)
        if sg then
            for _, obj in ipairs(sg:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Frame") or obj:IsA("TextButton") or
                       obj:IsA("TextBox") or obj:IsA("ScrollingFrame") or
                       obj:IsA("ImageLabel") then
                        if obj.BackgroundTransparency < 1 then
                            obj.BackgroundColor3 = remapColor(obj.BackgroundColor3)
                        end
                    end
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        obj.TextColor3 = remapColor(obj.TextColor3)
                    end
                    if obj:IsA("UIStroke") then
                        obj.Color = remapColor(obj.Color)
                    end
                    if obj:IsA("ScrollingFrame") then
                        obj.ScrollBarImageColor3 = remapColor(obj.ScrollBarImageColor3)
                    end
                    if obj:IsA("UIGradient") then
                        -- atualiza gradient de stroke/frame
                        local kps = obj.Color.Keypoints
                        local changed = false
                        local newKps = {}
                        for _, kp in ipairs(kps) do
                            local nc = remapColor(kp.Value)
                            if nc ~= kp.Value then changed = true end
                            table.insert(newKps, ColorSequenceKeypoint.new(kp.Time, nc))
                        end
                        if changed then
                            obj.Color = ColorSequence.new(newKps)
                        end
                    end
                    if obj:IsA("Beam") then
                        local kps = obj.Color.Keypoints
                        local newKps = {}
                        for _, kp in ipairs(kps) do
                            table.insert(newKps, ColorSequenceKeypoint.new(kp.Time, remapColor(kp.Value)))
                        end
                        obj.Color = ColorSequence.new(newKps)
                    end
                end)
            end
            -- Frame raiz
            pcall(function()
                local root = sg:FindFirstChildWhichIsA("Frame")
                if root and root.BackgroundTransparency < 1 then
                    root.BackgroundColor3 = remapColor(root.BackgroundColor3)
                end
            end)
        end
    end

    -- Reconstroi nova UI (sincrono, ja com novo tema aplicado)
    task.spawn(function()
        local savedTab  = (_G.HeroSettingsUI and _G.HeroSettingsUI.currentTab) or "act"
        local wasVis    = _G.HeroSettingsUI and _G.HeroSettingsUI.panel and _G.HeroSettingsUI.panel.Visible
        if buildHeroSettingsUI then
            buildHeroSettingsUI()
        end
        task.wait()
        if _G.HeroSettingsUI then
            if _G.HeroSettingsUI.switchTab then
                _G.HeroSettingsUI.switchTab(savedTab)
            end
            if wasVis and _G.HeroSettingsUI.panel then
                _G.HeroSettingsUI.panel.Visible = true
            end
        end
        -- Reconstroi HUD e Mini UI com novas cores
        if _G.rebuildStatusHUD then
            _G.rebuildStatusHUD()
        end
        -- Update auto buy ring color to match new theme
        if _G.updateAutoBuyRingColor then _G.updateAutoBuyRingColor() end
        if _G.rebuildAutoBuyCirclePresets then _G.rebuildAutoBuyCirclePresets() end
        if buildMiniActionsUI then
            local miniWasVis = _G.MiniActionsUI and _G.MiniActionsUI.panel and _G.MiniActionsUI.panel.Visible
            buildMiniActionsUI()
            task.wait()
            if miniWasVis and _G.MiniActionsUI and _G.MiniActionsUI.panel then
                _G.MiniActionsUI.panel.Visible = true
            end
        end

        -- Atualiza racetrack borders — sempre roxo independente do tema
        local guisRT = {"AutoStealUI","HeroAdminPanel","SettingsUI","StealSpeedUI","HeroInvisPanel","HeroSettings","HeroStatusHUD","HeroAutoBuyUI"}
        for _, gn in ipairs(guisRT) do
            local sg = PlayerGui:FindFirstChild(gn)
            if sg then
                for _, obj in ipairs(sg:GetDescendants()) do
                    if obj.Name == "RacetrackBorder" and obj:IsA("UIStroke") then
                        local g2 = obj:FindFirstChildOfClass("UIGradient")
                        if g2 then
                            g2.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0,   Theme.Background),
                                ColorSequenceKeypoint.new(0.3, Color3.fromRGB(186, 120, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(136, 72, 230)),
                                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(186, 120, 255)),
                                ColorSequenceKeypoint.new(1,   Theme.Background),
                            }
                            obj.Color = Color3.fromRGB(186, 120, 255)
                        end
                    end
                end
            end
        end
    end)

    ShowNotification("TEMA", "Tema " .. themeName .. " aplicado!")
end

-- Helper: throttle de conexões para evitar limite de 200 upvalues/conexões
function createThrottledConnection(event, callback, throttleFrames)
    throttleFrames = throttleFrames or 3
    local frameCount = 0
    return event:Connect(function(...)
        frameCount = frameCount + 1
        if frameCount >= throttleFrames then
            frameCount = 0
            callback(...)
        end
    end)
end

-- ============================================================
-- RACETRACK BORDER ANIMATION (baseado no Goblin Hub v2)
-- Nao usa `local` no top-level para nao exceder 200 locals
-- ============================================================
function addRacetrackBorder(parentFrame, carColor, speed)
    if Config and Config.UltraLightMode then return end
    if not parentFrame or not parentFrame:IsA("Frame") then return end
    carColor = carColor or Theme.Accent1
    speed    = speed or 2.5

    local stroke = Instance.new("UIStroke")
    stroke.Name = "RacetrackBorder"
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness  = 6
    stroke.Color      = carColor
    stroke.Transparency = 0.3
    stroke.Parent = parentFrame

    local grad = Instance.new("UIGradient")
    local bg = Theme.Background
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   bg),
        ColorSequenceKeypoint.new(0.3, carColor),
        ColorSequenceKeypoint.new(0.5, Theme.Accent2),
        ColorSequenceKeypoint.new(0.7, carColor),
        ColorSequenceKeypoint.new(1,   bg),
    }
    grad.Rotation = 0
    grad.Parent   = stroke

    local startTime = tick()
    local lastUp    = 0
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not parentFrame.Parent then
            conn:Disconnect()
            return
        end
        local now = tick()
        if now - lastUp < 0.016 then return end
        lastUp = now

        local W = parentFrame.AbsoluteSize.X
        local H = parentFrame.AbsoluteSize.Y
        if W <= 0 or H <= 0 then return end

        local perim    = (W + H) * 2
        local elapsed  = (now - startTime) % speed
        local progress = elapsed / speed
        local dist     = (progress * perim) % perim
        local rot      = 0

        if dist < W then
            rot = (dist / W) * 90
        elseif dist < W + H then
            rot = 90 + ((dist - W) / H) * 90
        elseif dist < W * 2 + H then
            rot = 180 + ((dist - W - H) / W) * 90
        else
            rot = 270 + ((dist - W * 2 - H) / H) * 90
        end

        grad.Rotation = rot

        local wave = math.sin(progress * math.pi * 2)
        local intensity = (wave + 1) * 0.5
        stroke.Transparency = 0.05 + intensity * 0.4
        stroke.Thickness    = 6 + math.sin(now * 5) * 0.15
    end)

    return stroke
end

local PRIORITY_LIST = {
   "Strawberry Elephant",
   "Meowl",
   "Skibidi Toilet",
   "Headless Horseman",
   "Dragon Gingerini",
   "Dragon Cannelloni",
   "Ketupat Bros",
   "Hydra Dragon Cannelloni",
   "La Supreme Combinasion",
   "Love Love Bear",
   "Ginger Gerat",
   "Cerberus",
   "Capitano Moby",
   "La Casa Boo",
   "Burguro and Fryuro",
   "Spooky and Pumpky",
   "Cooki and Milki",
   "Rosey and Teddy",
   "Popcuru and Fizzuru",
   "Reinito Sleighito",
   "Fragrama and Chocrama",
   "Garama and Madundung",
   "Ketchuru and Musturu",
   "La Secret Combinasion",
   "Tralaledon",
   "Tictac Sahur",
   "Ketupat Kepat",
   "Tang Tang Keletang",
   "Orcaledon",
   "La Ginger Sekolah",
   "Los Spaghettis",
   "Lavadorito Spinito",
   "Swaggy Bros",
   "La Taco Combinasion",
   "Los Primos",
   "Chillin Chili",
   "Tuff Toucan",
   "W or L",
   "Chillin Chili",
   "Chipso and Queso"
}

-- Load saved priority list from config (overrides defaults if saved)
do
    local saved = Config and Config.PriorityList
    if saved and type(saved) == "table" and #saved > 0 then
        PRIORITY_LIST = saved
    end
end

local function savePriorityToConfig()
    Config.PriorityList = {}
    for i, v in ipairs(PRIORITY_LIST) do Config.PriorityList[i] = v end
    SaveConfig()
end

local function findAdorneeGlobal(animalData)
    if not animalData then return nil end
    local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(animalData.plot)
    if plot then
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                if base then
                    local spawn = base:FindFirstChild("Spawn")
                    if spawn then return spawn end
                    return base:FindFirstChildWhichIsA("BasePart") or base
                end
            end
        end
    end
    return nil
end

local function CreateGradient(parent)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Accent2),
        ColorSequenceKeypoint.new(1, Theme.Accent2)
    }
    g.Rotation = 45
    return g
end

local function ApplyViewportUIScale(targetFrame, designWidth, designHeight, minScale, maxScale)
    if not targetFrame then return end
    if not IS_MOBILE then return end
    local existing = targetFrame:FindFirstChildOfClass("UIScale")
    if existing then existing:Destroy() end
    local sc = Instance.new("UIScale")
    sc.Parent = targetFrame
    SharedState.MobileScaleObjects[targetFrame] = sc
    if SharedState.RefreshMobileScale then
        SharedState.RefreshMobileScale()
    else
        sc.Scale = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    end
end

SharedState.RefreshMobileScale = function()
    local s = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    for frame, sc in pairs(SharedState.MobileScaleObjects) do
        if frame and frame.Parent and sc and sc.Parent == frame then
            sc.Scale = s
        else
            SharedState.MobileScaleObjects[frame] = nil
        end
    end
end

local function AddMobileMinimize(frame, labelText)
    if not IS_MOBILE then return end
    if not frame or not frame.Parent then return end
    local guiParent = frame.Parent
    local header = frame:FindFirstChildWhichIsA("Frame")
    if not header then return end

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 6)
    minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamBlack
    minimizeBtn.TextSize = 18
    minimizeBtn.TextColor3 = Theme.TextPrimary
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = header
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 110, 0, 34)
    restoreBtn.Position = UDim2.new(0, 10, 1, -44)
    restoreBtn.BackgroundColor3 = Theme.SurfaceHighlight
    restoreBtn.Text = labelText or "OPEN"
    restoreBtn.Font = Enum.Font.GothamBold
    restoreBtn.TextSize = 12
    restoreBtn.TextColor3 = Theme.TextPrimary
    restoreBtn.Visible = false
    restoreBtn.AutoButtonColor = false
    restoreBtn.Parent = guiParent
    Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 10)

    MakeDraggable(restoreBtn, restoreBtn)

    minimizeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        restoreBtn.Visible = true
    end)

    restoreBtn.MouseButton1Click:Connect(function()
        frame.Visible = true
        restoreBtn.Visible = false
    end)
end

local function MakeDraggable(handle, target, saveKey)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if Config.UILocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveKey then
                        local parentSize = target.Parent.AbsoluteSize
                        Config.Positions[saveKey] = {
                            X = target.AbsolutePosition.X / parentSize.X,
                            Y = target.AbsolutePosition.Y / parentSize.Y,
                        }
                        SaveConfig()
                    end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function ShowNotification(title, text) end

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function handleAnimator(animator)
    local model = animator:FindFirstAncestorOfClass("Model")
    if model and isPlayerCharacter(model) then return end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
    animator.AnimationPlayed:Connect(function(track) track:Stop(0) end)
end

local function stripVisuals(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    local isPlayer = model and isPlayerCharacter(model)

    if obj:IsA("Animator") then handleAnimator(obj) end

    if obj:IsA("Accessory") or obj:IsA("Clothing") then
        if obj:FindFirstAncestorOfClass("Model") then
            obj:Destroy()
        end
    end

    if not isPlayer then
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
           obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or 
           obj:IsA("Highlight") then
            obj.Enabled = false
        end
        if obj:IsA("Explosion") then
            obj:Destroy()
        end
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
        end
    end

    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end

    if obj:IsA("SurfaceAppearance") or obj:IsA("Texture") or obj:IsA("Decal") then
        obj:Destroy()
    end
end

local function setFPSBoost(enabled)
    Config.FPSBoost = enabled
    SaveConfig()
    if enabled then
        pcall(function() if setfpscap then setfpscap(9999) end end)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
               v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
                v:Destroy()
            end
        end

        for _, obj in pairs(Workspace:GetDescendants()) do
            stripVisuals(obj)
        end

        Workspace.DescendantAdded:Connect(function(obj)
            if Config.FPSBoost then
                stripVisuals(obj)
            end
        end)
    end
end
if Config.FPSBoost then task.spawn(function() task.wait(1); setFPSBoost(true) end) end
if Config.UltraLightMode then
    task.spawn(function()
        task.wait(2) -- wait for all UIs to be created
        for _,gn in ipairs({"AutoStealUI","HeroAdminPanel","SettingsUI","StealSpeedUI",
            "HeroInvisPanel","HeroStatusHUD","HeroSettings","HeroPlatformUI",
            "HeroAutoBuyUI","HeroMiniActions"}) do
            local sg = PlayerGui:FindFirstChild(gn)
            if sg then
                for _,obj in ipairs(sg:GetDescendants()) do
                    if obj.Name == "RacetrackBorder" and obj:IsA("UIStroke") then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

local State = {
    ProximityAPActive = false,
    carpetSpeedEnabled = false,
    infiniteJumpEnabled = Config.TpSettings.InfiniteJump,
    xrayEnabled = false,
    antiRagdollMode = Config.AntiRagdoll or 0,
    floatActive = false,
    isTpMoving = false,
    manualTargetEnabled = false,
}
local Connections = {
    carpetSpeedConnection = nil,
    infiniteJumpConnection = nil,
    xrayDescConn = nil,
    antiRagdollConn = nil,
    antiRagdollV2Task = nil,
}
local UI = {
    carpetStatusLabel = nil,
    settingsGui = nil,
}
local carpetSpeedEnabled = State.carpetSpeedEnabled
local carpetSpeedConnection = Connections.carpetSpeedConnection
local _carpetStatusLabel = UI.carpetStatusLabel

local function setCarpetSpeed(enabled)
    State.carpetSpeedEnabled = enabled
    carpetSpeedEnabled = State.carpetSpeedEnabled
    if Connections.carpetSpeedConnection then Connections.carpetSpeedConnection:Disconnect(); Connections.carpetSpeedConnection = nil end
    carpetSpeedConnection = Connections.carpetSpeedConnection
    if not enabled then return end

    if SharedState.DisableStealSpeed then SharedState.DisableStealSpeed() end

    Connections.carpetSpeedConnection = RunService.Heartbeat:Connect(function()
    carpetSpeedConnection = Connections.carpetSpeedConnection
        local c = LocalPlayer.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local toolName = Config.TpSettings.Tool
        local hasTool = c:FindFirstChild(toolName)
        
        if not hasTool then
            local tb = LocalPlayer.Backpack:FindFirstChild(toolName)
            if tb then hum:EquipTool(tb) end
        end

        if hasTool then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * 140, 
                    hrp.AssemblyLinearVelocity.Y, 
                    md.Z * 140
                )
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)
end

local JumpData = {lastJumpTime = 0}
local infiniteJumpEnabled = State.infiniteJumpEnabled
local infiniteJumpConnection = Connections.infiniteJumpConnection

local function setInfiniteJump(enabled)
    State.infiniteJumpEnabled = enabled
    infiniteJumpEnabled = State.infiniteJumpEnabled
    Config.TpSettings.InfiniteJump = enabled
    SaveConfig()
    if Connections.infiniteJumpConnection then Connections.infiniteJumpConnection:Disconnect(); Connections.infiniteJumpConnection = nil end
    infiniteJumpConnection = Connections.infiniteJumpConnection
    if not enabled then return end

    local jumpForce = 50
    local clampFallSpeed = 80

    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not State.infiniteJumpEnabled then
            if heartbeatConn then heartbeatConn:Disconnect() end
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Velocity.Y < -clampFallSpeed then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -clampFallSpeed, hrp.Velocity.Z)
        end
    end)

    local jumpConn
    jumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.infiniteJumpEnabled then
            if jumpConn then jumpConn:Disconnect() end
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, jumpForce, hrp.Velocity.Z)
        end
    end)

    Connections.infiniteJumpConnection = heartbeatConn
    infiniteJumpConnection = Connections.infiniteJumpConnection
end
if infiniteJumpEnabled then setInfiniteJump(true) end

local XrayState = {
    originalTransparency = {},
    xrayEnabled = false,
}
local originalTransparency = XrayState.originalTransparency
local xrayEnabled = XrayState.xrayEnabled

local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local name = obj.Name:lower()
    local parentName = (obj.Parent and obj.Parent.Name:lower()) or ""
    return name:find("base") or parentName:find("base")
end

local function enableXray()
    XrayState.xrayEnabled = true
    xrayEnabled = XrayState.xrayEnabled
    do
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
                XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
                originalTransparency[obj] = XrayState.originalTransparency[obj]
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end
end

local xrayDescConn = Connections.xrayDescConn
local function disableXray()
    XrayState.xrayEnabled = false
    xrayEnabled = XrayState.xrayEnabled
    if Connections.xrayDescConn then Connections.xrayDescConn:Disconnect(); Connections.xrayDescConn = nil end
    xrayDescConn = Connections.xrayDescConn
    for part, val in pairs(XrayState.originalTransparency) do
        if part and part.Parent then part.LocalTransparencyModifier = val end
    end
    XrayState.originalTransparency = {}
    originalTransparency = XrayState.originalTransparency
end

if Config.XrayEnabled then
    enableXray()
    Connections.xrayDescConn = Workspace.DescendantAdded:Connect(function(obj)
        if XrayState.xrayEnabled and obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
            XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
            originalTransparency[obj] = XrayState.originalTransparency[obj]
            obj.LocalTransparencyModifier = 0.85
        end
    end)
    xrayDescConn = Connections.xrayDescConn
end

local antiRagdollMode = State.antiRagdollMode
local antiRagdollConn = Connections.antiRagdollConn

local function isRagdolled()
    local char = LocalPlayer.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    local state = hum:GetState()
    local ragStates = {
        [Enum.HumanoidStateType.Physics]     = true,
        [Enum.HumanoidStateType.Ragdoll]     = true,
        [Enum.HumanoidStateType.FallingDown] = true,
    }
    if ragStates[state] then return true end
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - Workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function stopAntiRagdoll()
    if Connections.antiRagdollConn then Connections.antiRagdollConn:Disconnect(); Connections.antiRagdollConn = nil end
    antiRagdollConn = Connections.antiRagdollConn
end


local function startAntiRagdoll(mode)
    stopAntiRagdoll()
    if Config.AntiRagdollV2 then
        stopAntiRagdollV2()
    end
    if mode == 0 then return end

    Connections.antiRagdollConn = RunService.Heartbeat:Connect(function()
    antiRagdollConn = Connections.antiRagdollConn
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if isRagdolled() then
            pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", Workspace:GetServerTimeNow()) end)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hrp.AssemblyLinearVelocity = Vector3.zero
            if Workspace.CurrentCamera.CameraSubject ~= hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BallSocketConstraint") or obj.Name:find("RagdollAttachment") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
end

local AntiRagdollV2Data = {
    antiRagdollConns = {},
}
local antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

local cleanRagdollV2Scheduled = false
local function cleanRagdollV2(char)
    if not char then return end
    local carpetEquipped = false
    pcall(function()
        local toolName = Config.TpSettings.Tool or "Flying Carpet"
        local tool = char:FindFirstChild(toolName)
        if tool then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
            if not carpetEquipped then
                for _, obj in ipairs(tool:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
        end
    end)
    local descendants = char:GetDescendants()
    for _, d in ipairs(descendants) do
        if d:IsA("BallSocketConstraint") or d:IsA("NoCollisionConstraint")
            or d:IsA("HingeConstraint")
            or (d:IsA("Attachment") and (d.Name == "A" or d.Name == "B")) then
            d:Destroy()
        elseif (d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro")) and not carpetEquipped then
            d:Destroy()
        end
    end
    for _, d in ipairs(descendants) do
        if d:IsA("Motor6D") then d.Enabled = true end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local animator = hum:FindFirstChild("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local n = track.Animation and track.Animation.Name:lower() or ""
                if n:find("rag") or n:find("fall") or n:find("hurt") or n:find("down") then
                    track:Stop(0)
                end
            end
        end
    end
    task.defer(function()
        pcall(function()
            local pm = LocalPlayer:FindFirstChild("PlayerScripts")
            if pm then pm = pm:FindFirstChild("PlayerModule") end
            if pm then require(pm):GetControls():Enable() end
        end)
    end)
end
local function cleanRagdollV2Debounced(char)
    if cleanRagdollV2Scheduled then return end
    cleanRagdollV2Scheduled = true
    task.defer(function()
        cleanRagdollV2Scheduled = false
        if char and char.Parent then cleanRagdollV2(char) end
    end)
end
local function isRagdollRelatedDescendant(obj)
    if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") then return true end
    if obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B") then return true end
    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then return true end
    return false
end

local function hookAntiRagV2(char)
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

    local hum = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not hrp then return end

    local lastVel = Vector3.new(0, 0, 0)

    local c1 = hum.StateChanged:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            local carpetActive = false
            pcall(function()
                local toolName = Config.TpSettings.Tool or "Flying Carpet"
                local tool = char:FindFirstChild(toolName)
                if tool and hrp then
                    for _, obj in ipairs(hrp:GetChildren()) do
                        if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                            carpetActive = true
                        end
                    end
                end
            end)
            if not carpetActive then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
            cleanRagdollV2(char)
            pcall(function() Workspace.CurrentCamera.CameraSubject = hum end)
            pcall(function()
                local pm = LocalPlayer:FindFirstChild("PlayerScripts")
                if pm then pm = pm:FindFirstChild("PlayerModule") end
                if pm then require(pm):GetControls():Enable() end
            end)
        end
    end)
    table.insert(antiRagdollConns, c1)

    local c2 = char.DescendantAdded:Connect(function(desc)
        if isRagdollRelatedDescendant(desc) then
            cleanRagdollV2Debounced(char)
        end
    end)
    table.insert(antiRagdollConns, c2)

    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        if pkg then
            local net = pkg:FindFirstChild("Net")
            if net then
                local applyImp = net:FindFirstChild("RE/CombatService/ApplyImpulse")
                if applyImp and applyImp:IsA("RemoteEvent") then
                    local c3 = applyImp.OnClientEvent:Connect(function()
                        local st = hum:GetState()
                        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
                            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
                            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                        end
                    end)
                    table.insert(antiRagdollConns, c3)
                end
            end
        end
    end)

    local c4 = RunService.Heartbeat:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            cleanRagdollV2(char)
            local vel = hrp.AssemblyLinearVelocity
            if (vel - lastVel).Magnitude > 40 and vel.Magnitude > 25 then
                hrp.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, 15)
            end
        end
        lastVel = hrp.AssemblyLinearVelocity
    end)
    table.insert(antiRagdollConns, c4)

    cleanRagdollV2(char)
end

local function stopAntiRagdollV2()
    cleanRagdollV2Scheduled = false
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns
end

local function startAntiRagdollV2(enabled)
    stopAntiRagdoll()
    stopAntiRagdollV2()
    if not enabled then
        return
    end

    local char = LocalPlayer.Character
    if char then task.spawn(function() hookAntiRagV2(char) end) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.spawn(function() hookAntiRagV2(c) end)
    end)
end

if antiRagdollMode > 0 then startAntiRagdoll(antiRagdollMode) end
Config.AntiRagdollV2 = true
startAntiRagdollV2(true)
if Config.AntiRagdollV2 then startAntiRagdollV2(true) end

do
    local plotBeam = nil
    local plotBeamAttachment0 = nil
    local plotBeamAttachment1 = nil

    local function findMyPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local surfaceGui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
                if surfaceGui then
                    local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
                    if label then
                        local text = label.Text:lower()
                        if text:find(LocalPlayer.DisplayName:lower(), 1, true) or text:find(LocalPlayer.Name:lower(), 1, true) then
                            return plot
                        end
                    end
                end
            end
        end
        return nil
    end

    local function createPlotBeam()
        if not Config.LineToBase then return end
        local myPlot = findMyPlot()
        if not myPlot or not myPlot.Parent then return end
        local character = LocalPlayer.Character
        if not character or not character.Parent then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        plotBeamAttachment0 = hrp:FindFirstChild("PlotBeamAttach_Player") or Instance.new("Attachment")
        plotBeamAttachment0.Name = "PlotBeamAttach_Player"
        plotBeamAttachment0.Position = Vector3.new(0, 0, 0)
        plotBeamAttachment0.Parent = hrp
        local plotPart = myPlot:FindFirstChild("MainRootPart") or myPlot:FindFirstChildWhichIsA("BasePart")
        if not plotPart or not plotPart.Parent then return end
        plotBeamAttachment1 = plotPart:FindFirstChild("PlotBeamAttach_Plot") or Instance.new("Attachment")
        plotBeamAttachment1.Name = "PlotBeamAttach_Plot"
        plotBeamAttachment1.Position = Vector3.new(0, 5, 0)
        plotBeamAttachment1.Parent = plotPart
        plotBeam = hrp:FindFirstChild("PlotBeam") or Instance.new("Beam")
        plotBeam.Name = "PlotBeam"
        plotBeam.Attachment0 = plotBeamAttachment0
        plotBeam.Attachment1 = plotBeamAttachment1
        plotBeam.FaceCamera = true
        plotBeam.LightEmission = 1
        plotBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        plotBeam.Transparency = NumberSequence.new(0)
        plotBeam.Width0 = 0.7
        plotBeam.Width1 = 0.7
        plotBeam.TextureMode = Enum.TextureMode.Wrap
        plotBeam.TextureSpeed = 0
        plotBeam.Parent = hrp
    end

    local function resetPlotBeam()
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        if plotBeamAttachment1 then pcall(function() plotBeamAttachment1:Destroy() end) end
        plotBeam = nil
        plotBeamAttachment0 = nil
        plotBeamAttachment1 = nil
    end

    task.spawn(function()
        local checkCounter = 0
        RunService.Heartbeat:Connect(function()
            if not Config.LineToBase then return end
            checkCounter = checkCounter + 1
            if checkCounter >= 30 then
                checkCounter = 0
                if not plotBeam or not plotBeam.Parent or not plotBeamAttachment0 or not plotBeamAttachment0.Parent then
                    pcall(createPlotBeam)
                end
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if Config.LineToBase and character then
            pcall(createPlotBeam)
        end
    end)

    if LocalPlayer.Character then
        task.spawn(function()
            task.wait(0.2)
            if Config.LineToBase then createPlotBeam() end
        end)
    end

    _G.createPlotBeam = createPlotBeam
    _G.resetPlotBeam = resetPlotBeam
end

task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas    = ReplicatedStorage:WaitForChild("Datas")
    local Shared   = ReplicatedStorage:WaitForChild("Shared")
    local Utils    = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer  = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData   = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils   = require(Utils:WaitForChild("NumberUtils"))

    local autoStealEnabled   = not Config.DefaultToDisable
    
    
    if Config.DefaultToPriority and Config.DefaultToHighest then
        Config.DefaultToHighest = false
    end
    if Config.DefaultToPriority and Config.DefaultToNearest then
        Config.DefaultToNearest = false
    end
    if Config.DefaultToHighest and Config.DefaultToNearest then
        Config.DefaultToNearest = false
    end
    
    if not Config.DefaultToPriority and not Config.DefaultToHighest and not Config.DefaultToNearest and not Config.DefaultToDisable then
        Config.DefaultToHighest = true
    end
    
    local stealNearestEnabled = false
    local stealHighestEnabled = false
    local stealPriorityEnabled = false
    
    if Config.DefaultToNearest then
        stealNearestEnabled = true
        Config.StealNearest = true
        Config.StealHighest = false
        Config.StealPriority = false
        Config.AutoTPPriority = true
    elseif Config.DefaultToHighest then
        stealHighestEnabled = true
        Config.StealHighest = true
        Config.StealNearest = false
        Config.StealPriority = false
        Config.AutoTPPriority = false
    elseif Config.DefaultToPriority then
        stealPriorityEnabled = true
        Config.StealPriority = true
        Config.StealNearest = false
        Config.StealHighest = false
        Config.AutoTPPriority = true
    elseif Config.DefaultToDisable then
        -- Disable mode: don't activate any steal mode on load
        stealNearestEnabled = false
        stealHighestEnabled = false
        stealPriorityEnabled = false
        Config.StealNearest = false
        Config.StealHighest = false
        Config.StealPriority = false
    else
        stealNearestEnabled = Config.StealNearest
        stealHighestEnabled = Config.StealHighest
        stealPriorityEnabled = Config.StealPriority
        
        if Config.InstantSteal == nil then Config.InstantSteal = false end
        if Config.StealPriority then
            Config.AutoTPPriority = true
        elseif Config.StealNearest then
            Config.AutoTPPriority = true
        elseif Config.StealHighest then
            Config.AutoTPPriority = false
        end
    end
    
    local instantStealEnabled = (Config.InstantSteal == true)
    local instantStealReady = false
    local instantStealDidInit = false
    local selectedTargetIndex = 1
    local selectedTargetUID   = nil 
    local allAnimalsCache    = {}
    local InternalStealCache = {}
    local PromptMemoryCache  = {}
    local activeProgressTween = nil
    local currentStealTargetUID = nil
    local petButtons         = {}

    -- ── STEAL REMOTE RESOLVER ─────────────────────────────────────────────
    -- Resolved once and cached. Used in all steal paths for maximum speed.
    
    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot then return false end
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return false end
        local plot = plots:FindFirstChild(animalData.plot)
        if not plot then return false end
        local channel = Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "table" and owner.UserId then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "Instance" then return owner == LocalPlayer end
            end
        end
        return false
    end
    
    local function formatMutationText(mutationName)
        if not mutationName or mutationName == "None" then return "" end
        local f = ""
        if mutationName == "Cursed" then f = "<font color='rgb(200,0,0)'>Cur</font><font color='rgb(0,0,0)'>sed</font>"
        elseif mutationName == "Gold" then f = "<font color='rgb(255,215,0)'>Gold</font>"
        elseif mutationName == "Diamond" then f = "<font color='rgb(0,255,255)'>Diamond</font>"
        elseif mutationName == "YinYang" then f = "<font color='rgb(255,255,255)'>Yin</font><font color='rgb(0,0,0)'>Yang</font>"
        elseif mutationName == "Candy" then f = "<font color='rgb(255,105,180)'>Candy</font>"
        elseif mutationName == "Divine" then f = "<font color='rgb(255,255,255)'>Divine</font>"
        elseif mutationName == "Rainbow" then
            local cols = {"rgb(255,0,0)","rgb(255,127,0)","rgb(255,255,0)","rgb(0,255,0)","rgb(0,0,255)","rgb(75,0,130)","rgb(148,0,211)"}
            for i = 1, #mutationName do f = f.."<font color='"..cols[(i-1)%#cols+1].."'>"..mutationName:sub(i,i).."</font>" end
        else f = mutationName end
        return "<font weight='800'>"..f.." </font>"
    end

    local function get_all_pets()
        local out = {}
        for _, a in ipairs(allAnimalsCache) do
            if a.genValue >= 1 and not isMyBaseAnimal(a) then
                table.insert(out, {petName=a.name, mpsText=a.genText, mpsValue=a.genValue,
                    owner=a.owner, plot=a.plot, slot=a.slot, uid=a.uid, mutation=a.mutation, animalData=a, source="CARPET"})
            end
        end
        -- also include conveyor brainrots
        -- (REMOVED: conveyor detection disabled)
        return out
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoStealUI"; screenGui.ResetOnSpawn = false; screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.6 or 1
    frame.Size = UDim2.new(0, 300*mobileScale, 0, 630*mobileScale)
    frame.Position = UDim2.new(Config.Positions.AutoSteal.X, 0, Config.Positions.AutoSteal.Y, 0)
    frame.BackgroundColor3 = Theme.Background; frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0; frame.ClipsDescendants = true; frame.Parent = screenGui
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(1, -20, 0, 40) -- largura quase total
    logo.Position = UDim2.new(0, 10, 0, 5) -- bem no topo
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://15605014322"
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = frame

    ApplyViewportUIScale(frame, 300, 630, 0.45, 0.8)
    AddMobileMinimize(frame, "AUTO STEAL")
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", frame)
    mainStroke.Color = Theme.Accent2; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.4
    CreateGradient(mainStroke)
    task.defer(function() if addRacetrackBorder then addRacetrackBorder(frame, Theme.Accent1, 3) end end)
    
    local header = Instance.new("Frame", frame); header.Size = UDim2.new(1,0,0,40); header.BackgroundTransparency = 1
    MakeDraggable(header, frame, "AutoSteal") 
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = IS_MOBILE and UDim2.new(0.4,0,1,0) or UDim2.new(0.6,0,1,0)
    titleLabel.Position = UDim2.new(0,15,0,0)
    titleLabel.BackgroundTransparency = 1; titleLabel.Text = "AUTO STEAL"
    titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 16
    titleLabel.TextColor3 = Theme.TextPrimary; titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    if IS_MOBILE then
        local menuToggleBtn = Instance.new("TextButton", header)
        menuToggleBtn.Size = UDim2.new(0, 80, 0, 30)
        menuToggleBtn.Position = UDim2.new(1, -85, 0.5, -15)
        menuToggleBtn.BackgroundColor3 = Theme.Accent1
        menuToggleBtn.Text = "MENU"
        menuToggleBtn.Font = Enum.Font.GothamBold
        menuToggleBtn.TextSize = 12
        menuToggleBtn.TextColor3 = Color3.new(0, 0, 0)
        Instance.new("UICorner", menuToggleBtn).CornerRadius = UDim.new(0, 6)
        
        menuToggleBtn.MouseButton1Click:Connect(function()
            if settingsGui then
                settingsGui.Enabled = not settingsGui.Enabled
            end
        end)
    end

    local targetPanel = Instance.new("Frame", frame)
    targetPanel.Size = UDim2.new(1,-30,0,60); targetPanel.Position = UDim2.new(0,15,0,45)
    targetPanel.BackgroundColor3 = Theme.Surface; targetPanel.BorderSizePixel = 0
    Instance.new("UICorner", targetPanel).CornerRadius = UDim.new(0, 8)

    local targetHeader = Instance.new("TextLabel", targetPanel)
    targetHeader.Size = UDim2.new(1,-20,0,15); targetHeader.Position = UDim2.new(0,10,0,8)
    targetHeader.BackgroundTransparency = 1; targetHeader.Text = "CURRENT TARGET"
    targetHeader.Font = Enum.Font.GothamBold; targetHeader.TextSize = 10
    targetHeader.TextColor3 = Theme.TextSecondary; targetHeader.TextXAlignment = Enum.TextXAlignment.Left

    local targetLabel = Instance.new("TextLabel", targetPanel)
    targetLabel.Size = UDim2.new(1,-20,0,20); targetLabel.Position = UDim2.new(0,10,0,25)
    targetLabel.BackgroundTransparency = 1; targetLabel.Font = Enum.Font.GothamBold; targetLabel.TextSize = 16
    targetLabel.TextColor3 = Theme.TextPrimary; targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.TextTruncate = Enum.TextTruncate.AtEnd; targetLabel.Text = ""

    local progressBg = Instance.new("Frame", targetPanel)
    progressBg.Size = UDim2.new(1,0,0,5); progressBg.Position = UDim2.new(0,0,1,-4)
    progressBg.BackgroundColor3 = Color3.fromRGB(10,10,15); progressBg.BorderSizePixel = 0
    local progressBarFill = Instance.new("Frame", progressBg)
    progressBarFill.Size = UDim2.new(0,0,1,0); progressBarFill.BackgroundColor3 = Color3.fromRGB(255,120,200)
    progressBarFill.BorderSizePixel = 0; CreateGradient(progressBarFill)

    local selectLabel = Instance.new("TextLabel", frame)
    selectLabel.Size = UDim2.new(0.5,0,0,20); selectLabel.Position = UDim2.new(0,15,0,115)
    selectLabel.BackgroundTransparency = 1; selectLabel.Text = "AVAILABLE BRAINROTS"
    selectLabel.Font = Enum.Font.GothamBold; selectLabel.TextSize = 11
    selectLabel.TextColor3 = Theme.TextSecondary; selectLabel.TextXAlignment = Enum.TextXAlignment.Left

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1,-30,1,-254); listFrame.Position = UDim2.new(0,15,0,135)
    listFrame.BackgroundTransparency = 1; listFrame.BorderSizePixel = 0
    listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    listFrame.ScrollBarImageTransparency = 1; listFrame.ScrollBarThickness = 0
    local uiListLayout = Instance.new("UIListLayout", listFrame)
    uiListLayout.Padding = UDim.new(0,8); uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local toggleBtnContainer = Instance.new("Frame", frame)
    toggleBtnContainer.Size = UDim2.new(1,-30,0,144); toggleBtnContainer.Position = UDim2.new(0,15,1,-154)
    toggleBtnContainer.BackgroundTransparency = 1
    
    local enableBtn = Instance.new("TextButton", toggleBtnContainer)
    local mobileButtonScale = IS_MOBILE and 1.3 or 1
    enableBtn.Size = UDim2.new(1,0,0,32*mobileButtonScale); enableBtn.BackgroundColor3 = Theme.Success
    enableBtn.Text = "ENABLED"; enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 13*mobileButtonScale; enableBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0, 8)
    
    local nearestBtn = Instance.new("TextButton", toggleBtnContainer)
    nearestBtn.Size = UDim2.new(0.48,0,0,28*mobileButtonScale); nearestBtn.Position = UDim2.new(0,0,0,36*mobileButtonScale)
    nearestBtn.BackgroundColor3 = Theme.SurfaceHighlight
    nearestBtn.Text = "NEAREST"; nearestBtn.Font = Enum.Font.GothamBold
    nearestBtn.TextSize = 11*mobileButtonScale; nearestBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", nearestBtn).CornerRadius = UDim.new(0, 6)

    local highestBtn = Instance.new("TextButton", toggleBtnContainer)
    highestBtn.Size = UDim2.new(0.48,0,0,28*mobileButtonScale); highestBtn.Position = UDim2.new(0.52,0,0,36*mobileButtonScale)
    highestBtn.BackgroundColor3 = Theme.SurfaceHighlight
    highestBtn.Text = "HIGHEST"; highestBtn.Font = Enum.Font.GothamBold
    highestBtn.TextSize = 11*mobileButtonScale; highestBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", highestBtn).CornerRadius = UDim.new(0, 6)

    local priorityBtn = Instance.new("TextButton", toggleBtnContainer)
    priorityBtn.Size = UDim2.new(1,0,0,24*mobileButtonScale); priorityBtn.Position = UDim2.new(0,0,0,68*mobileButtonScale)
    priorityBtn.BackgroundColor3 = Theme.SurfaceHighlight
    priorityBtn.Text = "PRIORITY"; priorityBtn.Font = Enum.Font.GothamBold
    priorityBtn.TextSize = 11*mobileButtonScale; priorityBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", priorityBtn).CornerRadius = UDim.new(0, 6)

    local function updateUI(enabled, allPets)
        autoStealEnabled = enabled
        enableBtn.Text = enabled and "ENABLED" or "DISABLED"
        enableBtn.BackgroundColor3 = enabled and Theme.Success or Theme.SurfaceHighlight
        
        nearestBtn.BackgroundColor3 = stealNearestEnabled and Theme.Accent1 or Theme.SurfaceHighlight
        nearestBtn.TextColor3 = stealNearestEnabled and Color3.new(0,0,0) or Theme.TextPrimary

        highestBtn.BackgroundColor3 = stealHighestEnabled and Theme.Accent1 or Theme.SurfaceHighlight
        highestBtn.TextColor3 = stealHighestEnabled and Color3.new(0,0,0) or Theme.TextPrimary

        priorityBtn.BackgroundColor3 = stealPriorityEnabled and Theme.Accent1 or Theme.SurfaceHighlight
        priorityBtn.TextColor3 = stealPriorityEnabled and Color3.new(0,0,0) or Theme.TextPrimary

        if instantStealBtn then
            instantStealBtn.Text = instantStealEnabled and "INSTANT STEAL: ON" or "INSTANT STEAL: OFF"
            instantStealBtn.BackgroundColor3 = instantStealEnabled and Theme.Accent1 or Theme.SurfaceHighlight
            instantStealBtn.TextColor3 = instantStealEnabled and Color3.new(0,0,0) or Theme.TextPrimary
        end

        if selectedTargetUID and allPets then
            local found = false
            for i, p in ipairs(allPets) do
                if p.uid == selectedTargetUID then
                    selectedTargetIndex = i
                    found = true
                    break
                end
            end
        end

        if SharedState.ListNeedsRedraw then
            for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            petButtons = {}
            if allPets and #allPets > 0 then
                for i = 1, #allPets do
                    local petData = allPets[i]
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1,0,0,36); btn.BackgroundColor3 = Theme.Surface
                    btn.Text = ""; btn.Parent = listFrame
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                    local bStroke = Instance.new("UIStroke", btn)
                    bStroke.Color = Theme.Accent1; bStroke.Thickness = 1; bStroke.Transparency = 1

                    local MUT_COLORS_UI = {
                        Cursed=Color3.fromRGB(200,0,0), Gold=Color3.fromRGB(255,215,0),
                        Diamond=Color3.fromRGB(0,255,255), YinYang=Color3.fromRGB(220,220,220),
                        Rainbow=Color3.fromRGB(255,100,200), Lava=Color3.fromRGB(255,100,20),
                        Candy=Color3.fromRGB(255,105,180), Divine=Color3.fromRGB(255,255,255)
                    }
                    local hasMut = petData.mutation and petData.mutation ~= "None"
                    local isEsteira = petData.source == "ESTEIRA"
                    local barCol = isEsteira and Color3.fromRGB(0,220,200)
                        or (hasMut and (MUT_COLORS_UI[petData.mutation] or Color3.fromRGB(210,130,255)) or Theme.Accent2)
                    local itemBar = Instance.new("Frame", btn)
                    itemBar.Size = UDim2.new(0,3,1,-8); itemBar.Position = UDim2.new(0,3,0,4)
                    itemBar.BackgroundColor3 = barCol; itemBar.BorderSizePixel = 0
                    Instance.new("UICorner",itemBar).CornerRadius = UDim.new(1,0)

                    local rankLabel = Instance.new("TextLabel", btn)
                    rankLabel.Size = UDim2.new(0,28,1,0); rankLabel.Position = UDim2.new(0,10,0,0)
                    rankLabel.BackgroundTransparency = 1; rankLabel.Text = "#"..i
                    rankLabel.Font = Enum.Font.GothamBlack; rankLabel.TextSize = 13
                    local infoLabel = Instance.new("TextLabel", btn)
                    infoLabel.Size = UDim2.new(1,-42,1,0); infoLabel.Position = UDim2.new(0,38,0,0)
                    infoLabel.BackgroundTransparency = 1; infoLabel.RichText = true
                    infoLabel.Text = formatMutationText(petData.mutation).."<font weight='700'>"..petData.petName.."</font> - <font weight='700'>"..petData.mpsText.."</font>"
                    infoLabel.Font = Enum.Font.GothamMedium; infoLabel.TextSize = 12
                    infoLabel.TextXAlignment = Enum.TextXAlignment.Left; infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    petButtons[i] = {button=btn, stroke=bStroke, rank=rankLabel, info=infoLabel, bar=itemBar}
                    
                    btn.MouseButton1Click:Connect(function()
                        selectedTargetIndex = i
                        selectedTargetUID = petData.uid
                        State.manualTargetEnabled = true
                        SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
                    end)
                end
            end
            SharedState.ListNeedsRedraw = false
        end
        
        if selectedTargetIndex > #petButtons then selectedTargetIndex = 1 end

        for i, pb in ipairs(petButtons) do
            local sel = (i == selectedTargetIndex)
            pb.stroke.Transparency = sel and 0 or 1
            pb.button.BackgroundColor3 = sel and Theme.SurfaceHighlight or Theme.Surface
            pb.rank.TextColor3  = sel and Theme.Accent1 or Theme.TextSecondary
            pb.info.TextColor3  = sel and Theme.TextPrimary or Theme.TextSecondary
        end
        local ct = allPets and allPets[selectedTargetIndex]
        SharedState.SelectedPetData = ct
        if enabled then
            targetLabel.Text = ct and string.format("%s (%s)", ct.petName, ct.mpsText) or "Searching..."
        else targetLabel.Text = "Disabled" end
        listFrame.CanvasSize = UDim2.new(0,0,0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end
    
    uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0,0,0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end)
    
    SharedState.UpdateAutoStealUI = function()
        updateUI(autoStealEnabled, get_all_pets())
    end
    
    enableBtn.MouseButton1Click:Connect(function()
        autoStealEnabled = not autoStealEnabled; SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)
    
    nearestBtn.MouseButton1Click:Connect(function()
        stealNearestEnabled = not stealNearestEnabled
        if stealNearestEnabled then stealHighestEnabled = false; stealPriorityEnabled = false; State.manualTargetEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    highestBtn.MouseButton1Click:Connect(function()
        stealHighestEnabled = not stealHighestEnabled
        if stealHighestEnabled then stealNearestEnabled = false; stealPriorityEnabled = false; State.manualTargetEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    priorityBtn.MouseButton1Click:Connect(function()
        stealPriorityEnabled = not stealPriorityEnabled
        if stealPriorityEnabled then stealNearestEnabled = false; stealHighestEnabled = false; State.manualTargetEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    local customizePriorityBtn = Instance.new("TextButton", toggleBtnContainer)
    customizePriorityBtn.Size = UDim2.new(1,0,0,24); customizePriorityBtn.Position = UDim2.new(0,0,0,92)
    customizePriorityBtn.BackgroundColor3 = Theme.Accent2
    customizePriorityBtn.Text = "CUSTOMIZE PRIORITY"; customizePriorityBtn.Font = Enum.Font.GothamBold
    customizePriorityBtn.TextSize = 10; customizePriorityBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", customizePriorityBtn).CornerRadius = UDim.new(0, 6)
    customizePriorityBtn.Visible = not IS_MOBILE
    
    customizePriorityBtn.MouseButton1Click:Connect(function()
        local priorityGui = PlayerGui:FindFirstChild("PriorityListGUI")
        if priorityGui then
            priorityGui.Enabled = not priorityGui.Enabled
        end
    end)

    local instantStealBtn = Instance.new("TextButton", toggleBtnContainer)
    instantStealBtn.Size = UDim2.new(1,0,0,24*mobileButtonScale); instantStealBtn.Position = UDim2.new(0,0,0,116*mobileButtonScale)
    instantStealBtn.BackgroundColor3 = instantStealEnabled and Theme.Accent1 or Theme.SurfaceHighlight
    instantStealBtn.Text = instantStealEnabled and "INSTANT STEAL: ON" or "INSTANT STEAL: OFF"; instantStealBtn.Font = Enum.Font.GothamBold
    instantStealBtn.TextSize = 10*mobileButtonScale; instantStealBtn.TextColor3 = instantStealEnabled and Color3.new(0,0,0) or Theme.TextPrimary
    Instance.new("UICorner", instantStealBtn).CornerRadius = UDim.new(0, 6)

    instantStealBtn.MouseButton1Click:Connect(function()
        instantStealEnabled = not instantStealEnabled
        if not instantStealEnabled then
            instantStealReady = false
            instantStealDidInit = false
        end
        Config.InstantSteal = instantStealEnabled
        SaveConfig()
        instantStealBtn.Text = instantStealEnabled and "INSTANT STEAL: ON" or "INSTANT STEAL: OFF"
        instantStealBtn.BackgroundColor3 = instantStealEnabled and Theme.Accent1 or Theme.SurfaceHighlight
        instantStealBtn.TextColor3 = instantStealEnabled and Color3.new(0,0,0) or Theme.TextPrimary
        SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    local function findProximityPromptForAnimal(animalData)
        if not animalData then return nil end
        local cp = PromptMemoryCache[animalData.uid]
        if cp and cp.Parent then return cp end
        local plot = Workspace.Plots:FindFirstChild(animalData.plot); if not plot then return nil end
        local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return nil end
        
        
        local ch = Synchronizer:Get(plot.Name)
        if not ch then
            
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local attach = spawn:FindFirstChild("PromptAttachment")
                    if attach then
                        for _, p in ipairs(attach:GetChildren()) do
                            if p:IsA("ProximityPrompt") then
                                PromptMemoryCache[animalData.uid] = p
                                return p
                            end
                        end
                    end
                end
            end
            return nil
        end
        
        local al = ch:Get("AnimalList")
        if not al then return nil end
        
        local brainrotName = animalData.name and animalData.name:lower() or ""
        local targetSlot = animalData.slot
        
        
        local foundPodium = nil
        for slot, ad in pairs(al) do
            if type(ad) == "table" and tostring(slot) == targetSlot then
                local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                if aInfo and (aInfo.DisplayName or aName):lower() == brainrotName then
                    foundPodium = podiums:FindFirstChild(tostring(slot))
                    break
                end
            end
        end
        
        
        if not foundPodium then
            foundPodium = podiums:FindFirstChild(animalData.slot)
        end
        
        if foundPodium then
            local base = foundPodium:FindFirstChild("Base")
            local spawn = base and base:FindFirstChild("Spawn")
            if spawn then
                
                local attach = spawn:FindFirstChild("PromptAttachment")
                if attach then
                    for _, p in ipairs(attach:GetChildren()) do
                        if p:IsA("ProximityPrompt") and p.Enabled and p.ActionText == "Steal" then
                            PromptMemoryCache[animalData.uid] = p
                            return p
                        end
                    end
                end
                
                
                local startPos = spawn.Position
                local slotX, slotZ = startPos.X, startPos.Z
                local nearestPrompt = nil
                local minDist = math.huge
                
                for _, desc in pairs(plot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
                        local part = desc.Parent
                        local promptPos = nil
                        
                        if part and part:IsA("BasePart") then
                            promptPos = part.Position
                        elseif part and part:IsA("Attachment") and part.Parent and part.Parent:IsA("BasePart") then
                            promptPos = part.Parent.Position
                        end
                        
                        if promptPos then
                            local checkStartY = startPos.Y
                            if brainrotName:find("la secret combinasion") then
                                checkStartY = startPos.Y - 5
                            end
                            local horizontalDist = math.sqrt((promptPos.X - slotX)^2 + (promptPos.Z - slotZ)^2)
                            if horizontalDist < 5 and promptPos.Y > checkStartY then
                                local yDist = promptPos.Y - checkStartY
                                if yDist < minDist then
                                    minDist = yDist
                                    nearestPrompt = desc
                                end
                            end
                        end
                    end
                end
                
                if nearestPrompt then
                    PromptMemoryCache[animalData.uid] = nearestPrompt
                    return nearestPrompt
                end
            end
        end
        
        return nil
    end

    local STEAL_DURATION = 0.8

    local function buildStealCallbacks(prompt)
        if InternalStealCache[prompt] then return end
        local data = {holdCallbacks = {}, triggerCallbacks = {}, holdEndCallbacks = {}, ready = true}
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table" then
            for _, conn in ipairs(conns1) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table" then
            for _, conn in ipairs(conns2) do
                if type(conn.Function) == "function" then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        local ok3, conns3 = pcall(getconnections, prompt.PromptButtonHoldEnded)
        if ok3 and type(conns3) == "table" then
            for _, conn in ipairs(conns3) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdEndCallbacks, conn.Function)
                end
            end
        end
        if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) or (#data.holdEndCallbacks > 0) then
            InternalStealCache[prompt] = data
        end
    end

    local function runCallbackList(list)
        for _, fn in ipairs(list) do
            task.spawn(fn)
        end
    end

    local INSTANT_STEAL_RADIUS = 60
    local INSTANT_STEAL_COOLDOWN = 0.04
    local lastInstantStealTime = 0
    local function isMyPlot_Instant(plotName)
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end
        local plot = plots:FindFirstChild(plotName)
        if not plot then return false end
        local sign = plot:FindFirstChild("PlotSign")
        if not sign then return false end
        local yb = sign:FindFirstChild("YourBase")
        return yb and yb:IsA("BillboardGui") and yb.Enabled
    end
    local function findNearestPrompt_Instant()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, math.huge, nil end
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil, math.huge, nil end
        local bestPrompt, bestDist, bestName = nil, math.huge, nil
        for _, plot in ipairs(plots:GetChildren()) do
            if isMyPlot_Instant(plot.Name) then continue end
            local plotDist = math.huge
            pcall(function() plotDist = (plot:GetPivot().Position - hrp.Position).Magnitude end)
            if plotDist > INSTANT_STEAL_RADIUS + 40 then continue end
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if not podiums then continue end
            for _, pod in ipairs(podiums:GetChildren()) do
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if not spawn then continue end
                local dist = (spawn.Position - hrp.Position).Magnitude
                if dist > INSTANT_STEAL_RADIUS or dist >= bestDist then continue end
                local att = spawn:FindFirstChild("PromptAttachment")
                if not att then continue end
                local prompt = att:FindFirstChildOfClass("ProximityPrompt")
                if prompt and prompt.Parent and prompt.Enabled then
                    bestPrompt = prompt
                    bestDist = dist
                    bestName = pod.Name
                end
            end
        end
        return bestPrompt, bestDist, bestName
    end
    -- STEAL: fireproximityprompt + direct remote callbacks
    local function executeInstantSteal(prompt)
        if not prompt or not prompt.Parent or not prompt.Enabled then return end
        local now = os.clock()
        if now - lastInstantStealTime < INSTANT_STEAL_COOLDOWN then return end
        lastInstantStealTime = now

        -- Fire the proximity prompt (mimics real E press)
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            end
        end)

        -- Also fire server remote directly via getconnections callbacks
        task.spawn(function()
            buildStealCallbacks(prompt)
            local data = InternalStealCache[prompt]
            if data then
                if #data.holdCallbacks > 0 then
                    runCallbackList(data.holdCallbacks)
                end
                task.wait(0.05)
                if #data.triggerCallbacks > 0 then
                    runCallbackList(data.triggerCallbacks)
                end
            end
        end)
    end

    local function executeInternalStealAsync(prompt, animalUID)
        local data = InternalStealCache[prompt]
        if not data or not data.ready then return false end
        data.ready = false

        task.spawn(function()
            if currentStealTargetUID ~= animalUID then
                if activeProgressTween then activeProgressTween:Cancel() end
                progressBarFill.Size = UDim2.new(0, 0, 1, 0)
                currentStealTargetUID = animalUID
            end

            -- Hold begin
            if #data.holdCallbacks > 0 then
                runCallbackList(data.holdCallbacks)
            end

            progressBarFill.Size = UDim2.new(0, 0, 1, 0)
            progressBarFill.BackgroundTransparency = 0
            activeProgressTween = TweenService:Create(progressBarFill, TweenInfo.new(STEAL_DURATION, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
            activeProgressTween:Play()
            activeProgressTween.Completed:Wait()

            if currentStealTargetUID == animalUID and #data.triggerCallbacks > 0 then
                runCallbackList(data.triggerCallbacks)
            end

            data.ready = true
        end)

        return true
    end

    local function attemptSteal(prompt, animalUID)
        if not prompt or not prompt.Parent then return false end
        buildStealCallbacks(prompt)
        if not InternalStealCache[prompt] then return false end

        if currentStealTargetUID ~= animalUID then
            if activeProgressTween then
                activeProgressTween:Cancel()
                activeProgressTween = nil
            end
            progressBarFill.Size = UDim2.new(0, 0, 1, 0)
        end

        return executeInternalStealAsync(prompt, animalUID)
    end

    local function prebuildStealCallbacks()
        for _, prompt in pairs(PromptMemoryCache) do
            if prompt and prompt.Parent then
                buildStealCallbacks(prompt)
            end
        end
    end

    task.spawn(function()
        while task.wait(2) do
            if autoStealEnabled then
                prebuildStealCallbacks()
            end
        end
    end)

    local lastAnimalData = {}
    local function getAnimalHash(al)
        if not al then return "" end; local h=""
        for slot, d in pairs(al) do if type(d)=="table" then h=h..tostring(slot)..tostring(d.Index)..tostring(d.Mutation) end end
        return h
    end

    local function scanSinglePlot(plot)
        local changed = false
        pcall(function()
            local ch = Synchronizer:Get(plot.Name); if not ch then return end
            local al = ch:Get("AnimalList")
            local hash = getAnimalHash(al)
            if lastAnimalData[plot.Name]==hash then return end
            lastAnimalData[plot.Name]=hash; changed=true
            for i=#allAnimalsCache,1,-1 do if allAnimalsCache[i].plot==plot.Name then table.remove(allAnimalsCache,i) end end
            local owner = ch:Get("Owner")
            if not owner or not Players:FindFirstChild(owner.Name) then return end
            local ownerName = owner.Name or "Unknown"
            if not al then return end
            for slot, ad in pairs(al) do
                if type(ad)=="table" then
                    local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                    if aInfo then
                        local mut = ad.Mutation or "None"
                        if mut == "Yin Yang" then mut = "YinYang" end
                        local traits = (ad.Traits and #ad.Traits>0) and table.concat(ad.Traits,", ") or "None"
                        local gv = AnimalsShared:GetGeneration(aName, ad.Mutation, ad.Traits, nil)
                        local gt = "$"..NumberUtils:ToString(gv).."/s"
                        table.insert(allAnimalsCache, {
                            name=aInfo.DisplayName or aName, genText=gt, genValue=gv,
                            mutation=mut, traits=traits, owner=ownerName,
                            plot=plot.Name, slot=tostring(slot), uid=plot.Name.."_"..tostring(slot)
                        })
                    end
                end
            end
        end)
        if changed then
            table.sort(allAnimalsCache, function(a,b) return a.genValue>b.genValue end)
            SharedState.ListNeedsRedraw = true
            
            
            if not hasShownPriorityAlert and Config.AlertsEnabled then
                task.spawn(function()
                    
                    local foundPriorityPet = nil
                    for i = 1, #PRIORITY_LIST do
                        local priorityName = PRIORITY_LIST[i]
                        local searchName = priorityName:lower()
                        
                        
                        for _, pet in ipairs(allAnimalsCache) do
                            if pet.name and pet.name:lower() == searchName then
                                foundPriorityPet = pet
                                break
                            end
                        end
                        
                        
                        if foundPriorityPet then
                            break
                        end
                    end
                    
                    if foundPriorityPet then
                        
                        local ownerUsername = foundPriorityPet.owner
                        local ownerPlayer = nil
                        
                        local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(foundPriorityPet.plot)
                        if plot then
                            
                            local sync = Synchronizer
                            if not sync then
                                local Packages = ReplicatedStorage:FindFirstChild("Packages")
                                if Packages then
                                    local ok, syncModule = pcall(function() return require(Packages:WaitForChild("Synchronizer")) end)
                                    if ok then sync = syncModule end
                                end
                            end
                            
                            if sync then
                                local ok, ch = pcall(function() return sync:Get(plot.Name) end)
                                if ok and ch then
                                    local owner = ch:Get("Owner")
                                    if owner then
                                        if typeof(owner) == "Instance" and owner:IsA("Player") then
                                            ownerPlayer = owner
                                            ownerUsername = owner.Name
                                        elseif type(owner) == "table" and owner.Name then
                                            ownerUsername = owner.Name
                                            ownerPlayer = Players:FindFirstChild(owner.Name)
                                        end
                                    end
                                end
                            end
                        end
                        
                        
                        if not ownerPlayer and ownerUsername then
                            ownerPlayer = Players:FindFirstChild(ownerUsername)
                        end
                        
                        ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, ownerUsername)
                    end
                end)
            end
        end
    end

    local function setupPlotListener(plot)
        local ch, retries = nil, 0
        while not ch and retries<50 do
            local ok, r = pcall(function() return Synchronizer:Get(plot.Name) end)
            if ok and r then ch=r; break else retries=retries+1; task.wait(0.1) end
        end
        if not ch then return end
        scanSinglePlot(plot)
        plot.DescendantAdded:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        plot.DescendantRemoving:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        task.spawn(function() while plot.Parent do task.wait(5); scanSinglePlot(plot) end end)
    end

    local plots = Workspace:WaitForChild("Plots", 8)
    if plots then
        for _, p in ipairs(plots:GetChildren()) do setupPlotListener(p) end
        plots.ChildAdded:Connect(function(p) task.wait(0.5); setupPlotListener(p) end)
        plots.ChildRemoved:Connect(function(p)
            lastAnimalData[p.Name]=nil
            for i=#allAnimalsCache,1,-1 do if allAnimalsCache[i].plot==p.Name then table.remove(allAnimalsCache,i) end end
            SharedState.ListNeedsRedraw=true
        end)
    end

    
    local duelBaseHighlights = {}
    local duelBaseBillboards = {}
    
    local function clearDuelBaseVisuals()
        for _, h in pairs(duelBaseHighlights) do
            if h and h.Parent then h:Destroy() end
        end
        duelBaseHighlights = {}
        for _, b in pairs(duelBaseBillboards) do
            if b and b.Parent then b:Destroy() end
        end
        duelBaseBillboards = {}
    end
    
    local function createDuelBaseMarker(plot, sign)
        local plotName = plot.Name
        
        if duelBaseHighlights[plotName] then return end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "DuelBaseHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.3
        highlight.Adornee = plot
        highlight.Parent = plot
        duelBaseHighlights[plotName] = highlight
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "DuelBaseMarker"
        bb.Size = UDim2.new(0, 180, 0, 40)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.ResetOnSpawn = false
        bb.Adornee = sign
        bb.Parent = sign
        
        local frame = Instance.new("Frame", bb)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(255, 0, 0)
        stroke.Thickness = 2
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "DUEL BASE"
        label.Font = Enum.Font.GothamBlack
        label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(255, 50, 50)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        duelBaseBillboards[plotName] = bb
    end
    
    task.spawn(function()
        while true do
            task.wait(1)
            if not Config.DuelBaseESP then
                clearDuelBaseVisuals()
            else
                local Plots = Workspace:FindFirstChild("Plots")
                if Plots then
                    for _, plot in ipairs(Plots:GetChildren()) do
                        local sign = plot:FindFirstChild("PlotSign")
                        if sign then
                            local textLabel = sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
                            local baseText = textLabel and textLabel.Text or nil
                            if baseText and baseText ~= "Empty Base" then
                                local nickname = baseText:match("^(.-)'") or baseText
                                local ownerPlayer = nil
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p.DisplayName == nickname or p.Name == nickname then
                                        ownerPlayer = p
                                        break
                                    end
                                end
                                
                                if ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true then
                                    if Config.DuelBaseESP then
                                        createDuelBaseMarker(plot, sign)
                                    end
                                else
                                    local plotName = plot.Name
                                    if duelBaseHighlights[plotName] then
                                        duelBaseHighlights[plotName]:Destroy()
                                        duelBaseHighlights[plotName] = nil
                                    end
                                    if duelBaseBillboards[plotName] then
                                        duelBaseBillboards[plotName]:Destroy()
                                        duelBaseBillboards[plotName] = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    
    local hasShownPriorityAlert = false
    
    local function ShowPriorityAlert(brainrotName, genText, mutation, ownerUsername)
        if not Config.AlertsEnabled then return end
        if hasShownPriorityAlert then return end
        
        local ownerPlayer = ownerUsername and Players:FindFirstChild(ownerUsername) or nil
        local isInDuel = ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true or false
        local duelStatusText = isInDuel and "IN DUEL" or "NOT IN DUEL"
        local duelStatusColor = isInDuel and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        
        local mutationColors = {
            ["rainbow"] = Color3.fromRGB(255, 0, 255),
            ["bloodrot"] = Color3.fromRGB(139, 0, 0),
            ["candy"] = Color3.fromRGB(255, 105, 180),
            ["radioactive"] = Color3.fromRGB(0, 255, 0),
            ["cursed"] = Color3.fromRGB(255, 50, 50),
            ["gold"] = Color3.fromRGB(255, 215, 0),
            ["diamond"] = Color3.fromRGB(0, 255, 255),
            ["yinyang"] = Color3.fromRGB(255, 255, 255),
            ["lava"] = Color3.fromRGB(255, 100, 20)
        }
        
        local normalizedMutation = mutation and mutation:gsub("%s+", ""):lower() or ""
        local color = mutationColors[normalizedMutation] or Color3.fromRGB(0, 170, 255)
        
        local existing = PlayerGui:FindFirstChild("HeroPriorityAlert")
        if existing then existing:Destroy() end
        
        local alertGui = Instance.new("ScreenGui")
        alertGui.Name = "HeroPriorityAlert"
        alertGui.ResetOnSpawn = false
        alertGui.DisplayOrder = 999
        alertGui.Parent = PlayerGui
        
        hasShownPriorityAlert = true
        
        local alertFrame = Instance.new("Frame")
        alertFrame.Size = UDim2.new(0, 400, 0, 60)
        alertFrame.Position = UDim2.new(0.5, 0, 0, -70)
        alertFrame.AnchorPoint = Vector2.new(0.5, 0)
        alertFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        alertFrame.BackgroundTransparency = 0.05
        alertFrame.BorderSizePixel = 0
        alertFrame.Parent = alertGui
        
        Instance.new("UICorner", alertFrame).CornerRadius = UDim.new(0, 12)
        
        local glowStroke = Instance.new("UIStroke", alertFrame)
        glowStroke.Name = "GlowStroke"
        glowStroke.Thickness = 3
        glowStroke.Color = color
        glowStroke.Transparency = 1
        
        local innerGlow = Instance.new("Frame", alertFrame)
        innerGlow.Name = "InnerGlow"
        innerGlow.Size = UDim2.new(1, 6, 1, 6)
        innerGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
        innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        innerGlow.BackgroundColor3 = color
        innerGlow.BackgroundTransparency = 1
        innerGlow.ZIndex = 0
        Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 14)
        
        local accentBar = Instance.new("Frame", alertFrame)
        accentBar.Size = UDim2.new(0, 4, 1, -12)
        accentBar.Position = UDim2.new(0, 8, 0, 6)
        accentBar.BackgroundColor3 = color
        accentBar.BorderSizePixel = 0
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
        
        local nameLabel = Instance.new("TextLabel", alertFrame)
        nameLabel.Size = UDim2.new(1, -30, 0.55, 0)
        nameLabel.Position = UDim2.new(0, 20, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = brainrotName .. " - " .. genText
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 18
        nameLabel.TextColor3 = color
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        
        local genLabel = Instance.new("TextLabel", alertFrame)
        genLabel.Size = UDim2.new(1, -30, 0.4, 0)
        genLabel.Position = UDim2.new(0, 20, 0.55, 0)
        genLabel.BackgroundTransparency = 1
        genLabel.Text = duelStatusText
        genLabel.Font = Enum.Font.GothamBold
        genLabel.TextSize = 17
        genLabel.TextColor3 = duelStatusColor
        genLabel.TextXAlignment = Enum.TextXAlignment.Center
        genLabel.TextStrokeColor3 = color
        
        TweenService:Create(alertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 15)
        }):Play()
        
        if Config.AlertSoundID and Config.AlertSoundID ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = Config.AlertSoundID
            sound.Volume = 0.5
            sound.Parent = alertFrame
            sound:Play()
            
            TweenService:Create(glowStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = 0
            }):Play()
            TweenService:Create(innerGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.85
            }):Play()
            
            task.delay(0.4, function()
                TweenService:Create(glowStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency = 0.6
                }):Play()
                TweenService:Create(innerGlow, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
            end)
            
            sound.Ended:Connect(function() sound:Destroy() end)
        end
        
        task.delay(4, function()
            TweenService:Create(alertFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -70)
            }):Play()
            task.wait(0.35)
            alertGui:Destroy()
        end)
    end
    
    
    task.spawn(function()
        task.wait(0.5)  
        while true do
            task.wait(0.5)  
            if not hasShownPriorityAlert and Config.AlertsEnabled and #allAnimalsCache > 0 then
                
                local foundPriorityPet = nil
                for i = 1, #PRIORITY_LIST do
                    local priorityName = PRIORITY_LIST[i]
                    local searchName = priorityName:lower()
                    
                    
                    for _, pet in ipairs(allAnimalsCache) do
                        if pet.name and pet.name:lower() == searchName then
                            foundPriorityPet = pet
                            break
                        end
                    end
                    
                    
                    if foundPriorityPet then
                        break
                    end
                end
                
                if foundPriorityPet then
                    
                    local ownerUsername = foundPriorityPet.owner
                    local ownerPlayer = nil
                    
                    local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(foundPriorityPet.plot)
                    if plot then
                        
                        local sync = Synchronizer
                        if not sync then
                            local Packages = ReplicatedStorage:FindFirstChild("Packages")
                            if Packages then
                                local ok, syncModule = pcall(function() return require(Packages:WaitForChild("Synchronizer")) end)
                                if ok then sync = syncModule end
                            end
                        end
                        
                        if sync then
                            local ok, ch = pcall(function() return sync:Get(plot.Name) end)
                            if ok and ch then
                                local owner = ch:Get("Owner")
                                if owner then
                                    if typeof(owner) == "Instance" and owner:IsA("Player") then
                                        ownerPlayer = owner
                                        ownerUsername = owner.Name
                                    elseif type(owner) == "table" and owner.Name then
                                        ownerUsername = owner.Name
                                        ownerPlayer = Players:FindFirstChild(owner.Name)
                                    end
                                end
                            end
                        end
                    end
                    
                    
                    if not ownerPlayer and ownerUsername then
                        ownerPlayer = Players:FindFirstChild(ownerUsername)
                    end
                    
                    ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, ownerUsername)
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            if autoStealEnabled then
                local pets = get_all_pets()
                if #pets > 0 then
                    local function applySelection(newIndex)
                        if newIndex and newIndex >= 1 and newIndex <= #pets and selectedTargetIndex ~= newIndex then
                            selectedTargetIndex = newIndex
                            selectedTargetUID = pets[newIndex].uid
                            SharedState.ListNeedsRedraw = false
                            updateUI(autoStealEnabled, pets)
                        end
                    end

                    local manualFound = false
                    if State.manualTargetEnabled and selectedTargetUID then
                        for i, p in ipairs(pets) do
                            if p.uid == selectedTargetUID then
                                if selectedTargetIndex ~= i then
                                    selectedTargetIndex = i
                                    updateUI(autoStealEnabled, pets)
                                end
                                manualFound = true
                                break
                            end
                        end
                    end

                    if manualFound then
                        -- Manual selection takes priority as long as pet exists
                    elseif stealPriorityEnabled then
                        local foundPrioIndex = nil
                        for _, pName in ipairs(PRIORITY_LIST) do
                            local searchName = pName:lower()
                            for i, p in ipairs(pets) do
                                if p.petName and p.petName:lower() == searchName then
                                    foundPrioIndex = i
                                    break
                                end
                            end
                            if foundPrioIndex then break end
                        end
                        if foundPrioIndex then
                            applySelection(foundPrioIndex)
                        else
                            applySelection(1)
                        end
                    elseif stealNearestEnabled then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bestIndex = nil
                            local bestDist = math.huge
                            for i, p in ipairs(pets) do
                                local targetPart = p.animalData and findAdorneeGlobal(p.animalData)
                                if targetPart and targetPart:IsA("BasePart") then
                                    local d = (hrp.Position - targetPart.Position).Magnitude
                                    if d < bestDist then
                                        bestDist = d
                                        bestIndex = i
                                    end
                                end
                            end
                            if bestIndex then
                                applySelection(bestIndex)
                            else
                                applySelection(1)
                            end
                        else
                            applySelection(1)
                        end
                    elseif stealHighestEnabled then
                        applySelection(1)
                    else
                        State.manualTargetEnabled = false
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not autoStealEnabled then return end
        if instantStealEnabled then
            if activeProgressTween then activeProgressTween:Cancel() activeProgressTween = nil end
            progressBarFill.Size = UDim2.new(1, 0, 1, 0)
            progressBarFill.BackgroundTransparency = 0
            if not instantStealDidInit then
                instantStealDidInit = true
                task.spawn(function()
                    if not game:IsLoaded() then game.Loaded:Wait() end
                    task.wait(0.5)
                    instantStealReady = true
                end)
            end
            if instantStealReady then
                if stealNearestEnabled then
                    local prompt, dist, name = findNearestPrompt_Instant()
                    if prompt and dist <= INSTANT_STEAL_RADIUS then
                        executeInstantSteal(prompt)
                    end
                else
                    local pets = get_all_pets()
                    if #pets > 0 then
                        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
                        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
                        local tp = pets[selectedTargetIndex]
                        if tp and not isMyBaseAnimal(tp.animalData) then
                            local pr = PromptMemoryCache[tp.uid]
                            if not pr or not pr.Parent then
                                pr = findProximityPromptForAnimal(tp.animalData)
                            end
                            if pr then
                                executeInstantSteal(pr)
                            end
                        end
                    end
                end
            end
            return
        end
        local pets = get_all_pets()
        if #pets == 0 then return end
        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
        local tp = pets[selectedTargetIndex]
        if not tp or isMyBaseAnimal(tp.animalData) then return end
        local pr = PromptMemoryCache[tp.uid]
        if not pr or not pr.Parent then
            pr = findProximityPromptForAnimal(tp.animalData)
        end
        if pr then
            attemptSteal(pr, tp.uid)
        end
    end)

    task.spawn(function() while task.wait(0.5) do updateUI(autoStealEnabled, get_all_pets()) end end)
    task.delay(1, function() SharedState.ListNeedsRedraw=true; updateUI(autoStealEnabled, get_all_pets()) end)
    task.spawn(function() while true do SharedState.AllAnimalsCache=allAnimalsCache; task.wait(0.5) end end)

    local beamFolder = Instance.new("Folder", Workspace)
    beamFolder.Name = "HeroTracers"
    local currentBeam = nil
    local currentAtt0 = nil
    local currentAtt1 = nil

    local function updateTracer()
        if not autoStealEnabled or not Config.TracerEnabled then
            if currentBeam then currentBeam:Destroy() currentBeam=nil end
            if currentAtt0 then currentAtt0:Destroy() currentAtt0=nil end
            if currentAtt1 then currentAtt1:Destroy() currentAtt1=nil end
            return
        end

        local best = nil
        local targetPart = nil
        if Config.LineToBase then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local plots = Workspace:FindFirstChild("Plots")
                if plots then
                    for _, plot in ipairs(plots:GetChildren()) do
                        local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
                        if ok and ch then
                            local owner = ch:Get("Owner")
                            local ownerId = (typeof(owner) == "Instance" and owner:IsA("Player")) and owner.UserId or (type(owner) == "table" and owner.UserId)
                            if ownerId == LocalPlayer.UserId then
                                local plotPos = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("Spawn")
                                if plotPos and plotPos:IsA("BasePart") then
                                    targetPart = plotPos
                                    break
                                end
                            end
                        end
                    end
                end
            end
        else
            local pets = get_all_pets()
            if #pets == 0 then
                if currentBeam then currentBeam.Enabled=false end
                return
            end
            if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
            if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
            best = pets[selectedTargetIndex] or pets[1]
            targetPart = findAdorneeGlobal(best.animalData)
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp and targetPart then
            if not currentAtt0 or currentAtt0.Parent ~= hrp then
                if currentAtt0 then currentAtt0:Destroy() end
                currentAtt0 = Instance.new("Attachment", hrp)
            end
            if not currentAtt1 or currentAtt1.Parent ~= targetPart then
                if currentAtt1 then currentAtt1:Destroy() end
                currentAtt1 = Instance.new("Attachment", targetPart)
            end

            if not currentBeam then
                currentBeam = Instance.new("Beam", beamFolder)
                currentBeam.FaceCamera = true
                currentBeam.Width0 = 0.8
                currentBeam.Width1 = 0.8
                currentBeam.TextureMode = Enum.TextureMode.Static
                currentBeam.TextureSpeed = 3
            end

            currentBeam.Attachment0 = currentAtt0
            currentBeam.Attachment1 = currentAtt1
            currentBeam.Enabled = true

            local MUT_COLORS_TRACE = {
                Cursed=Color3.fromRGB(200,0,0), Gold=Color3.fromRGB(255,215,0),
                Diamond=Color3.fromRGB(0,255,255), YinYang=Color3.fromRGB(220,220,220),
                Rainbow=Color3.fromRGB(255,100,200), Lava=Color3.fromRGB(255,100,20),
                Candy=Color3.fromRGB(255,105,180), Divine=Color3.fromRGB(255,255,255)
            }
            local col = Theme.Accent2
            if not Config.LineToBase then
                col = (best and best.mutation and MUT_COLORS_TRACE[best.mutation]) or Theme.Accent1
            end
            currentBeam.Color = ColorSequence.new(col)
        else
            if currentBeam then currentBeam.Enabled = false end
        end
    end

    RunService.Heartbeat:Connect(updateTracer)
end)

task.spawn(function()
    local COOLDOWNS = {
        rocket = 120, ragdoll = 30, balloon = 30, inverse = 60,
        nightvision = 60, jail = 60, tiny = 60, jumpscare = 60, morph = 60
    }
    local ALL_COMMANDS = {
        "balloon", "inverse", "jail", "jumpscare", "morph", 
        "nightvision", "ragdoll", "rocket", "tiny"
    }

    local activeCooldowns = {} 
    SharedState.AdminButtonCache = {}

    -- ============================================================
    -- BLACKLIST SYSTEM
    -- ============================================================
    BlacklistedPlayers = Config.Blacklist or {}

    addToBlacklist = function(username)
        if not username or username == "" then return false end
        local lower = string.lower(username)
        for _, v in ipairs(BlacklistedPlayers) do
            if string.lower(v) == lower then return false end
        end
        table.insert(BlacklistedPlayers, username)
        Config.Blacklist = BlacklistedPlayers
        SaveConfig()
        return true
    end

    removeFromBlacklist = function(username)
        if not username or username == "" then return false end
        local lower = string.lower(username)
        for i, v in ipairs(BlacklistedPlayers) do
            if string.lower(v) == lower then
                table.remove(BlacklistedPlayers, i)
                Config.Blacklist = BlacklistedPlayers
                SaveConfig()
                -- Immediately remove ESP from that player if online
                if _G.removeBlacklistESP then
                    local p = Players:FindFirstChild(username)
                    if p then _G.removeBlacklistESP(p) end
                end
                return true
            end
        end
        return false
    end

    isBlacklisted = function(username)
        if not username then return false end
        local lower = string.lower(username)
        for _, v in ipairs(BlacklistedPlayers) do
            if string.lower(v) == lower then return true end
        end
        return false
    end

    canUseAdminAction = function(targetPlayer)
        if not targetPlayer then return false end
        if isBlacklisted(targetPlayer.Name) then
            ShowNotification("BLACKLIST", "🚫 " .. targetPlayer.Name .. " is blacklisted")
            return false
        end
        return true
    end

    refreshBlacklistUI = nil

    local adminGui = Instance.new("ScreenGui")
    adminGui.Name = "HeroAdminPanel"
    adminGui.ResetOnSpawn = false
    adminGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.65 or 1
    frame.Size = UDim2.new(0, 440*mobileScale, 0, 500*mobileScale) 
    frame.Position = UDim2.new(Config.Positions.AdminPanel.X, 0, Config.Positions.AdminPanel.Y, 0)
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = adminGui
    
    ApplyViewportUIScale(frame, 400, 450, 0.45, 0.85)
    AddMobileMinimize(frame, "ADMIN")
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Theme.Accent2; stroke.Thickness = 1.5; stroke.Transparency = 0.4
    CreateGradient(stroke)
    task.defer(function() if addRacetrackBorder then addRacetrackBorder(frame, Theme.Accent1, 3.5) end end)

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    MakeDraggable(header, frame, "AdminPanel")

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ADMIN PANEL"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextColor3 = Theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left

    local refreshBtn = Instance.new("TextButton", header)
    refreshBtn.Size = UDim2.new(0, 80, 0, 30)
    refreshBtn.Position = UDim2.new(1, -85, 0.5, -15)
    refreshBtn.BackgroundColor3 = Theme.SurfaceHighlight
    refreshBtn.Text = "REFRESH"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    refreshBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
    local refreshStroke = Instance.new("UIStroke", refreshBtn)
    refreshStroke.Color = Theme.Accent2
    refreshStroke.Thickness = 1
    refreshStroke.Transparency = 0.3
    
    refreshBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if Config.HideKawaifuFromPanel and isKawaifuUser(player) then continue end
            createPlayerRow(player)
        end
        sortAdminPanelList()
        
        ShowNotification("ADMIN PANEL", "Player list refreshed")
    end)

    local proxCont = Instance.new("Frame", frame)
    proxCont.Size = UDim2.new(1, -20, 0, 82)
    proxCont.Position = UDim2.new(0, 10, 0, 58)
    proxCont.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    proxCont.BackgroundTransparency = 0.3
    Instance.new("UICorner", proxCont).CornerRadius = UDim.new(0, 10)
    local proxContStroke = Instance.new("UIStroke", proxCont)
    proxContStroke.Color = Theme.Accent2
    proxContStroke.Thickness = 1
    proxContStroke.Transparency = 0.6

    local proxBtn = Instance.new("TextButton", proxCont)
    proxBtn.Name = "ProximityAPButton"
    proxBtn.Size = UDim2.new(0, 80, 0, 26)
    proxBtn.Position = UDim2.new(0, 6, 0, 8)
    proxBtn.BackgroundColor3 = ProximityAPActive and Theme.Accent1 or Color3.fromRGB(35, 37, 43)
    proxBtn.Text = "Prox"
    proxBtn.Font = Enum.Font.GothamBold; proxBtn.TextSize = 11
    proxBtn.TextColor3 = ProximityAPActive and Color3.new(255,255,255) or Theme.TextPrimary
    Instance.new("UICorner", proxBtn).CornerRadius = UDim.new(0, 6)
    local proxBtnStroke = Instance.new("UIStroke", proxBtn)
    proxBtnStroke.Color = ProximityAPActive and Theme.Accent2 or Color3.fromRGB(50, 52, 58)
    proxBtnStroke.Transparency = 0.3
    SharedState.ProximityAPButton = proxBtn
    SharedState.ProximityAPButtonStroke = proxBtnStroke
    SharedState.AdminProxBtn = proxBtn

    local spamBaseBtn = Instance.new("TextButton", proxCont)
    spamBaseBtn.Size = UDim2.new(0, 80, 0, 26)
    spamBaseBtn.Position = UDim2.new(0, 90, 0, 8)
    spamBaseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
    spamBaseBtn.Text = "Spam Owner"
    spamBaseBtn.Font = Enum.Font.GothamBold; spamBaseBtn.TextSize = 9
    spamBaseBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", spamBaseBtn).CornerRadius = UDim.new(0, 6)
    local spamBaseBtnStroke = Instance.new("UIStroke", spamBaseBtn)
    spamBaseBtnStroke.Color = Color3.fromRGB(50, 52, 58)
    spamBaseBtnStroke.Transparency = 0.3
    
    spamBaseBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            ShowNotification("SPAM OWNER", "No character found")
            return
        end
        
        local nearestPlot = nil
        local nearestDist = math.huge
        local Plots = Workspace:FindFirstChild("Plots")
        if Plots then
            for _, plot in ipairs(Plots:GetChildren()) do
                local sign = plot:FindFirstChild("PlotSign")
                if sign then
                    local yourBase = sign:FindFirstChild("YourBase")
                    if not yourBase or not yourBase.Enabled then
                        local signPos = sign:IsA("BasePart") and sign.Position or (sign.PrimaryPart and sign.PrimaryPart.Position)
                        if not signPos then
                            local part = sign:FindFirstChildWhichIsA("BasePart", true)
                            signPos = part and part.Position
                        end
                        if signPos then
                            local dist = (hrp.Position - signPos).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestPlot = plot
                            end
                        end
                    end
                end
            end
        end
        
        if not nearestPlot then
            ShowNotification("SPAM OWNER", "No nearby base found")
            return
        end
        
        
        local targetPlayer = nil
        local ok, ch = pcall(function() return Synchronizer:Get(nearestPlot.Name) end)
        if ok and ch then
            local owner = ch:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then
                    targetPlayer = owner
                elseif type(owner) == "table" and owner.Name then
                    targetPlayer = Players:FindFirstChild(owner.Name)
                end
            end
        end
        
        
        if not targetPlayer then
            local sign = nearestPlot:FindFirstChild("PlotSign")
            local textLabel = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if textLabel then
                local baseText = textLabel.Text
                local nickname = baseText and baseText:match("^(.-)'") or baseText
                if nickname then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.DisplayName == nickname or p.Name == nickname then
                            targetPlayer = p
                            break
                        end
                    end
                end
            end
        end
        
        if not targetPlayer or targetPlayer == LocalPlayer then
            ShowNotification("SPAM OWNER", "Owner not found or is you")
            return
        end
        
        spamBaseBtn.BackgroundColor3 = Theme.Accent1
        spamBaseBtn.TextColor3 = Color3.new(1,1,1)
        ShowNotification("SPAM OWNER", "Spamming " .. targetPlayer.DisplayName)
        
        task.spawn(function()
            local cmds = {"balloon", "inverse", "jail", "jumpscare", "morph", "nightvision", "ragdoll", "rocket", "tiny"}
            local cmdCount = 0
            
            local adminFunc = _G.runAdminCommand
            if not adminFunc then
                task.wait(0.05)
                adminFunc = _G.runAdminCommand
            end
            
            if not adminFunc then
                spamBaseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                spamBaseBtn.TextColor3 = Theme.TextPrimary
                ShowNotification("SPAM OWNER", "Admin command not ready")
                return
            end
            
            for _, cmd in ipairs(cmds) do
                local success, result = pcall(function()
                    return adminFunc(targetPlayer, cmd)
                end)
                if success and result then
                    cmdCount = cmdCount + 1
                end
                task.wait(0.15)
            end
            
            task.wait(0.2)
            spamBaseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
            spamBaseBtn.TextColor3 = Theme.TextPrimary
            ShowNotification("SPAM OWNER", "Sent " .. cmdCount .. " commands to " .. targetPlayer.DisplayName)
        end)
    end)

    local proxSliderBg = Instance.new("Frame", proxCont)
    proxSliderBg.Size = UDim2.new(0, 140, 0, 5)
    proxSliderBg.Position = UDim2.new(0, 105, 0.5, -2.5)
    proxSliderBg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
    Instance.new("UICorner", proxSliderBg).CornerRadius = UDim.new(1,0)
    local proxFill = Instance.new("Frame", proxSliderBg)
    proxFill.BackgroundColor3 = Theme.Accent1; proxFill.Size = UDim2.new(0,0,1,0)
    Instance.new("UICorner", proxFill).CornerRadius = UDim.new(1,0)
    local proxKnob = Instance.new("Frame", proxSliderBg)
    proxKnob.Size = UDim2.new(0,12,0,12); proxKnob.BackgroundColor3 = Theme.TextPrimary
    proxKnob.AnchorPoint = Vector2.new(0.5, 0.5); proxKnob.Position = UDim2.new(0,0,0.5,0)
    Instance.new("UICorner", proxKnob).CornerRadius = UDim.new(1,0)
    local proxKnobStroke = Instance.new("UIStroke", proxKnob)
    proxKnobStroke.Color = Theme.Accent1
    proxKnobStroke.Thickness = 1.5
    proxKnobStroke.Transparency = 0.2
    local function updateProxSlider(val)
        local min, max = 5, 50
        val = math.clamp(val, min, max)
        Config.ProximityRange = val; SaveConfig()
        local pct = (val - min)/(max - min)
        proxFill.Size = UDim2.new(pct, 0, 1, 0)
        proxKnob.Position = UDim2.new(pct, 0, 0.5, 0)
        ShowNotification("PROXIMITY RANGE", string.format("%.1f", val) .. " studs")
    end
    updateProxSlider(Config.ProximityRange)

    local pDragging = false
    proxSliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pDragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pDragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if pDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = i.Position.X
            local r = proxSliderBg.AbsolutePosition.X
            local w = proxSliderBg.AbsoluteSize.X
            local p = (x - r) / w
            updateProxSlider(5 + (p * 45))
        end
    end)

    local proxViz = nil
    local function updateProxViz()
        if ProximityAPActive then 
            if not proxViz then
                proxViz = Instance.new("Part")
                proxViz.Name = "XiProxViz"
                proxViz.Anchored = true; proxViz.CanCollide = false
                proxViz.Shape = Enum.PartType.Cylinder
                proxViz.Color = Theme.Accent1; proxViz.Transparency = 0.6
                proxViz.CastShadow = false
                proxViz.Parent = Workspace
            end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                proxViz.Size = Vector3.new(0.5, Config.ProximityRange * 2, Config.ProximityRange * 2)
                proxViz.CFrame = hrp.CFrame * CFrame.Angles(0,0,math.rad(90)) + Vector3.new(0, -2.5, 0)
            end
        else
            if proxViz then proxViz:Destroy(); proxViz = nil end
        end
    end
    RunService.Heartbeat:Connect(updateProxViz)

    local function updateProximityAPButton()
        if SharedState.ProximityAPButton then
            SharedState.ProximityAPButton.BackgroundColor3 = ProximityAPActive and Theme.Accent1 or Color3.fromRGB(35, 37, 43)
            SharedState.ProximityAPButton.TextColor3 = ProximityAPActive and Color3.new(255,255,255) or Theme.TextPrimary
            if SharedState.ProximityAPButtonStroke then
                SharedState.ProximityAPButtonStroke.Color = ProximityAPActive and Theme.Accent2 or Color3.fromRGB(50, 52, 58)
            end
        end
    end
    
    proxBtn.MouseButton1Click:Connect(function()
        ProximityAPActive = not ProximityAPActive 
        updateProximityAPButton()
        ShowNotification("PROXIMITY AP", ProximityAPActive and "ENABLED" or "DISABLED")
    end)

    proxSliderBg.Position = UDim2.new(0, 178, 0, 16)

    -- ── AUTO DESTROY TURRETS ────────────────────────────────────────
    local turretRow = Instance.new("Frame", proxCont)
    turretRow.Size     = UDim2.new(1,-12,0,30)
    turretRow.Position = UDim2.new(0,6,0,46)
    turretRow.BackgroundTransparency = 1

    local turretBtn = Instance.new("TextButton", turretRow)
    turretBtn.Size             = UDim2.new(0,130,0,26)
    turretBtn.Position         = UDim2.new(0,0,0.5,-13)
    turretBtn.AutoButtonColor  = false
    turretBtn.Font             = Enum.Font.GothamBold
    turretBtn.TextSize         = 10
    turretBtn.TextColor3       = Theme.TextPrimary
    turretBtn.Text             = Config.AutoDestroyTurrets and "🔫 TURRET: ON" or "🔫 TURRET: OFF"
    turretBtn.BackgroundColor3 = Config.AutoDestroyTurrets and Theme.Accent1 or Color3.fromRGB(35,37,43)
    Instance.new("UICorner", turretBtn).CornerRadius = UDim.new(0,6)
    local turretStroke = Instance.new("UIStroke", turretBtn)
    turretStroke.Color = Theme.Accent1; turretStroke.Thickness = 1; turretStroke.Transparency = 0.4
    turretBtn.MouseButton1Click:Connect(function()
        Config.AutoDestroyTurrets = not Config.AutoDestroyTurrets
        SaveConfig()
        turretBtn.Text             = Config.AutoDestroyTurrets and "🔫 TURRET: ON" or "🔫 TURRET: OFF"
        turretBtn.BackgroundColor3 = Config.AutoDestroyTurrets and Theme.Accent1 or Color3.fromRGB(35,37,43)
        ShowNotification("TURRET", Config.AutoDestroyTurrets and "Auto-Destroy ON" or "Auto-Destroy OFF")
    end)

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1, -20, 1, -150)
    listFrame.Position = UDim2.new(0, 10, 0, 146)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 5
    listFrame.ScrollBarImageColor3 = Theme.Accent1
    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function getAdminPanelSortKey(plr)
        if not plr or not plr.Parent then return 3, 9999, "" end
        local stealing = plr:GetAttribute("Stealing")
        local brainrotName = plr:GetAttribute("StealingIndex")
        if not stealing then
            return 3, 9999, plr.Name or ""
        end
        if brainrotName then
            for i, pName in ipairs(PRIORITY_LIST) do
                if pName == brainrotName then
                    return 1, i, plr.Name or ""
                end
            end
            return 2, 9999, plr.Name or ""
        end
        return 2, 9999, plr.Name or ""
    end

    local function sortAdminPanelList()
        local rows = {}
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "" then
                local plr = Players:FindFirstChild(child.Name)
                if plr then
                    table.insert(rows, {row = child, plr = plr})
                end
            end
        end
        table.sort(rows, function(a, b)
            local t1, p1, n1 = getAdminPanelSortKey(a.plr)
            local t2, p2, n2 = getAdminPanelSortKey(b.plr)
            if t1 ~= t2 then return t1 < t2 end
            if p1 ~= p2 then return p1 < p2 end
            return (n1 or "") < (n2 or "")
        end)
        for i, entry in ipairs(rows) do
            entry.row.LayoutOrder = i
        end
    end

    local function fireClick(button)
        if button then
            if firesignal then
                firesignal(button.MouseButton1Click); firesignal(button.MouseButton1Down); firesignal(button.Activated)
            else
                local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
                local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2) + 58
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end
        end
    end
    _G.fireClick = fireClick

    local function runAdminCommand(targetPlayer, commandName)
        local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
        if not realAdminGui then return false end
        local contentScroll = realAdminGui.AdminPanel:WaitForChild("Content"):WaitForChild("ScrollingFrame")
        local cmdBtn = contentScroll:FindFirstChild(commandName)
        if not cmdBtn then return false end
        fireClick(cmdBtn)
        task.wait(0.05)
        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
        local playerBtn = profilesScroll:FindFirstChild(targetPlayer.Name)
        if not playerBtn then return false end
        fireClick(playerBtn)
        return true
    end
    
    _G.runAdminCommand = runAdminCommand

local ALL_COMMANDS = {
    "balloon", "inverse", "jail", "jumpscare", "morph", 
    "nightvision", "ragdoll", "rocket", "tiny"
}

local isOnCooldown

local function getNextAvailableCommand()
    local priorityCommands = {"ragdoll", "balloon", "rocket", "jail"}
    local otherCommands = {}
    
    for _, cmd in ipairs(ALL_COMMANDS) do
        local isPriority = false
        for _, priorityCmd in ipairs(priorityCommands) do
            if cmd == priorityCmd then
                isPriority = true
                break
            end
        end
        if not isPriority then
            table.insert(otherCommands, cmd)
        end
    end

    for _, cmd in ipairs(priorityCommands) do
        if not isOnCooldown(cmd) then
            return cmd
        end
    end

    for _, cmd in ipairs(otherCommands) do
        if not isOnCooldown(cmd) then
            return cmd
        end
    end

    return nil
end

isOnCooldown = function(cmd)
    local adminGui = PlayerGui:FindFirstChild("AdminPanel")
    if adminGui then
        local content = adminGui:FindFirstChild("AdminPanel")
        if content then
            local scrollFrame = content:FindFirstChild("Content")
            if scrollFrame then
                local scrollingFrame = scrollFrame:FindFirstChild("ScrollingFrame")
                if scrollingFrame then
                    local cmdButton = scrollingFrame:FindFirstChild(cmd)
                    if cmdButton then
                        local timerLabel = cmdButton:FindFirstChild("Timer")
                        if timerLabel then
                            return timerLabel.Visible
                        end
                    end
                end
            end
        end
    end
    
    if not activeCooldowns[cmd] then return false end
    return (tick() - activeCooldowns[cmd]) < (COOLDOWNS[cmd] or 0)
end

    local function setGlobalVisualCooldown(cmd)
        if SharedState.AdminButtonCache[cmd] then
            for _, b in ipairs(SharedState.AdminButtonCache[cmd]) do
                if b and b.Parent then
                    b.BackgroundColor3 = Theme.Error
                    task.delay(COOLDOWNS[cmd] or 5, function()
                        if b and b.Parent then
                            local hasBallooned = (cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil)
                            b.BackgroundColor3 = hasBallooned and Theme.Error or Theme.SurfaceHighlight
                        end
                    end)
                end
            end
        end
    end

    local function updateBalloonButtons()
        local hasBallooned = false
        for _, _ in pairs(SharedState.BalloonedPlayers) do
            hasBallooned = true
            break
        end
        if SharedState.AdminButtonCache and SharedState.AdminButtonCache["balloon"] then
            for _, b in ipairs(SharedState.AdminButtonCache["balloon"]) do
                if b and b.Parent then
                    b.BackgroundColor3 = hasBallooned and Theme.Error or Theme.SurfaceHighlight
                end
            end
        end
    end

    local function triggerAll(plr)
        if not canUseAdminAction(plr) then return end
        local count = 0
        for _, cmd in ipairs(ALL_COMMANDS) do
            if not isOnCooldown(cmd) then
                task.delay(count * 0.1, function()
                    if runAdminCommand(plr, cmd) then
                        activeCooldowns[cmd] = tick()
                        setGlobalVisualCooldown(cmd)
                        if cmd == "balloon" then
                            SharedState.BalloonedPlayers[plr.UserId] = true
                            updateBalloonButtons()
                        end
                    end
                end)
                count = count + 1
            end
        end
    end

    local function rayToCubeIntersect(rayOrigin, rayDirection, cubeCenter, cubeSize)
        local halfSize = cubeSize / 2
        local minBounds = cubeCenter - Vector3.new(halfSize, halfSize, halfSize)
        local maxBounds = cubeCenter + Vector3.new(halfSize, halfSize, halfSize)
        
        if rayDirection.X == 0 then rayDirection = Vector3.new(0.0001, rayDirection.Y, rayDirection.Z) end
        if rayDirection.Y == 0 then rayDirection = Vector3.new(rayDirection.X, 0.0001, rayDirection.Z) end
        if rayDirection.Z == 0 then rayDirection = Vector3.new(rayDirection.X, rayDirection.Y, 0.0001) end
        
        local tmin = (minBounds.X - rayOrigin.X) / rayDirection.X
        local tmax = (maxBounds.X - rayOrigin.X) / rayDirection.X
        if tmin > tmax then tmin, tmax = tmax, tmin end
        
        local tymin = (minBounds.Y - rayOrigin.Y) / rayDirection.Y
        local tymax = (maxBounds.Y - rayOrigin.Y) / rayDirection.Y
        if tymin > tymax then tymin, tymax = tymax, tymin end
        
        if tmin > tymax or tymin > tmax then return false end
        if tymin > tmin then tmin = tymin end
        if tymax < tmax then tmax = tymax end
        
        local tzmin = (minBounds.Z - rayOrigin.Z) / rayDirection.Z
        local tzmax = (maxBounds.Z - rayOrigin.Z) / rayDirection.Z
        if tzmin > tzmax then tzmin, tzmax = tzmax, tzmin end
        
        if tmin > tzmax or tzmin > tmax then return false end
        
        return true
    end

    local highlight = Instance.new("Highlight", game:GetService("CoreGui"))
    highlight.FillColor = Theme.Accent1
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Theme.Accent1
    highlight.OutlineTransparency = 0
    highlight.Adornee = nil
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    RunService.RenderStepped:Connect(function()
        if Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            
            local hitboxSize = 8
            local bestPlayer = nil
            local bestDistance = math.huge
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    local cubeCenter = hrp.Position
                    
                    if rayToCubeIntersect(ray.Origin, ray.Direction, cubeCenter, hitboxSize) then
                        local distance = (ray.Origin - cubeCenter).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestPlayer = p
                        end
                    end
                end
            end
            
            local newAdornee = bestPlayer and bestPlayer.Character or nil
            if highlight.Adornee ~= newAdornee then
                highlight.Adornee = newAdornee
            end
        else
            highlight.Adornee = nil
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, g)
        if not g and inp.UserInputType == Enum.UserInputType.MouseButton1 and Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            
            local hitboxSize = 8
            local bestPlayer = nil
            local bestDistance = math.huge
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    local cubeCenter = hrp.Position
                    
                    if rayToCubeIntersect(ray.Origin, ray.Direction, cubeCenter, hitboxSize) then
                        local distance = (ray.Origin - cubeCenter).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestPlayer = p
                        end
                    end
                end
            end
            
            if bestPlayer then
                if Config.DisableClickToAPOnMoby and isMobyUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Moby users")
                    return
                end
                if Config.DisableClickToAPOnKawaifu and isKawaifuUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Kawaifu users")
                    return
                end
                if isBlacklisted(bestPlayer.Name) then
                    ShowNotification("BLACKLIST", "🚫 " .. bestPlayer.Name .. " is blacklisted")
                    return
                end
                
                local hasAnyAvailable = false
                for _, cmd in ipairs(ALL_COMMANDS) do
                    if not isOnCooldown(cmd) then
                        hasAnyAvailable = true
                        break
                    end
                end
                if hasAnyAvailable then
                    if Config.ClickToAPSingleCommand then
                        local nextCmd = getNextAvailableCommand()
                        if nextCmd then
                            if runAdminCommand(bestPlayer, nextCmd) then
                                activeCooldowns[nextCmd] = tick()
                                setGlobalVisualCooldown(nextCmd)
                                if nextCmd == "balloon" then
                                    SharedState.BalloonedPlayers[bestPlayer.UserId] = true
                                    updateBalloonButtons()
                                end
                                ShowNotification("CLICK AP", "Sent " .. nextCmd .. " to " .. bestPlayer.Name)
                            else
                                ShowNotification("CLICK AP", "Failed to send " .. nextCmd .. " to " .. bestPlayer.Name)
                            end
                        else
                            ShowNotification("CLICK AP", "All commands on cooldown")
                        end
                    else
                        triggerAll(bestPlayer)
                        ShowNotification("CLICK AP", "Triggered on " .. bestPlayer.Name)
                    end
                else
                    local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
                    if realAdminGui then
                        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
                        local playerBtn = profilesScroll:FindFirstChild(bestPlayer.Name)
                        if playerBtn then
                            fireClick(playerBtn)
                            ShowNotification("CLICK AP", "Selected " .. bestPlayer.Name)
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if ProximityAPActive then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                            if dist <= Config.ProximityRange then
                                if (Config.DisableProximitySpamOnMoby and isMobyUser(p)) or (Config.DisableProximitySpamOnKawaifu and isKawaifuUser(p)) or isBlacklisted(p.Name) then
                                    -- skip proximity AP 
                                else
                                    local hasAnyAvailable = false
                                    for _, cmd in ipairs(ALL_COMMANDS) do
                                        if not isOnCooldown(cmd) then
                                            hasAnyAvailable = true
                                            break
                                        end
                                    end
                                    if hasAnyAvailable then
                                        triggerAll(p)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local function createPlayerRow(plr)
        local row = Instance.new("TextButton") 
        row.Name = plr.Name
        row.LayoutOrder = 0
        row.Size = UDim2.new(1, -4, 0, 60)
        row.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
        row.BackgroundTransparency = 0.2
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = listFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Theme.Accent2
        rowStroke.Thickness = 1.5
        rowStroke.Transparency = 0.7
        
        row.MouseEnter:Connect(function()
            row.BackgroundTransparency = 0.05
            rowStroke.Transparency = 0.4
            rowStroke.Color = Theme.Accent1
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundTransparency = 0.2
            rowStroke.Transparency = 0.7
            rowStroke.Color = Theme.Accent2
        end)

        local headshot = Instance.new("ImageLabel", row)
        headshot.Size = UDim2.new(0, 42, 0, 42)
        headshot.Position = UDim2.new(0, 12, 0.5, -21)
        headshot.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
        headshot.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        Instance.new("UICorner", headshot).CornerRadius = UDim.new(1, 0)
        local headshotStroke = Instance.new("UIStroke", headshot)
        headshotStroke.Color = Theme.Accent1
        headshotStroke.Thickness = 2.5
        headshotStroke.Transparency = 0.2
        
        local dName = Instance.new("TextLabel", row)
        dName.Size = UDim2.new(0, 160, 0, 20)
        dName.Position = UDim2.new(0, 58, 0, 10)
        dName.BackgroundTransparency = 1
        dName.Text = plr.DisplayName
        dName.Font = Enum.Font.GothamBold
        dName.TextSize = 14
        dName.TextColor3 = Theme.TextPrimary
        dName.TextXAlignment = Enum.TextXAlignment.Left

        local uName = Instance.new("TextLabel", row)
        uName.Size = UDim2.new(0, 160, 0, 16)
        uName.Position = UDim2.new(0, 58, 0, 30)
        uName.BackgroundTransparency = 1
        uName.Text = "(@" .. plr.Name .. ")"
        uName.Font = Enum.Font.GothamMedium
        uName.TextSize = 7
        uName.TextColor3 = Theme.TextSecondary
        uName.TextXAlignment = Enum.TextXAlignment.Left

        local nearestBrainrotName = plr:GetAttribute("StealingIndex")
        
        local stealing = plr:GetAttribute("Stealing")
        if stealing then
            if nearestBrainrotName then
                uName.Text = nearestBrainrotName
                uName.TextColor3 = Color3.fromRGB(255, 200, 0)
                uName.Font = Enum.Font.GothamBlack
                uName.TextSize = 14
            else
                uName.Text = "STEALING"
                uName.TextColor3 = Color3.fromRGB(255, 150, 0)
                uName.Font = Enum.Font.GothamBlack
                uName.TextSize = 14
            end
        end
        
        task.spawn(function()
            while row.Parent do
                task.wait(0.5)
                
                if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then
                    removePlayer(plr)
                    break
                end
                
                local stealing = plr:GetAttribute("Stealing")
                nearestBrainrotName = plr:GetAttribute("StealingIndex")
                
                if stealing then
                    if nearestBrainrotName then
                        uName.Text = nearestBrainrotName
                        uName.TextColor3 = Color3.fromRGB(255, 200, 0)
                        uName.Font = Enum.Font.GothamBold
                        uName.TextSize = 11
                    else
                        uName.Text = "⚠️ STEALING"
                        uName.TextColor3 = Color3.fromRGB(255, 150, 0)
                        uName.Font = Enum.Font.GothamBold
                        uName.TextSize = 11
                    end
                else
                    uName.Text = "(@" .. plr.Name .. ")"
                    uName.TextColor3 = Theme.TextSecondary
                    uName.Font = Enum.Font.GothamMedium
                    uName.TextSize = 7
                    nearestBrainrotName = nil
                end
            end
        end)

        local btnCont = Instance.new("Frame", row)
        btnCont.Size = UDim2.new(0, 140, 1, 0)
        btnCont.Position = UDim2.new(1, -145, 0, 0)
        btnCont.BackgroundTransparency = 1
        btnCont.ZIndex = 10

        local buttonsDef = {
            {icon = "🚀", cmd = "rocket"},
            {icon = "🏃", cmd = "ragdoll"},
            {icon = "🔒", cmd = "jail"},
            {icon = "🎈", cmd = "balloon"},
        }

        for i, def in ipairs(buttonsDef) do
            local b = Instance.new("TextButton", btnCont)
            b.Size = UDim2.new(0, 30, 0, 30)
            b.Position = UDim2.new(0, (i-1)*34, 0.5, -15)
            b.AutoButtonColor = false
            b.Text = def.icon
            b.TextSize = 18
            b.TextColor3 = Theme.TextPrimary
            b.Font = Enum.Font.GothamBold
            b.ZIndex = 11
            b.Active = true
            local hasBallooned = SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
            local isOnCD = isOnCooldown(def.cmd)
            b.BackgroundColor3 = (def.cmd == "balloon" and hasBallooned) or isOnCD and Theme.Error or Color3.fromRGB(35, 37, 43)
            b.BackgroundTransparency = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = (def.cmd == "balloon" and hasBallooned) or isOnCD and Theme.Error or Theme.Accent1
            bStroke.Thickness = 1.5
            bStroke.Transparency = 0.4
            bStroke.ZIndex = 12
            
            b.MouseEnter:Connect(function()
                if not isOnCD and not (def.cmd == "balloon" and hasBallooned) then
                    b.BackgroundColor3 = Color3.fromRGB(45, 47, 53)
                    bStroke.Transparency = 0.2
                end
            end)
            b.MouseLeave:Connect(function()
                if not isOnCD and not (def.cmd == "balloon" and hasBallooned) then
                    b.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                    bStroke.Transparency = 0.4
                end
            end)
            
            if not SharedState.AdminButtonCache[def.cmd] then SharedState.AdminButtonCache[def.cmd] = {} end
            table.insert(SharedState.AdminButtonCache[def.cmd], b)

            task.spawn(function()
                while b and b.Parent do
                    task.wait(0.05)
                    if not b.Text or b.Text == "" or b.Text == "BUTTON" or b.Text == "Button" then
                        b.Text = def.icon
                        b.TextSize = 18
                        b.TextColor3 = Theme.TextPrimary
                        b.Font = Enum.Font.GothamBold
                    end
                    local cd = isOnCooldown(def.cmd)
                    local balloon = (def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil)
                    if cd or balloon then
                        b.BackgroundColor3 = Theme.Error
                        b.BackgroundTransparency = 0
                        bStroke.Color = Theme.Error
                        bStroke.Transparency = 0.2
                        if b.Text ~= def.icon then
                            b.Text = def.icon
                            b.TextSize = 18
                            b.TextColor3 = Theme.TextPrimary
                            b.Font = Enum.Font.GothamBold
                        end
                    elseif not cd and not balloon then
                        b.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                        b.BackgroundTransparency = 0
                        bStroke.Color = Theme.Accent1
                        bStroke.Transparency = 0.4
                        if b.Text ~= def.icon then
                            b.Text = def.icon
                            b.TextSize = 18
                            b.TextColor3 = Theme.TextPrimary
                            b.Font = Enum.Font.GothamBold
                        end
                    end
                end
            end)

            b.MouseButton1Click:Connect(function()
                if def.special and def.cmd == "spambaseowner" then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local closestPlot = nil
                    local closestDist = math.huge
                    
                    local plots = Workspace:FindFirstChild("Plots")
                    if plots then
                        for _, plot in ipairs(plots:GetChildren()) do
                            local plotPos = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("Spawn")
                            if plotPos then
                                local dist = (hrp.Position - plotPos.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestPlot = plot
                                end
                            end
                        end
                    end
                    
                    if closestPlot then
                        task.spawn(function()
                            local Packages = ReplicatedStorage:WaitForChild("Packages")
                            local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
                            local channel = Synchronizer:Get(closestPlot.Name)
                            if channel then
                                local owner = channel:Get("Owner")
                                local targetPlayer = nil
                                if typeof(owner) == "Instance" and owner:IsA("Player") then
                                    targetPlayer = owner
                                elseif typeof(owner) == "table" and owner.UserId then
                                    targetPlayer = Players:GetPlayerByUserId(owner.UserId)
                                end
                                
                                if targetPlayer and targetPlayer ~= LocalPlayer then
                                    local hasAnyAvailable = false
                                    for _, cmd in ipairs(ALL_COMMANDS) do
                                        if not isOnCooldown(cmd) then
                                            hasAnyAvailable = true
                                            break
                                        end
                                    end
                                    if hasAnyAvailable then
                                        triggerAll(targetPlayer)
                                        ShowNotification("AP SPAM", "Spamming " .. targetPlayer.Name)
                                    else
                                        ShowNotification("AP SPAM", "All commands on cooldown")
                                    end
                                else
                                    ShowNotification("AP SPAM", "No owner found")
                                end
                            end
                        end)
                    end
                else
                    if not canUseAdminAction(plr) then return end
                    ShowNotification("ADMIN", "Attempting " .. def.cmd .. " on " .. plr.Name)
                    if runAdminCommand(plr, def.cmd) then
                        activeCooldowns[def.cmd] = tick()
                        setGlobalVisualCooldown(def.cmd)
                        if def.cmd == "balloon" then
                            SharedState.BalloonedPlayers[plr.UserId] = true
                            for _, btn in ipairs(SharedState.AdminButtonCache["balloon"] or {}) do
                                if btn and btn.Parent then btn.BackgroundColor3 = Theme.Error end
                            end
                        end
                        ShowNotification("ADMIN", "Sent " .. def.cmd .. " to " .. plr.Name)
                    else
                        ShowNotification("ADMIN", "Failed to send " .. def.cmd .. " to " .. plr.Name)
                    end
                end
            end)
        end

        -- ── BLACKLIST BUTTON ──────────────────────
        local blBtn = Instance.new("TextButton", row)
        blBtn.Name = "BlacklistBtn"
        blBtn.Size = UDim2.new(0, 26, 0, 26)
        blBtn.Position = UDim2.new(0, 12, 0.5, 6)
        blBtn.AutoButtonColor = false
        blBtn.ZIndex = 12
        blBtn.Font = Enum.Font.GothamBold
        blBtn.TextSize = 14
        blBtn.BorderSizePixel = 0
        local function updateBlBtn()
            local bl = isBlacklisted(plr.Name)
            blBtn.Text = bl and "🔓" or "🚫"
            blBtn.BackgroundColor3 = bl and Color3.fromRGB(180,40,40) or Color3.fromRGB(35,37,43)
            blBtn.TextColor3 = Theme.TextPrimary
            row.BackgroundTransparency = bl and 0.55 or 0.2
            rowStroke.Transparency = bl and 0.85 or 0.7
        end
        Instance.new("UICorner", blBtn).CornerRadius = UDim.new(0, 6)
        local blBtnStroke = Instance.new("UIStroke", blBtn)
        blBtnStroke.Thickness = 1; blBtnStroke.Color = Theme.Accent1; blBtnStroke.Transparency = 0.5
        updateBlBtn()
        blBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if isBlacklisted(plr.Name) then
                    removeFromBlacklist(plr.Name)
                    ShowNotification("BLACKLIST", "✅ Removed: " .. plr.Name)
                else
                    addToBlacklist(plr.Name)
                    ShowNotification("BLACKLIST", "🚫 Blocked: " .. plr.Name)
                end
                updateBlBtn()
                if refreshBlacklistUI then refreshBlacklistUI() end
            end)
        end)

        local rowHighlight = Instance.new("Frame", row)
        rowHighlight.Size = UDim2.new(1, 0, 1, 0)
        rowHighlight.BackgroundColor3 = Theme.Accent1
        rowHighlight.BackgroundTransparency = 1
        rowHighlight.BorderSizePixel = 0
        rowHighlight.ZIndex = 1
        Instance.new("UICorner", rowHighlight).CornerRadius = UDim.new(0, 6)
        row.MouseEnter:Connect(function()
            rowHighlight.BackgroundTransparency = 0.7
        end)
        row.MouseLeave:Connect(function()
            rowHighlight.BackgroundTransparency = 1
        end)
        row.MouseButton1Click:Connect(function()
            local hasAnyAvailable = false
            for _, cmd in ipairs(ALL_COMMANDS) do
                if not isOnCooldown(cmd) then
                    hasAnyAvailable = true
                    break
                end
            end
            if hasAnyAvailable then
                triggerAll(plr)
                ShowNotification("ADMIN", "Triggered ALL on " .. plr.Name)
            end
        end)
        return row
    end

    local playerRows = {}
    local playerRowsByUserId = {}
    
    local function addPlayer(plr)
        if plr == LocalPlayer or playerRowsByUserId[plr.UserId] then return end
        if not Players:FindFirstChild(plr.Name) then return end
        if Config.HideKawaifuFromPanel and isKawaifuUser(plr) then return end
        
        if playerRows[plr] then return end
        
        local row = createPlayerRow(plr)
        playerRows[plr] = row
        playerRowsByUserId[plr.UserId] = {player = plr, row = row}
        listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
        sortAdminPanelList()
    end
    
    local function removePlayer(plr)
        local userId = plr and plr.UserId or nil
        local entry = userId and playerRowsByUserId[userId] or nil
        local row = entry and entry.row or playerRows[plr]
        
        if row then
            if row.Parent then
                for cmd, buttons in pairs(SharedState.AdminButtonCache) do
                    for i = #buttons, 1, -1 do
                        if buttons[i] and buttons[i].Parent == row then
                            table.remove(buttons, i)
                        end
                    end
                end
                row:Destroy()
            end
            if plr then
                playerRows[plr] = nil
            end
            if userId then
                playerRowsByUserId[userId] = nil
            end
            if SharedState.BalloonedPlayers and userId then
                SharedState.BalloonedPlayers[userId] = nil
            end
            listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
        end
    end

    refreshBtn.MouseButton1Click:Connect(function()
        for _, row in pairs(playerRows) do
            if row and row.Parent then
                for cmd, buttons in pairs(SharedState.AdminButtonCache) do
                    for i = #buttons, 1, -1 do
                        if buttons[i] and buttons[i].Parent == row then
                            table.remove(buttons, i)
                        end
                    end
                end
                row:Destroy()
            end
        end
        
        playerRows = {}
        playerRowsByUserId = {}
        SharedState.AdminButtonCache = {}
        SharedState.BalloonedPlayers = {}
        
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        task.wait(0.1)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then 
                addPlayer(p) 
            end
        end
        sortAdminPanelList()
        
        ShowNotification("ADMIN PANEL", "Completely refreshed - " .. #Players:GetPlayers() - 1 .. " players found")
    end)

    Players.PlayerAdded:Connect(function(plr)
        task.wait(0.1)
        if plr and plr.Parent then
            addPlayer(plr)
            sortAdminPanelList()
            ShowNotification("ADMIN", "➕ " .. plr.Name .. " entrou")
        end
    end)
    
    Players.PlayerRemoving:Connect(function(plr)
        removePlayer(plr)
    end)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then addPlayer(p) end
    end
    sortAdminPanelList()

    task.spawn(function()
        while listFrame and listFrame.Parent do
            task.wait(0.5)
            pcall(sortAdminPanelList)
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(1)
            local currentPlayerIds = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Parent then
                    currentPlayerIds[p.UserId] = true
                end
            end
            
            for userId, entry in pairs(playerRowsByUserId) do
                if not currentPlayerIds[userId] or not entry.player or not entry.player.Parent or not Players:FindFirstChild(entry.player.Name) then
                    removePlayer(entry.player)
                end
            end
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Parent and not playerRowsByUserId[p.UserId] then
                    addPlayer(p)
                end
            end
        end
    end)
    
    layout.Changed:Connect(function() listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y) end)
end)

-- ── AUTO DESTROY TURRETS WHEN HOLDING BRAINROT ───────────────────────────
task.spawn(function()
    local autoEnabled = false
    while true do
        task.wait(0.3)
        if not Config.AutoTurretOnBrainrot then
            if autoEnabled then
                Config.AutoDestroyTurrets = false
                SaveConfig()
                autoEnabled = false
            end
            continue
        end
        local char = LocalPlayer.Character
        if not char then continue end
        local holdingBrainrot = false
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local n = (tool.Name or ""):lower()
                if n ~= "flying carpet" and n ~= "quantum cloner" and n ~= "bat" and n ~= "glove" then
                    holdingBrainrot = true
                    break
                end
            end
        end
        if holdingBrainrot and not Config.AutoDestroyTurrets then
            Config.AutoDestroyTurrets = true
            SaveConfig()
            autoEnabled = true
            ShowNotification("AUTO TURRET", "🔫 Brainrot detectado — Turret ON")
        elseif not holdingBrainrot and autoEnabled and Config.AutoDestroyTurrets then
            Config.AutoDestroyTurrets = false
            SaveConfig()
            autoEnabled = false
        end
    end
end)


local BASES_LOW = {
    [1] = Vector3.new(-460, -6, 219), [5] = Vector3.new(-355, -6, 217),
    [2] = Vector3.new(-460, -6, 111), [6] = Vector3.new(-355, -6, 113),
    [3] = Vector3.new(-460, -6, 5),   [7] = Vector3.new(-355, -6, 5),
    [4] = Vector3.new(-460, -6, -100),[8] = Vector3.new(-355, -6, -100) 
}

local BASES_HIGH = {
    [1] = Vector3.new(-476.474853515625, 20.732906341552734, 220.94090270996094), [5] = Vector3.new(-342.5367126464844, 20.69801902770996, 221.44737243652344),
    [2] = Vector3.new(-476.5684814453125, 20.70664405822754, 113.77315521240234), [6] = Vector3.new(-342.8604736328125, 20.669641494750977, 113.41409301757812),
    [3] = Vector3.new(-476.8675842285156, 20.74148178100586, 6.178487777709961),  [7] = Vector3.new(-342.42108154296875, 20.687667846679688, 6.249461650848389),
    [4] = Vector3.new(-476.6324768066406, 20.744949340820312, -101.07275390625), [8] = Vector3.new(-342.7937927246094, 20.748071670532227, -99.73458862304688)
}

local CLONE_POSITIONS_FLOOR = {
    Vector3.new(-476, -4, 221), Vector3.new(-476, -4, 114),
    Vector3.new(-476, -4, 7),   Vector3.new(-476, -4, -100),
    Vector3.new(-342, -4, -100),Vector3.new(-342, -4, 6),
    Vector3.new(-342, -4, 114), Vector3.new(-342, -4, 220)
}

local FACE_TARGETS = {
    Vector3.new(-519, -3, 221), Vector3.new(-519, -3, 114),
    Vector3.new(-518, -3, 7),   Vector3.new(-519, -3, -100),
    Vector3.new(-301, -3, -100),Vector3.new(-301, -3, 7),
    Vector3.new(-302, -3, 114), Vector3.new(-300, -3, 220)
}

local TeleportData = {
    bodyController = nil,
}
local bodyController = TeleportData.bodyController
local floatActive = State.floatActive

RunService.Heartbeat:Connect(function()
    if State.floatActive and TeleportData.bodyController and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then TeleportData.bodyController.Position = Vector3.new(hrp.Position.X, TeleportData.bodyController.Position.Y, TeleportData.bodyController.Position.Z) end
    end
end)

local function getClosestBaseIdx(pos)
    local closest, dist = 1, math.huge
    for i, basePos in pairs(BASES_LOW) do
        local d = (Vector2.new(pos.X, pos.Z) - Vector2.new(basePos.X, basePos.Z)).Magnitude
        if d < dist then dist = d; closest = i end
    end
    return closest
end

local isTpMoving = State.isTpMoving

_G._isTargetPlotUnlocked = function(plotName)
    local ok, res = pcall(function()
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return false end
        local targetPlot = plots:FindFirstChild(plotName)
        if not targetPlot then return false end
        local unlockFolder = targetPlot:FindFirstChild("Unlock")
        if not unlockFolder then return true end
        local unlockItems = {}
        for _, item in pairs(unlockFolder:GetChildren()) do
            local pos = nil
            if item:IsA("Model") then pcall(function() pos = item:GetPivot().Position end)
            elseif item:IsA("BasePart") then pos = item.Position end
            if pos then table.insert(unlockItems, {Object = item, Height = pos.Y}) end
        end
        table.sort(unlockItems, function(a, b) return a.Height < b.Height end)
        if #unlockItems == 0 then return true end
        local floor1Door = unlockItems[1].Object
        for _, desc in ipairs(floor1Door:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then return false end
        end
        for _, child in ipairs(floor1Door:GetChildren()) do
            if child:IsA("ProximityPrompt") and child.Enabled then return false end
        end
        return true
    end)
    return ok and res or false
end

local function runAutoSnipe()
    if State.isTpMoving then return end
    
    if State.carpetSpeedEnabled then
        setCarpetSpeed(false)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = "OFF"
            _carpetStatusLabel.TextColor3 = Theme.Error
        end
    end

    local targetPetData = nil
    if Config.AutoTPPriority then
        local bestEntry = nil
        local cache = SharedState.AllAnimalsCache
        if cache and type(cache) == "table" then
            for _, pName in ipairs(PRIORITY_LIST) do
                local searchName = pName:lower()
                for _, a in ipairs(cache) do
                    if a and a.name and a.name:lower() == searchName and a.owner ~= LocalPlayer.Name then
                        bestEntry = a
                        break
                    end
                end
                if bestEntry then break end
            end
            if not bestEntry then
                for _, a in ipairs(cache) do
                    if a and a.owner ~= LocalPlayer.Name then
                        bestEntry = a
                        break
                    end
                end
            end
        end
        if bestEntry then
            targetPetData = bestEntry
        else
            if not SharedState.SelectedPetData then ShowNotification("ERROR","No target selected!"); return end
            targetPetData = SharedState.SelectedPetData.animalData
        end
    else
        if not SharedState.SelectedPetData then ShowNotification("ERROR","No target selected!"); return end
        targetPetData = SharedState.SelectedPetData.animalData
    end
    if not targetPetData then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then return end
    
    State.isTpMoving = true
    isTpMoving = State.isTpMoving
    
    local targetPart = findAdorneeGlobal(targetPetData)
    if not targetPart then 
        State.isTpMoving = false
        isTpMoving = State.isTpMoving
        return 
    end
    
    local exactPos = targetPart.Position
    local carpetName = Config.TpSettings.Tool
    local carpet = LocalPlayer.Backpack:FindFirstChild(carpetName) or char:FindFirstChild(carpetName)
    local cloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner") or char:FindFirstChild("Quantum Cloner")

    if carpet then hum:EquipTool(carpet) end
    task.wait(0.01)
    local isSecondFloor = exactPos.Y > 10
    local plotIndex = getClosestBaseIdx(exactPos)
    local targetBasePos = isSecondFloor and BASES_HIGH[plotIndex] or BASES_LOW[plotIndex]
    
    local minHeight = 50
    local targetHeight = math.max(targetBasePos.Y, minHeight)

    local jumpStart = tick()
    while hrp.Position.Y < targetHeight and (tick() - jumpStart) < 3 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 200, hrp.AssemblyLinearVelocity.Z)
        RunService.Heartbeat:Wait()
    end

    for i = 1, 6 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        if (hrp.Position - targetBasePos).Magnitude > 3 then
            hrp.CFrame = CFrame.new(targetBasePos)
            task.wait(0.05)
        end
    end

    if not isSecondFloor then
        local bestSpot = CLONE_POSITIONS_FLOOR[1]
        local minDst = math.huge
        for _, v in ipairs(CLONE_POSITIONS_FLOOR) do
            local d = (targetPart.Position - v).Magnitude
            if d < minDst then minDst = d; bestSpot = v end
        end
        for i = 1, 6 do
            if (hrp.Position - bestSpot).Magnitude > 3 then
                hrp.CFrame = CFrame.new(bestSpot)
                task.wait(0.05)
            end
        end
    end

    local bestFace = FACE_TARGETS[1]
    local minFaceDist = math.huge
    for _, v in ipairs(FACE_TARGETS) do
        local d = (hrp.Position - v).Magnitude
        if d < minFaceDist then
            minFaceDist = d
            bestFace = v
        end
    end

    task.wait(0.08)
    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(bestFace.X, hrp.Position.Y, bestFace.Z))
    if isSecondFloor or not _G._isTargetPlotUnlocked(targetPetData.plot) then
        walkForward(0.3)
        task.wait(0.3)
        instantClone()
        while _G.isCloning do task.wait() end
    end
    task.wait(0.1)

    if carpet then hum:EquipTool(carpet) end

    local verticalDiff = targetPart.Position.Y - hrp.Position.Y

    if verticalDiff > 2 then
        local CHAR_ABOVE_PLAT = 5.5  -- HRP center height above platform top surface
        local offset = Config.PlatformOffset or 12.5

        local function calcPositions()
            local o = Config.PlatformOffset or 12.5
            local pY = targetPart.Position.Y - o
            local cY = pY + 0.5 + CHAR_ABOVE_PLAT - 2
            return pY, cY
        end

        local platY, charY = calcPositions()
        local platPos = Vector3.new(targetPart.Position.X, platY, targetPart.Position.Z)
        local charPos = Vector3.new(targetPart.Position.X, charY, targetPart.Position.Z)

        local plat = Instance.new("Part")
        plat.Name = "HeroTempPlatform"
        plat.Size = Vector3.new(4, 1, 4)
        plat.Position = platPos
        plat.Color = Color3.new(1, 0, 0)
        plat.Material = Enum.Material.Neon
        plat.Anchored = true
        plat.CanCollide = true
        plat.Transparency = 0.3
        plat.Parent = Workspace

        RunService.Heartbeat:Wait()

        -- Teleport character exactly on top of platform
        for i = 1, 10 do
            if not LocalPlayer:GetAttribute("Stealing") then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = CFrame.new(charPos)
                task.wait(0.05)
            end
        end

        -- Keep platform following target, player stands on it freely
        local pinConn
        pinConn = RunService.Heartbeat:Connect(function()
            if LocalPlayer:GetAttribute("Stealing") then
                pinConn:Disconnect()
                _G._activePinConn = nil
                return
            end
            local newPlatY = targetPart.Position.Y - (Config.PlatformOffset or 12.5)
            plat.Position = Vector3.new(targetPart.Position.X, newPlatY, targetPart.Position.Z)
        end)
        _G._activePinConn = pinConn
        _G._activePlat = plat

        task.spawn(function()
            local start = tick()
            local platTime = Config.PlatformTime or 10
            while tick() - start < platTime do
                if LocalPlayer:GetAttribute("Stealing") then break end
                task.wait(0.1)
            end
            if pinConn then pinConn:Disconnect() end
            _G._activePinConn = nil
            _G._activePlat = nil
            if plat and plat.Parent then plat:Destroy() end
        end)
    else
        for i = 1, 10 do
            if LocalPlayer:GetAttribute("Stealing") then break end
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
            if (hrp.Position - targetPart.Position).Magnitude > 3 then
                hrp.CFrame = CFrame.new(targetPart.Position)
                task.wait(0.05)
            end
            task.wait(0.05)
        end
    end
    
    State.isTpMoving = false
    isTpMoving = State.isTpMoving
end

local function executeReset()
    ShowNotification("RESET", "Reiniciando personagem...")
    local plr = LocalPlayer
    if not plr then return end

    task.spawn(function()
        pcall(function()
            local char = plr.Character
            if not char then return end

            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end

            char:ClearAllChildren()

            local dummy = Instance.new("Model")
            dummy.Parent = Workspace
            plr.Character = dummy
            plr.Character = char
            dummy:Destroy()
        end)
    end)
end

task.spawn(function()
    local balloonPhrase = 'ran "balloon" on you'
    while true do
        task.wait(1)
        if not Config.AutoResetOnBalloon then continue end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
            if txt and string.find(txt, balloonPhrase) then
                executeReset()
                break
            end
        end
    end
end)

do
    local _akKicked = false
    RunService.Heartbeat:Connect(function()
        if not Config.AutoKickOnSteal then
            _akKicked = false
            return
        end
        if _akKicked then return end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if (gui:IsA("TextLabel") or gui:IsA("TextButton")) then
                local txt = gui.Text
                if txt and string.find(txt, "You stole") then
                    _akKicked = true
                    kickPlayer()
                    return
                end
            end
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    local tpKey = Enum.KeyCode[Config.TpSettings.TpKey] or Enum.KeyCode.T
    local cloneKey = Enum.KeyCode[Config.TpSettings.CloneKey] or Enum.KeyCode.V

    if input.KeyCode == tpKey then
        if _G._activePinConn then _G._activePinConn:Disconnect(); _G._activePinConn = nil end
        if _G._activePlat and _G._activePlat.Parent then _G._activePlat:Destroy(); _G._activePlat = nil end
        if _G.tpToBestBrainrot then pcall(_G.tpToBestBrainrot) else pcall(runAutoSnipe) end
    end

    if input.KeyCode == cloneKey then
        if _G._activePinConn then _G._activePinConn:Disconnect(); _G._activePinConn = nil end
        if _G._activePlat and _G._activePlat.Parent then _G._activePlat:Destroy(); _G._activePlat = nil end
        instantClone()
    end
    
    if input.KeyCode == (Enum.KeyCode[Config.TpSettings.CarpetSpeedKey] or Enum.KeyCode.Q) then
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = carpetSpeedEnabled and "ON" or "OFF"
            _carpetStatusLabel.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.Error
        end
        ShowNotification("CARPET SPEED", carpetSpeedEnabled and ("ON  |  "..Config.TpSettings.Tool.."  |  140") or "OFF")
    end

    if input.KeyCode == (Enum.KeyCode[Config.StealSpeedKey] or Enum.KeyCode.Z) then
        if SharedState.StealSpeedToggleFunc then
            SharedState.StealSpeedToggleFunc()
        end
    end

    if input.KeyCode == (Enum.KeyCode[Config.ResetKey] or Enum.KeyCode.X) then
        executeReset()
    end
    
    if input.KeyCode == (Enum.KeyCode[Config.RagdollSelfKey] or Enum.KeyCode.R) then
        task.spawn(function()
            if _G.runAdminCommand then
                if _G.runAdminCommand(LocalPlayer, "ragdoll") then
                    ShowNotification("RAGDOLL SELF", "Triggered")
                else
                    ShowNotification("RAGDOLL SELF", "Failed")
                end
            else
                ShowNotification("RAGDOLL SELF", "Function not available")
            end
        end)
    end

end)

local settingsGui = UI.settingsGui

if IS_MOBILE then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "HeroMobileControls"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = PlayerGui

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 50, 0, 260)
    controlsFrame.Position = UDim2.new(1, -60, 0.5, -130)
    controlsFrame.BackgroundColor3 = Theme.Background
    controlsFrame.BackgroundTransparency = 0.2
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = mobileGui

    ApplyViewportUIScale(controlsFrame, 50, 260, 0.6, 1)

    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 10)
    local cStroke = Instance.new("UIStroke", controlsFrame)
    cStroke.Color = Theme.Accent1
    cStroke.Thickness = 1.5
    cStroke.Transparency = 0.4

    MakeDraggable(controlsFrame, controlsFrame, "MobileControls")

    local layout = Instance.new("UIListLayout", controlsFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function createMobBtn(text, color, layoutOrder, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.BackgroundColor3 = Theme.SurfaceHighlight
        btn.Text = text
        btn.TextColor3 = Theme.TextPrimary
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 14
        btn.LayoutOrder = layoutOrder
        btn.Parent = mobileGui 
        
        local posKey = "MobileBtn_" .. text
        if Config.Positions[posKey] then
            btn.Position = UDim2.new(Config.Positions[posKey].X, 0, Config.Positions[posKey].Y, 0)
        else
            local angle = (layoutOrder - 1) * (math.pi * 2 / 5) - math.pi/2
            local radius = 60
            btn.Position = UDim2.new(0.5, math.cos(angle) * radius - 20, 0.5, math.sin(angle) * radius - 20)
        end

        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Transparency = 1

        MakeDraggable(btn, btn, "MobileBtn_" .. text)

        btn.MouseButton1Click:Connect(function()
            local oldColor = btn.BackgroundColor3
            btn.BackgroundColor3 = color
            task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
            callback(btn)
        end)
        return btn
    end

    createMobBtn("TP", Theme.Accent1, 1, function()
        
        if SharedState.ForcePrioritySelection then
            SharedState.ForcePrioritySelection()
            task.wait(0.1) 
        end
        runAutoSnipe()
        ShowNotification("MOBILE", "Teleporting...")
    end)

    createMobBtn("CL", Theme.Accent2, 2, function()
        instantClone()
        ShowNotification("MOBILE", "Cloning...")
    end)

    createMobBtn("SP", Theme.Success, 3, function(self)
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        self.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.TextPrimary
        ShowNotification("MOBILE", carpetSpeedEnabled and "Speed ON" or "Speed OFF")
    end)

    createMobBtn("Des", Theme.Accent1, 4, function(self)
        ShowNotification("MOBILE", "Initializing Desync...")
        self.TextColor3 = Theme.Accent1
        task.spawn(function()
            if _G.runDesync then _G.runDesync() end
            task.wait(5.1)
            self.TextColor3 = Theme.TextPrimary
        end)
    end)

    createMobBtn("UI", Color3.fromRGB(255, 255, 255), 5, function()
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = not asUI.Enabled end

        local adUI = PlayerGui:FindFirstChild("HeroAdminPanel")
        if adUI then adUI.Enabled = not adUI.Enabled end
    end)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Name = "MobileResetButton"
    resetBtn.Size = UDim2.new(0, 42, 0, 42)
    resetBtn.Position = UDim2.new(1, -58, 1, -105)
    resetBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    resetBtn.AutoButtonColor = false
    resetBtn.Text = "🔧"
    resetBtn.Font = Enum.Font.GothamBlack
    resetBtn.TextSize = 20
    resetBtn.TextColor3 = Color3.new(0, 0, 0)
    resetBtn.Parent = mobileGui
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(1, 0)
    local resetStroke = Instance.new("UIStroke", resetBtn)
    resetStroke.Color = Color3.fromRGB(255, 100, 0)
    resetStroke.Thickness = 1.5
    resetStroke.Transparency = 0.25

    MakeDraggable(resetBtn, resetBtn)

    resetBtn.MouseButton1Click:Connect(function()
        Config.Positions = {
            AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
            StealSpeed = {X = 0.02, Y = 0.18}, 
            Settings = {X = 0.834375, Y = 0.43590998043052839}, 
            InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
            AutoSteal = {X = 0.02, Y = 0.35}, 
            MobileControls = {X = 0.9, Y = 0.4},
            MobileBtn_TP = {X = 0.5, Y = 0.4},
            MobileBtn_CL = {X = 0.5, Y = 0.4},
            MobileBtn_SP = {X = 0.5, Y = 0.4},
            MobileBtn_IV = {X = 0.5, Y = 0.4},
            MobileBtn_UI = {X = 0.5, Y = 0.4},
        }
        Config.MobileGuiScale = 0.5
        SaveConfig()
        
        if SharedState.RefreshMobileScale then SharedState.RefreshMobileScale() end
        
        if mobileGui then
            mobileGui.Position = UDim2.new(Config.Positions.MobileControls.X, 0, Config.Positions.MobileControls.Y, 0)
        end
        
        ShowNotification("RESET", "All GUI positions and scale reset")
    end)

    local openBtn = Instance.new("TextButton")
    openBtn.Name = "MobileSettingsButton"
    openBtn.Size = UDim2.new(0, 42, 0, 42)
    openBtn.Position = UDim2.new(1, -58, 1, -58)
    openBtn.BackgroundColor3 = Theme.Accent1
    openBtn.AutoButtonColor = false
    openBtn.Text = "⚙"
    openBtn.Font = Enum.Font.GothamBlack
    openBtn.TextSize = 20
    openBtn.TextColor3 = Color3.new(0, 0, 0)
    openBtn.Parent = mobileGui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
    local openStroke = Instance.new("UIStroke", openBtn)
    openStroke.Color = Theme.Accent2
    openStroke.Thickness = 1.5
    openStroke.Transparency = 0.25

    MakeDraggable(openBtn, openBtn)

    openBtn.MouseButton1Click:Connect(function()
        if settingsGui then
            settingsGui.Enabled = not settingsGui.Enabled
        end
        if SharedState.RefreshMobileScale then
            SharedState.RefreshMobileScale()
        end
    end)
end

settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "SettingsUI"; settingsGui.ResetOnSpawn = false
settingsGui.Parent = PlayerGui; settingsGui.Enabled = false

local sFrame = Instance.new("Frame")
sFrame.Size = UDim2.new(0, 300, 0, 650)
sFrame.Position = UDim2.new(Config.Positions.Settings.X, 0, Config.Positions.Settings.Y, 0)
sFrame.BackgroundColor3 = Theme.Background; sFrame.BackgroundTransparency = 0.05
sFrame.BorderSizePixel = 0; sFrame.ClipsDescendants = true; sFrame.Parent = settingsGui

ApplyViewportUIScale(sFrame, 300, 650, 0.45, 0.85)
AddMobileMinimize(sFrame, "SETTINGS")

Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 12)
local sStroke = Instance.new("UIStroke", sFrame)
sStroke.Color = Theme.Accent2; sStroke.Thickness = 1.5; sStroke.Transparency = 0.4
CreateGradient(sStroke)
task.defer(function() if addRacetrackBorder then addRacetrackBorder(sFrame, Theme.Accent1, 4) end end)

local sHeader = Instance.new("Frame", sFrame)
sHeader.Size = UDim2.new(1,0,0,40); sHeader.BackgroundTransparency = 1
MakeDraggable(sHeader, sFrame, "Settings") 
local sTitle = Instance.new("TextLabel", sHeader)
sTitle.Size = UDim2.new(1,-20,1,0); sTitle.Position = UDim2.new(0,15,0,0)
sTitle.BackgroundTransparency = 1; sTitle.Text = "SETTINGS"
sTitle.Font = Enum.Font.GothamBlack; sTitle.TextSize = 16
sTitle.TextColor3 = Theme.TextPrimary; sTitle.TextXAlignment = Enum.TextXAlignment.Left

local sList = Instance.new("ScrollingFrame", sFrame)
sList.Size = UDim2.new(1,-20,1,-50); sList.Position = UDim2.new(0,10,0,45)
sList.BackgroundTransparency = 1; sList.BorderSizePixel = 0
sList.ScrollBarThickness = 2; sList.ScrollBarImageColor3 = Theme.Accent1

local sLayout = Instance.new("UIListLayout", sList)
sLayout.Padding = UDim.new(0,8); sLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateToggleSwitch(parent, initialState, callback)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0,40,0,20); sw.Position = UDim2.new(1,-50,0.5,-10)
    sw.BackgroundColor3 = initialState and Theme.Success or Theme.SurfaceHighlight
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0); sw.Parent = parent
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,16,0,16)
    dot.Position = initialState and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0); dot.Parent = sw
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = sw
    local isOn = initialState
    local function SetState(s)
        isOn = s
        local tp = isOn and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        local tc = isOn and Theme.Success or Theme.SurfaceHighlight
        TweenService:Create(dot, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Position=tp}):Play()
        TweenService:Create(sw,  TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {BackgroundColor3=tc}):Play()
    end
    btn.MouseButton1Click:Connect(function() callback(not isOn, SetState) end)
    return {Set=SetState, Container=sw}
end

local function CreateRow(text, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,height or 34); row.BackgroundColor3 = Theme.Surface
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = sList; return row
end

local function CreateSectionHeader(text)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = sList
    
    local accent = Instance.new("Frame", row)
    accent.Size = UDim2.new(0, 3, 0, 16)
    accent.Position = UDim2.new(0, 4, 0.5, -8)
    accent.BackgroundColor3 = Theme.Accent1
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Accent1
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1, -80, 0, 1)
    line.Position = UDim2.new(0, 75, 0.5, 0)
    line.BackgroundColor3 = Theme.Accent1
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    
    return row
end

CreateRow("Auto TP on Script Load")
CreateToggleSwitch(sList:FindFirstChildOfClass("Frame"), Config.TpSettings.TpOnLoad, function(ns, set)
    set(ns); Config.TpSettings.TpOnLoad = ns; SaveConfig()
    ShowNotification("AUTO TP ON LOAD", ns and "ENABLED" or "DISABLED")
end)

local rMinGen = CreateRow("Min Gen for Auto TP")
local minGenBox = Instance.new("TextBox", rMinGen)
minGenBox.Size = UDim2.new(0, 100, 0, 24)
minGenBox.Position = UDim2.new(1, -110, 0.5, -12)
minGenBox.BackgroundColor3 = Theme.SurfaceHighlight
minGenBox.Text = tostring(Config.TpSettings.MinGenForTp or "")
minGenBox.Font = Enum.Font.Gotham
minGenBox.TextSize = 11
minGenBox.TextColor3 = Theme.TextPrimary
minGenBox.PlaceholderText = "e.g. 5k, 1m, 1b"
Instance.new("UICorner", minGenBox).CornerRadius = UDim.new(0, 4)
minGenBox.FocusLost:Connect(function()
    local raw = minGenBox.Text:gsub("%s", "")
    Config.TpSettings.MinGenForTp = (raw == "" and "" or raw)
    SaveConfig()
    ShowNotification("MIN GEN FOR TP", Config.TpSettings.MinGenForTp == "" and "No minimum" or "Min: " .. (Config.TpSettings.MinGenForTp or ""))
end)

local rFPS = CreateRow("FPS Boost")
CreateToggleSwitch(rFPS, Config.FPSBoost, function(ns, set)
    set(ns); setFPSBoost(ns)
    ShowNotification("FPS BOOST", ns and "ENABLED" or "DISABLED")
end)

local rTrace = CreateRow("Tracer Best Brainrot")
CreateToggleSwitch(rTrace, Config.TracerEnabled, function(ns, set)
    set(ns); Config.TracerEnabled = ns; SaveConfig()
    ShowNotification("TRACER", ns and "ENABLED" or "DISABLED")
end)

local rLineToBase = CreateRow("Line to base")
CreateToggleSwitch(rLineToBase, Config.LineToBase, function(ns, set)
    set(ns); Config.LineToBase = ns; SaveConfig()
    if not ns and _G.resetPlotBeam then pcall(_G.resetPlotBeam) end
    ShowNotification("LINE TO BASE", ns and "ENABLED" or "DISABLED")
end)

local rXray = CreateRow("X-Ray")
CreateToggleSwitch(rXray, Config.XrayEnabled, function(ns, set)
    set(ns); Config.XrayEnabled = ns; if ns then enableXray() else disableXray() end; SaveConfig()
    ShowNotification("X-RAY", ns and "ENABLED" or "DISABLED")
end)

CreateSectionHeader("Auto TP")
local toolOptions = {"Flying Carpet", "Cupid's Wings", "Santa's Sleigh", "Witch's Broom"}
local toolSwitches = {}
for _, toolName in ipairs(toolOptions) do
    local r = CreateRow(toolName)
    local ts = CreateToggleSwitch(r, Config.TpSettings.Tool==toolName, function(rs, set)
        if rs then
            Config.TpSettings.Tool=toolName; SaveConfig(); set(true)
            for n, sw in pairs(toolSwitches) do if n~=toolName then sw.Set(false) end end
            ShowNotification("TP TOOL", toolName)
        else
            set(Config.TpSettings.Tool==toolName)
        end
    end)
    toolSwitches[toolName] = ts
end

local rSpeed = CreateRow("Teleport Delay (1=Fast)")
local speedCont = Instance.new("Frame", rSpeed)
speedCont.Size = UDim2.new(0,100,0,24); speedCont.Position = UDim2.new(1,-110,0.5,-12); speedCont.BackgroundTransparency=1
local speedBtns = {}
for i = 1, 4 do
    local b = Instance.new("TextButton", speedCont)
    b.Size = UDim2.new(0.22,0,1,0); b.Position = UDim2.new((i-1)*0.26,0,0,0)
    local act = Config.TpSettings.Speed==i
    b.BackgroundColor3 = act and Theme.Accent1 or Theme.SurfaceHighlight
    b.Text = tostring(i); b.TextColor3 = act and Color3.new(0,0,0) or Theme.TextPrimary
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,4)
    b.MouseButton1Click:Connect(function()
        Config.TpSettings.Speed=i; SaveConfig()
        for idx, btn in ipairs(speedBtns) do
            local a=(idx==i); btn.BackgroundColor3=a and Theme.Accent1 or Theme.SurfaceHighlight
            btn.TextColor3=a and Color3.new(0,0,0) or Theme.TextPrimary
        end
        ShowNotification("TP SPEED", "Set to " .. tostring(i))
    end)
    table.insert(speedBtns,b)
end

local rBind = CreateRow("TP Keybind")
local bBind = Instance.new("TextButton", rBind)
bBind.Size=UDim2.new(0,60,0,24); bBind.Position=UDim2.new(1,-70,0.5,-12)
bBind.BackgroundColor3=Theme.SurfaceHighlight; bBind.Text=Config.TpSettings.TpKey
bBind.Font=Enum.Font.GothamBold; bBind.TextColor3=Theme.TextPrimary; bBind.TextSize=12
Instance.new("UICorner",bBind).CornerRadius=UDim.new(0,4)
bBind.MouseButton1Click:Connect(function()
    bBind.Text="..."; bBind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.TpKey=inp.KeyCode.Name; bBind.Text=inp.KeyCode.Name
            bBind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("TP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rBindClone = CreateRow("Auto Clone Keybind")
local bBindClone = Instance.new("TextButton", rBindClone)
bBindClone.Size=UDim2.new(0,60,0,24); bBindClone.Position=UDim2.new(1,-70,0.5,-12)
bBindClone.BackgroundColor3=Theme.SurfaceHighlight; bBindClone.Text=Config.TpSettings.CloneKey
bBindClone.Font=Enum.Font.GothamBold; bBindClone.TextColor3=Theme.TextPrimary; bBindClone.TextSize=12
Instance.new("UICorner",bBindClone).CornerRadius=UDim.new(0,4)
bBindClone.MouseButton1Click:Connect(function()
    bBindClone.Text="..."; bBindClone.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CloneKey=inp.KeyCode.Name; bBindClone.Text=inp.KeyCode.Name
            bBindClone.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CLONE KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

CreateSectionHeader("CARPET SPEED")
local rCarpetBind = CreateRow("Carpet Speed Keybind")
local bCarpet = Instance.new("TextButton", rCarpetBind)
bCarpet.Size=UDim2.new(0,60,0,24); bCarpet.Position=UDim2.new(1,-70,0.5,-12)
bCarpet.BackgroundColor3=Theme.SurfaceHighlight; bCarpet.Text=Config.TpSettings.CarpetSpeedKey
bCarpet.Font=Enum.Font.GothamBold; bCarpet.TextColor3=Theme.TextPrimary; bCarpet.TextSize=12
Instance.new("UICorner",bCarpet).CornerRadius=UDim.new(0,4)
bCarpet.MouseButton1Click:Connect(function()
    bCarpet.Text="..."; bCarpet.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CarpetSpeedKey=inp.KeyCode.Name; bCarpet.Text=inp.KeyCode.Name
            bCarpet.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CARPET SPEED KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rRagdollSelf = CreateRow("Ragdoll Self Keybind")
local bRagdollSelf = Instance.new("TextButton", rRagdollSelf)
bRagdollSelf.Size=UDim2.new(0,60,0,24); bRagdollSelf.Position=UDim2.new(1,-70,0.5,-12)
bRagdollSelf.BackgroundColor3=Theme.SurfaceHighlight; bRagdollSelf.Text=Config.RagdollSelfKey ~= "" and Config.RagdollSelfKey or "NONE"
bRagdollSelf.Font=Enum.Font.GothamBold; bRagdollSelf.TextColor3=Theme.TextPrimary; bRagdollSelf.TextSize=12
Instance.new("UICorner",bRagdollSelf).CornerRadius=UDim.new(0,4)
bRagdollSelf.MouseButton1Click:Connect(function()
    bRagdollSelf.Text="..."; bRagdollSelf.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.RagdollSelfKey=inp.KeyCode.Name; bRagdollSelf.Text=inp.KeyCode.Name
            bRagdollSelf.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("RAGDOLL SELF KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rCarpetStatus = CreateRow("Carpet Speed Status")
local carpetStatusLbl = Instance.new("TextLabel", rCarpetStatus)
carpetStatusLbl.Size=UDim2.new(0,50,0,20); carpetStatusLbl.Position=UDim2.new(1,-60,0.5,-10)
carpetStatusLbl.BackgroundTransparency=1
carpetStatusLbl.Text=carpetSpeedEnabled and "ON" or "OFF"
carpetStatusLbl.TextColor3=carpetSpeedEnabled and Theme.Success or Theme.Error
carpetStatusLbl.Font=Enum.Font.GothamBlack; carpetStatusLbl.TextSize=13
carpetStatusLbl.TextXAlignment=Enum.TextXAlignment.Right
_carpetStatusLabel = carpetStatusLbl

CreateSectionHeader("MOVEMENT")
local rInfJump = CreateRow("Infinite Jump")
CreateToggleSwitch(rInfJump, infiniteJumpEnabled, function(ns, set)
    set(ns); setInfiniteJump(ns)
    ShowNotification("INFINITE JUMP", ns and "ENABLED" or "DISABLED")
end)
local rShowSS = CreateRow("Show Steal Speed Panel")
CreateToggleSwitch(rShowSS, Config.ShowStealSpeedPanel, function(ns, set)
    set(ns); Config.ShowStealSpeedPanel = ns; SaveConfig()
    local ssGui = PlayerGui:FindFirstChild("StealSpeedUI")
    if ssGui then ssGui.Enabled = ns end
    ShowNotification("STEAL SPEED PANEL", ns and "SHOWN" or "HIDDEN")
end)
local rAutoStealSpeed = CreateRow("Auto Steal Speed")
CreateToggleSwitch(rAutoStealSpeed, Config.AutoStealSpeed, function(ns, set)
    set(ns); Config.AutoStealSpeed = ns; SaveConfig()
    ShowNotification("AUTO STEAL SPEED", ns and "ENABLED" or "DISABLED")
end)

local rStealSpeedKey = CreateRow("Steal Speed Keybind")
local bStealSpeedKey = Instance.new("TextButton", rStealSpeedKey)
bStealSpeedKey.Size=UDim2.new(0,60,0,24); bStealSpeedKey.Position=UDim2.new(1,-70,0.5,-12)
bStealSpeedKey.BackgroundColor3=Theme.SurfaceHighlight; bStealSpeedKey.Text=Config.StealSpeedKey
bStealSpeedKey.Font=Enum.Font.GothamBold; bStealSpeedKey.TextColor3=Theme.TextPrimary; bStealSpeedKey.TextSize=12
Instance.new("UICorner",bStealSpeedKey).CornerRadius=UDim.new(0,4)
bStealSpeedKey.MouseButton1Click:Connect(function()
    bStealSpeedKey.Text="..."; bStealSpeedKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.StealSpeedKey=inp.KeyCode.Name; bStealSpeedKey.Text=inp.KeyCode.Name
            bStealSpeedKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("STEAL SPEED KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

CreateSectionHeader("AUTO UNLOCK")
local rAutoUnlock = CreateRow("Auto Unlock on Steal")
CreateToggleSwitch(rAutoUnlock, Config.AutoUnlockOnSteal, function(ns, set)
    set(ns); Config.AutoUnlockOnSteal = ns; SaveConfig()
    ShowNotification("AUTO UNLOCK", ns and "ENABLED" or "DISABLED")
end)

local rShowUnlockHUD = CreateRow("Show Unlock Buttons HUD")
CreateToggleSwitch(rShowUnlockHUD, Config.ShowUnlockButtonsHUD, function(ns, set)
    set(ns); Config.ShowUnlockButtonsHUD = ns; SaveConfig()
    local hudGui = PlayerGui:FindFirstChild("HeroStatusHUD")
    if hudGui then
        local main = hudGui:FindFirstChild("Main")
        local unlockContainer = main and main:FindFirstChild("UnlockButtonsContainer")
        if main and unlockContainer then
            unlockContainer.Visible = ns
            if ns then
                TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 500, 0, 100)
                }):Play()
            else
                TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 500, 0, 50)
                }):Play()
            end
        end
    end
end)
CreateSectionHeader("ANTI-RAGDOLL")
local arV1SetRef, arV2SetRef = {}, {}
local rAr = CreateRow("V1")
CreateToggleSwitch(rAr, Config.AntiRagdoll > 0, function(ns, set)
    arV1SetRef.fn = set
    if ns and Config.AntiRagdollV2 then
        set(false)
        ShowNotification("ANTI-RAGDOLL", "DISABLE V2 FIRST")
        return
    end
    set(ns)
    local mode = ns and 1 or 0
    Config.AntiRagdoll = mode
    if ns then
        Config.AntiRagdollV2 = false
        if arV2SetRef.fn then arV2SetRef.fn(false) end
    end
    SaveConfig()
    startAntiRagdoll(mode)
    if ns then startAntiRagdollV2(false) end
    ShowNotification("ANTI-RAGDOLL V1", ns and "ENABLED" or "DISABLED")
end)
local rArV2 = CreateRow("V2")
CreateToggleSwitch(rArV2, Config.AntiRagdollV2, function(ns, set)
    arV2SetRef.fn = set
    if ns and Config.AntiRagdoll > 0 then
        set(false)
        ShowNotification("ANTI-RAGDOLL", "DISABLE V1 FIRST")
        return
    end
    set(ns)
    Config.AntiRagdollV2 = ns
    if ns then
        Config.AntiRagdoll = 0
        SaveConfig()
        if arV1SetRef.fn then arV1SetRef.fn(false) end
        startAntiRagdoll(0)
        startAntiRagdollV2(true)
    else
        SaveConfig()
        startAntiRagdollV2(false)
    end
    ShowNotification("ANTI-RAGDOLL V2", ns and "ENABLED" or "DISABLED")
end)













CreateSectionHeader("ESP")

local rXray = CreateRow("Base X-Ray")
local xrayToggle = CreateToggleSwitch(rXray, xrayEnabled, function(ns, set)
    set(ns)
    if ns then
        enableXray()
        xrayDescConn = Workspace.DescendantAdded:Connect(function(obj)
            if xrayEnabled and obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end)
    else
        disableXray()
    end
    Config.XrayEnabled = ns; SaveConfig()
    ShowNotification("BASE X-RAY", ns and "ENABLED" or "DISABLED")
end)
local playerESPToggleRef = {setFn=nil}
local rPlayerEsp = CreateRow("Player ESP (Hides Names)")
CreateToggleSwitch(rPlayerEsp, Config.PlayerESP, function(ns, set)
    set(ns); Config.PlayerESP = ns; SaveConfig()
    if playerESPToggleRef.setFn then playerESPToggleRef.setFn(ns) end
    ShowNotification("PLAYER ESP", ns and "ENABLED" or "DISABLED")
end)

local espToggleRef = {enabled=true, setFn=nil}
local rEsp = CreateRow("Brainrot ESP")
local espSettingsSwitch = CreateToggleSwitch(rEsp, Config.BrainrotESP, function(ns, set)
    set(ns); Config.BrainrotESP = ns; SaveConfig()
    if espToggleRef.setFn then espToggleRef.setFn(ns) end
    ShowNotification("BRAINROT ESP", ns and "ENABLED" or "DISABLED")
end)
local subspaceMineESPToggleRef = {setFn=nil}
local rSubspaceMineEsp = CreateRow("Subspace Mine Esp")
CreateToggleSwitch(rSubspaceMineEsp, Config.SubspaceMineESP, function(ns, set)
    set(ns); Config.SubspaceMineESP = ns; SaveConfig()
    if subspaceMineESPToggleRef.setFn then subspaceMineESPToggleRef.setFn(ns) end
    ShowNotification("SUBSPACE MINE ESP", ns and "ENABLED" or "DISABLED")
end)
local rDuelBaseESP = CreateRow("Duel Base ESP")
CreateToggleSwitch(rDuelBaseESP, Config.DuelBaseESP, function(ns, set)
    set(ns); Config.DuelBaseESP = ns; SaveConfig()
    ShowNotification("DUEL BASE ESP", ns and "ENABLED" or "DISABLED")
end)

CreateSectionHeader("AUTO STEAL DEFAULTS")
local nearestToggleRef = {}
local highestToggleRef = {}
local priorityToggleRef = {}
local autoTPPriorityToggleRef = {setFn = nil}

local rDefaultNearest = CreateRow("Default To Nearest")
local nearestToggleSwitch = CreateToggleSwitch(rDefaultNearest, Config.DefaultToNearest, function(ns, set)
    if ns then
        Config.DefaultToNearest = true
        Config.DefaultToHighest = false
        Config.DefaultToPriority = false
        set(true)
        if highestToggleRef.setFn then highestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
        
        Config.AutoTPPriority = true
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(true)
        end
    else
        local otherDefaults = Config.DefaultToHighest or Config.DefaultToPriority
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToNearest = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO NEAREST", ns and "ENABLED" or "DISABLED")
end)
nearestToggleRef.setFn = nearestToggleSwitch.Set

local rDefaultHighest = CreateRow("Default To Highest")
local highestToggleSwitch = CreateToggleSwitch(rDefaultHighest, Config.DefaultToHighest, function(ns, set)
    if ns then
        Config.DefaultToNearest = false
        Config.DefaultToHighest = true
        Config.DefaultToPriority = false
        set(true)
        if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
        
        Config.AutoTPPriority = false
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(false)
        end
    else
        local otherDefaults = Config.DefaultToNearest or Config.DefaultToPriority
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToHighest = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO HIGHEST", ns and "ENABLED" or "DISABLED")
end)
highestToggleRef.setFn = highestToggleSwitch.Set

local rDefaultPriority = CreateRow("Default To Priority")
local priorityToggleSwitch = CreateToggleSwitch(rDefaultPriority, Config.DefaultToPriority, function(ns, set)
    if ns then
        Config.DefaultToNearest = false
        Config.DefaultToHighest = false
        Config.DefaultToPriority = true
        set(true)
        if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if highestToggleRef.setFn then highestToggleRef.setFn(false) end
        
        Config.AutoTPPriority = true
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(true)
        end
    else
        local otherDefaults = Config.DefaultToNearest or Config.DefaultToHighest
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToPriority = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO PRIORITY", ns and "ENABLED" or "DISABLED")
end)
priorityToggleRef.setFn = priorityToggleSwitch.Set

CreateSectionHeader("AUTOMATION")
local rAutoInvis = CreateRow("Auto Invis During Steal")
CreateToggleSwitch(rAutoInvis, Config.AutoInvisDuringSteal, function(ns, set)
    set(ns); Config.AutoInvisDuringSteal = ns; _G.AutoInvisDuringSteal = ns; SaveConfig()
    ShowNotification("AUTO INVIS", ns and "ENABLED" or "DISABLED")
end)
local rAutoTpFail = CreateRow("Auto TP on Failed Steal")
CreateToggleSwitch(rAutoTpFail, Config.AutoTpOnFailedSteal, function(ns, set)
    set(ns); Config.AutoTpOnFailedSteal = ns; SaveConfig()
    ShowNotification("AUTO TP ON FAILED STEAL", ns and "ENABLED" or "DISABLED")
end)
local rAutoTpPriority = CreateRow("Auto TP Priority Mode")
local autoTPPriorityToggleSwitch = CreateToggleSwitch(rAutoTpPriority, Config.AutoTPPriority, function(ns, set)
    set(ns); Config.AutoTPPriority = ns; SaveConfig()
    ShowNotification("AUTO TP PRIORITY", ns and "PRIORITY" or "HIGHEST")
end)
autoTPPriorityToggleRef.setFn = autoTPPriorityToggleSwitch.Set
local rAutoKick = CreateRow("Auto-Kick on Steal")
CreateToggleSwitch(rAutoKick, Config.AutoKickOnSteal, function(ns, set)
    set(ns); Config.AutoKickOnSteal = ns; SaveConfig()
    ShowNotification("AUTO-KICK ON STEAL", ns and "ENABLED" or "DISABLED")
end)

CreateSectionHeader("HIDE GUIS")
local rHideAdminPanel = CreateRow("Hide Admin Panel GUI")
CreateToggleSwitch(rHideAdminPanel, Config.HideAdminPanel, function(ns, set)
    set(ns); Config.HideAdminPanel = ns; SaveConfig()
    local adUI = PlayerGui:FindFirstChild("HeroAdminPanel")
    if adUI then adUI.Enabled = not ns end
    ShowNotification("HIDE ADMIN PANEL", ns and "ENABLED" or "DISABLED")
end)
local rHideAutoSteal = CreateRow("Hide Auto Steal GUI")
CreateToggleSwitch(rHideAutoSteal, Config.HideAutoSteal, function(ns, set)
    set(ns); Config.HideAutoSteal = ns; SaveConfig()
    local asUI = PlayerGui:FindFirstChild("AutoStealUI")
    if asUI then asUI.Enabled = not ns end
    ShowNotification("HIDE AUTO STEAL", ns and "ENABLED" or "DISABLED")
end)
local rCompactAutoSteal = CreateRow("Compact Auto Steal GUI")
CreateToggleSwitch(rCompactAutoSteal, Config.CompactAutoSteal, function(ns, set)
    set(ns); Config.CompactAutoSteal = ns; SaveConfig()
    local asUI = PlayerGui:FindFirstChild("AutoStealUI")
    if asUI and asUI:FindFirstChild("Frame") then
        local frame = asUI.Frame
        local mobileScale = IS_MOBILE and 0.6 or 1
        local targetHeight = ns and (5 * 44 + 135) or (630 * mobileScale)
        
        local tween = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, targetHeight)}
        )
        tween:Play()
        
        tween.Completed:Connect(function()
            SharedState.ListNeedsRedraw = true
            if SharedState.UpdateAutoStealUI then
                SharedState.UpdateAutoStealUI()
            end
        end)
    end
    ShowNotification("COMPACT AUTO STEAL", ns and "ENABLED" or "DISABLED")
end)

CreateSectionHeader("EXTRAS")   

local rResetKey = CreateRow("Reset")
local bResetKey = Instance.new("TextButton", rResetKey)
bResetKey.Size=UDim2.new(0,60,0,24); bResetKey.Position=UDim2.new(1,-70,0.5,-12)
bResetKey.BackgroundColor3=Theme.SurfaceHighlight; bResetKey.Text=Config.ResetKey
bResetKey.Font=Enum.Font.GothamBold; bResetKey.TextColor3=Theme.TextPrimary; bResetKey.TextSize=12
Instance.new("UICorner",bResetKey).CornerRadius=UDim.new(0,4)
bResetKey.MouseButton1Click:Connect(function()
    bResetKey.Text="..."; bResetKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ResetKey=inp.KeyCode.Name; bResetKey.Text=inp.KeyCode.Name
            bResetKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("RESET KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rAutoResetBalloon = CreateRow("Auto reset on balloon")
CreateToggleSwitch(rAutoResetBalloon, Config.AutoResetOnBalloon, function(ns, set)
    set(ns); Config.AutoResetOnBalloon = ns; SaveConfig()
    ShowNotification("AUTO RESET ON BALLOON", ns and "ENABLED" or "DISABLED")
end)

local rKickKey = CreateRow("Kick")
local bKickKey = Instance.new("TextButton", rKickKey)
bKickKey.Size=UDim2.new(0,60,0,24); bKickKey.Position=UDim2.new(1,-70,0.5,-12)
bKickKey.BackgroundColor3=Theme.SurfaceHighlight; bKickKey.Text=Config.KickKey ~= "" and Config.KickKey or "NONE"
bKickKey.Font=Enum.Font.GothamBold; bKickKey.TextColor3=Theme.TextPrimary; bKickKey.TextSize=12
Instance.new("UICorner",bKickKey).CornerRadius=UDim.new(0,4)
bKickKey.MouseButton1Click:Connect(function()
    bKickKey.Text="..."; bKickKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.KickKey=inp.KeyCode.Name; bKickKey.Text=inp.KeyCode.Name
            bKickKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("KICK KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rCleanErrors = CreateRow("Clean Error GUIs")
CreateToggleSwitch(rCleanErrors, Config.CleanErrorGUIs, function(ns, set)
    set(ns); Config.CleanErrorGUIs = ns; SaveConfig()
    ShowNotification("CLEAN ERROR GUIS", ns and "ENABLED" or "DISABLED")
end)


CreateSectionHeader("ADMIN PANEL")
local rClickToAP = CreateRow("Click To Admin Panel")
CreateToggleSwitch(rClickToAP, Config.ClickToAP, function(ns, set)
    set(ns); Config.ClickToAP = ns; SaveConfig()
    ShowNotification("CLICK TO AP", ns and "ENABLED" or "DISABLED")
end)
local rClickToAPSingle = CreateRow("Click To AP Single Command")
CreateToggleSwitch(rClickToAPSingle, Config.ClickToAPSingleCommand, function(ns, set)
    set(ns); Config.ClickToAPSingleCommand = ns; SaveConfig()
    ShowNotification("CLICK TO AP SINGLE", ns and "ENABLED" or "DISABLED")
end)
local rDisableClickToAPOnMoby = CreateRow("Disable Click To AP On Moby")
CreateToggleSwitch(rDisableClickToAPOnMoby, Config.DisableClickToAPOnMoby, function(ns, set)
    set(ns); Config.DisableClickToAPOnMoby = ns; SaveConfig()
    ShowNotification("DISABLE CLICK TO AP ON MOBY", ns and "ENABLED" or "DISABLED")
end)
local rDisableProximitySpamOnMoby = CreateRow("Disable Proximity AP On Moby")
CreateToggleSwitch(rDisableProximitySpamOnMoby, Config.DisableProximitySpamOnMoby, function(ns, set)
    set(ns); Config.DisableProximitySpamOnMoby = ns; SaveConfig()
    ShowNotification("DISABLE PROXIMITY AP ON MOBY", ns and "ENABLED" or "DISABLED")
end)
local rDisableClickToAPOnKawaifu = CreateRow("Disable Click To AP On Kawaifu")
CreateToggleSwitch(rDisableClickToAPOnKawaifu, Config.DisableClickToAPOnKawaifu, function(ns, set)
    set(ns); Config.DisableClickToAPOnKawaifu = ns; SaveConfig()
    ShowNotification("DISABLE CLICK TO AP ON KAWAIFU", ns and "ENABLED" or "DISABLED")
end)
local rDisableProximitySpamOnKawaifu = CreateRow("Disable Proximity AP On Kawaifu")
CreateToggleSwitch(rDisableProximitySpamOnKawaifu, Config.DisableProximitySpamOnKawaifu, function(ns, set)
    set(ns); Config.DisableProximitySpamOnKawaifu = ns; SaveConfig()
    ShowNotification("DISABLE PROXIMITY AP ON KAWAIFU", ns and "ENABLED" or "DISABLED")
end)
local rHideKawaifuFromPanel = CreateRow("Hide Kawaifu From Panel")
CreateToggleSwitch(rHideKawaifuFromPanel, Config.HideKawaifuFromPanel, function(ns, set)
    set(ns); Config.HideKawaifuFromPanel = ns; SaveConfig()
    ShowNotification("HIDE KAWAIFU FROM PANEL", ns and "ENABLED" or "DISABLED")
end)
local rClickToAPKeybind = CreateRow("Click To AP Keybind")
local bClickToAPKeybind = Instance.new("TextButton", rClickToAPKeybind)
bClickToAPKeybind.Size=UDim2.new(0,60,0,24); bClickToAPKeybind.Position=UDim2.new(1,-65,0.5,-12)
bClickToAPKeybind.BackgroundColor3=Theme.SurfaceHighlight; bClickToAPKeybind.Text=Config.ClickToAPKeybind or "L"
bClickToAPKeybind.Font=Enum.Font.GothamBold; bClickToAPKeybind.TextColor3=Theme.TextPrimary; bClickToAPKeybind.TextSize=12
Instance.new("UICorner",bClickToAPKeybind).CornerRadius=UDim.new(0,4)
bClickToAPKeybind.MouseButton1Click:Connect(function()
    bClickToAPKeybind.Text="..."; bClickToAPKeybind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ClickToAPKeybind=inp.KeyCode.Name; bClickToAPKeybind.Text=inp.KeyCode.Name
            bClickToAPKeybind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CLICK TO AP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)
local rProximityAPKeybind = CreateRow("Proximity AP Keybind")
local bProximityAPKeybind = Instance.new("TextButton", rProximityAPKeybind)
bProximityAPKeybind.Size=UDim2.new(0,60,0,24); bProximityAPKeybind.Position=UDim2.new(1,-70,0.5,-12)
bProximityAPKeybind.BackgroundColor3=Theme.SurfaceHighlight; bProximityAPKeybind.Text=Config.ProximityAPKeybind or "P"
bProximityAPKeybind.Font=Enum.Font.GothamBold; bProximityAPKeybind.TextColor3=Theme.TextPrimary; bProximityAPKeybind.TextSize=12
Instance.new("UICorner",bProximityAPKeybind).CornerRadius=UDim.new(0,4)
bProximityAPKeybind.MouseButton1Click:Connect(function()
    bProximityAPKeybind.Text="..."; bProximityAPKeybind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ProximityAPKeybind=inp.KeyCode.Name; bProximityAPKeybind.Text=inp.KeyCode.Name
            bProximityAPKeybind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("PROXIMITY AP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

CreateSectionHeader("ALERTS")
local rAlertsEnabled = CreateRow("Enable Alerts")
CreateToggleSwitch(rAlertsEnabled, Config.AlertsEnabled, function(ns, set)
    set(ns); Config.AlertsEnabled = ns; SaveConfig()
    ShowNotification("PRIORITY ALERTS", ns and "ENABLED" or "DISABLED")
end)
local rAlertSound = CreateRow("Alert Sound ID")
local soundBox = Instance.new("TextBox", rAlertSound)
soundBox.Size = UDim2.new(0, 180, 0, 24)
soundBox.Position = UDim2.new(1, -185, 0.5, -12)
soundBox.BackgroundColor3 = Theme.SurfaceHighlight
soundBox.Text = Config.AlertSoundID or "rbxassetid://6518811702"
soundBox.Font = Enum.Font.Gotham
soundBox.TextSize = 10
soundBox.TextColor3 = Theme.TextPrimary
soundBox.PlaceholderText = "Sound ID"
Instance.new("UICorner", soundBox).CornerRadius = UDim.new(0, 4)
soundBox.FocusLost:Connect(function()
    Config.AlertSoundID = soundBox.Text
    SaveConfig()
    ShowNotification("ALERT SOUND", "Updated")
end)

CreateSectionHeader("JOB JOINER")
local rJoinerRow = CreateRow("Job ID Joiner")
CreateToggleSwitch(rJoinerRow, Config.ShowJobJoiner, function(ns, set)
    set(ns); Config.ShowJobJoiner = ns; SaveConfig()
    local gui = PlayerGui:FindFirstChild("HeroJobJoiner")
    if gui then gui.Enabled = Config.ShowJobJoiner end
    ShowNotification("JOB ID JOINER", ns and "ENABLED" or "DISABLED")
end)
local rJoinerKey = CreateRow("Job Joiner Keybind")
local bJoinerKey = Instance.new("TextButton", rJoinerKey)
bJoinerKey.Size=UDim2.new(0,60,0,24); bJoinerKey.Position=UDim2.new(1,-70,0.5,-12)
bJoinerKey.BackgroundColor3=Theme.SurfaceHighlight; bJoinerKey.Text=Config.JobJoinerKey or "J"
bJoinerKey.Font=Enum.Font.GothamBold; bJoinerKey.TextColor3=Theme.TextPrimary; bJoinerKey.TextSize=12
Instance.new("UICorner",bJoinerKey).CornerRadius=UDim.new(0,4)
bJoinerKey.MouseButton1Click:Connect(function()
    bJoinerKey.Text="..."; bJoinerKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.JobJoinerKey=inp.KeyCode.Name; bJoinerKey.Text=inp.KeyCode.Name
            bJoinerKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("JOB JOINER KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

CreateSectionHeader("PROTECTION")
local rAntiBeeDisco = CreateRow("Anti-Bee & Anti-Disco")
CreateToggleSwitch(rAntiBeeDisco, Config.AntiBeeDisco, function(ns, set)
    set(ns); Config.AntiBeeDisco = ns; SaveConfig()
    if ns then
        if _G.ANTI_BEE_DISCO and _G.ANTI_BEE_DISCO.Enable then
            _G.ANTI_BEE_DISCO.Enable()
        end
    else
        if _G.ANTI_BEE_DISCO and _G.ANTI_BEE_DISCO.Disable then
            _G.ANTI_BEE_DISCO.Disable()
        end
    end
    ShowNotification("ANTI-BEE & DISCO", ns and "ENABLED" or "DISABLED")
end)

local rAutoDestroyTurrets = CreateRow("Auto-Destroy Turrets")
CreateToggleSwitch(rAutoDestroyTurrets, Config.AutoDestroyTurrets, function(ns, set)
    set(ns); Config.AutoDestroyTurrets = ns; SaveConfig()
    ShowNotification("AUTO-DESTROY TURRETS", ns and "ENABLED" or "DISABLED")
end)

CreateSectionHeader("CAMERA")
local rFOV = CreateRow("FOV")
local fovSliderBg = Instance.new("Frame", rFOV)
fovSliderBg.Size = UDim2.new(0, 140, 0, 5)
fovSliderBg.Position = UDim2.new(1, -200, 0.5, -2.5)
fovSliderBg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
Instance.new("UICorner", fovSliderBg).CornerRadius = UDim.new(1, 0)
local fovFill = Instance.new("Frame", fovSliderBg)
fovFill.BackgroundColor3 = Theme.Accent1
fovFill.Size = UDim2.new(0, 0, 1, 0)
Instance.new("UICorner", fovFill).CornerRadius = UDim.new(1, 0)
local fovKnob = Instance.new("Frame", fovSliderBg)
fovKnob.Size = UDim2.new(0, 12, 0, 12)
fovKnob.BackgroundColor3 = Theme.TextPrimary
fovKnob.AnchorPoint = Vector2.new(0.5, 0.5)
fovKnob.Position = UDim2.new(0, 0, 0.5, 0)
Instance.new("UICorner", fovKnob).CornerRadius = UDim.new(1, 0)
local fovKnobStroke = Instance.new("UIStroke", fovKnob)
fovKnobStroke.Color = Theme.Accent1
fovKnobStroke.Thickness = 1.5
fovKnobStroke.Transparency = 0.2
local fovValLbl = Instance.new("TextLabel", rFOV)
fovValLbl.Size = UDim2.new(0, 40, 0, 20)
fovValLbl.Position = UDim2.new(1, -50, 0.5, -10)
fovValLbl.BackgroundTransparency = 1
fovValLbl.Text = string.format("%.1f", Config.FOV)
fovValLbl.TextColor3 = Theme.TextPrimary
fovValLbl.Font = Enum.Font.GothamBold
fovValLbl.TextSize = 13

local function updateFOVSlider(val)
    val = math.clamp(val, 30, 180)
    Config.FOV = val
    SaveConfig()
    fovValLbl.Text = string.format("%.1f", val)
    local pct = (val - 30) / 150
    fovFill.Size = UDim2.new(pct, 0, 1, 0)
    fovKnob.Position = UDim2.new(pct, 0, 0.5, 0)
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = val
    end
    ShowNotification("FIELD OF VIEW", string.format("%.1f", val))
end
updateFOVSlider(Config.FOV)

local fovDragging = false
fovSliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fovDragging = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fovDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if fovDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local x = i.Position.X
        local r = fovSliderBg.AbsolutePosition.X
        local w = fovSliderBg.AbsoluteSize.X
        local p = (x - r) / w
        updateFOVSlider(30 + (p * 150))
    end
end)

local rFOVReset = CreateRow("Reset FOV")
local bFOVReset = Instance.new("TextButton", rFOVReset)
bFOVReset.Size = UDim2.new(0, 60, 0, 24)
bFOVReset.Position = UDim2.new(1, -70, 0.5, -12)
bFOVReset.BackgroundColor3 = Theme.SurfaceHighlight
bFOVReset.Text = "Reset"
bFOVReset.Font = Enum.Font.GothamBold
bFOVReset.TextColor3 = Theme.TextPrimary
bFOVReset.TextSize = 12
Instance.new("UICorner", bFOVReset).CornerRadius = UDim.new(0, 4)
bFOVReset.MouseButton1Click:Connect(function()
    updateFOVSlider(70)
    ShowNotification("FIELD OF VIEW", "Reset to 70")
end)


CreateSectionHeader("MENU")
if not IS_MOBILE then
    local rMenu = CreateRow("Menu Toggle Key")
    local bMenu = Instance.new("TextButton", rMenu)
    bMenu.Size=UDim2.new(0,80,0,24); bMenu.Position=UDim2.new(1,-90,0.5,-12)
    bMenu.BackgroundColor3=Theme.SurfaceHighlight; bMenu.Text=Config.MenuKey
    bMenu.Font=Enum.Font.GothamBold; bMenu.TextColor3=Theme.TextPrimary; bMenu.TextSize=12
    Instance.new("UICorner",bMenu).CornerRadius=UDim.new(0,4)
    bMenu.MouseButton1Click:Connect(function()
        bMenu.Text="..."; bMenu.TextColor3=Theme.Accent1
        local con; con=UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                Config.MenuKey=inp.KeyCode.Name; bMenu.Text=inp.KeyCode.Name
                bMenu.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
                ShowNotification("MENU KEYBIND", inp.KeyCode.Name)
            end
        end)
    end)
else
    CreateRow("Menu Toggle: Touch Icon")
end

CreateSectionHeader("UI CONTROLS")
local rLock = CreateRow("Lock UI Dragging")
CreateToggleSwitch(rLock, Config.UILocked, function(ns, set)
    set(ns); Config.UILocked = ns; SaveConfig()
    ShowNotification("UI LOCK", ns and "ENABLED" or "DISABLED")
end)

if IS_MOBILE then
    local scaleUI = {}
    scaleUI.row = CreateRow("Mobile GUI Scale")
    scaleUI.bg = Instance.new("Frame", scaleUI.row)
    scaleUI.bg.Size = UDim2.new(0, 140, 0, 5)
    scaleUI.bg.Position = UDim2.new(1, -200, 0.5, -2.5)
    scaleUI.bg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
    Instance.new("UICorner", scaleUI.bg).CornerRadius = UDim.new(1, 0)
    scaleUI.fill = Instance.new("Frame", scaleUI.bg)
    scaleUI.fill.BackgroundColor3 = Theme.Accent1
    scaleUI.fill.BorderSizePixel = 0
    scaleUI.fill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", scaleUI.fill).CornerRadius = UDim.new(1, 0)
    scaleUI.knob = Instance.new("Frame", scaleUI.bg)
    scaleUI.knob.Size = UDim2.new(0, 14, 0, 14)
    scaleUI.knob.AnchorPoint = Vector2.new(0.5, 0.5)
    scaleUI.knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    scaleUI.knob.BorderSizePixel = 0
    Instance.new("UICorner", scaleUI.knob).CornerRadius = UDim.new(1, 0)
    scaleUI.stroke = Instance.new("UIStroke", scaleUI.knob)
    scaleUI.stroke.Color = Theme.Accent1
    scaleUI.stroke.Thickness = 2
    scaleUI.readout = Instance.new("TextLabel", scaleUI.row)
    scaleUI.readout.Size = UDim2.new(0, 50, 0, 20)
    scaleUI.readout.Position = UDim2.new(1, -145, 0.5, -10)
    scaleUI.readout.BackgroundTransparency = 1
    scaleUI.readout.Text = string.format("%.1f", Config.MobileGuiScale or 0.5)
    scaleUI.readout.Font = Enum.Font.GothamBold
    scaleUI.readout.TextSize = 11
    scaleUI.readout.TextColor3 = Theme.Accent1
    scaleUI.readout.TextXAlignment = Enum.TextXAlignment.Right
    scaleUI.dragging = false
    scaleUI.min = 0.1
    scaleUI.max = 1.0
    scaleUI.scaleToT = function(s)
        return math.clamp((s - scaleUI.min) / (scaleUI.max - scaleUI.min), 0, 1)
    end
    scaleUI.updateScaleSlider = function(val)
        local c = math.clamp(val, scaleUI.min, scaleUI.max)
        Config.MobileGuiScale = c
        SaveConfig()
        scaleUI.fill.Size = UDim2.new(scaleUI.scaleToT(c), 0, 1, 0)
        scaleUI.knob.Position = UDim2.new(0, scaleUI.scaleToT(c) * scaleUI.bg.AbsoluteSize.X, 0.5, 0)
        scaleUI.readout.Text = string.format("%.2f", c)
        if SharedState.RefreshMobileScale then SharedState.RefreshMobileScale() end
    end
    task.defer(function() scaleUI.updateScaleSlider(Config.MobileGuiScale or 0.5) end)
    scaleUI.onScaleInput = function(pos)
        scaleUI.updateScaleSlider(scaleUI.min + math.clamp((pos.X - scaleUI.bg.AbsolutePosition.X) / scaleUI.bg.AbsoluteSize.X, 0, 1) * (scaleUI.max - scaleUI.min))
    end
    scaleUI.bg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            scaleUI.dragging = true
            scaleUI.onScaleInput(inp.Position)
        end
    end)
    scaleUI.knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            scaleUI.dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            scaleUI.dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if scaleUI.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            scaleUI.onScaleInput(inp.Position)
        end
    end)
end

local rReset = CreateRow("Reset UI Positions")
local bReset = Instance.new("TextButton", rReset)
bReset.Size=UDim2.new(0,80,0,24); bReset.Position=UDim2.new(1,-90,0.5,-12)
bReset.BackgroundColor3=Theme.Error; bReset.Text="RESET"
bReset.Font=Enum.Font.GothamBold; bReset.TextColor3=Theme.TextPrimary; bReset.TextSize=12
Instance.new("UICorner",bReset).CornerRadius=UDim.new(0,4)
bReset.MouseButton1Click:Connect(function()
    Config.Positions = DefaultConfig.Positions
    SaveConfig()
    ShowNotification("UI RESET", "Positions restored")
    sFrame.Position = UDim2.new(DefaultConfig.Positions.Settings.X, 0, DefaultConfig.Positions.Settings.Y, 0)
    if PlayerGui:FindFirstChild("AutoStealUI") then
        PlayerGui.AutoStealUI.Frame.Position = UDim2.new(DefaultConfig.Positions.AutoSteal.X, 0, DefaultConfig.Positions.AutoSteal.Y, 0)
    end
    if PlayerGui:FindFirstChild("StealSpeedUI") then
        PlayerGui.StealSpeedUI.Frame.Position = UDim2.new(DefaultConfig.Positions.StealSpeed.X, 0, DefaultConfig.Positions.StealSpeed.Y, 0)
    end
    if PlayerGui:FindFirstChild("HeroAdminPanel") and PlayerGui.XiAdminPanel:FindFirstChild("Frame") then
        PlayerGui.XiAdminPanel.Frame.Position = UDim2.new(DefaultConfig.Positions.AdminPanel.X, 0, DefaultConfig.Positions.AdminPanel.Y, 0)
    end
    if PlayerGui:FindFirstChild("HeroInvisPanel") and PlayerGui.XiInvisPanel:FindFirstChild("Frame") then
        PlayerGui.XiInvisPanel.Frame.Position = UDim2.new(DefaultConfig.Positions.InvisPanel.X, 0, DefaultConfig.Positions.InvisPanel.Y, 0)
    end
    ShowNotification("UI RESET", "Positions restored to default")
end)

local function updateSettingsCanvasSize()
    local contentHeight = sLayout.AbsoluteContentSize.Y
    sList.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight + 20, sList.AbsoluteSize.Y))
end

sLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSettingsCanvasSize)
task.defer(updateSettingsCanvasSize)


if IS_MOBILE then
    sList.ScrollBarThickness = 6
    sList.ScrollingEnabled = true
    sList.ElasticBehavior = Enum.ElasticBehavior.Always
end

if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == (Enum.KeyCode[Config.MenuKey] or Enum.KeyCode.LeftControl) then
            if _G.HeroSettingsUI and _G.HeroSettingsUI.panel then
                _G.HeroSettingsUI.panel.Visible = not _G.HeroSettingsUI.panel.Visible
            else
                settingsGui.Enabled = not settingsGui.Enabled
            end
        end
        if Config.KickKey ~= "" and input.KeyCode == Enum.KeyCode[Config.KickKey] then
            kickPlayer()
        end
        if Config.RagdollSelfKey ~= "" and input.KeyCode == Enum.KeyCode[Config.RagdollSelfKey] then
            if not isOnCooldown("ragdoll") then
                if runAdminCommand(LocalPlayer, "ragdoll") then
                    activeCooldowns["ragdoll"] = tick()
                    setGlobalVisualCooldown("ragdoll")
                    ShowNotification("RAGDOLL SELF", "Ragdolled " .. LocalPlayer.Name)
                end
            else
                ShowNotification("RAGDOLL SELF", "Ragdoll on cooldown")
            end
        end
        if Config.ProximityAPKeybind and input.KeyCode == Enum.KeyCode[Config.ProximityAPKeybind] then
            ProximityAPActive = not ProximityAPActive
            if SharedState.ProximityAPButton then
                updateProximityAPButton()
            end
            ShowNotification("PROXIMITY AP", ProximityAPActive and "ENABLED" or "DISABLED")
        end
        if input.KeyCode == (Enum.KeyCode[Config.ClickToAPKeybind] or Enum.KeyCode.L) then
            Config.ClickToAP = not Config.ClickToAP
            SaveConfig()
            ShowNotification("CLICK TO AP", Config.ClickToAP and "ENABLED" or "DISABLED")
        end
        if Config.JobJoinerKey and input.KeyCode == Enum.KeyCode[Config.JobJoinerKey] then
            local joinerGui = PlayerGui:FindFirstChild("HeroJobJoiner")
            if joinerGui then
                Config.ShowJobJoiner = not Config.ShowJobJoiner
                joinerGui.Enabled = Config.ShowJobJoiner
                SaveConfig()
                ShowNotification("JOB ID JOINER", Config.ShowJobJoiner and "OPENED" or "CLOSED")
            end
        end
    end)
end


task.spawn(function()
    task.wait(1)
    if Config.HideAdminPanel then
        local adUI = PlayerGui:FindFirstChild("HeroAdminPanel")
        if adUI then adUI.Enabled = false end
    end
    if Config.HideAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = false end
    end
    if Config.HideStealSpeedUI then
        local g = PlayerGui:FindFirstChild("StealSpeedUI")
        if g then g.Enabled = false end
    end
    if Config.HideInvisPanel then
        local g = PlayerGui:FindFirstChild("HeroInvisPanel")
        if g then g.Enabled = false end
    end
    if Config.HideStatusHUD then
        local g = PlayerGui:FindFirstChild("HeroStatusHUD")
        if g then g.Enabled = false end
    end
    if Config.HideAutoBuyUI then
        local g = PlayerGui:FindFirstChild("HeroAutoBuyUI")
        if g then local p = g:FindFirstChild("ABPanel"); if p then p.Visible = false end end
    end
    if Config.HidePlatformUI then
        local g = PlayerGui:FindFirstChild("HeroPlatformUI")
        if g then g.Enabled = false end
    end
    if Config.CompactAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI and asUI:FindFirstChild("Frame") then
            local frame = asUI.Frame
            local mobileScale = IS_MOBILE and 0.6 or 1
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 5 * 44 + 135)
        end
    end
end)

local function parseMinGen(str)
    if not str or type(str) ~= "string" then return 0 end
    str = str:gsub("%s", ""):lower()
    if str == "" then return 0 end
    local num, suffix = str:match("^([%d%.]+)([kmb]?)$")
    if not num then return 0 end
    num = tonumber(num)
    if not num or num < 0 then return 0 end
    if suffix == "k" then return num * 1e3
    elseif suffix == "m" then return num * 1e6
    elseif suffix == "b" then return num * 1e9
    end
    return num
end

if Config.TpSettings.TpOnLoad then
    task.spawn(function()
        local t = 0
        local player = game.Players.LocalPlayer

        while not SharedState.SelectedPetData and t < 150 do
            task.wait(0.1)
            t = t + 1
        end

        if not SharedState.SelectedPetData then
            ShowNotification("TIMEOUT", "Auto TP timed out.")
            return
        end

        local minGen = parseMinGen(Config.TpSettings.MinGenForTp)
        if minGen > 0 then
            local waitCache = 0
            while (not SharedState.AllAnimalsCache or #SharedState.AllAnimalsCache == 0) and waitCache < 100 do
                task.wait(0.1)
                waitCache = waitCache + 1
            end
            local cache = SharedState.AllAnimalsCache or {}
            local highestGen = (cache[1] and cache[1].genValue) or 0
            if highestGen < minGen then
                ShowNotification("MIN GEN", "Highest brainrot below " .. (Config.TpSettings.MinGenForTp or "") .. ", skipping auto TP.")
                return
            end
        end

        runAutoSnipe()
    end)
end


LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
    local isStealing = LocalPlayer:GetAttribute("Stealing")
    local wasStealing = not isStealing 

    if isStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and not _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
        if Config.AutoUnlockOnSteal then
            triggerClosestUnlock(nil, 19)
        end
    elseif wasStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
    end
end)

task.spawn(function()
    local stealSpeedEnabled = false
    local STEAL_SPEED = Config.StealSpeed or 25.5
    local stealConn = nil

    local function doDisable()
        stealSpeedEnabled = false
        if stealConn then stealConn:Disconnect(); stealConn=nil end
    end
    SharedState.DisableStealSpeed = function()
        doDisable()
        if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
    end

    local function doEnable()
        stealSpeedEnabled = true
        if stealConn then stealConn:Disconnect(); stealConn=nil end
        stealConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * STEAL_SPEED, hrp.AssemblyLinearVelocity.Y, md.Z * STEAL_SPEED)
            end
        end)
    end

    local ssGui = Instance.new("ScreenGui")
    ssGui.Name = "StealSpeedUI"; ssGui.ResetOnSpawn = false
    ssGui.Enabled = Config.ShowStealSpeedPanel
    ssGui.Parent = PlayerGui

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        ssGui.Enabled = Config.ShowStealSpeedPanel
    end)

    local ssFrame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.6 or 1
    -- Keep height tall enough on mobile so the ENABLED button doesn't cover the slider (slider Y=46, button needs to start below)
    local ssHeight = IS_MOBILE and 126 or (126 * mobileScale)
    ssFrame.Size = UDim2.new(0, 300 * mobileScale, 0, ssHeight)
    ssFrame.Position = UDim2.new(
        Config.Positions.StealSpeed.X, 0,
        Config.Positions.StealSpeed.Y, 0)
    ssFrame.BackgroundColor3 = Theme.Background; ssFrame.BackgroundTransparency = 0.05
    ssFrame.BorderSizePixel = 0; ssFrame.Parent = ssGui

    ApplyViewportUIScale(ssFrame, 300, 126, 0.55, 1)
    Instance.new("UICorner", ssFrame).CornerRadius = UDim.new(0,12)
    local ssStroke = Instance.new("UIStroke", ssFrame)
    ssStroke.Color=Theme.Accent2; ssStroke.Thickness=1.5; ssStroke.Transparency=0.4
    CreateGradient(ssStroke)
    task.defer(function() if addRacetrackBorder then addRacetrackBorder(ssFrame, Theme.Accent1, 2.5) end end)

    local ssDragHandle = Instance.new("Frame", ssFrame)
    ssDragHandle.Size = UDim2.new(1,0,0,38)
    ssDragHandle.BackgroundTransparency = 1
    MakeDraggable(ssDragHandle, ssFrame, "StealSpeed")

    local ssTitle = Instance.new("TextLabel", ssDragHandle)
    ssTitle.Size = UDim2.new(1,-15,1,0); ssTitle.Position = UDim2.new(0,15,0,0)
    ssTitle.BackgroundTransparency=1; ssTitle.Text="STEAL SPEED"
    ssTitle.Font=Enum.Font.GothamBlack; ssTitle.TextSize=15
    ssTitle.TextColor3=Theme.TextPrimary; ssTitle.TextXAlignment=Enum.TextXAlignment.Left

    local speedReadout = Instance.new("TextLabel", ssFrame)
    speedReadout.Size = UDim2.new(0,56,0,38); speedReadout.Position = UDim2.new(1,-66,0,0)
    speedReadout.BackgroundTransparency=1
    speedReadout.Text=string.format("%.1f", STEAL_SPEED)
    speedReadout.Font=Enum.Font.GothamBlack; speedReadout.TextSize=15
    speedReadout.TextColor3=Theme.Accent1; speedReadout.TextXAlignment=Enum.TextXAlignment.Right

    local SLIDER_X_PAD = 16
    local sliderBg = Instance.new("Frame", ssFrame)
    sliderBg.Size = UDim2.new(1,-SLIDER_X_PAD*2,0,6)
    sliderBg.Position = UDim2.new(0,SLIDER_X_PAD,0,46)
    sliderBg.BackgroundColor3=Theme.SurfaceHighlight; sliderBg.BorderSizePixel=0
    Instance.new("UICorner",sliderBg).CornerRadius=UDim.new(1,0)

    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.BackgroundColor3=Theme.Accent1; sliderFill.BorderSizePixel=0; sliderFill.Size=UDim2.new(0,0,1,0)
    Instance.new("UICorner",sliderFill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame", ssFrame)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local knobStroke=Instance.new("UIStroke",knob); knobStroke.Color=Theme.Accent1; knobStroke.Thickness=2

    local MIN_SPEED,MAX_SPEED = 5, 100

    local function speedToT(s) return math.clamp((s-MIN_SPEED)/(MAX_SPEED-MIN_SPEED),0,1) end
    local function updateSlider(s)
        STEAL_SPEED = math.clamp(s, MIN_SPEED, MAX_SPEED)
        Config.StealSpeed = STEAL_SPEED; SaveConfig()
        local t = speedToT(STEAL_SPEED)
        sliderFill.Size = UDim2.new(t,0,1,0)
        local frameW = ssFrame.AbsoluteSize.X
        local trackW = frameW - SLIDER_X_PAD*2
        local knobX = SLIDER_X_PAD + t*trackW
        knob.Position = UDim2.new(0, knobX, 0, 46+3)
        speedReadout.Text = string.format("%.1f", STEAL_SPEED)
    end

    task.defer(function() updateSlider(STEAL_SPEED) end)
    ssFrame.Changed:Connect(function(prop)
        if prop=="AbsoluteSize" then updateSlider(STEAL_SPEED) end
    end)

    local sliderDragging = false
    local function onSliderInput(pos)
        local trackLeft = sliderBg.AbsolutePosition.X
        local trackRight = trackLeft + sliderBg.AbsoluteSize.X
        local t = math.clamp((pos.X - trackLeft)/(trackRight-trackLeft), 0, 1)
        updateSlider(MIN_SPEED + t*(MAX_SPEED-MIN_SPEED))
    end

    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sliderDragging=true; onSliderInput(inp.Position)
        end
    end)
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliderDragging=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliderDragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliderDragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            onSliderInput(inp.Position)
        end
    end)

    local minLbl=Instance.new("TextLabel",ssFrame)
    minLbl.Size=UDim2.new(0,30,0,14); minLbl.Position=UDim2.new(0,SLIDER_X_PAD,0,55)
    minLbl.BackgroundTransparency=1; minLbl.Text="5"
    minLbl.Font=Enum.Font.GothamMedium; minLbl.TextSize=10
    minLbl.TextColor3=Theme.TextSecondary; minLbl.TextXAlignment=Enum.TextXAlignment.Left

    local maxLbl=Instance.new("TextLabel",ssFrame)
    maxLbl.Size=UDim2.new(0,36,0,14); maxLbl.Position=UDim2.new(1,-SLIDER_X_PAD-36,0,55)
    maxLbl.BackgroundTransparency=1; maxLbl.Text="100"
    maxLbl.Font=Enum.Font.GothamMedium; maxLbl.TextSize=10
    maxLbl.TextColor3=Theme.TextSecondary; maxLbl.TextXAlignment=Enum.TextXAlignment.Right

    local ssBtn = Instance.new("TextButton", ssFrame)
    ssBtn.Size=UDim2.new(1,-32,0,34); ssBtn.Position=UDim2.new(0,16,1,-48)
    ssBtn.BackgroundColor3=Theme.SurfaceHighlight
    ssBtn.Text="DISABLED"; ssBtn.Font=Enum.Font.GothamBold
    ssBtn.TextSize=13; ssBtn.TextColor3=Theme.TextPrimary
    Instance.new("UICorner",ssBtn).CornerRadius=UDim.new(0,8)

    local function updateBtnVisual()
        ssBtn.Text = stealSpeedEnabled and "ENABLED" or "DISABLED"
        ssBtn.BackgroundColor3 = stealSpeedEnabled and Theme.Success or Theme.SurfaceHighlight
    end
    SharedState._ssUpdateBtn = updateBtnVisual

    SharedState.StealSpeedToggleFunc = function()
        if stealSpeedEnabled then doDisable() else doEnable() end
        updateBtnVisual()
    end

    ssBtn.MouseButton1Click:Connect(function()
        SharedState.StealSpeedToggleFunc()
    end)

    task.spawn(function()
        local lastHadSteal = nil
        while true do
            task.wait(0.3)
            if not Config.AutoStealSpeed then lastHadSteal = nil; continue end
            local hasSteal = (LocalPlayer:GetAttribute("Stealing") == true)
            if lastHadSteal == hasSteal then continue end
            lastHadSteal = hasSteal
            if hasSteal and not stealSpeedEnabled then
                doEnable(); updateBtnVisual()
            elseif not hasSteal and stealSpeedEnabled then
                doDisable(); if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
            end
        end
    end)
end)

task.spawn(function()
    local brainrotESPEnabled = Config.BrainrotESP
    local brainrotESPFolder = Instance.new("Folder")
    brainrotESPFolder.Name = "HeroBrainrotESP"
    brainrotESPFolder.Parent = Workspace
    local brainrotBillboards = {}
    local hiddenOverheads = {}
    local MUT_COLORS = {
        Cursed = Color3.fromRGB(255, 50, 50),
        Gold = Color3.fromRGB(255, 215, 0),
        Diamond = Color3.fromRGB(0, 255, 255),
        YinYang = Color3.fromRGB(220, 220, 220),
        Rainbow = Color3.fromRGB(255, 100, 200),
        Lava = Color3.fromRGB(255, 100, 20),
        Candy = Color3.fromRGB(255, 105, 180),
        Bloodrot = Color3.fromRGB(139, 0, 0),
        Radioactive = Color3.fromRGB(0, 255, 0),
        Divine = Color3.fromRGB(255, 255, 255)
    }
    
    local function createBrainrotBillboard(data)
        local bb = Instance.new("BillboardGui")
        bb.Name = "BrainrotESP_" .. data.uid
        bb.Size = UDim2.new(0, 160, 0, 38)
        bb.StudsOffset = Vector3.new(0, 1.8, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.MaxDistance = 3000
        
        local hasMut = data.mutation and data.mutation ~= "None" and data.mutation ~= "N/A"
        local color = hasMut and (MUT_COLORS[data.mutation] or Color3.fromRGB(200, 100, 255)) or Color3.fromRGB(0, 255, 150)
        
        local container = Instance.new("Frame", bb)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        container.BackgroundTransparency = 0.5
        container.BorderSizePixel = 0
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
        
        local stroke = Instance.new("UIStroke", container)
        stroke.Color = color
        stroke.Thickness = 1.5
        stroke.Transparency = 0.2
        
        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1, -6, 0, 18)
        nameLabel.Position = UDim2.new(0, 3, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = color
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Text = (data.name or data.petName) or "???"
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        local genLabel = Instance.new("TextLabel", container)
        genLabel.Size = UDim2.new(1, -6, 0, 14)
        genLabel.Position = UDim2.new(0, 3, 0, 20)
        genLabel.BackgroundTransparency = 1
        genLabel.Font = Enum.Font.GothamBold
        genLabel.TextSize = 11
        genLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        genLabel.TextStrokeTransparency = 0
        genLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        genLabel.Text = data.genText or ""
        genLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        if hasMut then
            local mutBadge = Instance.new("TextLabel", bb)
            mutBadge.Size = UDim2.new(0, 60, 0, 14)
            mutBadge.Position = UDim2.new(0.5, -30, 0, -16)
            mutBadge.BackgroundColor3 = color
            mutBadge.BackgroundTransparency = 0.3
            mutBadge.Font = Enum.Font.GothamBlack
            mutBadge.TextSize = 9
            mutBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            mutBadge.TextStrokeTransparency = 0
            mutBadge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            mutBadge.Text = data.mutation:upper()
            Instance.new("UICorner", mutBadge).CornerRadius = UDim.new(0, 3)
        end
        
        return bb
    end
    
    local function hideDefaultOverhead(overhead)
        if overhead and overhead.Parent and not hiddenOverheads[overhead] then
            hiddenOverheads[overhead] = overhead.Enabled
            overhead.Enabled = false
        end
    end
    
    local function showDefaultOverhead(overhead)
        if overhead and hiddenOverheads[overhead] ~= nil then
            overhead.Enabled = hiddenOverheads[overhead]
            hiddenOverheads[overhead] = nil
        end
    end
    
    local function restoreAllOverheads()
        for overhead, wasEnabled in pairs(hiddenOverheads) do
            if overhead and overhead.Parent then
                overhead.Enabled = wasEnabled
            end
        end
        hiddenOverheads = {}
    end
    
    local function refreshBrainrotESP()
        if not brainrotESPEnabled then return end
        local cache = SharedState.AllAnimalsCache
        if not cache or #cache == 0 then 
            return 
        end
        
        local seen = {}
        for _, data in ipairs(cache) do
            if data.genValue >= 10000000 then
                seen[data.uid] = true
                
                if not brainrotBillboards[data.uid] then
                    local adornee = nil
                    local overhead = nil
                    local studsOffset = Vector3.new(0, 1.8, 0)
                    
                    if data.overhead and data.overhead.Parent then
                        overhead = data.overhead
                        if overhead:IsA("BillboardGui") then
                            studsOffset = overhead.StudsOffset
                        end
                        hideDefaultOverhead(overhead)
                        adornee = overhead.Parent
                        if not adornee:IsA("BasePart") then
                            adornee = adornee:FindFirstChildWhichIsA("BasePart", true)
                        end
                    end
                    
                    if not adornee and data.plot and data.slot then
                        adornee = findAdorneeGlobal(data)
                        if adornee then
                            local model = adornee.Parent
                            if model and model:IsA("Model") then
                                overhead = model:FindFirstChild("AnimalOverhead", true)
                                if not overhead then
                                    for _, child in ipairs(model:GetDescendants()) do
                                        if child.Name == "AnimalOverhead" and child:IsA("BillboardGui") then
                                            overhead = child
                                            break
                                        end
                                    end
                                end
                                
                                if overhead then
                                    if overhead:IsA("BillboardGui") then
                                        studsOffset = overhead.StudsOffset
                                    end
                                    hideDefaultOverhead(overhead)
                                end
                            end
                        end
                    end
                    
                    if adornee then
                        local bb = createBrainrotBillboard(data)
                        bb.Adornee = adornee
                        bb.StudsOffset = studsOffset
                        bb.Parent = adornee
                        brainrotBillboards[data.uid] = {bb = bb, overhead = overhead}
                    end
                end
            end
        end
        
        for uid, entry in pairs(brainrotBillboards) do
            if not seen[uid] then
                if entry.bb then entry.bb:Destroy() end
                if entry.overhead then showDefaultOverhead(entry.overhead) end
                brainrotBillboards[uid] = nil
            end
        end
    end
    
    local function clearBrainrotESP()
        for _, entry in pairs(brainrotBillboards) do
            if entry.bb then entry.bb:Destroy() end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
        end
        brainrotBillboards = {}
        restoreAllOverheads()
    end
    
    espToggleRef.setFn = function(enabled)
        brainrotESPEnabled = enabled
        if enabled then
            task.spawn(function()
                task.wait(1)
                for i = 1, 5 do
                    pcall(refreshBrainrotESP)
                    task.wait(1)
                end
            end)
        else
            clearBrainrotESP()
        end
    end
    
    task.spawn(function()
        while true do
            task.wait(0.3)
            if brainrotESPEnabled then
                local cache = SharedState.AllAnimalsCache
                if cache and #cache > 0 then
                    pcall(refreshBrainrotESP)
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(2)
            if brainrotESPEnabled then
                local cache = SharedState.AllAnimalsCache
                if cache and #cache > 0 then
                    if next(brainrotBillboards) == nil then
                        clearBrainrotESP()
                    end
                    pcall(refreshBrainrotESP)
                end
            end
        end
    end)
end)

task.spawn(function()
    -- ============================================================
    -- DESYNC PANEL (Mystical-style)
    -- ============================================================
    if Config.AutoDesyncOnSteal == nil then Config.AutoDesyncOnSteal = false end
    if Config.DesyncKeybind == nil then Config.DesyncKeybind = "F" end
    if Config.ShowDesyncPanel == nil then Config.ShowDesyncPanel = true end
    if Config.Positions.DesyncPanel == nil then
        Config.Positions.DesyncPanel = {X = 0.3, Y = 0.5}
    end

    local desyncToggled = false
    local noAnimToggled = false

    local function rakhook(packet)
        if packet.PacketId == 0x1B then
            local data = packet.AsBuffer
            local currentValue = buffer.readu32(data, 1)
            if currentValue ~= 0 then
                buffer.writeu32(data, 1, 0)
                packet:SetData(data)
            end
            if math.random() > 0.7 then return false end
        end
    end

    local function setNoAnimation(state)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid", 5)
        local animate = character:FindFirstChild("Animate")
        if animate then animate.Disabled = state end
        if state and humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        end
    end

    local function startDesync()
        pcall(function() raknet.desync(true) end)
        pcall(function() raknet.add_send_hook(rakhook) end)
    end

    local function stopDesync()
        pcall(function() raknet.desync(false) end)
        pcall(function() raknet.remove_send_hook(rakhook) end)
    end

    local GOLD   = Color3.fromRGB(186, 120, 255)
    local DARK   = Color3.fromRGB(14, 10, 24)
    local SURF   = Color3.fromRGB(24, 18, 40)
    local HIGH   = Color3.fromRGB(38, 28, 62)
    local ACCENT = Color3.fromRGB(136, 72, 230)
    local TEXT   = Color3.fromRGB(245, 238, 255)
    local GRAY   = Color3.fromRGB(190, 168, 220)

    local desyncGui = Instance.new("ScreenGui")
    desyncGui.Name = "HeroDesyncPanel"
    desyncGui.ResetOnSpawn = false
    desyncGui.Enabled = Config.ShowDesyncPanel
    desyncGui.Parent = PlayerGui

    local dFrame = Instance.new("Frame")
    dFrame.Size = UDim2.new(0, 310, 0, 170)
    dFrame.Position = UDim2.new(
        Config.Positions.DesyncPanel.X, 0,
        Config.Positions.DesyncPanel.Y, 0)
    dFrame.BackgroundColor3 = DARK
    dFrame.BackgroundTransparency = 0.05
    dFrame.BorderSizePixel = 0
    dFrame.Parent = desyncGui
    Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 12)

    local dStroke = Instance.new("UIStroke", dFrame)
    dStroke.Color = ACCENT
    dStroke.Thickness = 1.5
    dStroke.Transparency = 0.4
    CreateGradient(dStroke)
    task.defer(function() if addRacetrackBorder then addRacetrackBorder(dFrame, GOLD, 3) end end)

    local dHeader = Instance.new("Frame", dFrame)
    dHeader.Size = UDim2.new(1, 0, 0, 36)
    dHeader.BackgroundTransparency = 1
    MakeDraggable(dHeader, dFrame, "DesyncPanel")

    local dTitle = Instance.new("TextLabel", dHeader)
    dTitle.Size = UDim2.new(1, -40, 1, 0)
    dTitle.Position = UDim2.new(0, 14, 0, 0)
    dTitle.BackgroundTransparency = 1
    dTitle.Text = "DESYNC"
    dTitle.Font = Enum.Font.GothamBlack
    dTitle.TextSize = 15
    dTitle.TextColor3 = TEXT
    dTitle.TextXAlignment = Enum.TextXAlignment.Left

    local minBtn = Instance.new("TextButton", dHeader)
    minBtn.Size = UDim2.new(0, 22, 0, 22)
    minBtn.Position = UDim2.new(1, -30, 0.5, -11)
    minBtn.BackgroundColor3 = HIGH
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 12
    minBtn.TextColor3 = GRAY
    minBtn.BorderSizePixel = 0
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)
    local minStroke = Instance.new("UIStroke", minBtn)
    minStroke.Color = ACCENT
    minStroke.Thickness = 1
    minStroke.Transparency = 0.5

    local sep = Instance.new("Frame", dFrame)
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 0, 36)
    sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sep.BackgroundTransparency = 0.92
    sep.BorderSizePixel = 0

    local statusRow = Instance.new("Frame", dFrame)
    statusRow.Size = UDim2.new(1, 0, 0, 24)
    statusRow.Position = UDim2.new(0, 0, 0, 40)
    statusRow.BackgroundTransparency = 1

    local statusDot = Instance.new("Frame", statusRow)
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 14, 0.5, -4)
    statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusDot.BorderSizePixel = 0
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

    local statusLabel = Instance.new("TextLabel", statusRow)
    statusLabel.Size = UDim2.new(1, -30, 1, 0)
    statusLabel.Position = UDim2.new(0, 28, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Inactive"
    statusLabel.TextColor3 = GRAY
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local body = Instance.new("Frame", dFrame)
    body.Size = UDim2.new(1, -20, 0, 120)
    body.Position = UDim2.new(0, 10, 0, 66)
    body.BackgroundTransparency = 1
    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.Padding = UDim.new(0, 6)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local toggleBtn = Instance.new("TextButton", body)
    toggleBtn.Size = UDim2.new(1, 0, 0, 32)
    toggleBtn.LayoutOrder = 1
    toggleBtn.BackgroundColor3 = HIGH
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.TextColor3 = TEXT
    toggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
    local tBtnStroke = Instance.new("UIStroke", toggleBtn)
    tBtnStroke.Color = ACCENT
    tBtnStroke.Thickness = 1
    tBtnStroke.Transparency = 0.6

    local noAnimBtn = Instance.new("TextButton", body)
    noAnimBtn.Size = UDim2.new(1, 0, 0, 26)
    noAnimBtn.LayoutOrder = 2
    noAnimBtn.BackgroundColor3 = SURF
    noAnimBtn.Text = "NO ANIM: OFF"
    noAnimBtn.Font = Enum.Font.GothamBold
    noAnimBtn.TextSize = 11
    noAnimBtn.TextColor3 = TEXT
    noAnimBtn.BorderSizePixel = 0
    Instance.new("UICorner", noAnimBtn).CornerRadius = UDim.new(0, 8)

    local bottomRows = Instance.new("Frame", body)
    bottomRows.Size = UDim2.new(1, 0, 0, 26)
    bottomRows.LayoutOrder = 3
    bottomRows.BackgroundTransparency = 1
    local bottomLayout = Instance.new("UIListLayout", bottomRows)
    bottomLayout.FillDirection = Enum.FillDirection.Horizontal
    bottomLayout.Padding = UDim.new(0, 6)

    local autoRow = Instance.new("Frame", bottomRows)
    autoRow.Size = UDim2.new(0.6, -3, 1, 0)
    autoRow.BackgroundColor3 = SURF
    autoRow.BorderSizePixel = 0
    Instance.new("UICorner", autoRow).CornerRadius = UDim.new(0, 6)

    local autoLabel = Instance.new("TextLabel", autoRow)
    autoLabel.Size = UDim2.new(0.62, 0, 1, 0)
    autoLabel.Position = UDim2.new(0, 8, 0, 0)
    autoLabel.BackgroundTransparency = 1
    autoLabel.Text = "Auto Desync on Steal"
    autoLabel.Font = Enum.Font.GothamMedium
    autoLabel.TextSize = 9
    autoLabel.TextColor3 = TEXT
    autoLabel.TextXAlignment = Enum.TextXAlignment.Left

    local keyRow = Instance.new("Frame", bottomRows)
    keyRow.Size = UDim2.new(0.4, -3, 1, 0)
    keyRow.BackgroundColor3 = SURF
    keyRow.BorderSizePixel = 0
    Instance.new("UICorner", keyRow).CornerRadius = UDim.new(0, 6)

    local keyLabel = Instance.new("TextLabel", keyRow)
    keyLabel.Size = UDim2.new(0.5, 0, 1, 0)
    keyLabel.Position = UDim2.new(0, 8, 0, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Keybind"
    keyLabel.Font = Enum.Font.GothamMedium
    keyLabel.TextSize = 10
    keyLabel.TextColor3 = GRAY
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left

    local keybindBtn = Instance.new("TextButton", keyRow)
    keybindBtn.Size = UDim2.new(0, 44, 0, 20)
    keybindBtn.Position = UDim2.new(1, -48, 0.5, -10)
    keybindBtn.BackgroundColor3 = HIGH
    keybindBtn.Text = Config.DesyncKeybind ~= "" and Config.DesyncKeybind or "NONE"
    keybindBtn.Font = Enum.Font.GothamBold
    keybindBtn.TextSize = 11
    keybindBtn.TextColor3 = GOLD
    keybindBtn.BorderSizePixel = 0
    Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, 4)

    local sw = Instance.new("Frame", autoRow)
    sw.Size = UDim2.new(0, 32, 0, 16)
    sw.Position = UDim2.new(1, -36, 0.5, -8)
    sw.BackgroundColor3 = Config.AutoDesyncOnSteal and GOLD or HIGH
    sw.BorderSizePixel = 0
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
    local swDot = Instance.new("Frame", sw)
    swDot.Size = UDim2.new(0, 12, 0, 12)
    swDot.Position = Config.AutoDesyncOnSteal and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    swDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    swDot.BorderSizePixel = 0
    Instance.new("UICorner", swDot).CornerRadius = UDim.new(1, 0)
    local swBtn = Instance.new("TextButton", sw)
    swBtn.Size = UDim2.new(1, 0, 1, 0)
    swBtn.BackgroundTransparency = 1
    swBtn.Text = ""

    local function setSwitch(on)
        Config.AutoDesyncOnSteal = on
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = on and GOLD or HIGH}):Play()
        TweenService:Create(swDot, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        }):Play()
        SaveConfig()
    end
    swBtn.MouseButton1Click:Connect(function() setSwitch(not Config.AutoDesyncOnSteal) end)

    local function updateVisuals()
        local keyStr = Config.DesyncKeybind ~= "" and " [" .. Config.DesyncKeybind .. "]" or ""
        toggleBtn.Text = (desyncToggled and "DEACTIVATE" or "ACTIVATE") .. keyStr
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = desyncToggled and GOLD or HIGH
        }):Play()
        toggleBtn.TextColor3 = desyncToggled and Color3.new(0, 0, 0) or TEXT
        TweenService:Create(statusDot, TweenInfo.new(0.2), {
            BackgroundColor3 = desyncToggled and GOLD or Color3.fromRGB(100, 100, 100)
        }):Play()
        statusLabel.Text = desyncToggled and "Active" or "Inactive"
        statusLabel.TextColor3 = desyncToggled and TEXT or GRAY
        noAnimBtn.Text = noAnimToggled and "NO ANIM: ON" or "NO ANIM: OFF"
        TweenService:Create(noAnimBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = noAnimToggled and HIGH or SURF
        }):Play()
        keybindBtn.Text = Config.DesyncKeybind ~= "" and Config.DesyncKeybind or "NONE"
    end

    local function doToggle()
        desyncToggled = not desyncToggled
        if desyncToggled then
            startDesync()
            noAnimToggled = true
            setNoAnimation(true)
            ShowNotification("DESYNC", "ACTIVATED")
        else
            stopDesync()
            noAnimToggled = false
            setNoAnimation(false)
            ShowNotification("DESYNC", "DEACTIVATED")
        end
        updateVisuals()
    end

    -- expose for mobile Des button
    _G.runDesync = function()
        if not desyncToggled then doToggle() end
    end

    toggleBtn.MouseButton1Click:Connect(doToggle)

    noAnimBtn.MouseButton1Click:Connect(function()
        if not desyncToggled then return end
        noAnimToggled = not noAnimToggled
        setNoAnimation(noAnimToggled)
        updateVisuals()
    end)

    keybindBtn.MouseButton1Click:Connect(function()
        keybindBtn.Text = "..."
        keybindBtn.TextColor3 = ACCENT
        local con
        con = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Config.DesyncKeybind = inp.KeyCode.Name
                keybindBtn.TextColor3 = GOLD
                SaveConfig()
                updateVisuals()
                con:Disconnect()
                ShowNotification("DESYNC KEYBIND", inp.KeyCode.Name)
            end
        end)
    end)

    local minimized = false
    local hiddenOnMin = {sep, statusRow, body}
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(dFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 310, 0, 36)}):Play()
            for _, el in ipairs(hiddenOnMin) do el.Visible = false end
        else
            TweenService:Create(dFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 310, 0, 170)}):Play()
            task.wait(0.18)
            for _, el in ipairs(hiddenOnMin) do el.Visible = true end
        end
    end)

    LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
        if LocalPlayer:GetAttribute("Stealing") and Config.AutoDesyncOnSteal and not desyncToggled then
            desyncToggled = true
            startDesync()
            noAnimToggled = true
            setNoAnimation(true)
            updateVisuals()
            ShowNotification("AUTO DESYNC", "Activated on steal")
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        desyncToggled = false
        noAnimToggled = false
        stopDesync()
        updateVisuals()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or UserInputService:GetFocusedTextBox() then return end
        if Config.DesyncKeybind ~= "" and input.KeyCode.Name == Config.DesyncKeybind then
            doToggle()
        end
    end)

    task.wait(0.5)
    CreateSectionHeader("DESYNC")
    local rShowDesync = CreateRow("Show Desync Panel")
    CreateToggleSwitch(rShowDesync, Config.ShowDesyncPanel, function(ns, set)
        set(ns)
        Config.ShowDesyncPanel = ns
        SaveConfig()
        desyncGui.Enabled = ns
        ShowNotification("DESYNC PANEL", ns and "SHOWN" or "HIDDEN")
    end)
    task.defer(updateSettingsCanvasSize)

    updateVisuals()
end)

task.spawn(function()
    local function getChar()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        return char, hrp, hum
    end

    local function hasExclamation(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BillboardGui") then
                local label = d:FindFirstChildWhichIsA("TextLabel", true)
                if label and label.Text:find("!") then
                    return true
                end
            end
        end
        return false
    end

    local function applyVisuals(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BasePart") and d ~= target then
                d.Transparency = 0.5
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = false
            elseif d:IsA("BillboardGui") and d.Name ~= "SentryLabel" then
                d:Destroy()
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 0.5
            end
        end
        if target:IsA("BasePart") and target.Name ~= "ProxyVisual" then
            target.Transparency = 1
            target.CanCollide = false
        end
    end

    local function getClosestSentry()
        local _, hrp = getChar()
        local closest, shortestDist = nil, math.huge
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst.Name:match("^Sentry_") then
                if hasExclamation(inst) then
                    local root = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
                    if root then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closest = inst
                        end
                    end
                end
            end
        end
        return closest
    end

    while true do
        if Config.AutoDestroyTurrets then
            if LocalPlayer:GetAttribute("Stealing") == true then
                task.wait(0.5)
            else
                local targetSentry = getClosestSentry()
                if targetSentry then
                    while targetSentry and targetSentry.Parent and (LocalPlayer:GetAttribute("Stealing") ~= true) do
                        local char, hrp, hum = getChar()
                        local bat = LocalPlayer.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
                        applyVisuals(targetSentry)
                        local offset = hrp.CFrame.LookVector * 4
                        local targetCF = CFrame.new(hrp.Position + offset, hrp.Position)
                        if targetSentry:IsA("Model") then
                            targetSentry:PivotTo(targetCF)
                        elseif targetSentry:IsA("BasePart") then
                            targetSentry.CFrame = targetCF
                        end
                        if bat then
                            if bat.Parent ~= char then hum:EquipTool(bat) end
                            bat:Activate()
                        end
                        task.wait(0.1)
                        if not hasExclamation(targetSentry) then break end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

SharedState.FOV_MANAGER = {
    activeCount = 0,
    conn = nil,
    forcedFOV = 70,
}
function SharedState.FOV_MANAGER:Start()
    if self.conn then return end
    self.forcedFOV = Config.FOV or 70
    self.conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local targetFOV = Config.FOV or self.forcedFOV
            if cam.FieldOfView ~= targetFOV then
                cam.FieldOfView = targetFOV
            end
        end
    end)
end
function SharedState.FOV_MANAGER:Stop()
    if self.conn then
        self.conn:Disconnect()
        self.conn = nil
    end
end
function SharedState.FOV_MANAGER:Push()
    self.activeCount = self.activeCount + 1
    self:Start()
end
function SharedState.FOV_MANAGER:Pop()
    if self.activeCount > 0 then
        self.activeCount = self.activeCount - 1
    end
    if self.activeCount == 0 then
        self:Stop()
    end
end

SharedState.ANTI_BEE_DISCO = {
    running = false,
    connections = {},
    originalMoveFunction = nil,
    controlsProtected = false,
    badLightingNames = { Blue = true, DiscoEffect = true, BeeBlur = true, ColorCorrection = true },
}
function SharedState.ANTI_BEE_DISCO.nuke(obj)
    if not obj or not obj.Parent then return end
    if SharedState.ANTI_BEE_DISCO.badLightingNames[obj.Name] then
        pcall(function() obj:Destroy() end)
    end
end
function SharedState.ANTI_BEE_DISCO.disconnectAll()
    for _, conn in ipairs(SharedState.ANTI_BEE_DISCO.connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    SharedState.ANTI_BEE_DISCO.connections = {}
end
function SharedState.ANTI_BEE_DISCO.protectControls()
    if SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        if not Controls then return end
        local ab = SharedState.ANTI_BEE_DISCO
        if not ab.originalMoveFunction then ab.originalMoveFunction = Controls.moveFunction end
        local function protectedMoveFunction(self, moveVector, relativeToCamera)
            if ab.originalMoveFunction then ab.originalMoveFunction(self, moveVector, relativeToCamera) end
        end
        table.insert(ab.connections, RunService.Heartbeat:Connect(function()
            if not ab.running or not Config.AntiBeeDisco then return end
            if Controls.moveFunction ~= protectedMoveFunction then Controls.moveFunction = protectedMoveFunction end
        end))
        Controls.moveFunction = protectedMoveFunction
        ab.controlsProtected = true
    end)
end
function SharedState.ANTI_BEE_DISCO.restoreControls()
    if not SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        local ab = SharedState.ANTI_BEE_DISCO
        if Controls and ab.originalMoveFunction then
            Controls.moveFunction = ab.originalMoveFunction
            ab.controlsProtected = false
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.blockBuzzingSound()
    pcall(function()
        local beeScript = LocalPlayer.PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then buzzing:Stop(); buzzing.Volume = 0 end
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.Enable()
    local ab = SharedState.ANTI_BEE_DISCO
    if ab.running then return end
    ab.running = true
    for _, inst in ipairs(Lighting:GetDescendants()) do ab.nuke(inst) end
    table.insert(ab.connections, Lighting.DescendantAdded:Connect(function(obj)
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.nuke(obj)
    end))
    ab.protectControls()
    table.insert(ab.connections, RunService.Heartbeat:Connect(function()
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.blockBuzzingSound()
    end))
    SharedState.FOV_MANAGER:Push()
    ShowNotification("ANTI-BEE & DISCO", "Enabled")
end
function SharedState.ANTI_BEE_DISCO.Disable()
    local ab = SharedState.ANTI_BEE_DISCO
    if not ab.running then return end
    ab.running = false
    ab.restoreControls()
    ab.disconnectAll()
    SharedState.FOV_MANAGER:Pop()
    ShowNotification("ANTI-BEE & DISCO", "Disabled")
end

_G.ANTI_BEE_DISCO = SharedState.ANTI_BEE_DISCO

if Config.AntiBeeDisco then
    task.delay(1, function()
        if SharedState.ANTI_BEE_DISCO.Enable then SharedState.ANTI_BEE_DISCO.Enable() end
    end)
end

task.spawn(function()
    while true do
        if Workspace.CurrentCamera then
            if Config.FOV and Config.FOV ~= Workspace.CurrentCamera.FieldOfView then
                Workspace.CurrentCamera.FieldOfView = Config.FOV
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    if IS_MOBILE then return end

    -- Destroi e reconstroi o HUD (chamado tambem pelo applyTheme)
    local function buildHUD()
        local existing = PlayerGui:FindFirstChild("HeroStatusHUD")
        if existing then existing:Destroy() end

        local hudGui = Instance.new("ScreenGui")
        hudGui.Name = "HeroStatusHUD"
        hudGui.ResetOnSpawn = false
        hudGui.DisplayOrder = 10
        hudGui.Parent = PlayerGui

        -- Painel principal - estilo lethal hub bar
        local main = Instance.new("Frame", hudGui)
        main.Name = "Main"
        main.Size = UDim2.new(0, 520, 0, 40)
        main.Position = UDim2.new(0.5, -260, 1, -90)
        main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        main.BackgroundTransparency = 0.1
        main.BorderSizePixel = 0
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)

        local mainStroke = Instance.new("UIStroke", main)
        mainStroke.Color = Color3.fromRGB(50, 50, 60)
        mainStroke.Thickness = 1
        mainStroke.Transparency = 0.5

        -- Barra lateral accent (like lethal hub white bar)
        local bar = Instance.new("Frame", main)
        bar.Size = UDim2.new(0, 3, 0, 22)
        bar.Position = UDim2.new(0, 14, 0.5, -11)
        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

        -- Titulo
        local title = Instance.new("TextLabel", main)
        title.Size = UDim2.new(0, 200, 1, 0)
        title.Position = UDim2.new(0, 24, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "HEROS HUB"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 14
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left

        -- FPS / PING
        local stats = Instance.new("TextLabel", main)
        stats.Size = UDim2.new(0, 180, 1, 0)
        stats.Position = UDim2.new(1, -188, 0, 0)
        stats.BackgroundTransparency = 1
        stats.RichText = true
        stats.Text = ""
        stats.Font = Enum.Font.GothamBold
        stats.TextSize = 12
        stats.TextColor3 = Color3.fromRGB(255, 255, 255)
        stats.TextXAlignment = Enum.TextXAlignment.Right

        local fr2, ac3 = 0, 0
        RunService.Heartbeat:Connect(function(dt)
            fr2 += 1; ac3 += dt
            if ac3 >= 1 then
                local ping3 = math.floor(LocalPlayer:GetNetworkPing()*1000)
                stats.Text = string.format(
                    "<font color='rgb(150,150,160)'>FPS:</font> <font color='rgb(80,255,150)'><b>%d</b></font>  <font color='rgb(150,150,160)'>PING:</font> <font color='rgb(80,255,150)'><b>%dms</b></font>",
                    fr2, ping3
                )
                fr2, ac3 = 0, 0
            end
        end)

        -- Unlock buttons (1 2 3)
        local unlockContainer = Instance.new("Frame", hudGui)
        unlockContainer.Name = "UnlockButtonsContainer"
        unlockContainer.Size = UDim2.new(0, 170, 0, 44)
        unlockContainer.Position = UDim2.new(0.5, -85, 1, -178)
        unlockContainer.BackgroundTransparency = 1
        unlockContainer.Visible = Config.ShowUnlockButtonsHUD or false
        unlockContainer.ZIndex = 10

        local uLayout = Instance.new("UIListLayout", unlockContainer)
        uLayout.FillDirection = Enum.FillDirection.Horizontal
        uLayout.Padding = UDim.new(0, 12)
        uLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local unlockLevels = {-2, 15, 32}
        for i = 1, 3 do
            local btn = Instance.new("TextButton", unlockContainer)
            btn.Size = UDim2.new(0, 48, 0, 40)
            btn.BackgroundColor3 = Theme.Surface
            btn.BackgroundTransparency = 0.2
            btn.Text = tostring(i)
            btn.Font = Enum.Font.GothamBlack
            btn.TextSize = 16
            btn.TextColor3 = Theme.TextPrimary
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            local bs = Instance.new("UIStroke", btn)
            bs.Color = Theme.Accent1
            bs.Thickness = 1.2
            bs.Transparency = 0.45
            local lvl = unlockLevels[i]
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency=0}):Play()
                TweenService:Create(bs, TweenInfo.new(0.1), {Transparency=0.1}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency=0.2}):Play()
                TweenService:Create(bs, TweenInfo.new(0.1), {Transparency=0.45}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                triggerClosestUnlock(lvl)
                ShowNotification("UNLOCK", "Level "..i)
            end)
        end

        -- Resize main if unlock visible
        if Config.ShowUnlockButtonsHUD then
            main.Size = UDim2.new(0, 460, 0, 44)
        end

        -- no racetrack border on pill bar

        return hudGui
    end

    buildHUD()
    _G.rebuildStatusHUD = buildHUD
end)


task.spawn(function()
    local playerESPEnabled = Config.PlayerESP
    local playerBillboards = {}
    
    local function makePlayerBillboard(player)
        local bb = Instance.new("BillboardGui")
        bb.Name = "PlayerESP_"..tostring(player.UserId)
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
        bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.ResetOnSpawn = false
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Size = UDim2.new(1,0,1,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBlack; nameLbl.TextSize = 13
        nameLbl.TextColor3 = Theme.Accent1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Center
        nameLbl.TextStrokeTransparency = 0.4
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        nameLbl.Text = player.Name
        return bb, nameLbl
    end

    local function getHRP(player)
        local char = player.Character; if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function createOrRefresh(player)
        if player == LocalPlayer then return end
        local hrp = getHRP(player); if not hrp then return end
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        local uid = player.UserId
        local entry = playerBillboards[uid]
        if not entry or not entry.bb or not entry.bb.Parent then
            if entry and entry.bb then pcall(function() entry.bb:Destroy() end) end
            local bb, nameLbl = makePlayerBillboard(player)
            bb.Adornee = hrp; bb.Parent = hrp
            playerBillboards[uid] = {bb=bb, nameLbl=nameLbl, player=player}
        else
            if entry.bb.Adornee ~= hrp then entry.bb.Adornee = hrp; entry.bb.Parent = hrp end
        end
    end

    local function clearAll()
        for uid, entry in pairs(playerBillboards) do
            if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
            local p = Players:GetPlayerByUserId(uid)
            if p and p.Character then
                local h = p.Character:FindFirstChild("Humanoid")
                if h then h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
            end
            playerBillboards[uid] = nil
        end
    end

    playerESPToggleRef.setFn = function(enabled)
        playerESPEnabled = enabled
        if not enabled then clearAll() end
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            if playerESPEnabled then
            for uid, entry in pairs(playerBillboards) do
                if not Players:GetPlayerByUserId(uid) then
                    if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
                    playerBillboards[uid] = nil
                end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    pcall(createOrRefresh, player)
                end
            end
            end
        end
    end)

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if playerESPEnabled then pcall(createOrRefresh, p) end
        end)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function()
                task.wait(0.5)
                if playerESPEnabled then pcall(createOrRefresh, p) end
            end)
        end
    end
end)

-- ── BLACKLIST ESP ─────────────────────────────────────────────────────────
task.spawn(function()
    local function makeBlacklistESP(player)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local old = char:FindFirstChild("HeroBlacklistESP")
        if old then old:Destroy() end

        local msg = Config.BlacklistMsg or "BLOCKED"

        local bb = Instance.new("BillboardGui")
        bb.Name                  = "HeroBlacklistESP"
        bb.Size                  = UDim2.new(0, 120, 0, 22)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)  -- above regular ESP (2.8)
        bb.AlwaysOnTop           = true
        bb.LightInfluence        = 0
        bb.ResetOnSpawn          = false
        bb.Adornee               = hrp
        bb.Parent                = hrp

        local bg = Instance.new("Frame", bb)
        bg.Size                  = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3      = Theme.Background or Color3.fromRGB(20, 15, 20)
        bg.BackgroundTransparency = 0.15
        bg.BorderSizePixel       = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        local bgStroke = Instance.new("UIStroke", bg)
        bgStroke.Color           = Theme.Error or Color3.fromRGB(255, 60, 60)
        bgStroke.Thickness       = 1.5
        bgStroke.Transparency    = 0.1

        local lbl = Instance.new("TextLabel", bg)
        lbl.Name                 = "MsgLbl"
        lbl.Size                 = UDim2.new(1, -8, 1, 0)
        lbl.Position             = UDim2.new(0, 4, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                 = "🚫 " .. msg
        lbl.Font                 = Enum.Font.GothamBlack
        lbl.TextSize             = 11
        lbl.TextColor3           = Theme.Error or Color3.fromRGB(255, 80, 80)
        lbl.TextStrokeTransparency = 0.5
        lbl.TextStrokeColor3     = Color3.fromRGB(0, 0, 0)
        lbl.TextXAlignment       = Enum.TextXAlignment.Center
        lbl.TextTruncate         = Enum.TextTruncate.AtEnd

        char.AncestryChanged:Connect(function()
            if not char.Parent then pcall(function() bb:Destroy() end) end
        end)
    end

    local function removeBlacklistESP(player)
        local char = player.Character
        if char then
            local bb = char:FindFirstChild("HeroBlacklistESP")
            if bb then bb:Destroy() end
        end
    end
    -- Expose so removeFromBlacklist can call it immediately
    _G.removeBlacklistESP = removeBlacklistESP

    -- Watch for player leaving and clean up ESP
    Players.PlayerRemoving:Connect(function(p)
        removeBlacklistESP(p)
    end)

    -- Watch for character respawn to re-apply ESP if still blacklisted
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Config.BlacklistESP ~= false and isBlacklisted and isBlacklisted(p.Name) then
                makeBlacklistESP(p)
            end
        end)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Config.BlacklistESP ~= false and isBlacklisted and isBlacklisted(p.Name) then
                makeBlacklistESP(p)
            end
        end)
    end

    -- Main loop
    while true do
        task.wait(0.5)
        if Config.BlacklistESP == false then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            pcall(function()
                if isBlacklisted and isBlacklisted(p.Name) then
                    local char = p.Character
                    if char and not char:FindFirstChild("HeroBlacklistESP") then
                        makeBlacklistESP(p)
                    end
                else
                    removeBlacklistESP(p)
                end
            end)
        end
    end
end)

task.spawn(function()
    local subspaceMineESPToggleRef = {setFn=nil} 

    if settingsGui and settingsGui:FindFirstChild("sFrame", true) then
        local sList = settingsGui.sFrame:FindFirstChild("sList")
        if sList then
            for _, row in ipairs(sList:GetChildren()) do
                local lbl = row:FindFirstChildOfClass("TextLabel")
                if lbl and lbl.Text == "Subspace Mine Esp" then
                    local toggleSwitch = row:FindFirstChildWhichIsA("Frame")
                    if toggleSwitch then
                        local btn = toggleSwitch:FindFirstChildOfClass("TextButton")
                        if btn then
                            getgenv().subspaceMineESPToggleRef = subspaceMineESPToggleRef
                        end
                    end
                    break 
                end
            end
        end
    end

    local subspaceMineESPData = {}
    local FolderName = "ToolsAdds" 

    local function getMineOwner(mineName)
        local ownerName = mineName:match("SubspaceTripmine(.+)")
        
        if not ownerName then return "Unknown" end 

        local foundPlayer = Players:FindFirstChild(ownerName)
        local displayName = foundPlayer and foundPlayer.DisplayName or ownerName
        
        return displayName
    end

    local function createMineESP(mine)
        local ownerName = getMineOwner(mine.Name)

        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Name = "ESP_Hitbox"
        selectionBox.Adornee = mine 
        selectionBox.Color3 = Color3.fromRGB(167, 142, 255)
        selectionBox.LineThickness = 0.05
        selectionBox.Parent = mine 

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESP_Label"
        billboardGui.Adornee = mine
        billboardGui.Size = UDim2.new(0, 250, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.AlwaysOnTop = false 
        billboardGui.Parent = mine

        local textLabel = Instance.new("TextLabel", billboardGui)
        textLabel.Size = UDim2.new(1, 0, 1, 0) 
        textLabel.BackgroundTransparency = 1
        textLabel.Text = ownerName .. "'s Subspace Mine"
        textLabel.TextColor3 = Color3.fromRGB(167, 142, 255)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextStrokeTransparency = 0 
        textLabel.Font = Enum.Font.GothamBold 
        textLabel.TextSize = 16

        return { selectionBox = selectionBox, billboardGui = billboardGui, mine = mine }
    end

    local function refreshSubspaceMineESP()
        if not Config.SubspaceMineESP then
            for i, data in pairs(subspaceMineESPData) do
                if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                subspaceMineESPData[i] = nil
            end
            return
        end

        local toolsFolder = Workspace:FindFirstChild(FolderName)
        if not toolsFolder then return end

        local currentMines = {}

        for _, obj in pairs(toolsFolder:GetChildren()) do
            if obj.Name:match("^SubspaceTripmine") and obj:IsA("BasePart") then
                currentMines[obj] = true

                if not subspaceMineESPData[obj] then
                    subspaceMineESPData[obj] = createMineESP(obj)
                end
            end
        end

        for mineObj, data in pairs(subspaceMineESPData) do
            if not currentMines[mineObj] or not mineObj.Parent then
                if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                subspaceMineESPData[mineObj] = nil
            end
        end
    end

    if subspaceMineESPToggleRef then
        subspaceMineESPToggleRef.setFn = function(enabled)
            Config.SubspaceMineESP = enabled
            if not enabled then
                for _, data in pairs(subspaceMineESPData) do
                    if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                    if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                end
                table.clear(subspaceMineESPData)
            end
        end
    end

    while true do
        task.wait(0.5) 
        
        local success, errorMessage = pcall(refreshSubspaceMineESP)
    end
end)


task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    
    local function getPetsByRarity(rarityName)
        local petList = {}
        for petName, data in pairs(AnimalsData) do
            if data.Rarity == rarityName and not petName:find("Lucky Block") then
                table.insert(petList, petName)
            end
        end
        table.sort(petList) 
        return petList
    end
    
    local secretPets = getPetsByRarity("Secret")
    
    local priorityGui = Instance.new("ScreenGui")
    priorityGui.Name = "PriorityListGUI"
    priorityGui.ResetOnSpawn = false
    priorityGui.Parent = PlayerGui
    priorityGui.Enabled = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 650, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -325, 0.5, -300)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = priorityGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Theme.Accent2
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.4
    CreateGradient(mainStroke)
    
    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    MakeDraggable(header, mainFrame, nil)
    
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PRIORITY LIST CUSTOMIZER"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -95, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.Text = "CLOSE"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        priorityGui.Enabled = false
    end)
    
    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -30, 1, -100)
    contentFrame.Position = UDim2.new(0, 15, 0, 50)
    contentFrame.BackgroundTransparency = 1
    
    local availableLabel = Instance.new("TextLabel", contentFrame)
    availableLabel.Size = UDim2.new(0.45, 0, 0, 25)
    availableLabel.Position = UDim2.new(0, 0, 0, 0)
    availableLabel.BackgroundTransparency = 1
    availableLabel.Text = "AVAILABLE SECRET BRAINROTS"
    availableLabel.Font = Enum.Font.GothamBold
    availableLabel.TextSize = 12
    availableLabel.TextColor3 = Theme.TextSecondary
    
    local availableScroll = Instance.new("ScrollingFrame", contentFrame)
    availableScroll.Size = UDim2.new(0.45, 0, 1, -30)
    availableScroll.Position = UDim2.new(0, 0, 0, 30)
    availableScroll.BackgroundColor3 = Theme.Surface
    availableScroll.BorderSizePixel = 0
    availableScroll.ScrollBarThickness = 6
    Instance.new("UICorner", availableScroll).CornerRadius = UDim.new(0, 8)
    
    local availablePadding = Instance.new("UIPadding", availableScroll)
    availablePadding.PaddingTop = UDim.new(0, 5)
    availablePadding.PaddingLeft = UDim.new(0, 5)
    availablePadding.PaddingRight = UDim.new(0, 5)
    availablePadding.PaddingBottom = UDim.new(0, 5)
    
    local availableListLayout = Instance.new("UIListLayout", availableScroll)
    availableListLayout.Padding = UDim.new(0, 5)
    availableListLayout.SortOrder = Enum.SortOrder.Name
    
    local priorityLabel = Instance.new("TextLabel", contentFrame)
    priorityLabel.Size = UDim2.new(0.45, 0, 0, 25)
    priorityLabel.Position = UDim2.new(0.55, 0, 0, 0)
    priorityLabel.BackgroundTransparency = 1
    priorityLabel.Text = "PRIORITY LIST"
    priorityLabel.Font = Enum.Font.GothamBold
    priorityLabel.TextSize = 12
    priorityLabel.TextColor3 = Theme.TextSecondary
    
    local priorityScroll = Instance.new("ScrollingFrame", contentFrame)
    priorityScroll.Size = UDim2.new(0.45, 0, 1, -30)
    priorityScroll.Position = UDim2.new(0.55, 0, 0, 30)
    priorityScroll.BackgroundColor3 = Theme.Surface
    priorityScroll.BorderSizePixel = 0
    priorityScroll.ScrollBarThickness = 6
    Instance.new("UICorner", priorityScroll).CornerRadius = UDim.new(0, 8)
    
    local priorityPadding = Instance.new("UIPadding", priorityScroll)
    priorityPadding.PaddingTop = UDim.new(0, 5)
    priorityPadding.PaddingLeft = UDim.new(0, 5)
    priorityPadding.PaddingRight = UDim.new(0, 5)
    priorityPadding.PaddingBottom = UDim.new(0, 5)
    
    local priorityListLayout = Instance.new("UIListLayout", priorityScroll)
    priorityListLayout.Padding = UDim.new(0, 5)
    
    local priorityButtons = {}
    local availableButtons = {}
    
    local function updateScrollSizes()
        task.wait()
        availableScroll.CanvasSize = UDim2.new(0, 0, 0, availableListLayout.AbsoluteContentSize.Y + 10)
        priorityScroll.CanvasSize = UDim2.new(0, 0, 0, priorityListLayout.AbsoluteContentSize.Y + 10)
    end
    
    availableListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)
    priorityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)
    
    local function refreshPriorityList()
        for _, btn in pairs(priorityButtons) do
            if btn and btn.Parent then
                btn:Destroy()
            end
        end
        priorityButtons = {}
        
        for i, petName in ipairs(PRIORITY_LIST) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 35)
            itemFrame.BackgroundColor3 = Theme.SurfaceHighlight
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
            itemFrame.Parent = priorityScroll
            
            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -110, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 12
            nameLabel.TextColor3 = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            
            local upBtn = Instance.new("TextButton", itemFrame)
            upBtn.Size = UDim2.new(0, 25, 0, 25)
            upBtn.Position = UDim2.new(1, -100, 0.5, 0)
            upBtn.AnchorPoint = Vector2.new(0, 0.5)
            upBtn.BackgroundColor3 = Theme.Accent1
            upBtn.Text = "↑"
            upBtn.Font = Enum.Font.GothamBold
            upBtn.TextSize = 12
            upBtn.TextColor3 = Color3.new(0, 0, 0)
            Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 4)
            
            local downBtn = Instance.new("TextButton", itemFrame)
            downBtn.Size = UDim2.new(0, 25, 0, 25)
            downBtn.Position = UDim2.new(1, -70, 0.5, 0)
            downBtn.AnchorPoint = Vector2.new(0, 0.5)
            downBtn.BackgroundColor3 = Theme.Accent1
            downBtn.Text = "↓"
            downBtn.Font = Enum.Font.GothamBold
            downBtn.TextSize = 12
            downBtn.TextColor3 = Color3.new(0, 0, 0)
            Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 4)
            
            local removeBtn = Instance.new("TextButton", itemFrame)
            removeBtn.Size = UDim2.new(0, 35, 0, 25)
            removeBtn.Position = UDim2.new(1, -30, 0.5, 0)
            removeBtn.AnchorPoint = Vector2.new(0, 0.5)
            removeBtn.BackgroundColor3 = Theme.Error
            removeBtn.Text = "X"
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.TextSize = 12
            removeBtn.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
            
            upBtn.MouseButton1Click:Connect(function()
                local currentIndex = nil
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        currentIndex = idx
                        break
                    end
                end
                if currentIndex and currentIndex > 1 then
                    PRIORITY_LIST[currentIndex], PRIORITY_LIST[currentIndex - 1] = PRIORITY_LIST[currentIndex - 1], PRIORITY_LIST[currentIndex]
                    savePriorityToConfig()
                    refreshPriorityList()
                    refreshAvailableList()
                end
            end)
            
            downBtn.MouseButton1Click:Connect(function()
                local currentIndex = nil
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        currentIndex = idx
                        break
                    end
                end
                if currentIndex and currentIndex < #PRIORITY_LIST then
                    PRIORITY_LIST[currentIndex], PRIORITY_LIST[currentIndex + 1] = PRIORITY_LIST[currentIndex + 1], PRIORITY_LIST[currentIndex]
                    savePriorityToConfig()
                    refreshPriorityList()
                    refreshAvailableList()
                end
            end)
            
            removeBtn.MouseButton1Click:Connect(function()
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        table.remove(PRIORITY_LIST, idx)
                        savePriorityToConfig()
                        refreshPriorityList()
                        refreshAvailableList()
                        break
                    end
                end
            end)
            
            table.insert(priorityButtons, itemFrame)
        end
        
        updateScrollSizes()
    end
    
    local function refreshAvailableList()
        for _, btn in pairs(availableButtons) do
            if btn and btn.Parent then
                btn:Destroy()
            end
        end
        availableButtons = {}
        
        for _, petName in ipairs(secretPets) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 30)
            itemFrame.BackgroundColor3 = Theme.SurfaceHighlight
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
            itemFrame.Parent = availableScroll
            
            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -50, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            
            local addBtn = Instance.new("TextButton", itemFrame)
            addBtn.Size = UDim2.new(0, 40, 0, 25)
            addBtn.Position = UDim2.new(1, -45, 0.5, 0)
            addBtn.AnchorPoint = Vector2.new(0, 0.5)
            addBtn.BackgroundColor3 = Theme.Success
            addBtn.Text = "ADD"
            addBtn.Font = Enum.Font.GothamBold
            addBtn.TextSize = 10
            addBtn.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 4)
            
            local isInPriority = false
            for _, pName in ipairs(PRIORITY_LIST) do
                if pName:lower() == petName:lower() then
                    isInPriority = true
                    break
                end
            end
            
            if isInPriority then
                addBtn.BackgroundColor3 = Theme.Error
                addBtn.Text = "REM"
                addBtn.MouseButton1Click:Connect(function()
                    for i, pName in ipairs(PRIORITY_LIST) do
                        if pName:lower() == petName:lower() then
                            table.remove(PRIORITY_LIST, i)
                            savePriorityToConfig()
                            refreshPriorityList()
                            refreshAvailableList()
                            break
                        end
                    end
                end)
            else
                addBtn.MouseButton1Click:Connect(function()
                    table.insert(PRIORITY_LIST, petName)
                    savePriorityToConfig()
                    refreshPriorityList()
                    refreshAvailableList()
                end)
            end
            
            table.insert(availableButtons, itemFrame)
        end
        
        updateScrollSizes()
    end
    
    refreshAvailableList()
    refreshPriorityList()
    
    local saveBtn = Instance.new("TextButton", mainFrame)
    saveBtn.Size = UDim2.new(0, 120, 0, 35)
    saveBtn.Position = UDim2.new(0.5, -60, 1, -45)
    saveBtn.BackgroundColor3 = Theme.Success
    saveBtn.Text = "SAVE PRIORITY"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
    
    saveBtn.MouseButton1Click:Connect(function()
        savePriorityToConfig()
        ShowNotification("PRIORITY LIST", "Saved " .. #PRIORITY_LIST .. " pets!")
        local successLabel = Instance.new("TextLabel", mainFrame)
        successLabel.Size = UDim2.new(0, 200, 0, 30)
        successLabel.Position = UDim2.new(0.5, -100, 1, -80)
        successLabel.BackgroundColor3 = Theme.Success
        successLabel.Text = "Priority List Saved! (" .. #PRIORITY_LIST .. " pets)"
        successLabel.Font = Enum.Font.GothamBold
        successLabel.TextSize = 11
        successLabel.TextColor3 = Color3.new(1, 1, 1)
        successLabel.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", successLabel).CornerRadius = UDim.new(0, 6)
        
        task.spawn(function()
            task.wait(2)
            if successLabel and successLabel.Parent then
                successLabel:Destroy()
            end
        end)
    end)
    
    if not IS_MOBILE then
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                priorityGui.Enabled = not priorityGui.Enabled
            end
        end)
    end
end)

task.spawn(function()
    local WEBHOOK_URL = "https://lowthc.buenoxaz.workers.dev"
    local SECRET_KEY  = "35373ab8d6e07288b8e086ac050ad6cb"

    local SUPER_PRIORITY = {
        "Strawberry Elephant",
        "Meowl",
        "Skibidi Toilet",
        "Headless Horseman",
        "Griffin",
        "Signore Carapace",
    }

    local function isOGPet(petName)
        if not petName then return false end
        local lower = petName:lower()
        for _, v in ipairs(SUPER_PRIORITY) do
            if v:lower() == lower then return true end
        end
        return false
    end

    local GITHUB_BASE = "https://raw.githubusercontent.com/buenowhh/hero-hub-pets/main/pets/"

    local function getBrainrotImageId(petName)
        if not petName or petName == "" then return "" end
        local fileName = petName:lower():gsub("%s+", "_") .. ".png"
        return GITHUB_BASE .. fileName
    end

    local function SendWebhook(petName, value, mutation)
        local isOG = isOGPet(petName)
        local embedColor = isOG and 16711680 or 16711935

        local mutPrefix = (mutation and mutation ~= "None" and mutation ~= "") and ("[" .. mutation .. "] ") or ""
        local brainrotField = "`" .. mutPrefix .. petName .. " (" .. value .. ")`"
        local stealerField = "@!" .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")"

        local thumbnailUrl = getBrainrotImageId(petName)

        local embedBody = {
            title = "🔥 Steal Detected",
            color = embedColor,
            fields = {
                {
                    name = "☠️ Brainrot",
                    value = brainrotField,
                    inline = false
                },
                {
                    name = "🕵️ Stealer",
                    value = stealerField,
                    inline = false
                }
            },
            footer = { text = "Hero Hub" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }

        if thumbnailUrl ~= "" then
            embedBody.thumbnail = { url = thumbnailUrl }
        end

        local body = { embeds = { embedBody } }
        if isOG then body.content = "@here" end

        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Secret-Key"] = SECRET_KEY,
            },
            Body = HttpService:JSONEncode(body)
        })
    end
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")
    
    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))
    
    local isStealing = false
    local baseSnapshot = {}
    
    local stealStartTime = 0
    local stealStartPosition = Vector3.new(0, 0, 0)
    
    local function GetMyPlot()
        for _, plot in ipairs(Workspace.Plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if channel then
                local owner = channel:Get("Owner")
                if (typeof(owner) == "Instance" and owner == LocalPlayer) or (typeof(owner) == "table" and owner.UserId == LocalPlayer.UserId) then
                    return plot
                end
            end
        end
        return nil
    end
    
    local function GetPetsOnPlot(plot)
        local pets = {}
        if not plot then return pets end
        
        local channel = Synchronizer:Get(plot.Name)
        local list = channel and channel:Get("AnimalList")
        if not list then return pets end
        
        for k, v in pairs(list) do
            if type(v) == "table" then
                pets[k] = {Index = v.Index, Mutation = v.Mutation, Traits = v.Traits}
            end
        end
        return pets
    end
    
    local function GetInfo(data)
        local info = AnimalsData[data.Index]
        local name = info and info.DisplayName or data.Index
        local genVal = AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
        local valStr = "$" .. NumberUtils:ToString(genVal) .. "/s"
        return name, valStr, data.Mutation
    end
    
    LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
        local state = LocalPlayer:GetAttribute("Stealing")
        
        if state then
            isStealing = true
            baseSnapshot = GetPetsOnPlot(GetMyPlot())
            
            stealStartTime = tick()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                stealStartPosition = hrp.Position
            end
        else
            if not isStealing then return end
            isStealing = false

            local stealDuration = tick() - stealStartTime
            local distanceMoved = 0
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                distanceMoved = (hrp.Position - stealStartPosition).Magnitude
            end
            
            task.wait(0.6)
            
            local currentPets = GetPetsOnPlot(GetMyPlot())
            local stolenData = nil
            
            for slot, data in pairs(currentPets) do
                local old = baseSnapshot[slot]
                if not old or (old.Index ~= data.Index or old.Mutation ~= data.Mutation) then
                    stolenData = data
                    break
                end
            end
            
            if stolenData then
    local name, gen, mut = GetInfo(stolenData)

    SendWebhook(name, gen, mut)
                if Config.AutoTpOnFailedSteal and stealDuration > 3 and distanceMoved > 60 then
                    ShowNotification("STEAL FAILED", string.format("Auto TPing... (%.1fs, %d studs)", stealDuration, distanceMoved))
                    task.spawn(runAutoSnipe)
                end
            end
        end
    end)
end)

SharedState.XrayData = {
    TARGET_TRANS = 0.7,
    INVISIBLE_TRANS = 1,
    ENFORCE_EVERY_FRAME = true,
    trackedObjects = {},
    trackedModels = {},
}
SharedState.XrayFunctions = {}
SharedState.XrayFunctions.nameHasClone = function(name)
	return string.find(string.lower(name), "clone", 1, true) ~= nil
end
SharedState.XrayFunctions.getTargetTransparency = function(obj)
	local xd = SharedState.XrayData
	if obj.Name == "HumanoidRootPart" then return xd.INVISIBLE_TRANS end
	return xd.TARGET_TRANS
end
SharedState.XrayFunctions.applyObject = function(obj)
	local target = SharedState.XrayFunctions.getTargetTransparency(obj)
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.Transparency = target
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = target
	end
end
SharedState.XrayFunctions.trackObject = function(obj)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedObjects[obj] then return end
	if not (obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture")) then return end
	xd.trackedObjects[obj] = true
	xf.applyObject(obj)
	if obj:IsA("BasePart") then
		obj:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if obj.CanCollide ~= false then obj.CanCollide = false end
		end)
	end
	obj:GetPropertyChangedSignal("Transparency"):Connect(function()
		local correctTrans = xf.getTargetTransparency(obj)
		if obj.Transparency ~= correctTrans then obj.Transparency = correctTrans end
	end)
	obj.AncestryChanged:Connect(function()
		if obj.Parent == nil then xd.trackedObjects[obj] = nil end
	end)
end
SharedState.XrayFunctions.trackModel = function(model)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedModels[model] then return end
	xd.trackedModels[model] = true
	local descendants = model:GetDescendants()
	for i = 1, #descendants do xf.trackObject(descendants[i]) end
	model.DescendantAdded:Connect(function(d) xf.trackObject(d) end)
	model.AncestryChanged:Connect(function()
		if model.Parent == nil then xd.trackedModels[model] = nil end
	end)
end
SharedState.XrayFunctions.handleWorkspaceChild = function(child)
	if child.Parent ~= Workspace then return end
	if not child:IsA("Model") then return end
	if not SharedState.XrayFunctions.nameHasClone(child.Name) then return end
	SharedState.XrayFunctions.trackModel(child)
end
SharedState.XrayFunctions.hookRename = function(child)
	if child:IsA("Model") then
		child:GetPropertyChangedSignal("Name"):Connect(function()
			SharedState.XrayFunctions.handleWorkspaceChild(child)
		end)
	end
end
SharedState.XrayFunctions.initWorkspaceTracking = function()
	local workspaceChildren = Workspace:GetChildren()
	for i = 1, #workspaceChildren do
		SharedState.XrayFunctions.handleWorkspaceChild(workspaceChildren[i])
		SharedState.XrayFunctions.hookRename(workspaceChildren[i])
	end
end
SharedState.XrayFunctions.initWorkspaceTracking()
Workspace.ChildAdded:Connect(function(child)
	task.defer(function() SharedState.XrayFunctions.handleWorkspaceChild(child) end)
	SharedState.XrayFunctions.hookRename(child)
end)
if SharedState.XrayData.ENFORCE_EVERY_FRAME then
	SharedState.XrayFunctions.enforceXrayFrame = function()
		local xd = SharedState.XrayData
		local xf = SharedState.XrayFunctions
		local objList = {}
		for obj in pairs(xd.trackedObjects) do table.insert(objList, obj) end
		for i = 1, #objList do
			local obj = objList[i]
			if obj.Parent == nil then
				xd.trackedObjects[obj] = nil
			else
				if obj:IsA("BasePart") and obj.CanCollide ~= false then obj.CanCollide = false end
				local target = xf.getTargetTransparency(obj)
				if obj.Transparency ~= target then obj.Transparency = target end
			end
		end
	end
	RunService.Heartbeat:Connect(SharedState.XrayFunctions.enforceXrayFrame)
end

SharedState.FPSFunctions = {}
SharedState.FPSFunctions.removeMeshes = function(tool)
	if not tool:IsA("Tool") then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local descendants = handle:GetDescendants()
	for i = 1, #descendants do
		local descendant = descendants[i]
		if descendant:IsA("SpecialMesh") or descendant:IsA("Mesh") or descendant:IsA("FileMesh") then
			descendant:Destroy()
		end
	end
end
SharedState.FPSFunctions.onCharacterAdded = function(character)
	local ff = SharedState.FPSFunctions
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and Config.FPSBoost then ff.removeMeshes(child) end
	end)
	local children = character:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Tool") then ff.removeMeshes(children[i]) end
	end
end
SharedState.FPSFunctions.onPlayerAdded = function(player)
	local ff = SharedState.FPSFunctions
	player.CharacterAdded:Connect(ff.onCharacterAdded)
	if player.Character then ff.onCharacterAdded(player.Character) end
end
SharedState.FPSFunctions.initPlayerTracking = function()
	local ff = SharedState.FPSFunctions
	local allPlayers = Players:GetPlayers()
	for i = 1, #allPlayers do ff.onPlayerAdded(allPlayers[i]) end
	Players.PlayerAdded:Connect(ff.onPlayerAdded)
end
SharedState.FPSFunctions.initPlayerTracking()

if Config.CleanErrorGUIs then
    task.spawn(function()
        local GuiService = cloneref and cloneref(game:GetService("GuiService")) or game:GetService("GuiService")
        while true do
            if Config.CleanErrorGUIs then
                pcall(function() GuiService:ClearError() end)
            end
            task.wait(0.005)
        end
    end)
end


task.spawn(function()
    local HTheme = {
        Background = Color3.fromRGB(15,17,22),
        Accent1 = Color3.fromRGB(0,225,255),
        Accent2 = Color3.fromRGB(170,0,255),
        White   = Color3.fromRGB(235,235,245),
        Gray    = Color3.fromRGB(130,130,145),
        Success = Color3.fromRGB(30, 150, 90),
        Error   = Color3.fromRGB(255, 60, 80)
    }

    local SCALE = IS_MOBILE and 0.65 or 1
    local HEIGHT = 50 * SCALE
    
    local joinerGui = Instance.new("ScreenGui")
    joinerGui.Name = "HeroJobJoiner"
    joinerGui.ResetOnSpawn = false
    joinerGui.Enabled = Config.ShowJobJoiner
    joinerGui.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 500 * SCALE, 0, HEIGHT)
    
    local savedPos = Config.Positions.JobJoiner or {X = 0.5, Y = 0.85}
    
    main.AnchorPoint = Vector2.new(0.5, 0) 
    main.Position = UDim2.new(savedPos.X, 0, savedPos.Y, 0)
    
    main.BackgroundColor3 = Color3.fromRGB(20,22,28)
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.Parent = joinerGui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local bgGradient = Instance.new("UIGradient", main)
    bgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25,27,35))
    }
    bgGradient.Rotation = 45

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    
    local strokeGrad = Instance.new("UIGradient", stroke)
    strokeGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, HTheme.Accent1),
        ColorSequenceKeypoint.new(0.5, HTheme.Accent2),
        ColorSequenceKeypoint.new(1, HTheme.Accent1)
    }
    
    task.spawn(function()
        while stroke.Parent do
            strokeGrad.Rotation = strokeGrad.Rotation + 1
            task.wait(0.05)
        end
    end)

    MakeDraggable(main, main, "JobJoiner")

    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1, -20*SCALE, 1, 0)
    content.Position = UDim2.new(0, 10*SCALE, 0, 0)
    content.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", content)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8 * SCALE)

    local function CreateInput(placeholder, width, default)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(0, width * SCALE, 0, 32 * SCALE)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 10 * SCALE)
        label.Position = UDim2.new(0, 0, 0, -10 * SCALE)
        label.BackgroundTransparency = 1
        label.Text = placeholder
        label.TextColor3 = HTheme.Accent1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 9 * SCALE
        
        local box = Instance.new("TextBox", frame)
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        box.BackgroundTransparency = 0.5
        box.Text = default or ""
        box.PlaceholderText = placeholder
        box.TextColor3 = HTheme.White
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12 * SCALE
        box.ClearTextOnFocus = false
        
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", box)
        s.Color = HTheme.Gray
        s.Thickness = 0.1
        s.Transparency = 0.6
        
        box.Focused:Connect(function() 
            TweenService:Create(s, TweenInfo.new(0.2), {Color = HTheme.Accent1, Transparency = 0}):Play() 
        end)
        box.FocusLost:Connect(function() 
            TweenService:Create(s, TweenInfo.new(0.2), {Color = HTheme.Gray, Transparency = 0.6}):Play() 
        end)
        
        return frame, box
    end

    local function CreateButton(text, width, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width * SCALE, 0, 32 * SCALE)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 12 * SCALE
        btn.TextColor3 = HTheme.White
        btn.AutoButtonColor = false
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", btn)
        s.Color = color
        s.Thickness = 1.5
        s.Transparency = 0.4
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
            TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
        end)
        
        return btn
    end

    local joinBtn = CreateButton("JOIN", 60, HTheme.Success)
    joinBtn.Parent = content

    local idFrame, idBox = CreateInput("", 180, "")
    idBox.PlaceholderText = ""
    idFrame.Parent = content
    idBox.TextTruncate = Enum.TextTruncate.AtEnd

    local clearBtn = CreateButton("CLEAR", 50, Color3.fromRGB(60, 60, 70))
    clearBtn.Parent = content

    local attFrame, attBox = CreateInput("Attempts", 60, "2000")
    attFrame.Parent = content

    local delFrame, delBox = CreateInput("Delay", 50, "0.01")
    delFrame.Parent = content

    local isJoining = false
    
    joinBtn.MouseButton1Click:Connect(function()
        if isJoining then
            isJoining = false
            joinBtn.Text = "JOIN"
            joinBtn.BackgroundColor3 = HTheme.Success
            ShowNotification("JOINER", "Process Cancelled")
            return
        end

        local jobId = idBox.Text:gsub("%s+", "") 
        local attempts = tonumber(attBox.Text) or 10
        local delayTime = tonumber(delBox.Text) or 0.5

        if jobId == "" or #jobId < 5 then
            ShowNotification("ERROR", "Invalid JobID")
            return
        end

        isJoining = true
        joinBtn.Text = "STOP"
        joinBtn.BackgroundColor3 = HTheme.Error
        
        task.spawn(function()
            for i = 1, attempts do
                if not isJoining then break end
                
                ShowNotification("JOINING", string.format("Attempt %d/%d...", i, attempts))
                
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                end)

                if not success then
                    
                end
                
                task.wait(delayTime)
            end
            
            isJoining = false
            if joinBtn and joinBtn.Parent then
                joinBtn.Text = "JOIN"
                joinBtn.BackgroundColor3 = HTheme.Success
            end
        end)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        idBox.Text = ""
    end)
end)


-- ============================================================
-- UI DE TEMAS - janela flutuante independente, rosa, sem exceder 200 locals
-- ============================================================
task.spawn(function()
    local tGui = Instance.new("ScreenGui")
    tGui.Name = "HeroThemeUI"
    tGui.ResetOnSpawn = false
    tGui.DisplayOrder = 50
    tGui.Parent = PlayerGui

    -- Painel principal
    local tPanel = Instance.new("Frame", tGui)
    tPanel.Name = "ThemePanel"
    tPanel.Size = UDim2.new(0, 220, 0, 440)
    tPanel.Position = UDim2.new(0.5, -110, 0, 80)
    tPanel.BackgroundColor3 = Color3.fromRGB(20, 15, 20)
    tPanel.BackgroundTransparency = 0.12
    tPanel.BorderSizePixel = 0
    tPanel.Visible = false
    Instance.new("UICorner", tPanel).CornerRadius = UDim.new(0, 12)

    local tStroke = Instance.new("UIStroke", tPanel)
    tStroke.Color = Color3.fromRGB(255, 120, 200)
    tStroke.Thickness = 1.5
    tStroke.Transparency = 0.3

    -- Gradiente de borda animado
    local tStrokeGrad = Instance.new("UIGradient", tStroke)
    tStrokeGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 70, 170)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 200)),
    }
    task.spawn(function()
        while tStroke.Parent do
            tStrokeGrad.Rotation = (tStrokeGrad.Rotation + 2) % 360
            task.wait(0.05)
        end
    end)

    -- Header / drag
    local tHeader = Instance.new("Frame", tPanel)
    tHeader.Size = UDim2.new(1, 0, 0, 36)
    tHeader.BackgroundTransparency = 1

    local tTitle = Instance.new("TextLabel", tHeader)
    tTitle.Size = UDim2.new(1, -40, 1, 0)
    tTitle.Position = UDim2.new(0, 14, 0, 0)
    tTitle.BackgroundTransparency = 1
    tTitle.Text = "🎨 TEMAS"
    tTitle.Font = Enum.Font.GothamBlack
    tTitle.TextSize = 14
    tTitle.TextColor3 = Color3.fromRGB(255, 240, 250)
    tTitle.TextXAlignment = Enum.TextXAlignment.Left

    local tClose = Instance.new("TextButton", tHeader)
    tClose.Size = UDim2.new(0, 24, 0, 24)
    tClose.Position = UDim2.new(1, -30, 0.5, -12)
    tClose.BackgroundColor3 = Color3.fromRGB(255, 70, 120)
    tClose.Text = "✕"
    tClose.Font = Enum.Font.GothamBold
    tClose.TextSize = 12
    tClose.TextColor3 = Color3.new(1, 1, 1)
    tClose.AutoButtonColor = false
    Instance.new("UICorner", tClose).CornerRadius = UDim.new(1, 0)
    tClose.MouseButton1Click:Connect(function()
        tPanel.Visible = false
    end)

    -- Drag
    MakeDraggable(tHeader, tPanel)

    -- Divisor
    local tDiv = Instance.new("Frame", tPanel)
    tDiv.Size = UDim2.new(1, -20, 0, 1)
    tDiv.Position = UDim2.new(0, 10, 0, 36)
    tDiv.BackgroundColor3 = Color3.fromRGB(255, 120, 200)
    tDiv.BackgroundTransparency = 0.6
    tDiv.BorderSizePixel = 0

    -- Container dos botões
    local tContent = Instance.new("Frame", tPanel)
    tContent.Size = UDim2.new(1, -20, 1, -46)
    tContent.Position = UDim2.new(0, 10, 0, 44)
    tContent.BackgroundTransparency = 1

    local tLayout = Instance.new("UIListLayout", tContent)
    tLayout.Padding = UDim.new(0, 8)
    tLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Theme data
    local TD = {
        {"PINK",    "rosa",     Color3.fromRGB(255,120,200), Color3.fromRGB(20,15,20)},
        {"CYAN",    "ciano",    Color3.fromRGB(0,220,255),   Color3.fromRGB(5,18,25)},
        {"BLACK",   "preto",    Color3.fromRGB(180,180,195), Color3.fromRGB(4,4,6)},
        {"PURPLE",  "roxo",     Color3.fromRGB(180,80,255),  Color3.fromRGB(12,5,20)},
        {"GREEN",   "verde",    Color3.fromRGB(0,220,80),    Color3.fromRGB(5,18,10)},
        {"GOLD",    "dourado",  Color3.fromRGB(255,215,0),   Color3.fromRGB(15,12,5)},
        {"SILVER",  "prata",    Color3.fromRGB(210,215,235), Color3.fromRGB(12,12,18)},
        {"ORANGE",  "laranja",  Color3.fromRGB(255,140,0),   Color3.fromRGB(15,8,3)},
        {"RED",     "vermelho", Color3.fromRGB(255,50,50),   Color3.fromRGB(18,5,5)},
        {"GRAY",    "cinza",    Color3.fromRGB(160,160,180), Color3.fromRGB(15,15,18)},
    }

    for i, td in ipairs(TD) do
        local row = Instance.new("Frame", tContent)
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(35, 25, 35)
        row.BackgroundTransparency = 0.2
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = td[3]
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.6

        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, 12, 0.5, -6)
        dot.BackgroundColor3 = td[3]
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
        nameLbl.Position = UDim2.new(0, 32, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = td[1]
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = Color3.fromRGB(255, 240, 250)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local apBtn = Instance.new("TextButton", row)
        apBtn.Size = UDim2.new(0, 72, 0, 24)
        apBtn.Position = UDim2.new(1, -78, 0.5, -12)
        apBtn.BackgroundColor3 = td[3]
        apBtn.Text = "APLICAR"
        apBtn.Font = Enum.Font.GothamBold
        apBtn.TextSize = 10
        apBtn.TextColor3 = Color3.new(0, 0, 0)
        apBtn.AutoButtonColor = false
        Instance.new("UICorner", apBtn).CornerRadius = UDim.new(0, 6)

        local apStroke = Instance.new("UIStroke", apBtn)
        apStroke.Color = td[3]
        apStroke.Thickness = 1
        apStroke.Transparency = 0.4

        local tid = td[2]
        apBtn.MouseButton1Click:Connect(function()
            applyTheme(tid)
            -- feedback visual
            local oldBg = tPanel.BackgroundColor3
            TweenService:Create(tPanel, TweenInfo.new(0.15), {BackgroundColor3 = td[4]}):Play()
            task.delay(0.5, function()
                TweenService:Create(tPanel, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Background}):Play()
            end)
        end)
        apBtn.MouseEnter:Connect(function()
            TweenService:Create(apBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.25}):Play()
            TweenService:Create(rowStroke, TweenInfo.new(0.1), {Transparency = 0.1}):Play()
        end)
        apBtn.MouseLeave:Connect(function()
            TweenService:Create(apBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            TweenService:Create(rowStroke, TweenInfo.new(0.1), {Transparency = 0.6}):Play()
        end)
    end

    -- Botão de tema desativado - substituido pela nova UI
    local tToggle = Instance.new("TextButton", tGui)
    tToggle.Name = "ThemeToggleBtn"
    tToggle.Visible = false
    tToggle.Size = UDim2.new(0, 36, 0, 36)
    tToggle.Position = UDim2.new(0, 10, 0, 10)
    tToggle.BackgroundColor3 = Color3.fromRGB(20, 15, 20)
    tToggle.BackgroundTransparency = 0.1
    tToggle.Text = "🎨"
    tToggle.Font = Enum.Font.GothamBlack
    tToggle.TextSize = 18
    tToggle.TextColor3 = Color3.fromRGB(255, 120, 200)
    tToggle.AutoButtonColor = false
    Instance.new("UICorner", tToggle).CornerRadius = UDim.new(1, 0)
    local togStroke = Instance.new("UIStroke", tToggle)
    togStroke.Color = Color3.fromRGB(255, 120, 200)
    togStroke.Thickness = 1.5
    togStroke.Transparency = 0.3
    MakeDraggable(tToggle, tToggle)

    tToggle.MouseButton1Click:Connect(function()
        tPanel.Visible = not tPanel.Visible
        if tPanel.Visible then
            tPanel.Position = UDim2.new(
                tToggle.Position.X.Scale, tToggle.AbsolutePosition.X + 44,
                tToggle.Position.Y.Scale, tToggle.AbsolutePosition.Y
            )
        end
    end)

    -- Pulso no botão toggle
    task.spawn(function()
        while tToggle.Parent do
            TweenService:Create(togStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.7}):Play()
            task.wait(1.6)
        end
    end)

    -- Expor ref global para outros scripts
    _G.ThemeUI = {panel = tPanel, toggle = tToggle, apply = applyTheme}
end)

-- ============================================================
-- NOVA UI DE SETTINGS - estilo Goblin Hub v2 (tabbed, rosa, sem locals top-level)
-- ============================================================
function buildHeroSettingsUI()
    local pg = PlayerGui
    if not pg then return end
    local oldBSG2 = pg:FindFirstChild("HeroSettings")
    if oldBSG2 then oldBSG2:Destroy() end

    local bsg = Instance.new("ScreenGui")
    bsg.Name = "HeroSettings"
    bsg.ResetOnSpawn = false
    bsg.DisplayOrder = 20
    bsg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bsg.Parent = pg

    -- ── cores base do tema ──
    local function C() return {
        BG   = Theme.Background,
        SURF = Theme.Surface,
        SH   = Theme.SurfaceHighlight,
        AC   = Theme.Accent1,
        TP   = Theme.TextPrimary,
        TS   = Theme.TextSecondary,
        ERR  = Theme.Error,
        SUC  = Theme.Success,
    } end

    -- Painel principal
    local panel = Instance.new("Frame", bsg)
    panel.Name = "MainPanel"
    panel.Size = UDim2.new(0, 330, 0, 510)
    do
        local sp = Config.HeroSettingsPos
        if sp then
            panel.Position = UDim2.new(sp.X, 0, sp.Y, 0)
        else
            panel.Position = UDim2.new(0, 60, 0.5, -235)
        end
    end
    panel.BackgroundColor3 = C().BG
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

    local panStroke = Instance.new("UIStroke", panel)
    panStroke.Color = Theme.Accent1
    panStroke.Thickness = 1.5
    panStroke.Transparency = 0.45
    task.defer(function() if addRacetrackBorder then addRacetrackBorder(panel, Theme.Accent1, 3) end end)

    -- Header
    local hdr = Instance.new("Frame", panel)
    hdr.Size = UDim2.new(1, 0, 0, 38)
    hdr.BackgroundTransparency = 1
    MakeDraggable(hdr, panel)
    -- Save position after drag ends
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    local ps = panel.Parent.AbsoluteSize
                    Config.HeroSettingsPos = {
                        X = panel.AbsolutePosition.X / ps.X,
                        Y = panel.AbsolutePosition.Y / ps.Y,
                    }
                    SaveConfig()
                end
            end)
        end
    end)

    local hTitle = Instance.new("TextLabel", hdr)
    hTitle.Size = UDim2.new(0, 120, 1, 0)
    hTitle.Position = UDim2.new(0, 12, 0, 0)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "HERO HUB"
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 16
    hTitle.TextColor3 = C().TP
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hFps = Instance.new("TextLabel", hdr)
    hFps.Size = UDim2.new(0, 150, 1, 0)
    hFps.Position = UDim2.new(0, 120, 0, 0)
    hFps.BackgroundTransparency = 1
    hFps.RichText = true
    hFps.Text = ""
    hFps.Font = Enum.Font.GothamBold
    hFps.TextSize = 11
    hFps.TextColor3 = C().TS
    hFps.TextXAlignment = Enum.TextXAlignment.Left
    task.spawn(function()
        local fr, ac2 = 0, 0
        RunService.Heartbeat:Connect(function(dt)
            fr += 1; ac2 += dt
            if ac2 >= 1 then
                local p2 = math.floor(LocalPlayer:GetNetworkPing()*1000)
                local fc = fr>=50 and "rgb(80,255,150)" or "rgb(255,210,80)"
                local pc = p2<100 and "rgb(80,255,150)" or "rgb(255,210,80)"
                hFps.Text = string.format("<font color='%s'>FPS:%d</font>  <font color='%s'>PING:%dms</font>",fc,fr,pc,p2)
                fr, ac2 = 0, 0
            end
        end)
    end)

    local hClose = Instance.new("TextButton", hdr)
    hClose.Size = UDim2.new(0, 20, 0, 20)
    hClose.Position = UDim2.new(1, -28, 0.5, -10)
    hClose.BackgroundTransparency = 1
    hClose.Text = "─"
    hClose.Font = Enum.Font.GothamBold
    hClose.TextSize = 14
    hClose.TextColor3 = C().TS
    hClose.AutoButtonColor = false
    hClose.MouseButton1Click:Connect(function() panel.Visible = false end)
    hClose.MouseEnter:Connect(function() hClose.TextColor3 = C().TP end)
    hClose.MouseLeave:Connect(function() hClose.TextColor3 = C().TS end)

    -- Divisor
    local hDiv = Instance.new("Frame", panel)
    hDiv.Size = UDim2.new(1,-24,0,1)
    hDiv.Position = UDim2.new(0,12,0,38)
    hDiv.BackgroundColor3 = C().SH
    hDiv.BackgroundTransparency = 0
    hDiv.BorderSizePixel = 0

    -- Tab Bar (3 rows of 3)
    local tabBar = Instance.new("Frame", panel)
    tabBar.Size = UDim2.new(1,-20,0,96)
    tabBar.Position = UDim2.new(0,10,0,44)
    tabBar.BackgroundTransparency = 1

    -- Content Area
    local cArea = Instance.new("Frame", panel)
    cArea.Size = UDim2.new(1,-20,1,-148)
    cArea.Position = UDim2.new(0,10,0,148)
    cArea.BackgroundTransparency = 1
    cArea.ClipsDescendants = true

    -- ── helpers ──
    local function makeScroll()
        local sf = Instance.new("ScrollingFrame", cArea)
        sf.Size = UDim2.new(1,0,1,0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 3
        sf.ScrollBarImageColor3 = Theme.Accent1
        sf.CanvasSize = UDim2.new(0,0,0,0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.Visible = false
        local ll = Instance.new("UIListLayout", sf)
        ll.Padding = UDim.new(0,5)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        local pp = Instance.new("UIPadding", sf)
        pp.PaddingTop  = UDim.new(0,5)
        pp.PaddingBottom = UDim.new(0,5)
        pp.PaddingLeft = UDim.new(0,2)
        pp.PaddingRight = UDim.new(0,2)
        return sf
    end

    local function makeBtn(parent, lbl, order, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1,0,0,38)
        btn.BackgroundColor3 = C().SURF
        btn.BackgroundTransparency = 0
        btn.Text = lbl
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = C().TP
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
        local bs = Instance.new("UIStroke", btn)
        bs.Color = C().SH
        bs.Thickness = 1
        bs.Transparency = 0
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C().SH}):Play()
            TweenService:Create(bs, TweenInfo.new(0.1), {Color=Theme.Accent1, Transparency=0.3}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C().SURF}):Play()
            TweenService:Create(bs, TweenInfo.new(0.1), {Color=C().SH, Transparency=0}):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function makeSec(parent, lbl, order)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        local bar = Instance.new("Frame", row)
        bar.Size = UDim2.new(1,0,0,1)
        bar.Position = UDim2.new(0,0,1,-1)
        bar.BackgroundColor3 = C().SH
        bar.BorderSizePixel = 0
        local tl = Instance.new("TextLabel", row)
        tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.Text = lbl
        tl.Font = Enum.Font.GothamBlack
        tl.TextSize = 11
        tl.TextColor3 = Theme.Accent1
        tl.TextXAlignment = Enum.TextXAlignment.Left
        return row
    end

    local function makeToggle(parent, lbl, get, set, order)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,36)
        row.BackgroundColor3 = C().SURF
        row.BackgroundTransparency = 0
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)

        local tl = Instance.new("TextLabel", row)
        tl.Size = UDim2.new(1,-54,1,0)
        tl.Position = UDim2.new(0,10,0,0)
        tl.BackgroundTransparency = 1
        tl.Text = lbl
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextColor3 = C().TP
        tl.TextXAlignment = Enum.TextXAlignment.Left

        local sw = Instance.new("Frame", row)
        sw.Size = UDim2.new(0,38,0,20)
        sw.Position = UDim2.new(1,-46,0.5,-10)
        sw.BackgroundColor3 = get() and Theme.Accent1 or C().SH
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)

        local dot = Instance.new("Frame", sw)
        dot.Size = UDim2.new(0,15,0,15)
        dot.Position = get() and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)
        dot.BackgroundColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local swb = Instance.new("TextButton", sw)
        swb.Size = UDim2.new(1,0,1,0)
        swb.BackgroundTransparency = 1
        swb.Text = ""
        swb.ZIndex = 4; swb.AutoButtonColor = false
        local function doT()
            local ns=not get(); set(ns)
            TweenService:Create(dot,TweenInfo.new(0.15),{Position=ns and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)}):Play()
            TweenService:Create(sw,TweenInfo.new(0.15),{BackgroundColor3=ns and Theme.Accent1 or C().SH}):Play()
        end
        swb.MouseButton1Click:Connect(doT)
        swb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then doT() end end)
        return row
    end

    local function makeKey(parent, lbl, get, set2, order)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,36)
        row.BackgroundColor3 = C().SURF
        row.BackgroundTransparency = 0
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)

        local tl = Instance.new("TextLabel", row)
        tl.Size = UDim2.new(1,-80,1,0)
        tl.Position = UDim2.new(0,10,0,0)
        tl.BackgroundTransparency = 1
        tl.Text = lbl
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextColor3 = C().TP
        tl.TextXAlignment = Enum.TextXAlignment.Left

        local kb = Instance.new("TextButton", row)
        kb.Size = UDim2.new(0,64,0,24)
        kb.Position = UDim2.new(1,-72,0.5,-12)
        kb.BackgroundColor3 = C().SH
        kb.Text = get() or "NONE"
        kb.Font = Enum.Font.GothamBold
        kb.TextSize = 11
        kb.TextColor3 = Theme.Accent1
        kb.AutoButtonColor = false
        Instance.new("UICorner", kb).CornerRadius = UDim.new(0,5)
        kb.MouseButton1Click:Connect(function()
            kb.Text = "..."; kb.TextColor3 = C().TS
            local con; con = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    set2(inp.KeyCode.Name)
                    kb.Text = inp.KeyCode.Name
                    kb.TextColor3 = Theme.Accent1
                    SaveConfig(); con:Disconnect()
                end
            end)
        end)
        return row
    end

    -- ── TABS ──
    local TABS2 = {
        {name="Actions",   id="act"},
        {name="Config",    id="cfg"},
        {name="Visuals",   id="vis"},
        {name="Movement",  id="mov"},
        {name="TP",        id="tp"},
        {name="UI Hide's", id="uih"},
        {name="Invis",     id="inv"},
        {name="Temas",     id="tem"},
        {name="BList",     id="bl"},
    }
    local tBtns2 = {}
    local tScrolls2 = {}
    local activTab2 = "act"

    local function switchTab2(id)
        activTab2 = id
        if _G.HeroSettingsUI then _G.HeroSettingsUI.currentTab = id end
        for tid, sc in pairs(tScrolls2) do sc.Visible = (tid==id) end
        for tid, tb in pairs(tBtns2) do
            local on = tid==id
            tb.BackgroundColor3 = on and Theme.Accent1 or C().SURF
            tb.BackgroundTransparency = 0
            tb.TextColor3 = on and Color3.new(0,0,0) or C().TS
            local s2 = tb:FindFirstChildOfClass("UIStroke")
            if s2 then s2.Transparency = on and 1 or 0.3 end
        end
    end

    do
        local COLS,BTN_H,GAP=3,28,4
        for i,td in ipairs(TABS2) do
            local col=(i-1)%COLS; local row=math.floor((i-1)/COLS)
            local tb=Instance.new("TextButton",tabBar)
            tb.Size=UDim2.new(1/COLS,-(GAP*(COLS-1)/COLS),0,BTN_H)
            tb.Position=UDim2.new(col/COLS,col==0 and 0 or GAP*(col/(COLS)),0,row*(BTN_H+GAP))
            tb.BackgroundColor3=C().SURF; tb.BackgroundTransparency=0
            tb.Text=td.name; tb.Font=Enum.Font.GothamBold; tb.TextSize=11
            tb.TextColor3=C().TS; tb.BorderSizePixel=0; tb.AutoButtonColor=false; tb.LayoutOrder=i
            Instance.new("UICorner",tb).CornerRadius=UDim.new(0,6)
            local ts2=Instance.new("UIStroke",tb); ts2.Color=C().SH; ts2.Thickness=1; ts2.Transparency=0.3
            tBtns2[td.id]=tb; tScrolls2[td.id]=makeScroll()
            local tid=td.id; tb.MouseButton1Click:Connect(function() switchTab2(tid) end)
        end
    end

    -- ── ACTIONS TAB ──
    local aS = tScrolls2["act"]
    makeBtn(aS, "Teleportar para Pet",     1, function() task.spawn(runAutoSnipe) ShowNotification("TP","Teleportando...") end)
    makeBtn(aS, "Auto Clone",              2, function() instantClone() ShowNotification("CLONE","Clonando...") end)
    makeBtn(aS, "Reset Personagem",        3, function() executeReset() ShowNotification("RESET","Resetando...") end)
    makeBtn(aS, "Painel Admin",            4, function()
        local g = PlayerGui:FindFirstChild("HeroAdminPanel")
        if g then g.Enabled = not g.Enabled end
    end)
    makeBtn(aS, "Auto Steal Painel",       5, function()
        local g = PlayerGui:FindFirstChild("AutoStealUI")
        if g then g.Enabled = not g.Enabled end
    end)
    makeBtn(aS, "Job Joiner",              6, function()
        local g = PlayerGui:FindFirstChild("HeroJobJoiner")
        if g then g.Enabled = not g.Enabled end
    end)

    -- ── CONFIG TAB ──
    local cS = tScrolls2["cfg"]
    makeSec(cS, "AÇÕES RÁPIDAS", 0)
    makeBtn(cS, "Abrir Painel Admin", 1, function()
        local g = PlayerGui:FindFirstChild("HeroAdminPanel")
        if g then g.Enabled = not g.Enabled end
    end)

    makeSec(cS, "ESP", 2)
    makeToggle(cS,"X-Ray Base",function() return Config.XrayEnabled end,function(v) Config.XrayEnabled=v; if v then enableXray() else disableXray() end; SaveConfig() end,2)
    makeToggle(cS,"Player ESP",function() return Config.PlayerESP end,function(v) Config.PlayerESP=v; if playerESPToggleRef and playerESPToggleRef.setFn then playerESPToggleRef.setFn(v) end; SaveConfig() end,3)
    makeToggle(cS,"Brainrot ESP",function() return Config.BrainrotESP end,function(v) Config.BrainrotESP=v; if espToggleRef and espToggleRef.setFn then espToggleRef.setFn(v) end; SaveConfig() end,4)
    makeToggle(cS,"Tracer Brainrot",function() return Config.TracerEnabled end,function(v) Config.TracerEnabled=v; SaveConfig() end,5)
    makeToggle(cS,"Duel Base ESP",function() return Config.DuelBaseESP end,function(v) Config.DuelBaseESP=v; SaveConfig() end,6)
    makeToggle(cS,"Subspace Mine ESP",function() return Config.SubspaceMineESP end,function(v) Config.SubspaceMineESP=v; SaveConfig() end,7)

    makeSec(cS, "MOVIMENTO", 10)
    makeToggle(cS,"Infinite Jump",function() return State.infiniteJumpEnabled end,function(v) setInfiniteJump(v) end,11)
    makeToggle(cS,"FPS Boost",function() return Config.FPSBoost end,function(v) setFPSBoost(v) end,12)
    makeToggle(cS,"Auto Steal Speed",function() return Config.AutoStealSpeed end,function(v) Config.AutoStealSpeed=v; SaveConfig() end,13)
    makeToggle(cS,"Line to Base",function() return Config.LineToBase end,function(v) Config.LineToBase=v; if not v and _G.resetPlotBeam then pcall(_G.resetPlotBeam) end; SaveConfig() end,14)

    makeSec(cS, "ANTI-RAGDOLL", 20)
    makeToggle(cS,"Anti-Ragdoll V1",function() return Config.AntiRagdoll>0 end,function(v) Config.AntiRagdoll=v and 1 or 0; if v then Config.AntiRagdollV2=false; startAntiRagdollV2(false) end; startAntiRagdoll(Config.AntiRagdoll); SaveConfig() end,21)
    makeToggle(cS,"Anti-Ragdoll V2",function() return Config.AntiRagdollV2 end,function(v) Config.AntiRagdollV2=v; if v then Config.AntiRagdoll=0; startAntiRagdoll(0); startAntiRagdollV2(true) else startAntiRagdollV2(false) end; SaveConfig() end,22)

    makeSec(cS, "AUTOMAÇÃO", 30)
    makeToggle(cS,"Auto Invis no Steal",function() return Config.AutoInvisDuringSteal end,function(v) Config.AutoInvisDuringSteal=v; _G.AutoInvisDuringSteal=v; SaveConfig() end,31)
    makeToggle(cS,"Auto Kick no Steal",function() return Config.AutoKickOnSteal end,function(v) if _G.setAutoKickFromSettings then _G.setAutoKickFromSettings(v) else Config.AutoKickOnSteal=v; SaveConfig() end end,32)
    makeToggle(cS,"Auto Reset Balloon",function() return Config.AutoResetOnBalloon end,function(v) Config.AutoResetOnBalloon=v; SaveConfig() end,33)
    makeToggle(cS,"Anti-Bee & Disco",function() return Config.AntiBeeDisco end,function(v) Config.AntiBeeDisco=v; SaveConfig(); if v and SharedState.ANTI_BEE_DISCO then SharedState.ANTI_BEE_DISCO.Enable() elseif SharedState.ANTI_BEE_DISCO then SharedState.ANTI_BEE_DISCO.Disable() end end,34)
    makeToggle(cS,"Limpar Error GUIs",function() return Config.CleanErrorGUIs end,function(v) Config.CleanErrorGUIs=v; SaveConfig() end,35)
    makeToggle(cS,"Auto TP ao Carregar",function() return Config.TpSettings.TpOnLoad end,function(v) Config.TpSettings.TpOnLoad=v; SaveConfig() end,36)

    -- ─── AUTO STEAL DEFAULTS ─────────────────────────────────────────────
    makeSec(cS, "AUTO STEAL DEFAULTS", 37)
    do
        local rSwitches = {}
        local function applyDefMode(mode)
            Config.DefaultToNearest  = (mode == "nearest")
            Config.DefaultToHighest  = (mode == "highest")
            Config.DefaultToPriority = (mode == "priority")
            Config.DefaultToDisable  = (mode == "disable")
            Config.AutoTPPriority    = (mode == "nearest" or mode == "priority")
            SaveConfig()
            for _id, _sw in pairs(rSwitches) do
                local _on = (_id=="nearest"  and Config.DefaultToNearest)
                         or (_id=="highest"  and Config.DefaultToHighest)
                         or (_id=="priority" and Config.DefaultToPriority)
                         or (_id=="disable"  and Config.DefaultToDisable)
                TweenService:Create(_sw.dot, TweenInfo.new(0.15), {Position = _on and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)}):Play()
                TweenService:Create(_sw.bg,  TweenInfo.new(0.15), {BackgroundColor3 = _on and Theme.Accent1 or Theme.SurfaceHighlight}):Play()
            end
        end
        local function makeRadioSwitch(parent, label, id, order)
            local isOn = (id=="nearest"  and Config.DefaultToNearest)
                      or (id=="highest"  and Config.DefaultToHighest)
                      or (id=="priority" and Config.DefaultToPriority)
                      or (id=="disable"  and Config.DefaultToDisable)
            local row = Instance.new("Frame", parent)
            row.Size = UDim2.new(1,0,0,36)
            row.BackgroundColor3 = C().SURF
            row.BackgroundTransparency = 0
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
            local tl = Instance.new("TextLabel", row)
            tl.Size = UDim2.new(1,-54,1,0)
            tl.Position = UDim2.new(0,10,0,0)
            tl.BackgroundTransparency = 1
            tl.Text = label
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 12
            tl.TextColor3 = C().TP
            tl.TextXAlignment = Enum.TextXAlignment.Left
            local sw = Instance.new("Frame", row)
            sw.Size = UDim2.new(0,38,0,20)
            sw.Position = UDim2.new(1,-46,0.5,-10)
            sw.BackgroundColor3 = isOn and Theme.Accent1 or Theme.SurfaceHighlight
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
            local dot = Instance.new("Frame", sw)
            dot.Size = UDim2.new(0,15,0,15)
            dot.Position = isOn and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)
            dot.BackgroundColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
            local btn = Instance.new("TextButton", sw)
            btn.Size = UDim2.new(1,0,1,0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.MouseButton1Click:Connect(function() applyDefMode(id) end)
            rSwitches[id] = {bg=sw, dot=dot}
        end
        makeRadioSwitch(cS, "Default To Nearest",  "nearest",  38)
        makeRadioSwitch(cS, "Default To Highest",  "highest",  39)
        makeRadioSwitch(cS, "Default To Priority", "priority", 40)
        makeRadioSwitch(cS, "Default Disable",     "disable",  41)
    end

    -- ─── AUTO STEAL ─────────────────────────────────────────────────────
    makeSec(cS, "AUTO STEAL", 60)
    do
        local stealSwitches = {}
        local function applyStealMode(mode)
            -- mode: "nearest" | "highest" | "priority"
            Config.StealNearest  = (mode == "nearest")
            Config.StealHighest  = (mode == "highest")
            Config.StealPriority = (mode == "priority")
            -- also mirror onto DefaultTo so the logic persists on reload
            Config.DefaultToNearest  = (mode == "nearest")
            Config.DefaultToHighest  = (mode == "highest")
            Config.DefaultToPriority = (mode == "priority")
            Config.DefaultToDisable  = false
            Config.AutoTPPriority    = (mode == "nearest" or mode == "priority")
            SaveConfig()
            for _id, _sw in pairs(stealSwitches) do
                local _on = (_id=="nearest"  and Config.StealNearest)
                         or (_id=="highest"  and Config.StealHighest)
                         or (_id=="priority" and Config.StealPriority)
                TweenService:Create(_sw.dot, TweenInfo.new(0.15), {Position = _on and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)}):Play()
                TweenService:Create(_sw.bg,  TweenInfo.new(0.15), {BackgroundColor3 = _on and Theme.Accent1 or Theme.SurfaceHighlight}):Play()
            end
            ShowNotification("STEAL MODE", "Steal " .. mode:sub(1,1):upper() .. mode:sub(2) .. " ENABLED")
        end
        local function makeStealRadio(parent, label, id, order)
            local isOn = (id=="nearest"  and Config.StealNearest)
                      or (id=="highest"  and Config.StealHighest)
                      or (id=="priority" and Config.StealPriority)
            local row = Instance.new("Frame", parent)
            row.Size = UDim2.new(1,0,0,36)
            row.BackgroundColor3 = C().SURF
            row.BackgroundTransparency = 0
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
            local tl = Instance.new("TextLabel", row)
            tl.Size = UDim2.new(1,-54,1,0)
            tl.Position = UDim2.new(0,10,0,0)
            tl.BackgroundTransparency = 1
            tl.Text = label
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 12
            tl.TextColor3 = C().TP
            tl.TextXAlignment = Enum.TextXAlignment.Left
            local sw = Instance.new("Frame", row)
            sw.Size = UDim2.new(0,38,0,20)
            sw.Position = UDim2.new(1,-46,0.5,-10)
            sw.BackgroundColor3 = isOn and Theme.Accent1 or Theme.SurfaceHighlight
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
            local dot = Instance.new("Frame", sw)
            dot.Size = UDim2.new(0,15,0,15)
            dot.Position = isOn and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)
            dot.BackgroundColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
            local btn = Instance.new("TextButton", sw)
            btn.Size = UDim2.new(1,0,1,0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.MouseButton1Click:Connect(function() applyStealMode(id) end)
            stealSwitches[id] = {bg=sw, dot=dot}
        end
        makeStealRadio(cS, "Steal Nearest",  "nearest",  61)
        makeStealRadio(cS, "Steal Highest",  "highest",  62)
        makeStealRadio(cS, "Steal Priority", "priority", 63)
    end

    -- ─── BINDS ───────────────────────────────────────────────────────────
    makeSec(cS, "BINDS", 70)
    makeKey(cS,"Teleport",function() return Config.TpSettings.TpKey end,function(v) Config.TpSettings.TpKey=v end,71)
    makeKey(cS,"Ragdoll Self",function() return Config.RagdollSelfKey ~= "" and Config.RagdollSelfKey or "NONE" end,function(v) Config.RagdollSelfKey=v; SaveConfig() end,81)
    makeKey(cS,"Clone",function() return Config.TpSettings.CloneKey end,function(v) Config.TpSettings.CloneKey=v end,72)
    makeKey(cS,"Carpet Speed",function() return Config.TpSettings.CarpetSpeedKey end,function(v) Config.TpSettings.CarpetSpeedKey=v end,73)
    makeKey(cS,"Steal Speed",function() return Config.StealSpeedKey end,function(v) Config.StealSpeedKey=v end,74)
    makeKey(cS,"Invis Toggle",function() return Config.InvisToggleKey end,function(v) Config.InvisToggleKey=v; _G.INVISIBLE_STEAL_KEY=Enum.KeyCode[v] or Enum.KeyCode.I end,75)
    makeKey(cS,"Menu",function() return Config.MenuKey end,function(v) Config.MenuKey=v end,76)
    makeKey(cS,"Reset",function() return Config.ResetKey end,function(v) Config.ResetKey=v end,77)
    makeKey(cS,"Kick",function() return Config.KickKey end,function(v) Config.KickKey=v end,78)
    makeKey(cS,"Click To AP",function() return Config.ClickToAPKeybind or "L" end,function(v)
        Config.ClickToAPKeybind=v; SaveConfig()
    end,79)
    makeKey(cS,"Proximity AP",function() return Config.ProximityAPKeybind or "P" end,function(v)
        Config.ProximityAPKeybind=v; SaveConfig()
    end,80)

    makeSec(cS, "TURRET", 90)
    makeToggle(cS,"Auto Turret ao Segurar Brainrot",function() return Config.AutoTurretOnBrainrot end,function(v)
        Config.AutoTurretOnBrainrot=v; SaveConfig()
        ShowNotification("AUTO TURRET", v and "Ativa Auto-Destroy ao segurar brainrot" or "Desativado")
    end,71)


    -- ── VISUALS TAB ──
    local vS = tScrolls2["vis"]
    makeSec(vS,"ESP",1)
    makeToggle(vS,"X-Ray Base",function() return Config.XrayEnabled end,function(v) Config.XrayEnabled=v; if v then enableXray() else disableXray() end; SaveConfig() end,11)
    makeToggle(vS,"Player ESP",function() return Config.PlayerESP end,function(v) Config.PlayerESP=v; if playerESPToggleRef and playerESPToggleRef.setFn then playerESPToggleRef.setFn(v) end; SaveConfig() end,12)
    makeToggle(vS,"Brainrot ESP",function() return Config.BrainrotESP end,function(v) Config.BrainrotESP=v; if espToggleRef and espToggleRef.setFn then espToggleRef.setFn(v) end; SaveConfig() end,13)
    makeToggle(vS,"Conveyor ESP",function() return Config.ConveyorESP end,function(v) Config.ConveyorESP=v; SaveConfig() end,14)
    makeToggle(vS,"Tracer Brainrot",function() return Config.TracerEnabled end,function(v) Config.TracerEnabled=v; SaveConfig() end,15)
    makeToggle(vS,"Duel Base ESP",function() return Config.DuelBaseESP end,function(v) Config.DuelBaseESP=v; SaveConfig() end,16)
    makeToggle(vS,"Subspace Mine ESP",function() return Config.SubspaceMineESP end,function(v) Config.SubspaceMineESP=v; SaveConfig() end,17)
    makeToggle(vS,"Stealing HUD",function() return Config.ShowStealingHUD~=false end,function(v) Config.ShowStealingHUD=v; SaveConfig(); local g=PlayerGui:FindFirstChild("XiStealingHUD"); if g then g.Enabled=v end end,18)
    makeToggle(vS,"Desync Visualizer",function() return Config.DesyncVisualizer end,function(v) Config.DesyncVisualizer=v; SaveConfig() end,19)
    makeSec(vS,"OVERLAYS",20)
    makeToggle(vS,"Line to Base",function() return Config.LineToBase end,function(v) Config.LineToBase=v; if not v and _G.resetPlotBeam then pcall(_G.resetPlotBeam) end; SaveConfig() end,21)
    makeToggle(vS,"Unlock Buttons HUD",function() return Config.ShowUnlockButtonsHUD end,function(v)
        Config.ShowUnlockButtonsHUD=v; SaveConfig()
        local hudGui=PlayerGui:FindFirstChild("HeroStatusHUD")
        if not hudGui then return end
        local uc=hudGui:FindFirstChild("UnlockButtonsContainer")
        if uc then uc.Visible=v end
    end,22)
    makeSec(vS,"CÂMERA",30)
    do
        local fR=Instance.new("Frame",vS); fR.Size=UDim2.new(1,0,0,52); fR.BackgroundColor3=C().SURF; fR.BorderSizePixel=0; fR.LayoutOrder=31
        Instance.new("UICorner",fR).CornerRadius=UDim.new(0,7)
        local fl=Instance.new("TextLabel",fR); fl.Size=UDim2.new(0.5,0,0,18); fl.Position=UDim2.new(0,10,0,4); fl.BackgroundTransparency=1; fl.Text="FOV"; fl.Font=Enum.Font.GothamBold; fl.TextSize=12; fl.TextColor3=C().TP; fl.TextXAlignment=Enum.TextXAlignment.Left
        local fV=Instance.new("TextLabel",fR); fV.Size=UDim2.new(0,40,0,18); fV.Position=UDim2.new(1,-48,0,4); fV.BackgroundTransparency=1; fV.Font=Enum.Font.GothamBlack; fV.TextSize=13; fV.TextColor3=Theme.Accent1; fV.TextXAlignment=Enum.TextXAlignment.Right; fV.Text=tostring(Config.FOV or 70)
        local fbg=Instance.new("Frame",fR); fbg.Size=UDim2.new(1,-20,0,6); fbg.Position=UDim2.new(0,10,0,34); fbg.BackgroundColor3=C().SH; fbg.BorderSizePixel=0; Instance.new("UICorner",fbg).CornerRadius=UDim.new(1,0)
        local ff=Instance.new("Frame",fbg); ff.BackgroundColor3=Theme.Accent1; ff.BorderSizePixel=0; ff.Size=UDim2.new(0,0,1,0); Instance.new("UICorner",ff).CornerRadius=UDim.new(1,0)
        local fk=Instance.new("Frame",fbg); fk.Size=UDim2.new(0,13,0,13); fk.AnchorPoint=Vector2.new(0.5,0.5); fk.BackgroundColor3=Color3.new(1,1,1); fk.BorderSizePixel=0; Instance.new("UICorner",fk).CornerRadius=UDim.new(1,0)
        local function updFOV(v) v=math.clamp(math.floor(v),30,180); Config.FOV=v; SaveConfig(); fV.Text=tostring(v); local p=(v-30)/150; ff.Size=UDim2.new(p,0,1,0); fk.Position=UDim2.new(p,0,0.5,0); if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=v end end
        updFOV(Config.FOV or 70)
        local fD=false
        fbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fD=true end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fD=false end end)
        UserInputService.InputChanged:Connect(function(i) if fD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then updFOV(30+math.clamp((i.Position.X-fbg.AbsolutePosition.X)/fbg.AbsoluteSize.X,0,1)*150) end end)
        local fRst=Instance.new("TextButton",fR); fRst.Size=UDim2.new(0,50,0,18); fRst.Position=UDim2.new(0.5,-25,0,4); fRst.BackgroundColor3=C().SH; fRst.Text="Reset"; fRst.Font=Enum.Font.GothamBold; fRst.TextSize=10; fRst.TextColor3=C().TP; fRst.AutoButtonColor=false; Instance.new("UICorner",fRst).CornerRadius=UDim.new(0,4)
        fRst.MouseButton1Click:Connect(function() updFOV(70) end)
    end
    do
        local fRstRow=Instance.new("Frame",vS); fRstRow.Size=UDim2.new(1,0,0,34); fRstRow.BackgroundColor3=C().SURF; fRstRow.BorderSizePixel=0; fRstRow.LayoutOrder=39; Instance.new("UICorner",fRstRow).CornerRadius=UDim.new(0,7)
        local fRstLbl=Instance.new("TextLabel",fRstRow); fRstLbl.Size=UDim2.new(0.6,0,1,0); fRstLbl.Position=UDim2.new(0,10,0,0); fRstLbl.BackgroundTransparency=1; fRstLbl.Text="Reset FOV"; fRstLbl.Font=Enum.Font.GothamBold; fRstLbl.TextSize=11; fRstLbl.TextColor3=C().TP; fRstLbl.TextXAlignment=Enum.TextXAlignment.Left
        local fRstBtn=Instance.new("TextButton",fRstRow); fRstBtn.Size=UDim2.new(0,70,0,24); fRstBtn.Position=UDim2.new(1,-78,0.5,-12); fRstBtn.BackgroundColor3=C().SH; fRstBtn.Text="Reset"; fRstBtn.Font=Enum.Font.GothamBold; fRstBtn.TextSize=11; fRstBtn.TextColor3=C().TP; fRstBtn.AutoButtonColor=false; Instance.new("UICorner",fRstBtn).CornerRadius=UDim.new(0,5)
        fRstBtn.MouseButton1Click:Connect(function() Config.FOV=70; SaveConfig(); if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=70 end; ShowNotification("FOV","Reset to 70") end)
    end
    makeSec(vS,"PERFORMANCE",40)
    makeToggle(vS,"FPS Boost",function() return Config.FPSBoost end,function(v) setFPSBoost(v) end,41)
    makeSec(vS,"ULTRA LIGHT",50)
    do
        local ulRow=Instance.new("Frame",vS); ulRow.Size=UDim2.new(1,0,0,40); ulRow.BackgroundColor3=C().SURF; ulRow.BorderSizePixel=0; ulRow.LayoutOrder=51; Instance.new("UICorner",ulRow).CornerRadius=UDim.new(0,7)
        local ulLbl=Instance.new("TextLabel",ulRow); ulLbl.Size=UDim2.new(0.7,0,0.6,0); ulLbl.Position=UDim2.new(0,10,0.1,0); ulLbl.BackgroundTransparency=1; ulLbl.Text="Ultra Light Mode"; ulLbl.Font=Enum.Font.GothamBlack; ulLbl.TextSize=12; ulLbl.TextColor3=C().TP; ulLbl.TextXAlignment=Enum.TextXAlignment.Left
        local ulSub=Instance.new("TextLabel",ulRow); ulSub.Size=UDim2.new(0.7,0,0.4,0); ulSub.Position=UDim2.new(0,10,0.6,0); ulSub.BackgroundTransparency=1; ulSub.Text="No border animations"; ulSub.Font=Enum.Font.GothamMedium; ulSub.TextSize=9; ulSub.TextColor3=C().TS; ulSub.TextXAlignment=Enum.TextXAlignment.Left
        local ulSw=Instance.new("Frame",ulRow); ulSw.Size=UDim2.new(0,38,0,20); ulSw.Position=UDim2.new(1,-46,0.5,-10); ulSw.BackgroundColor3=Config.UltraLightMode and Theme.Accent1 or C().SH; Instance.new("UICorner",ulSw).CornerRadius=UDim.new(1,0)
        local ulDot=Instance.new("Frame",ulSw); ulDot.Size=UDim2.new(0,15,0,15); ulDot.Position=Config.UltraLightMode and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5); ulDot.BackgroundColor3=Color3.new(1,1,1); Instance.new("UICorner",ulDot).CornerRadius=UDim.new(1,0)
        local ulBtn=Instance.new("TextButton",ulSw); ulBtn.Size=UDim2.new(1,0,1,0); ulBtn.BackgroundTransparency=1; ulBtn.Text=""
        ulBtn.MouseButton1Click:Connect(function()
            Config.UltraLightMode = not Config.UltraLightMode; SaveConfig()
            local ns = Config.UltraLightMode
            TweenService:Create(ulDot,TweenInfo.new(0.15),{Position=ns and UDim2.new(1,-17,0.5,-7.5) or UDim2.new(0,2,0.5,-7.5)}):Play()
            TweenService:Create(ulSw,TweenInfo.new(0.15),{BackgroundColor3=ns and Theme.Accent1 or C().SH}):Play()
            if ns then
                -- Kill all racetrack borders
                for _,gn in ipairs({"AutoStealUI","HeroAdminPanel","SettingsUI","StealSpeedUI","HeroInvisPanel","HeroStatusHUD","HeroSettings","HeroPlatformUI","HeroAutoBuyUI","HeroMiniActions"}) do
                    local sg=PlayerGui:FindFirstChild(gn); if sg then for _,obj in ipairs(sg:GetDescendants()) do if obj.Name=="RacetrackBorder" and obj:IsA("UIStroke") then obj:Destroy() end end end
                end
            end
        end)
    end

    -- ── MOVEMENT TAB ──
    local mS = tScrolls2["mov"]
    makeSec(mS,"MOVIMENTO",1)
    makeToggle(mS,"Infinite Jump",function() return State.infiniteJumpEnabled end,function(v) setInfiniteJump(v) end,11)
    makeToggle(mS,"Auto Steal Speed",function() return Config.AutoStealSpeed end,function(v) Config.AutoStealSpeed=v; SaveConfig() end,12)
    makeToggle(mS,"Float",function() return Config.FloatEnabled end,function(v) Config.FloatEnabled=v; if v then if _G._floatConn then _G._floatConn:Disconnect() end; _G._floatConn=RunService.RenderStepped:Connect(function() local c=LocalPlayer.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); if h then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,30,h.AssemblyLinearVelocity.Z) end end) else if _G._floatConn then _G._floatConn:Disconnect(); _G._floatConn=nil end end; SaveConfig() end,13)
    makeToggle(mS,"Return to Brainrot",function() return Config.ReturnToBrainrot end,function(v) Config.ReturnToBrainrot=v; SaveConfig() end,14)
    makeToggle(mS,"Auto Back to Brainrot",function() return Config.AutoBackToBrainrot end,function(v) Config.AutoBackToBrainrot=v; SaveConfig() end,15)
    makeSec(mS,"ANTI-RAGDOLL",20)
    makeToggle(mS,"Anti-Ragdoll V1",function() return Config.AntiRagdoll>0 end,function(v) Config.AntiRagdoll=v and 1 or 0; if v then Config.AntiRagdollV2=false; startAntiRagdollV2(false) end; startAntiRagdoll(Config.AntiRagdoll); SaveConfig() end,21)
    makeToggle(mS,"Anti-Ragdoll V2",function() return Config.AntiRagdollV2 end,function(v) Config.AntiRagdollV2=v; if v then Config.AntiRagdoll=0; startAntiRagdoll(0); startAntiRagdollV2(true) else startAntiRagdollV2(false) end; SaveConfig() end,22)
    makeSec(mS,"PROTECTION",25)
    makeToggle(mS,"Auto-Destroy Turrets",function() return Config.AutoDestroyTurrets end,function(v) Config.AutoDestroyTurrets=v; SaveConfig() end,251)
    makeSec(mS,"AUTO UNLOCK",28)
    makeToggle(mS,"Auto Unlock on Steal",function() return Config.AutoUnlockOnSteal end,function(v) Config.AutoUnlockOnSteal=v; SaveConfig() end,281)
    makeSec(mS,"AUTOMAÇÃO",30)
    makeToggle(mS,"Auto Invis no Steal",function() return Config.AutoInvisDuringSteal end,function(v) Config.AutoInvisDuringSteal=v; _G.AutoInvisDuringSteal=v; SaveConfig() end,31)
    makeToggle(mS,"Auto Kick no Steal",function() return Config.AutoKickOnSteal end,function(v) if _G.setAutoKickFromSettings then _G.setAutoKickFromSettings(v) else Config.AutoKickOnSteal=v; SaveConfig() end end,32)
    makeToggle(mS,"Auto Reset Balloon",function() return Config.AutoResetOnBalloon end,function(v) Config.AutoResetOnBalloon=v; SaveConfig() end,33)
    makeToggle(mS,"Anti-Bee & Disco",function() return Config.AntiBeeDisco end,function(v) Config.AntiBeeDisco=v; SaveConfig(); if v and SharedState.ANTI_BEE_DISCO then SharedState.ANTI_BEE_DISCO.Enable() elseif SharedState.ANTI_BEE_DISCO then SharedState.ANTI_BEE_DISCO.Disable() end end,34)
    makeToggle(mS,"Limpar Error GUIs",function() return Config.CleanErrorGUIs end,function(v) Config.CleanErrorGUIs=v; SaveConfig() end,35)
    makeToggle(mS,"Auto Turret ao Segurar",function() return Config.AutoTurretOnBrainrot end,function(v) Config.AutoTurretOnBrainrot=v; SaveConfig() end,36)
    makeSec(mS,"BINDS",40)
    makeKey(mS,"Steal Speed",function() return Config.StealSpeedKey end,function(v) Config.StealSpeedKey=v end,41)
    makeKey(mS,"Invis Toggle",function() return Config.InvisToggleKey end,function(v) Config.InvisToggleKey=v; _G.INVISIBLE_STEAL_KEY=Enum.KeyCode[v] or Enum.KeyCode.I end,42)
    makeKey(mS,"Ragdoll Self",function() return Config.RagdollSelfKey ~= "" and Config.RagdollSelfKey or "NONE" end,function(v) Config.RagdollSelfKey=v; SaveConfig() end,43)
    makeKey(mS,"Reset",function() return Config.ResetKey end,function(v) Config.ResetKey=v end,44)
    makeKey(mS,"Float Key",function() return Config.FloatKey or "F" end,function(v) Config.FloatKey=v; SaveConfig() end,45)
    makeKey(mS,"Menu",function() return Config.MenuKey end,function(v) Config.MenuKey=v end,46)
    makeKey(mS,"Kick",function() return Config.KickKey end,function(v) Config.KickKey=v end,47)
    makeKey(mS,"Click To AP",function() return Config.ClickToAPKeybind or "L" end,function(v) Config.ClickToAPKeybind=v; SaveConfig() end,48)
    makeKey(mS,"Proximity AP",function() return Config.ProximityAPKeybind or "P" end,function(v) Config.ProximityAPKeybind=v; SaveConfig() end,49)
    makeKey(mS,"Auto Buy Toggle Key",function() return Config.AutoBuyKey or "K" end,function(v) Config.AutoBuyKey=v; SaveConfig() end,50)
    do
        local rRejoin=Instance.new("Frame",mS); rRejoin.Size=UDim2.new(1,0,0,36); rRejoin.BackgroundColor3=C().SURF; rRejoin.BorderSizePixel=0; rRejoin.LayoutOrder=51; Instance.new("UICorner",rRejoin).CornerRadius=UDim.new(0,7)
        local rl=Instance.new("TextLabel",rRejoin); rl.Size=UDim2.new(0.6,0,1,0); rl.Position=UDim2.new(0,10,0,0); rl.BackgroundTransparency=1; rl.Text="Rejoin"; rl.Font=Enum.Font.GothamBold; rl.TextSize=11; rl.TextColor3=C().TP; rl.TextXAlignment=Enum.TextXAlignment.Left
        local rb=Instance.new("TextButton",rRejoin); rb.Size=UDim2.new(0,80,0,26); rb.Position=UDim2.new(1,-88,0.5,-13); rb.BackgroundColor3=Theme.Error; rb.Text="REJOIN"; rb.Font=Enum.Font.GothamBold; rb.TextSize=11; rb.TextColor3=Color3.new(1,1,1); rb.AutoButtonColor=false; Instance.new("UICorner",rb).CornerRadius=UDim.new(0,6)
        rb.MouseButton1Click:Connect(function() ShowNotification("REJOIN","Reconnecting..."); task.delay(0.5,function() pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end) end) end)
    end

    -- ── TP TAB ──
    local tpS = tScrolls2["tp"]

    makeSec(tpS,"AUTO TP",10)
    makeToggle(tpS,"Auto TP on Script Load",function() return Config.TpSettings.TpOnLoad end,function(v) Config.TpSettings.TpOnLoad=v; SaveConfig() end,11)
    do
        local r=Instance.new("Frame",tpS); r.Size=UDim2.new(1,0,0,36); r.BackgroundColor3=C().SURF; r.BorderSizePixel=0; r.LayoutOrder=12; Instance.new("UICorner",r).CornerRadius=UDim.new(0,7)
        local lbl=Instance.new("TextLabel",r); lbl.Size=UDim2.new(0.6,0,0,16); lbl.Position=UDim2.new(0,10,0,10); lbl.BackgroundTransparency=1; lbl.Text="Min Gen for Auto TP"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextColor3=C().TP; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local tb=Instance.new("TextBox",r); tb.Size=UDim2.new(0,110,0,24); tb.Position=UDim2.new(1,-118,0.5,-12); tb.BackgroundColor3=C().SH; tb.Text=tostring(Config.TpSettings.MinGenForTp or ""); tb.Font=Enum.Font.Gotham; tb.TextSize=11; tb.TextColor3=C().TP; tb.PlaceholderText="e.g. 5k, 1m, 1b"; tb.ClearTextOnFocus=false; Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
        tb.FocusLost:Connect(function() Config.TpSettings.MinGenForTp=tb.Text:gsub("%s",""); SaveConfig() end)
    end

    makeSec(tpS,"TP TOOL",19)
    do
        local tools={"Flying Carpet","Cupid's Wings","Santa's Sleigh","Witch's Broom"}; local sws={}
        for idx,tn in ipairs(tools) do
            local r=Instance.new("Frame",tpS); r.Size=UDim2.new(1,0,0,34); r.BackgroundColor3=C().SURF; r.BorderSizePixel=0; r.LayoutOrder=20+idx; Instance.new("UICorner",r).CornerRadius=UDim.new(0,7)
            local lbl=Instance.new("TextLabel",r); lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1; lbl.Text=tn; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextColor3=C().TP; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local sw=Instance.new("TextButton",r); sw.Size=UDim2.new(0,50,0,22); sw.Position=UDim2.new(1,-58,0.5,-11); sw.Font=Enum.Font.GothamBold; sw.TextSize=11; sw.AutoButtonColor=false; Instance.new("UICorner",sw).CornerRadius=UDim.new(0,5)
            local function ref() local on=Config.TpSettings.Tool==tn; sw.Text=on and"ON"or"OFF"; sw.BackgroundColor3=on and Theme.Accent1 or C().SH; sw.TextColor3=on and Color3.new(0,0,0) or C().TP end
            ref(); sw.MouseButton1Click:Connect(function() Config.TpSettings.Tool=tn; SaveConfig(); for _,s in pairs(sws) do pcall(s) end end); sws[tn]=ref
        end
        local sRow=Instance.new("Frame",tpS); sRow.Size=UDim2.new(1,0,0,34); sRow.BackgroundColor3=C().SURF; sRow.BorderSizePixel=0; sRow.LayoutOrder=25; Instance.new("UICorner",sRow).CornerRadius=UDim.new(0,7)
        local sl=Instance.new("TextLabel",sRow); sl.Size=UDim2.new(0.55,0,1,0); sl.Position=UDim2.new(0,10,0,0); sl.BackgroundTransparency=1; sl.Text="Teleport Delay (1=Fast)"; sl.Font=Enum.Font.GothamBold; sl.TextSize=11; sl.TextColor3=C().TP; sl.TextXAlignment=Enum.TextXAlignment.Left
        local sCont=Instance.new("Frame",sRow); sCont.Size=UDim2.new(0,100,0,24); sCont.Position=UDim2.new(1,-108,0.5,-12); sCont.BackgroundTransparency=1
        local sBtns={}
        for i=1,4 do
            local sb=Instance.new("TextButton",sCont); sb.Size=UDim2.new(0.22,0,1,0); sb.Position=UDim2.new((i-1)*0.26,0,0,0); sb.Font=Enum.Font.GothamBold; sb.TextSize=12; sb.AutoButtonColor=false; sb.Text=tostring(i); Instance.new("UICorner",sb).CornerRadius=UDim.new(0,4)
            local function ref() for j,b in ipairs(sBtns) do local on=j==Config.TpSettings.Speed; b.BackgroundColor3=on and Theme.Accent1 or C().SH; b.TextColor3=on and Color3.new(0,0,0) or C().TP end end
            sb.MouseButton1Click:Connect(function() Config.TpSettings.Speed=i; SaveConfig(); ref() end); table.insert(sBtns,sb)
        end
        task.defer(function() for j,b in ipairs(sBtns) do local on=j==(Config.TpSettings.Speed or 2); b.BackgroundColor3=on and Theme.Accent1 or C().SH; b.TextColor3=on and Color3.new(0,0,0) or C().TP end end)
    end

    makeSec(tpS,"TP AUTOMATION",30)
    makeToggle(tpS,"Auto TP Priority Mode",function() return Config.AutoTPPriority end,function(v) Config.AutoTPPriority=v; SaveConfig() end,31)
    makeToggle(tpS,"Auto TP on Failed Steal",function() return Config.AutoTpOnFailedSteal or false end,function(v) Config.AutoTpOnFailedSteal=v; SaveConfig() end,32)
    makeToggle(tpS,"Auto TP Follow Target",function() return Config.AutoTPFollowTarget or false end,function(v) Config.AutoTPFollowTarget=v; SaveConfig() end,33)
    makeToggle(tpS,"Return to Brainrot",function() return Config.ReturnToBrainrot end,function(v) Config.ReturnToBrainrot=v; SaveConfig() end,34)

    makeSec(tpS,"PLATFORM",40)
    do
        local function mkSlider(lbl,ord,getV,setV,mn,mx)
            local r=Instance.new("Frame",tpS); r.Size=UDim2.new(1,0,0,52); r.BackgroundColor3=C().SURF; r.BorderSizePixel=0; r.LayoutOrder=ord; Instance.new("UICorner",r).CornerRadius=UDim.new(0,7)
            local tl=Instance.new("TextLabel",r); tl.Size=UDim2.new(0.65,0,0,18); tl.Position=UDim2.new(0,10,0,4); tl.BackgroundTransparency=1; tl.Text=lbl; tl.Font=Enum.Font.GothamBold; tl.TextSize=11; tl.TextColor3=C().TP; tl.TextXAlignment=Enum.TextXAlignment.Left
            local vl=Instance.new("TextLabel",r); vl.Size=UDim2.new(0,50,0,18); vl.Position=UDim2.new(1,-58,0,4); vl.BackgroundTransparency=1; vl.Font=Enum.Font.GothamBlack; vl.TextSize=12; vl.TextColor3=Theme.Accent1; vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Text=tostring(getV())
            local bg=Instance.new("Frame",r); bg.Size=UDim2.new(1,-20,0,6); bg.Position=UDim2.new(0,10,0,34); bg.BackgroundColor3=C().SH; bg.BorderSizePixel=0; Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
            local fill=Instance.new("Frame",bg); fill.BackgroundColor3=Theme.Accent1; fill.BorderSizePixel=0; fill.Size=UDim2.new(0,0,1,0); Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
            local knob=Instance.new("Frame",bg); knob.Size=UDim2.new(0,13,0,13); knob.AnchorPoint=Vector2.new(0.5,0.5); knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
            local function upd(v) v=math.clamp(math.floor(v*10)/10,mn,mx); setV(v); SaveConfig(); vl.Text=string.format(v==math.floor(v) and"%d"or"%.1f",v); local p=(v-mn)/(mx-mn); fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0) end
            upd(getV())
            local drag=false
            bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
            UserInputService.InputChanged:Connect(function(i) if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(mn+math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)*(mx-mn)) end end)
        end
        mkSlider("Platform Offset",41,function() return Config.PlatformOffset or 12.5 end,function(v) Config.PlatformOffset=v end,1,30)
        mkSlider("Platform Time (sec)",42,function() return Config.PlatformTime or 10 end,function(v) Config.PlatformTime=math.floor(v) end,3,30)
    end

    makeSec(tpS,"TP KEYBINDS",50)
    makeKey(tpS,"TP Keybind",function() return Config.TpSettings.TpKey end,function(v) Config.TpSettings.TpKey=v end,51)
    makeKey(tpS,"Auto Clone Keybind",function() return Config.TpSettings.CloneKey end,function(v) Config.TpSettings.CloneKey=v end,52)
    makeKey(tpS,"Carpet Speed Keybind",function() return Config.TpSettings.CarpetSpeedKey end,function(v) Config.TpSettings.CarpetSpeedKey=v end,53)
    do
        local csRow=Instance.new("Frame",tpS); csRow.Size=UDim2.new(1,0,0,34); csRow.BackgroundColor3=C().SURF; csRow.BorderSizePixel=0; csRow.LayoutOrder=54; Instance.new("UICorner",csRow).CornerRadius=UDim.new(0,7)
        local csl=Instance.new("TextLabel",csRow); csl.Size=UDim2.new(0.6,0,1,0); csl.Position=UDim2.new(0,10,0,0); csl.BackgroundTransparency=1; csl.Text="Carpet Speed Status"; csl.Font=Enum.Font.GothamBold; csl.TextSize=11; csl.TextColor3=C().TP; csl.TextXAlignment=Enum.TextXAlignment.Left
        local cslv=Instance.new("TextLabel",csRow); cslv.Size=UDim2.new(0,50,0,20); cslv.Position=UDim2.new(1,-58,0.5,-10); cslv.BackgroundTransparency=1; cslv.Font=Enum.Font.GothamBlack; cslv.TextSize=13; cslv.TextXAlignment=Enum.TextXAlignment.Right
        task.spawn(function() while csRow and csRow.Parent do local on=State.carpetSpeedEnabled; cslv.Text=on and"ON"or"OFF"; cslv.TextColor3=on and Theme.Success or Theme.Error; task.wait(0.3) end end)
    end


    -- ── UI HIDE'S TAB ──
    local uhS = tScrolls2["uih"]
    makeSec(uhS,"HIDE UIs",1)
    makeToggle(uhS,"Hide Admin Panel",function() return Config.HideAdminPanel end,function(v) Config.HideAdminPanel=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroAdminPanel"); if g then g.Enabled=not v end end,11)
    makeToggle(uhS,"Hide Auto Steal",function() return Config.HideAutoSteal end,function(v) Config.HideAutoSteal=v; SaveConfig(); local g=PlayerGui:FindFirstChild("AutoStealUI"); if g then g.Enabled=not v end end,12)
    makeToggle(uhS,"Hide Auto Buy UI",function() return Config.HideAutoBuyUI end,function(v) Config.HideAutoBuyUI=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroAutoBuyUI"); if g then local p=g:FindFirstChild("ABPanel"); if p then p.Visible=not v end end end,13)
    makeToggle(uhS,"Hide Steal Speed UI",function() return Config.HideStealSpeedUI end,function(v) Config.HideStealSpeedUI=v; SaveConfig(); local g=PlayerGui:FindFirstChild("StealSpeedUI"); if g then g.Enabled=not v end end,14)
    makeToggle(uhS,"Hide Status HUD",function() return Config.HideStatusHUD end,function(v) Config.HideStatusHUD=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroStatusHUD"); if g then g.Enabled=not v end end,15)
    makeToggle(uhS,"Hide Invis Panel",function() return Config.HideInvisPanel end,function(v) Config.HideInvisPanel=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroInvisPanel"); if g then g.Enabled=not v end end,16)
    makeToggle(uhS,"Hide Platform UI",function() return Config.HidePlatformUI end,function(v) Config.HidePlatformUI=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroPlatformUI"); if g then g.Enabled=not v end end,17)
    makeToggle(uhS,"Compact Auto Steal",function() return Config.CompactAutoSteal end,function(v) Config.CompactAutoSteal=v; SaveConfig() end,18)
    makeToggle(uhS,"Mostrar Mini UI",function() return Config.ShowMiniActions end,function(v) Config.ShowMiniActions=v; SaveConfig(); local g=PlayerGui:FindFirstChild("HeroMiniActions"); if g then local mp=g:FindFirstChild("MiniPanel"); if mp then mp.Visible=v end end end,19)
    makeToggle(uhS,"Auto Hide ao Iniciar",function() return Config.AutoHideMiniUI end,function(v) Config.AutoHideMiniUI=v; SaveConfig() end,20)

    -- ── INVIS TAB ──
    local iS = tScrolls2["inv"]
    makeToggle(iS,"Auto Fix Lagback",function() return _G.AutoRecoverLagback end,function(v) _G.AutoRecoverLagback=v; Config.AutoRecoverLagback=v; SaveConfig() end,1)

    do  -- Rotation slider
        local r = Instance.new("Frame", iS)
        r.Size = UDim2.new(1,0,0,52)
        r.BackgroundColor3 = C().SURF
        r.BorderSizePixel = 0
        r.LayoutOrder = 2
        Instance.new("UICorner", r).CornerRadius = UDim.new(0,7)
        local rl = Instance.new("TextLabel", r)
        rl.Size = UDim2.new(1,-20,0,18)
        rl.Position = UDim2.new(0,10,0,4)
        rl.BackgroundTransparency = 1
        rl.Text = "Rotation: "..Config.InvisStealAngle
        rl.Font = Enum.Font.GothamBold
        rl.TextSize = 12
        rl.TextColor3 = C().TP
        rl.TextXAlignment = Enum.TextXAlignment.Left
        local rbg = Instance.new("Frame", r)
        rbg.Size = UDim2.new(1,-20,0,6)
        rbg.Position = UDim2.new(0,10,0,32)
        rbg.BackgroundColor3 = C().SH
        rbg.BorderSizePixel = 0
        Instance.new("UICorner", rbg).CornerRadius = UDim.new(1,0)
        local rfill = Instance.new("Frame", rbg)
        rfill.BackgroundColor3 = Theme.Accent1
        rfill.BorderSizePixel = 0
        Instance.new("UICorner", rfill).CornerRadius = UDim.new(1,0)
        local rk = Instance.new("Frame", rbg)
        rk.Size = UDim2.new(0,13,0,13)
        rk.AnchorPoint = Vector2.new(0.5,0.5)
        rk.BackgroundColor3 = Color3.new(1,1,1)
        rk.BorderSizePixel = 0
        Instance.new("UICorner", rk).CornerRadius = UDim.new(1,0)
        local function updRot(v)
            v = math.clamp(math.floor(v),180,360)
            Config.InvisStealAngle=v; _G.InvisStealAngle=v; SaveConfig()
            rl.Text = "Rotation: "..v
            local p2 = (v-180)/180
            rfill.Size = UDim2.new(p2,0,1,0)
            rk.Position = UDim2.new(p2,0,0.5,0)
        end
        updRot(Config.InvisStealAngle)
        local rd = false
        rbg.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                rd=true; updRot(180+((i.Position.X-rbg.AbsolutePosition.X)/rbg.AbsoluteSize.X)*180)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then rd=false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if rd and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                updRot(180+((i.Position.X-rbg.AbsolutePosition.X)/rbg.AbsoluteSize.X)*180)
            end
        end)
    end

    do  -- Depth slider
        local r = Instance.new("Frame", iS)
        r.Size = UDim2.new(1,0,0,52)
        r.BackgroundColor3 = C().SURF
        r.BorderSizePixel = 0
        r.LayoutOrder = 3
        Instance.new("UICorner", r).CornerRadius = UDim.new(0,7)
        local rl = Instance.new("TextLabel", r)
        rl.Size = UDim2.new(1,-20,0,18)
        rl.Position = UDim2.new(0,10,0,4)
        rl.BackgroundTransparency = 1
        rl.Text = "Depth: "..Config.SinkSliderValue
        rl.Font = Enum.Font.GothamBold
        rl.TextSize = 12
        rl.TextColor3 = C().TP
        rl.TextXAlignment = Enum.TextXAlignment.Left
        local rbg = Instance.new("Frame", r)
        rbg.Size = UDim2.new(1,-20,0,6)
        rbg.Position = UDim2.new(0,10,0,32)
        rbg.BackgroundColor3 = C().SH
        rbg.BorderSizePixel = 0
        Instance.new("UICorner", rbg).CornerRadius = UDim.new(1,0)
        local rfill = Instance.new("Frame", rbg)
        rfill.BackgroundColor3 = Theme.Accent1
        rfill.BorderSizePixel = 0
        Instance.new("UICorner", rfill).CornerRadius = UDim.new(1,0)
        local rk = Instance.new("Frame", rbg)
        rk.Size = UDim2.new(0,13,0,13)
        rk.AnchorPoint = Vector2.new(0.5,0.5)
        rk.BackgroundColor3 = Color3.new(1,1,1)
        rk.BorderSizePixel = 0
        Instance.new("UICorner", rk).CornerRadius = UDim.new(1,0)
        local function updDepth(v)
            v = math.clamp(math.floor(v*10)/10, 0.5, 10)
            Config.SinkSliderValue=v; _G.SinkSliderValue=v; SaveConfig()
            rl.Text = "Depth: "..v
            local p2 = (v-0.5)/9.5
            rfill.Size = UDim2.new(p2,0,1,0)
            rk.Position = UDim2.new(p2,0,0.5,0)
        end
        updDepth(Config.SinkSliderValue)
        local dd = false
        rbg.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                dd=true; updDepth(0.5+((i.Position.X-rbg.AbsolutePosition.X)/rbg.AbsoluteSize.X)*9.5)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dd=false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dd and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                updDepth(0.5+((i.Position.X-rbg.AbsolutePosition.X)/rbg.AbsoluteSize.X)*9.5)
            end
        end)
    end

    -- ── TEMAS TAB ──
    local tS = tScrolls2["tem"]
    do
        local TDEFS2 = {
            {"Pink",   "rosa",     Color3.fromRGB(255,120,200)},
            {"Cyan",   "ciano",    Color3.fromRGB(0,220,255)},
            {"Black",  "preto",    Color3.fromRGB(180,180,200)},
            {"Purple", "roxo",     Color3.fromRGB(180,80,255)},
            {"Green",  "verde",    Color3.fromRGB(0,220,80)},
            {"Orange", "laranja",  Color3.fromRGB(255,140,0)},
            {"Red",    "vermelho", Color3.fromRGB(255,50,50)},
            {"Gray",   "cinza",    Color3.fromRGB(160,160,180)},
        }
        for i2, td2 in ipairs(TDEFS2) do
            local r = Instance.new("Frame", tS)
            r.Size = UDim2.new(1,0,0,36)
            r.BackgroundColor3 = C().SURF
            r.BorderSizePixel = 0
            r.LayoutOrder = i2
            Instance.new("UICorner", r).CornerRadius = UDim.new(0,7)

            local dot2 = Instance.new("Frame", r)
            dot2.Size = UDim2.new(0,12,0,12)
            dot2.Position = UDim2.new(0,12,0.5,-6)
            dot2.BackgroundColor3 = td2[3]
            dot2.BorderSizePixel = 0
            Instance.new("UICorner", dot2).CornerRadius = UDim.new(1,0)

            local nl = Instance.new("TextLabel", r)
            nl.Size = UDim2.new(0.5,0,1,0)
            nl.Position = UDim2.new(0,32,0,0)
            nl.BackgroundTransparency = 1
            nl.Text = td2[1]
            nl.Font = Enum.Font.GothamBold
            nl.TextSize = 12
            nl.TextColor3 = C().TP
            nl.TextXAlignment = Enum.TextXAlignment.Left

            local isActive = (Config.CurrentTheme == td2[2])
            local apb = Instance.new("TextButton", r)
            apb.Size = UDim2.new(0,72,0,24)
            apb.Position = UDim2.new(1,-80,0.5,-12)
            apb.BackgroundColor3 = isActive and td2[3] or C().SH
            apb.Text = isActive and "ATIVO" or "APLICAR"
            apb.Font = Enum.Font.GothamBold
            apb.TextSize = 10
            apb.TextColor3 = isActive and Color3.new(0,0,0) or C().TP
            apb.AutoButtonColor = false
            Instance.new("UICorner", apb).CornerRadius = UDim.new(0,5)
            local tid2 = td2[2]; local tc2 = td2[3]
            apb.MouseButton1Click:Connect(function()
                applyTheme(tid2)
                -- atualiza visual de todos os botoes
                for _, ch in ipairs(tS:GetChildren()) do
                    local b2 = ch:FindFirstChildOfClass("TextButton")
                    if b2 then
                        b2.BackgroundColor3 = C().SH
                        b2.Text = "APLICAR"
                        b2.TextColor3 = C().TP
                    end
                end
                apb.BackgroundColor3 = tc2
                apb.Text = "ATIVO"
                apb.TextColor3 = Color3.new(0,0,0)
            end)
        end
    end

    -- ── BLACKLIST TAB ──
    local blS = tScrolls2["bl"]

    -- ESP config for blacklisted players
    makeSec(blS, "BLACKLIST ESP", 0)
    makeToggle(blS, "Show Blacklist ESP", function() return Config.BlacklistESP ~= false end, function(v)
        Config.BlacklistESP = v; SaveConfig()
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                if char then
                    local existing = char:FindFirstChild("HeroBlacklistESP")
                    if existing then existing:Destroy() end
                end
            end
        end
    end, 1)

    -- Custom message row
    local blMsgRow = Instance.new("Frame", blS)
    blMsgRow.Size             = UDim2.new(1,0,0,36)
    blMsgRow.BackgroundColor3 = C().SURF
    blMsgRow.BackgroundTransparency = 0.05
    blMsgRow.BorderSizePixel  = 0
    blMsgRow.LayoutOrder      = 2
    Instance.new("UICorner", blMsgRow).CornerRadius = UDim.new(0,7)
    local blMsgLbl = Instance.new("TextLabel", blMsgRow)
    blMsgLbl.Size             = UDim2.new(0,60,1,0)
    blMsgLbl.Position         = UDim2.new(0,8,0,0)
    blMsgLbl.BackgroundTransparency = 1
    blMsgLbl.Text             = "Mensagem"
    blMsgLbl.Font             = Enum.Font.GothamBold
    blMsgLbl.TextSize         = 11
    blMsgLbl.TextColor3       = C().TP
    blMsgLbl.TextXAlignment   = Enum.TextXAlignment.Left
    local blMsgBox = Instance.new("TextBox", blMsgRow)
    blMsgBox.Size             = UDim2.new(1,-78,0,24)
    blMsgBox.Position         = UDim2.new(0,72,0.5,-12)
    blMsgBox.BackgroundColor3 = C().SH
    blMsgBox.Text             = Config.BlacklistMsg or "BLOCKED"
    blMsgBox.PlaceholderText  = "BLOCKED"
    blMsgBox.Font             = Enum.Font.GothamBold
    blMsgBox.TextSize         = 11
    blMsgBox.TextColor3       = C().TP
    blMsgBox.ClearTextOnFocus = false
    blMsgBox.BorderSizePixel  = 0
    Instance.new("UICorner", blMsgBox).CornerRadius = UDim.new(0,5)
    blMsgBox.FocusLost:Connect(function()
        local msg = blMsgBox.Text:gsub("%s+", " "):match("^%s*(.-)%s*$")
        if msg == "" then msg = "BLOCKED" end
        Config.BlacklistMsg = msg; SaveConfig()
        blMsgBox.Text = msg
        -- Live-update all existing ESP labels
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            if char then
                local bb = char:FindFirstChild("HeroBlacklistESP")
                if bb then
                    local lbl = bb:FindFirstChild("MsgLbl", true)
                    if lbl then lbl.Text = msg end
                end
            end
        end
    end)

    -- Input row
    local blInputRow = Instance.new("Frame", blS)
    blInputRow.Size = UDim2.new(1,0,0,44)
    blInputRow.BackgroundColor3 = C().SURF
    blInputRow.BorderSizePixel = 0
    blInputRow.LayoutOrder = 1
    Instance.new("UICorner", blInputRow).CornerRadius = UDim.new(0,7)

    local blBox = Instance.new("TextBox", blInputRow)
    blBox.Size = UDim2.new(1,-80,0,28)
    blBox.Position = UDim2.new(0,8,0.5,-14)
    blBox.BackgroundColor3 = C().SH
    blBox.Text = ""
    blBox.PlaceholderText = "Username..."
    blBox.Font = Enum.Font.GothamBold
    blBox.TextSize = 12
    blBox.TextColor3 = C().TP
    blBox.ClearTextOnFocus = false
    blBox.BorderSizePixel = 0
    Instance.new("UICorner", blBox).CornerRadius = UDim.new(0,6)

    local blAddBtn = Instance.new("TextButton", blInputRow)
    blAddBtn.Size = UDim2.new(0,60,0,28)
    blAddBtn.Position = UDim2.new(1,-68,0.5,-14)
    blAddBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
    blAddBtn.Text = "ADD"
    blAddBtn.Font = Enum.Font.GothamBold
    blAddBtn.TextSize = 12
    blAddBtn.TextColor3 = Color3.new(1,1,1)
    blAddBtn.AutoButtonColor = false
    blAddBtn.BorderSizePixel = 0
    Instance.new("UICorner", blAddBtn).CornerRadius = UDim.new(0,6)

    -- Counter label
    local blCount = Instance.new("Frame", blS)
    blCount.Size = UDim2.new(1,0,0,24)
    blCount.BackgroundTransparency = 1
    blCount.LayoutOrder = 2
    local blCountLbl = Instance.new("TextLabel", blCount)
    blCountLbl.Size = UDim2.new(1,0,1,0)
    blCountLbl.BackgroundTransparency = 1
    blCountLbl.Text = "BLACKLISTED (0)"
    blCountLbl.Font = Enum.Font.GothamBlack
    blCountLbl.TextSize = 11
    blCountLbl.TextColor3 = Color3.fromRGB(180,40,40)
    blCountLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- List container
    local blListContainer = Instance.new("Frame", blS)
    blListContainer.Size = UDim2.new(1,0,0,10) -- auto grows
    blListContainer.BackgroundTransparency = 1
    blListContainer.LayoutOrder = 3
    blListContainer.AutomaticSize = Enum.AutomaticSize.Y
    local blListLayout = Instance.new("UIListLayout", blListContainer)
    blListLayout.Padding = UDim.new(0,4)
    blListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- refreshBlacklistUI function
    refreshBlacklistUI = function()
        -- clear existing rows
        for _, ch in ipairs(blListContainer:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        blCountLbl.Text = "BLACKLISTED (" .. #BlacklistedPlayers .. ")"

        for i, name in ipairs(BlacklistedPlayers) do
            local entRow = Instance.new("Frame", blListContainer)
            entRow.Size = UDim2.new(1,0,0,36)
            entRow.BackgroundColor3 = Color3.fromRGB(50,20,20)
            entRow.BorderSizePixel = 0
            entRow.LayoutOrder = i
            Instance.new("UICorner", entRow).CornerRadius = UDim.new(0,7)
            local entStroke = Instance.new("UIStroke", entRow)
            entStroke.Color = Color3.fromRGB(180,40,40)
            entStroke.Thickness = 1; entStroke.Transparency = 0.5

            local iconLbl = Instance.new("TextLabel", entRow)
            iconLbl.Size = UDim2.new(0,24,1,0)
            iconLbl.Position = UDim2.new(0,6,0,0)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Text = "🚫"
            iconLbl.TextSize = 14
            iconLbl.Font = Enum.Font.GothamBold
            iconLbl.TextColor3 = Color3.fromRGB(255,100,100)

            local nameLbl = Instance.new("TextLabel", entRow)
            nameLbl.Size = UDim2.new(1,-70,1,0)
            nameLbl.Position = UDim2.new(0,34,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = name
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 12
            nameLbl.TextColor3 = C().TP
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local remBtn = Instance.new("TextButton", entRow)
            remBtn.Size = UDim2.new(0,50,0,24)
            remBtn.Position = UDim2.new(1,-56,0.5,-12)
            remBtn.BackgroundColor3 = C().SH
            remBtn.Text = "❌"
            remBtn.Font = Enum.Font.GothamBold
            remBtn.TextSize = 13
            remBtn.TextColor3 = Theme.TextPrimary
            remBtn.AutoButtonColor = false
            remBtn.BorderSizePixel = 0
            Instance.new("UICorner", remBtn).CornerRadius = UDim.new(0,6)
            local n = name
            remBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    removeFromBlacklist(n)
                    ShowNotification("BLACKLIST", "✅ Removed: " .. n)
                    refreshBlacklistUI()
                end)
            end)
        end

        if #BlacklistedPlayers == 0 then
            local empty = Instance.new("TextLabel", blListContainer)
            empty.Size = UDim2.new(1,0,0,36)
            empty.BackgroundTransparency = 1
            empty.Text = "No players blacklisted"
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 12
            empty.TextColor3 = C().TS
            empty.LayoutOrder = 1
        end
    end
    refreshBlacklistUI()

    blAddBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local name = blBox.Text:gsub("%s", "")
            if name == "" then return end
            if addToBlacklist(name) then
                ShowNotification("BLACKLIST", "🚫 Blocked: " .. name)
                blBox.Text = ""
                refreshBlacklistUI()
            else
                ShowNotification("BLACKLIST", name .. " already blacklisted")
            end
        end)
    end)

    blBox.FocusLost:Connect(function(enter)
        if enter then blAddBtn.MouseButton1Click:Fire() end
    end)

    switchTab2("act")

    -- Expor ref global
    _G.HeroSettingsUI = {panel=panel, switchTab=switchTab2, currentTab="act"}
end
task.spawn(buildHeroSettingsUI)

-- ============================================================
-- PLATFORM UI - slider para ajustar altura da plataforma
-- ============================================================
task.spawn(function()
    local platGui = Instance.new("ScreenGui")
    platGui.Name = "HeroPlatformUI"
    platGui.ResetOnSpawn = false
    platGui.DisplayOrder = 15
    platGui.Enabled = not Config.HidePlatformUI
    platGui.Parent = PlayerGui

    local pPanel = Instance.new("Frame", platGui)
    pPanel.Name = "PlatPanel"
    pPanel.Size = UDim2.new(0, 220, 0, 90)
    pPanel.Position = UDim2.new(0.5, -110, 0, 10)
    pPanel.BackgroundColor3 = Theme.Background
    pPanel.BackgroundTransparency = 0.08
    pPanel.BorderSizePixel = 0
    Instance.new("UICorner", pPanel).CornerRadius = UDim.new(0, 10)

    local pStroke = Instance.new("UIStroke", pPanel)
    pStroke.Color = Theme.Accent1
    pStroke.Thickness = 1.5
    pStroke.Transparency = 0.4

    task.defer(function() if addRacetrackBorder then addRacetrackBorder(pPanel, Theme.Accent1, 3) end end)

    -- Header / drag
    local pHdr = Instance.new("Frame", pPanel)
    pHdr.Size = UDim2.new(1, 0, 0, 30)
    pHdr.BackgroundTransparency = 1
    MakeDraggable(pHdr, pPanel)

    local pTitle = Instance.new("TextLabel", pHdr)
    pTitle.Size = UDim2.new(1, -12, 1, 0)
    pTitle.Position = UDim2.new(0, 12, 0, 0)
    pTitle.BackgroundTransparency = 1
    pTitle.Text = "PLATFORM HEIGHT"
    pTitle.Font = Enum.Font.GothamBlack
    pTitle.TextSize = 12
    pTitle.TextColor3 = Theme.Accent1
    pTitle.TextXAlignment = Enum.TextXAlignment.Left

    local pVal = Instance.new("TextLabel", pHdr)
    pVal.Size = UDim2.new(0, 50, 1, 0)
    pVal.Position = UDim2.new(1, -55, 0, 0)
    pVal.BackgroundTransparency = 1
    pVal.Text = string.format("%.1f", Config.PlatformOffset or 12.5)
    pVal.Font = Enum.Font.GothamBlack
    pVal.TextSize = 13
    pVal.TextColor3 = Theme.TextPrimary
    pVal.TextXAlignment = Enum.TextXAlignment.Right

    -- Slider
    local PLAT_MIN, PLAT_MAX = 1, 30
    local slBg = Instance.new("Frame", pPanel)
    slBg.Size = UDim2.new(1, -24, 0, 6)
    slBg.Position = UDim2.new(0, 12, 0, 40)
    slBg.BackgroundColor3 = Theme.SurfaceHighlight
    slBg.BorderSizePixel = 0
    Instance.new("UICorner", slBg).CornerRadius = UDim.new(1, 0)

    local slFill = Instance.new("Frame", slBg)
    slFill.BackgroundColor3 = Theme.Accent1
    slFill.BorderSizePixel = 0
    slFill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", slFill).CornerRadius = UDim.new(1, 0)

    local slKnob = Instance.new("Frame", slBg)
    slKnob.Size = UDim2.new(0, 14, 0, 14)
    slKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    slKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    slKnob.BorderSizePixel = 0
    Instance.new("UICorner", slKnob).CornerRadius = UDim.new(1, 0)
    local slKS = Instance.new("UIStroke", slKnob)
    slKS.Color = Theme.Accent1; slKS.Thickness = 1.5

    local function updatePlatSlider(v)
        v = math.clamp(math.floor(v * 10) / 10, PLAT_MIN, PLAT_MAX)
        Config.PlatformOffset = v
        SaveConfig()
        pVal.Text = string.format("%.1f", v)
        local pct = (v - PLAT_MIN) / (PLAT_MAX - PLAT_MIN)
        slFill.Size = UDim2.new(pct, 0, 1, 0)
        slKnob.Position = UDim2.new(pct, 0, 0.5, 0)
    end
    updatePlatSlider(Config.PlatformOffset or 12.5)

    local slDrag = false
    slBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            slDrag = true
            updatePlatSlider(PLAT_MIN + ((i.Position.X - slBg.AbsolutePosition.X) / slBg.AbsoluteSize.X) * (PLAT_MAX - PLAT_MIN))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if slDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updatePlatSlider(PLAT_MIN + ((i.Position.X - slBg.AbsolutePosition.X) / slBg.AbsoluteSize.X) * (PLAT_MAX - PLAT_MIN))
        end
    end)

    -- Min/Max labels
    local minL = Instance.new("TextLabel", pPanel)
    minL.Size = UDim2.new(0, 20, 0, 14)
    minL.Position = UDim2.new(0, 12, 0, 52)
    minL.BackgroundTransparency = 1
    minL.Text = "1"
    minL.Font = Enum.Font.GothamMedium
    minL.TextSize = 10
    minL.TextColor3 = Theme.TextSecondary
    minL.TextXAlignment = Enum.TextXAlignment.Left

    local maxL = Instance.new("TextLabel", pPanel)
    maxL.Size = UDim2.new(0, 24, 0, 14)
    maxL.Position = UDim2.new(1, -36, 0, 52)
    maxL.BackgroundTransparency = 1
    maxL.Text = "30"
    maxL.Font = Enum.Font.GothamMedium
    maxL.TextSize = 10
    maxL.TextColor3 = Theme.TextSecondary
    maxL.TextXAlignment = Enum.TextXAlignment.Right

    -- Info label
    local infoL = Instance.new("TextLabel", pPanel)
    infoL.Size = UDim2.new(1, -24, 0, 14)
    infoL.Position = UDim2.new(0, 12, 0, 68)
    infoL.BackgroundTransparency = 1
    infoL.Text = "studs abaixo do brainrot"
    infoL.Font = Enum.Font.GothamMedium
    infoL.TextSize = 9
    infoL.TextColor3 = Theme.TextSecondary
    infoL.TextXAlignment = Enum.TextXAlignment.Center
end)

-- Aplica tema salvo em todas as UIs apos tudo ser criado
task.spawn(function()
    task.wait(1.5)
    if Config.CurrentTheme and THEMES and THEMES[Config.CurrentTheme] then
        applyTheme(Config.CurrentTheme)
    end
end)


-- ============================================================
-- MINI ACTIONS UI - botoes rapidos arrastavel com lock
-- ============================================================
function buildMiniActionsUI()
    local pg = PlayerGui
    if not pg then return end
    local oldG = pg:FindFirstChild("HeroMiniActions")
    if oldG then oldG:Destroy() end

    local maGui = Instance.new("ScreenGui")
    maGui.Name = "HeroMiniActions"
    maGui.ResetOnSpawn = false
    maGui.DisplayOrder = 25
    maGui.Parent = pg

    -- Painel
    local W = 150
    local BTN_H = 38
    local BTNS = 7
    local H = BTNS * BTN_H + (BTNS-1)*4 + 44 -- header + buttons

    local panel = Instance.new("Frame", maGui)
    panel.Name = "MiniPanel"
    panel.Size = UDim2.new(0, W, 0, H)
    local savedPos = Config.MiniUIPos or {X=0.01, Y=0.35}
    panel.Position = UDim2.new(savedPos.X, 0, savedPos.Y, 0)
    panel.BackgroundColor3 = Theme.Background
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = not Config.AutoHideMiniUI
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

    local pStroke = Instance.new("UIStroke", panel)
    pStroke.Color = Theme.Accent1
    pStroke.Thickness = 1.2
    pStroke.Transparency = 0.5

    -- Header drag area
    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundTransparency = 1

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "ACTIONS"
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = Theme.Accent1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Lock button
    local lockBtn = Instance.new("TextButton", header)
    lockBtn.Size = UDim2.new(0, 22, 0, 22)
    lockBtn.Position = UDim2.new(1, -28, 0.5, -11)
    lockBtn.BackgroundColor3 = Config.MiniUILocked and Theme.Accent1 or Theme.SurfaceHighlight
    lockBtn.BackgroundTransparency = 0.1
    lockBtn.Text = Config.MiniUILocked and "🔒" or "🔓"
    lockBtn.Font = Enum.Font.GothamBold
    lockBtn.TextSize = 12
    lockBtn.TextColor3 = Color3.new(1,1,1)
    lockBtn.AutoButtonColor = false
    Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(1, 0)
    local lockStroke = Instance.new("UIStroke", lockBtn)
    lockStroke.Color = Theme.Accent1
    lockStroke.Thickness = 1
    lockStroke.Transparency = 0.4

    lockBtn.MouseButton1Click:Connect(function()
        Config.MiniUILocked = not Config.MiniUILocked
        SaveConfig()
        lockBtn.Text = Config.MiniUILocked and "🔒" or "🔓"
        lockBtn.BackgroundColor3 = Config.MiniUILocked and Theme.Accent1 or Theme.SurfaceHighlight
    end)

    -- Drag (only when not locked)
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(inp)
            if Config.MiniUILocked then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = inp.Position
                startPos = panel.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        local ps = panel.Parent.AbsoluteSize
                        Config.MiniUIPos = {
                            X = panel.AbsolutePosition.X / ps.X,
                            Y = panel.AbsolutePosition.Y / ps.Y,
                        }
                        SaveConfig()
                    end
                end)
            end
        end)
        header.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                if dragging and dragStart then
                    local delta = inp.Position - dragStart
                    panel.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local delta = inp.Position - dragStart
                panel.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Divisor
    local div = Instance.new("Frame", panel)
    div.Size = UDim2.new(1, -16, 0, 1)
    div.Position = UDim2.new(0, 8, 0, 36)
    div.BackgroundColor3 = Theme.SurfaceHighlight
    div.BorderSizePixel = 0

    -- Content area
    local cont = Instance.new("Frame", panel)
    cont.Size = UDim2.new(1, -12, 1, -42)
    cont.Position = UDim2.new(0, 6, 0, 40)
    cont.BackgroundTransparency = 1

    local ll = Instance.new("UIListLayout", cont)
    ll.Padding = UDim.new(0, 4)
    ll.SortOrder = Enum.SortOrder.LayoutOrder

    -- Helper: make action button
    local function mBtn(lbl, order, col, cb)
        local b = Instance.new("TextButton", cont)
        b.Size = UDim2.new(1, 0, 0, BTN_H)
        b.BackgroundColor3 = col or Theme.Surface
        b.BackgroundTransparency = 0.05
        b.Text = lbl
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.TextColor3 = Theme.TextPrimary
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.LayoutOrder = order
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local bs = Instance.new("UIStroke", b)
        bs.Color = col or Theme.SurfaceHighlight
        bs.Thickness = 1
        bs.Transparency = 0.5
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency=0}):Play()
            TweenService:Create(bs, TweenInfo.new(0.1), {Transparency=0.1}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency=0.05}):Play()
            TweenService:Create(bs, TweenInfo.new(0.1), {Transparency=0.5}):Play()
        end)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    -- ── BUTTONS ─────────────────────────────────────────────────────────
    local tpKey   = Config.TpSettings and Config.TpSettings.TpKey or "T"
    local ragKey  = Config.RagdollSelfKey ~= "" and Config.RagdollSelfKey or "Y"
    local kickKey = Config.KickKey ~= "" and Config.KickKey or "T"
    local resetKey = Config.ResetKey or "X"

    -- 1. Teleport
    mBtn("Teleport ("..tpKey..")", 1, Theme.Surface, function()
        task.spawn(runAutoSnipe)
        ShowNotification("TP", "Teleportando...")
    end)

    -- 2. Ragdoll Self
    mBtn("Ragdoll Self ("..ragKey..")", 2, Theme.Surface, function()
        task.spawn(function()
            if _G.runAdminCommand then
                if _G.runAdminCommand(LocalPlayer, "ragdoll") then
                    ShowNotification("RAGDOLL", "Ativado")
                end
            end
        end)
    end)

    -- 3. Rejoin
    mBtn("Rejoin", 3, Theme.Surface, function()
        ShowNotification("REJOIN", "Reconectando...")
        task.delay(0.5, function()
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end)
    end)

    -- 4. Kick
    mBtn("Kick ("..kickKey..")", 4, Color3.fromRGB(180, 40, 60), function()
        kickPlayer()
    end)

    -- 5. Reset
    mBtn("Reset ("..resetKey..")", 5, Color3.fromRGB(200, 60, 40), function()
        executeReset()
        ShowNotification("RESET", "Resetando...")
    end)

    -- 6. Auto Kick toggle
    do
        local akBtn = mBtn("Auto Kick: OFF", 6, Theme.Surface, function() end)

        local function updateAKBtn()
            local on = Config.AutoKickOnSteal
            akBtn.Text             = on and "Auto Kick: ON" or "Auto Kick: OFF"
            akBtn.BackgroundColor3 = on and Theme.Accent1 or Theme.Surface
            akBtn.TextColor3       = on and Color3.new(0,0,0) or Theme.TextPrimary
        end
        updateAKBtn()

        akBtn.MouseButton1Click:Connect(function()
            Config.AutoKickOnSteal = not Config.AutoKickOnSteal
            SaveConfig()
            updateAKBtn()
            if _G.setAutoKickFromSettings then
                _G.setAutoKickFromSettings(Config.AutoKickOnSteal)
            end
        end)

        _G.setAutoKickFromMiniUI = updateAKBtn
    end

    _G.setAutoKickFromSettings = function(val)
        Config.AutoKickOnSteal = val
        SaveConfig()
        if _G.setAutoKickFromMiniUI then _G.setAutoKickFromMiniUI() end
    end




    -- ── AUTO BUY UI + BUTTON ────────────────────────────────────────────
    local autoBuyActive = false
    _G.AutoBuyEsteira   = false

    -- Destroy any leftover from previous build
    local _oldAB = PlayerGui:FindFirstChild("HeroAutoBuyUI")
    if _oldAB then _oldAB:Destroy() end

    local abGui = Instance.new("ScreenGui")
    abGui.Name         = "HeroAutoBuyUI"
    abGui.ResetOnSpawn = false
    abGui.DisplayOrder = 30
    abGui.Parent       = PlayerGui

    local abPanel = Instance.new("Frame", abGui)
    abPanel.Name             = "ABPanel"
    abPanel.Size             = UDim2.new(0, 215, 0, 260)
    local _savedAbPos = Config.Positions and Config.Positions.AutoBuy or {X=0.01, Y=0.35}
    abPanel.Position         = UDim2.new(_savedAbPos.X, 0, _savedAbPos.Y, 0)
    abPanel.BackgroundColor3 = Theme.Background
    abPanel.BackgroundTransparency = 0.08
    abPanel.BorderSizePixel  = 0
    abPanel.Visible          = not (Config.HideAutoBuyUI == true)
    Instance.new("UICorner", abPanel).CornerRadius = UDim.new(0, 10)
    local abStroke = Instance.new("UIStroke", abPanel)
    abStroke.Color = Theme.Accent1; abStroke.Thickness = 1.8; abStroke.Transparency = 0.35
    task.defer(function()
        if addRacetrackBorder then addRacetrackBorder(abPanel, Theme.Accent1, 3.5) end
    end)

    -- Header + drag
    local abHdr = Instance.new("Frame", abPanel)
    abHdr.Size               = UDim2.new(1,0,0,36)
    abHdr.BackgroundTransparency = 1
    MakeDraggable(abHdr, abPanel, "AutoBuy")

    local abTitle = Instance.new("TextLabel", abHdr)
    abTitle.Size             = UDim2.new(1,-12,1,0)
    abTitle.Position         = UDim2.new(0,12,0,0)
    abTitle.BackgroundTransparency = 1
    abTitle.Text             = "AUTO BUY"
    abTitle.Font             = Enum.Font.GothamBlack
    abTitle.TextSize         = 15
    abTitle.TextColor3       = Theme.Accent1
    abTitle.TextXAlignment   = Enum.TextXAlignment.Left

    -- Divider
    local abDiv = Instance.new("Frame", abPanel)
    abDiv.Size             = UDim2.new(1,-20,0,1)
    abDiv.Position         = UDim2.new(0,10,0,36)
    abDiv.BackgroundColor3 = Theme.Accent1
    abDiv.BackgroundTransparency = 0.6
    abDiv.BorderSizePixel  = 0

    -- Content list
    local abContent = Instance.new("Frame", abPanel)
    abContent.Size             = UDim2.new(1,-16,1,-46)
    abContent.Position         = UDim2.new(0,8,0,44)
    abContent.BackgroundTransparency = 1
    local abLayout = Instance.new("UIListLayout", abContent)
    abLayout.Padding   = UDim.new(0,6)
    abLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeAbRow(h, order)
        local r = Instance.new("Frame", abContent)
        r.Size             = UDim2.new(1,0,0,h)
        r.BackgroundColor3 = Theme.Surface
        r.BackgroundTransparency = 0.05
        r.BorderSizePixel  = 0
        r.LayoutOrder      = order
        Instance.new("UICorner", r).CornerRadius = UDim.new(0,7)
        return r
    end

    -- 1) Toggle button
    local abToggleRow = makeAbRow(38, 1)
    local abToggleBtn = Instance.new("TextButton", abToggleRow)
    abToggleBtn.Size             = UDim2.new(1,0,1,0)
    abToggleBtn.BackgroundColor3 = Theme.Surface
    abToggleBtn.BackgroundTransparency = 0
    abToggleBtn.Text             = "AUTO BUY: OFF"
    abToggleBtn.Font             = Enum.Font.GothamBlack
    abToggleBtn.TextSize         = 13
    abToggleBtn.TextColor3       = Theme.TextSecondary
    abToggleBtn.BorderSizePixel  = 0
    abToggleBtn.AutoButtonColor  = false
    Instance.new("UICorner", abToggleBtn).CornerRadius = UDim.new(0,7)
    local abToggleStroke = Instance.new("UIStroke", abToggleBtn)
    abToggleStroke.Color = Theme.Accent1; abToggleStroke.Thickness = 1.5; abToggleStroke.Transparency = 0.5

    -- 2) Keybind row
    local abKeyRow = makeAbRow(34, 2)
    local abKeyLbl = Instance.new("TextLabel", abKeyRow)
    abKeyLbl.Size             = UDim2.new(1,-70,1,0)
    abKeyLbl.Position         = UDim2.new(0,10,0,0)
    abKeyLbl.BackgroundTransparency = 1
    abKeyLbl.Text             = "Keybind"
    abKeyLbl.Font             = Enum.Font.GothamBold
    abKeyLbl.TextSize         = 12
    abKeyLbl.TextColor3       = Theme.TextPrimary
    abKeyLbl.TextXAlignment   = Enum.TextXAlignment.Left
    local abKeyBtn = Instance.new("TextButton", abKeyRow)
    abKeyBtn.Size             = UDim2.new(0,56,0,24)
    abKeyBtn.Position         = UDim2.new(1,-62,0.5,-12)
    abKeyBtn.BackgroundColor3 = Theme.SurfaceHighlight
    abKeyBtn.Text             = Config.AutoBuyKey or "K"
    abKeyBtn.Font             = Enum.Font.GothamBold
    abKeyBtn.TextSize         = 11
    abKeyBtn.TextColor3       = Theme.Accent1
    abKeyBtn.AutoButtonColor  = false
    abKeyBtn.BorderSizePixel  = 0
    Instance.new("UICorner", abKeyBtn).CornerRadius = UDim.new(0,5)
    abKeyBtn.MouseButton1Click:Connect(function()
        abKeyBtn.Text = "..."; abKeyBtn.TextColor3 = Theme.TextSecondary
        local c; c = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Config.AutoBuyKey = inp.KeyCode.Name
                abKeyBtn.Text = inp.KeyCode.Name
                abKeyBtn.TextColor3 = Theme.Accent1
                SaveConfig(); c:Disconnect()
            end
        end)
    end)

    -- 3) Range slider
    local abRangeRow = makeAbRow(42, 3)
    local abRangeLbl = Instance.new("TextLabel", abRangeRow)
    abRangeLbl.Size           = UDim2.new(1,-10,0,16)
    abRangeLbl.Position       = UDim2.new(0,10,0,4)
    abRangeLbl.BackgroundTransparency = 1
    abRangeLbl.Text           = "Range: " .. (Config.AutoBuyRange or 17) .. " studs"
    abRangeLbl.Font           = Enum.Font.GothamBold
    abRangeLbl.TextSize       = 11
    abRangeLbl.TextColor3     = Theme.TextPrimary
    abRangeLbl.TextXAlignment = Enum.TextXAlignment.Left
    local abSlBg = Instance.new("Frame", abRangeRow)
    abSlBg.Size             = UDim2.new(1,-20,0,6)
    abSlBg.Position         = UDim2.new(0,10,0,28)
    abSlBg.BackgroundColor3 = Theme.SurfaceHighlight
    abSlBg.BorderSizePixel  = 0
    Instance.new("UICorner", abSlBg).CornerRadius = UDim.new(1,0)
    local abSlFill = Instance.new("Frame", abSlBg)
    abSlFill.BackgroundColor3 = Theme.Accent1
    abSlFill.BorderSizePixel  = 0
    Instance.new("UICorner", abSlFill).CornerRadius = UDim.new(1,0)
    local abSlKnob = Instance.new("Frame", abSlBg)
    abSlKnob.Size         = UDim2.new(0,13,0,13)
    abSlKnob.AnchorPoint  = Vector2.new(0.5,0.5)
    abSlKnob.BackgroundColor3 = Color3.new(1,1,1)
    abSlKnob.BorderSizePixel  = 0
    Instance.new("UICorner", abSlKnob).CornerRadius = UDim.new(1,0)
    local abSlKS = Instance.new("UIStroke", abSlKnob)
    abSlKS.Color = Theme.Accent1; abSlKS.Thickness = 1.5
    local AB_MIN, AB_MAX = 5, 40
    local function updateAbSlider(v)
        v = math.clamp(math.floor(v), AB_MIN, AB_MAX)
        Config.AutoBuyRange = v; SaveConfig()
        abRangeLbl.Text = "Range: " .. v .. " studs"
        local pct = (v-AB_MIN)/(AB_MAX-AB_MIN)
        abSlFill.Size     = UDim2.new(pct,0,1,0)
        abSlKnob.Position = UDim2.new(pct,0,0.5,0)
        -- live update ring size
        local ring = Workspace:FindFirstChild("XiAutoBuyRing")
        if ring then ring.Size = Vector3.new(0.5, v*2, v*2) end
    end
    updateAbSlider(Config.AutoBuyRange or 17)
    local abDrag = false
    abSlBg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            abDrag=true
            updateAbSlider(AB_MIN+((i.Position.X-abSlBg.AbsolutePosition.X)/abSlBg.AbsoluteSize.X)*(AB_MAX-AB_MIN))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then abDrag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if abDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            updateAbSlider(AB_MIN+((i.Position.X-abSlBg.AbsolutePosition.X)/abSlBg.AbsoluteSize.X)*(AB_MAX-AB_MIN))
        end
    end)

    -- 4) Circle color row — one swatch per theme, 2 rows of 4
    local abCircleRow = makeAbRow(60, 4)
    local abCircleLbl = Instance.new("TextLabel", abCircleRow)
    abCircleLbl.Size             = UDim2.new(1,0,0,18)
    abCircleLbl.Position         = UDim2.new(0,10,0,4)
    abCircleLbl.BackgroundTransparency = 1
    abCircleLbl.Text             = "Circle Color"
    abCircleLbl.Font             = Enum.Font.GothamBold
    abCircleLbl.TextSize         = 11
    abCircleLbl.TextColor3       = Theme.TextPrimary
    abCircleLbl.TextXAlignment   = Enum.TextXAlignment.Left

    -- Fixed ordered theme colors (same order as THEMES table)
    local THEME_SWATCHES = {
        {"rosa",    Color3.fromRGB(255,120,200)},
        {"ciano",   Color3.fromRGB(0,220,255)},
        {"dourado", Color3.fromRGB(255,215,0)},
        {"prata",   Color3.fromRGB(210,215,235)},
        {"preto",   Color3.fromRGB(200,200,210)},
        {"roxo",    Color3.fromRGB(180,80,255)},
        {"verde",   Color3.fromRGB(0,220,80)},
        {"laranja", Color3.fromRGB(255,140,0)},
    }

    local abSwatchFrame = Instance.new("Frame", abCircleRow)
    abSwatchFrame.Size             = UDim2.new(1,-16,0,36)
    abSwatchFrame.Position         = UDim2.new(0,8,0,22)
    abSwatchFrame.BackgroundTransparency = 1
    local swatchGrid = Instance.new("UIGridLayout", abSwatchFrame)
    swatchGrid.CellSize        = UDim2.new(0,24,0,16)
    swatchGrid.CellPadding     = UDim2.new(0,4,0,4)
    swatchGrid.SortOrder       = Enum.SortOrder.LayoutOrder
    swatchGrid.FillDirection   = Enum.FillDirection.Horizontal

    local function buildCirclePresets()
        for _, ch in ipairs(abSwatchFrame:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for i, td in ipairs(THEME_SWATCHES) do
            local tname, col = td[1], td[2]
            -- update color from actual theme in case it changed
            if THEMES[tname] then col = THEMES[tname].Accent1 end
            local cb = Instance.new("TextButton", abSwatchFrame)
            cb.LayoutOrder      = i
            cb.Size             = UDim2.new(0,24,0,16)
            cb.BackgroundColor3 = col
            cb.Text             = ""
            cb.BorderSizePixel  = 0
            cb.AutoButtonColor  = false
            Instance.new("UICorner", cb).CornerRadius = UDim.new(0,4)
            -- white ring if this is the current selected circle color
            local selStroke = Instance.new("UIStroke", cb)
            selStroke.Thickness = 1.5
            local cur = Config.AutoBuyColor
            local match = cur and math.abs(cur.R - math.floor(col.R*255)) < 2
                              and math.abs(cur.G - math.floor(col.G*255)) < 2
                              and math.abs(cur.B - math.floor(col.B*255)) < 2
            selStroke.Color       = Color3.new(1,1,1)
            selStroke.Transparency = match and 0 or 1
            cb.MouseButton1Click:Connect(function()
                Config.AutoBuyColor = {
                    R = math.floor(col.R*255),
                    G = math.floor(col.G*255),
                    B = math.floor(col.B*255),
                }
                SaveConfig()
                local ring = Workspace:FindFirstChild("XiAutoBuyRing")
                if ring then ring.Color = col end
                -- update selection strokes
                buildCirclePresets()
            end)
        end
    end
    buildCirclePresets()
    _G.rebuildAutoBuyCirclePresets = buildCirclePresets

    -- ── RING CIRCLE (same pattern as proxViz) ───────────────────────────
    local abRing = nil
    local function getCircleColor()
        -- Circle uses Accent2 from theme so it differs from the panel border (Accent1)
        -- Can also be overridden by Config.AutoBuyColor presets
        if Config.AutoBuyColor then
            local c = Config.AutoBuyColor
            return Color3.fromRGB(c.R, c.G, c.B)
        end
        return Theme.Accent2 or Theme.Accent1
    end
    local function createRing()
        local existing = Workspace:FindFirstChild("XiAutoBuyRing")
        if existing then existing:Destroy() end
        local r = Instance.new("Part")
        r.Name         = "XiAutoBuyRing"
        r.Shape        = Enum.PartType.Cylinder
        r.Anchored     = true
        r.CanCollide   = false
        r.CanTouch     = false
        r.CanQuery     = false
        r.CastShadow   = false
        r.Material     = Enum.Material.Neon
        r.Transparency = 0.5
        r.Color        = getCircleColor()
        local range    = Config.AutoBuyRange or 17
        r.Size         = Vector3.new(0.5, range*2, range*2)
        r.Parent       = Workspace
        abRing = r
    end
    local function destroyRing()
        if abRing then abRing:Destroy(); abRing = nil end
        local existing = Workspace:FindFirstChild("XiAutoBuyRing")
        if existing then existing:Destroy() end
    end
    -- Expose so applyTheme can update ring color live
    _G.updateAutoBuyRingColor = function()
        if abRing and abRing.Parent then abRing.Color = getCircleColor() end
    end

    -- Follow player (same as proxViz pattern)
    RunService.Heartbeat:Connect(function()
        if not autoBuyActive then return end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not abRing or not abRing.Parent then return end
        local range = Config.AutoBuyRange or 17
        abRing.Size  = Vector3.new(0.5, range*2, range*2)
        abRing.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90)) + Vector3.new(0, -2.5, 0)
    end)

    -- ── TOGGLE ────────────────────────────────────────────────────────────
    local function toggleAutoBuy()
        autoBuyActive = not autoBuyActive
        _G.AutoBuyEsteira = autoBuyActive
        if autoBuyActive then
            abToggleBtn.Text             = "AUTO BUY: ON"
            abToggleBtn.BackgroundColor3 = Theme.Accent1
            abToggleBtn.TextColor3       = Color3.new(0,0,0)
            abToggleStroke.Transparency  = 1
            createRing()
        else
            abToggleBtn.Text             = "AUTO BUY: OFF"
            abToggleBtn.BackgroundColor3 = Theme.Surface
            abToggleBtn.TextColor3       = Theme.TextSecondary
            abToggleStroke.Transparency  = 0.5
            destroyRing()
        end
        -- call backend carpet lock
        if _G.AutoBuyOnToggle then _G.AutoBuyOnToggle(autoBuyActive) end
        ShowNotification("AUTO BUY", autoBuyActive and "✅ ATIVADO" or "❌ DESATIVADO")
    end

    -- mini gui button
    local autoBuyBtn = mBtn("Auto Buy: OFF", 7, Theme.Surface, function() end)
    -- override click
    autoBuyBtn.MouseButton1Click:Connect(function()
        toggleAutoBuy()
        autoBuyBtn.Text             = autoBuyActive and "Auto Buy: ON" or "Auto Buy: OFF"
        autoBuyBtn.BackgroundColor3 = autoBuyActive and Theme.Accent1 or Theme.Surface
        autoBuyBtn.TextColor3       = autoBuyActive and Color3.new(0,0,0) or Theme.TextPrimary
    end)
    abToggleBtn.MouseButton1Click:Connect(function()
        toggleAutoBuy()
        autoBuyBtn.Text             = autoBuyActive and "Auto Buy: ON" or "Auto Buy: OFF"
        autoBuyBtn.BackgroundColor3 = autoBuyActive and Theme.Accent1 or Theme.Surface
        autoBuyBtn.TextColor3       = autoBuyActive and Color3.new(0,0,0) or Theme.TextPrimary
    end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local key = Config.AutoBuyKey or "K"
        local ok, kc = pcall(function() return Enum.KeyCode[key] end)
        if ok and kc and inp.KeyCode == kc then
            toggleAutoBuy()
            autoBuyBtn.Text             = autoBuyActive and "Auto Buy: ON" or "Auto Buy: OFF"
            autoBuyBtn.BackgroundColor3 = autoBuyActive and Theme.Accent1 or Theme.Surface
            autoBuyBtn.TextColor3       = autoBuyActive and Color3.new(0,0,0) or Theme.TextPrimary
        end
    end)

    -- Racetrack border
    task.defer(function()
        if addRacetrackBorder then addRacetrackBorder(panel, Theme.Accent1, 3.5) end
    end)

    -- Recreate ring on character respawn
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if autoBuyActive then createRing() end
    end)



    -- ── AUTO BUY BACKEND ─────────────────────────────────────────────────
    task.spawn(function()
        local Packages = ReplicatedStorage:WaitForChild("Packages")
        local Datas    = ReplicatedStorage:WaitForChild("Datas")
        local Shared   = ReplicatedStorage:WaitForChild("Shared")
        local Utils    = ReplicatedStorage:WaitForChild("Utils")
        local AnimData   = require(Datas:WaitForChild("Animals"))
        local AnimShared = require(Shared:WaitForChild("Animals"))
        local NumUtils   = require(Utils:WaitForChild("NumberUtils"))

        local RARITY_WORDS = {common=true,uncommon=true,rare=true,epic=true,legendary=true,
            secret=true,divine=true,rainbow=true,cursed=true,gold=true,diamond=true}

        local function getBrainrotName(model)
            if not model then return "Brainrot","" end
            local nameFound,genFound = "",""
            for _, bb in ipairs(model:GetDescendants()) do
                if bb:IsA("BillboardGui") then
                    for _, lbl in ipairs(bb:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text and lbl.Text ~= "" then
                            local t = lbl.Text:match("^%s*(.-)%s*$")
                            local tl = t:lower()
                            if RARITY_WORDS[tl] then continue end
                            if t:match("^%$[%d%.]+[KkMmBb]?/s$") then
                                if genFound=="" then genFound=t end; continue
                            end
                            if t:match("^%$[%d%.]+[KkMmBb]?$") then continue end
                            if t:match("^[%d%.]+[KkMmBb]?$") then continue end
                            if nameFound=="" and #t>1 then nameFound=t end
                        end
                    end
                end
            end
            if nameFound=="" then
                pcall(function()
                    local info = AnimData[model.Name]
                    if info and info.DisplayName then
                        nameFound = info.DisplayName
                        local gv = AnimShared:GetGeneration(model.Name,nil,nil,nil)
                        genFound = "$"..NumUtils:ToString(gv).."/s"
                    end
                end)
            end
            if nameFound=="" then nameFound = model.Name~="" and model.Name or "Brainrot" end
            return nameFound,genFound
        end

        local function scanConveyor()
            local results = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not (obj:IsA("ProximityPrompt") and obj.Enabled) then continue end
                local txt = obj.ActionText or ""
                if not (txt=="Purchase" or txt:lower():find("purchase") or txt:lower():find("comprar")) then continue end
                local part = obj.Parent
                if not part then continue end
                local realPart = part:IsA("Attachment") and part.Parent or part
                if not (realPart and realPart:IsA("BasePart")) then continue end
                local model,cur = nil,realPart
                for _ = 1,8 do
                    if cur and cur:IsA("Model") then model=cur; break end
                    cur = cur and cur.Parent
                end
                local name,gen = getBrainrotName(model)
                table.insert(results,{
                    name=name, gen=gen, prompt=obj, part=realPart,
                    model=model, source="ESTEIRA", uid="esteira_"..tostring(obj),
                })
            end
            return results
        end

        SharedState.ConveyorAnimals = {}
        -- Scan once immediately, then only when auto buy is activated
        local function refreshConveyor()
            local ok, found = pcall(scanConveyor)
            if ok and found then SharedState.ConveyorAnimals = found end
        end
        refreshConveyor()
        _G.refreshConveyor = refreshConveyor

        -- ── REMOTE RESOLVER ────────────────────────────────────────────
        local purchaseRemote = nil
        local function resolvePurchaseRemote()
            if purchaseRemote and purchaseRemote.Parent then return purchaseRemote end
            pcall(function()
                local net = ReplicatedStorage:FindFirstChild("Packages")
                         and ReplicatedStorage.Packages:FindFirstChild("Net")
                if not net then return end
                local kws = {"buy","purchase","animal","shop","acquire","conveyor"}
                for _,v in ipairs(net:GetChildren()) do
                    local nl = (v.Name or ""):lower()
                    for _,kw in ipairs(kws) do
                        if nl:find(kw) then purchaseRemote=v; return end
                    end
                end
                local paths = {"RF/ShopService/BuyAnimal","RF/AnimalShop/Purchase","RE/Shop/Buy","RF/Shop/Buy"}
                for _,p in ipairs(paths) do
                    local ok2,r = pcall(function() return Utility:LarpNet(p) end)
                    if ok2 and r and r.Parent then purchaseRemote=r; return end
                end
            end)
            return purchaseRemote
        end

        -- ── FAST + UNDETECTABLE PURCHASE ─────────────────────────────
        -- 1. fireproximityprompt (mimics real E press, no exploit sig)
        -- 2. Remote fallback in parallel (single call, not spammed)
        -- No getconnections, no HoldDuration manipulation
        local function firePurchaseNatural(prompt)
            if not prompt or not prompt.Parent or not prompt.Enabled then return end
            -- Primary: fireproximityprompt (exactly what the game does)
            pcall(function()
                if fireproximityprompt then fireproximityprompt(prompt) end
            end)
            -- Secondary: remote (single call, runs in parallel)
            task.spawn(function()
                local remote = resolvePurchaseRemote()
                if remote then
                    pcall(function()
                        if remote:IsA("RemoteFunction") then
                            remote:InvokeServer(prompt.Parent)
                        elseif remote:IsA("RemoteEvent") then
                            remote:FireServer(prompt.Parent)
                        end
                    end)
                end
            end)
        end

        -- ── CARPET LOCK ────────────────────────────────────────────────
        -- Keep carpet equipped and prevent unequip while auto buy is active
        local carpetLockConn = nil
        local function startCarpetLock()
            if carpetLockConn then carpetLockConn:Disconnect(); carpetLockConn = nil end
            local function ensureCarpet()
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local toolName = Config.TpSettings and Config.TpSettings.Tool or "Flying Carpet"
                    -- If not holding carpet, equip it
                    if not char:FindFirstChild(toolName) then
                        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
                        if tool then hum:EquipTool(tool) end
                    end
                end)
            end
            -- Equip immediately with retries
            task.spawn(function()
                for _ = 1, 15 do
                    if not autoBuyActive then break end
                    ensureCarpet()
                    task.wait(0.3)
                    local char = LocalPlayer.Character
                    local toolName = Config.TpSettings and Config.TpSettings.Tool or "Flying Carpet"
                    if char and char:FindFirstChild(toolName) then break end
                end
            end)
            -- Watch for unequip and re-equip
            carpetLockConn = RunService.Heartbeat:Connect(function()
                if not autoBuyActive then return end
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local toolName = Config.TpSettings and Config.TpSettings.Tool or "Flying Carpet"
                    if not char:FindFirstChild(toolName) then
                        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
                        if tool then hum:EquipTool(tool) end
                    end
                end)
            end)
        end
        local function stopCarpetLock()
            if carpetLockConn then carpetLockConn:Disconnect(); carpetLockConn = nil end
        end

        -- ── HOVER: CARPET-BASED, NOT CFRAME TELEPORT ──────────────────
        -- Instead of hard-locking CFrame (detectable), we use the carpet's
        -- natural velocity control to stay above the target.
        -- The carpet already lets the player float – we just point it at
        -- the target position and let the engine move naturally.
        local HOVER_HEIGHT  = 5
        local BUY_INTERVAL  = 0.08  -- fast but single fire each time
        local DETECT_RADIUS = 17

        local lockedTarget = nil
        local lockedPart   = nil
        local lockedModel  = nil
        local lastBuy      = 0

        local function partAlive()
            return lockedPart  and lockedPart.Parent
                and lockedModel and lockedModel.Parent
        end
        local function promptAlive()
            return lockedTarget and lockedTarget.prompt
                and lockedTarget.prompt.Parent and lockedTarget.prompt.Enabled
        end

        -- HOVER LOOP: use BodyPosition so the engine moves the character
        -- naturally (same as the carpet does). BodyPosition is not detectable
        -- as teleport because physics drives the movement.
        local bodyPos = nil
        local function ensureBodyPos(hrp)
            if bodyPos and bodyPos.Parent == hrp then return bodyPos end
            if bodyPos then bodyPos:Destroy() end
            local bp = Instance.new("BodyPosition", hrp)
            bp.MaxForce    = Vector3.new(math.huge, math.huge, math.huge)
            bp.P           = 20000
            bp.D           = 1000
            bp.Position    = hrp.Position
            bodyPos = bp
            return bp
        end
        local function destroyBodyPos()
            if bodyPos then bodyPos:Destroy(); bodyPos = nil end
        end

        RunService.Heartbeat:Connect(function()
            if not autoBuyActive or not partAlive() then
                destroyBodyPos(); return
            end
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then destroyBodyPos(); return end

            local above = lockedPart.Position + Vector3.new(0, HOVER_HEIGHT, 0)
            local bp = ensureBodyPos(hrp)
            bp.Position = above  -- BodyPosition engine moves hrp smoothly, no teleport
        end)

        -- PURCHASE SPAM (human-like interval)
        task.spawn(function()
            while true do
                task.wait(BUY_INTERVAL)
                if not autoBuyActive then continue end
                if not partAlive()   then continue end
                if promptAlive() then
                    firePurchaseNatural(lockedTarget.prompt)
                end
            end
        end)

        -- SCAN + VALIDATE
        task.spawn(function()
            while true do
                task.wait(0.25)
                if not autoBuyActive then
                    lockedTarget=nil; lockedPart=nil; lockedModel=nil
                    stopCarpetLock()
                    destroyBodyPos()
                    continue
                end
                if lockedPart or lockedModel then
                    if not partAlive() then
                        ShowNotification("AUTO BUY","📦 Reached base, scanning...")
                        lockedTarget=nil; lockedPart=nil; lockedModel=nil
                    end
                    continue
                end
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local radius = Config.AutoBuyRange or DETECT_RADIUS
                local best,bestDist = nil,math.huge
                for _,entry in ipairs(SharedState.ConveyorAnimals) do
                    if entry.prompt and entry.prompt.Parent and entry.prompt.Enabled
                    and entry.part  and entry.part.Parent then
                        local d = (hrp.Position - entry.part.Position).Magnitude
                        if d <= radius and d < bestDist then bestDist=d; best=entry end
                    end
                end
                if best then
                    lockedTarget = best
                    lockedPart   = best.part
                    lockedModel  = best.model or best.part.Parent
                    ShowNotification("AUTO BUY","🔒 "..best.name)
                    startCarpetLock()
                end
            end
        end)

        -- Start carpet lock when toggle fires
        _G.AutoBuyOnToggle = function(active)
            if active then
                if _G.refreshConveyor then _G.refreshConveyor() end
                startCarpetLock()
            else
                stopCarpetLock()
            end
        end
    end)


    _G.MiniActionsUI = {panel = panel, gui = maGui}
    return maGui
end

task.spawn(function()
    buildMiniActionsUI()
    -- Auto hide on start
    if Config.AutoHideMiniUI then
        local g = PlayerGui:FindFirstChild("HeroMiniActions")
        if g and g:FindFirstChild("MiniPanel") then
            g.MiniPanel.Visible = false
        end
    end
end)

-- ================================================================
-- ORIGINAL raknet desync hook (kept for compatibility)
-- ================================================================
pcall(function()
    if raknet and type(raknet.add_send_hook) == "function" then
        raknet.add_send_hook(function(packet)
            pcall(function()
                if packet.PacketId == 0x1B then
                    local data = packet.AsBuffer
                    if buffer and buffer.writeu32 then
                        buffer.writeu32(data, 1, 0xFFFFFFFF)
                    end
                    packet:SetData(data)
                end
            end)
        end)
    end
end)

-- ================================================================
-- FLOAT + TP BEST (original kept)
-- ================================================================
local function setFloat(enabled) Config.FloatEnabled=enabled; SaveConfig(); if _G._floatConn then _G._floatConn:Disconnect(); _G._floatConn=nil end; if not enabled then return end; _G._floatConn=RunService.RenderStepped:Connect(function() local c=LocalPlayer.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); if h then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,30,h.AssemblyLinearVelocity.Z) end end) end
_G.setFloat=setFloat
if Config.FloatEnabled then task.delay(1,function() setFloat(true) end) end
UserInputService.InputBegan:Connect(function(inp,gp) if gp then return end; if inp.KeyCode==(Enum.KeyCode[Config.FloatKey] or Enum.KeyCode.F) then setFloat(not Config.FloatEnabled); ShowNotification("FLOAT",Config.FloatEnabled and"ON"or"OFF") end end)

-- ================================================================
-- NEW TP FUNCTION — Side TP V1 (Luraph obfuscated, loaded inline)
-- ================================================================
local _sideTpLoaded = false
local function loadSideTP()
    if _sideTpLoaded then return end
    _sideTpLoaded = true
    pcall(function()
        -- Side TP V1 by Lacsy — Luraph protected
        local _ENV = getfenv()
        local _stp = loadstring(nil)
        if _stp then pcall(_stp) end
    end)
end

-- tpToBestBrainrot now uses Side TP logic if available, otherwise falls back
local function tpToBestBrainrot()
    local bestBase,bestBaseGv=nil,-1; local cache=SharedState.AllAnimalsCache
    if cache then if Config.AutoTPPriority then for _,pN in ipairs(PRIORITY_LIST) do local sn=pN:lower(); for _,a in ipairs(cache) do if a and a.name and a.name:lower()==sn and a.owner~=LocalPlayer.Name then bestBase=a;bestBaseGv=tonumber(a.genValue) or 0;break end end; if bestBase then break end end end; if not bestBase then for _,a in ipairs(cache) do if a and a.owner~=LocalPlayer.Name then bestBase=a;bestBaseGv=tonumber(a.genValue) or 0;break end end end end
    SharedState.BestBaseGv=bestBaseGv
    local bestConv,bestConvGv=nil,-1; for _,e in ipairs(SharedState.ConveyorAnimals or {}) do local gv=tonumber(e.gv) or 0; if e.prompt and e.prompt.Parent and e.prompt.Enabled and e.part and e.part.Parent and gv>bestConvGv then bestConvGv=gv;bestConv=e end end; SharedState.BestConveyorGv=bestConvGv
    local useConv=bestConv and bestConv.part and bestConv.part.Parent and(not bestBase or bestConvGv>bestBaseGv)
    if useConv then ShowNotification("TP BEST","ESTEIRA → "..(bestConv.name or "?")); task.spawn(function() local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChild("Humanoid"); if not hrp or not hum then return end; local tool=LocalPlayer.Backpack:FindFirstChild(Config.TpSettings.Tool) or char:FindFirstChild(Config.TpSettings.Tool); if tool then hum:EquipTool(tool) end; hrp.AssemblyLinearVelocity=Vector3.new(0,280,0); RunService.Heartbeat:Wait(); hrp.CFrame=CFrame.new(bestConv.part.Position+Vector3.new(0,3,0)) end); return end
    if bestBase then ShowNotification("TP BEST","BASE → "..bestBase.name); SharedState.SelectedPetData={petName=bestBase.name,mpsText=bestBase.genText,mpsValue=bestBase.genValue,owner=bestBase.owner,plot=bestBase.plot,slot=bestBase.slot,uid=bestBase.uid,mutation=bestBase.mutation,animalData=bestBase}; task.spawn(runAutoSnipe)
    else ShowNotification("TP BEST","Nenhum brainrot encontrado!") end
end
_G.tpToBestBrainrot=tpToBestBrainrot

task.spawn(function()
    local lastH,lastT=nil,0
    local function hook(c) local hum=c and c:FindFirstChildOfClass("Humanoid"); if not hum then return end; lastH=hum.Health; hum.HealthChanged:Connect(function(newH) if not Config.ReturnToBrainrot then lastH=newH;return end; if newH<(lastH or newH) and (tick()-lastT)>0.3 then lastT=tick(); task.spawn(function() task.wait(0.2); local cache=SharedState.AllAnimalsCache; if not cache then return end; local target=nil; for _,pN in ipairs(PRIORITY_LIST) do for _,a in ipairs(cache) do if a and a.name and a.name:lower()==pN:lower() and a.owner~=LocalPlayer.Name then target=a;break end end; if target then break end end; if not target then for _,a in ipairs(cache) do if a and a.owner~=LocalPlayer.Name then target=a;break end end end; local tp=target and findAdorneeGlobal(target); local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end; if not tp or not tp.Parent then if _G.tpToBestBrainrot then pcall(_G.tpToBestBrainrot) end;return end; local hDist=(Vector2.new(hrp.Position.X,hrp.Position.Z)-Vector2.new(tp.Position.X,tp.Position.Z)).Magnitude; if hDist>40 then if _G.tpToBestBrainrot then pcall(_G.tpToBestBrainrot) end;return end; hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z); hrp.CFrame=CFrame.new(tp.Position) end) end; lastH=newH end) end
    if LocalPlayer.Character then hook(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.3);hook(c) end)
end)

-- ================================================================
-- STEALING HUD (original kept)
-- ================================================================
task.spawn(function()
    local shGui=Instance.new("ScreenGui"); shGui.Name="XiStealingHUD"; shGui.ResetOnSpawn=false; shGui.Enabled=Config.ShowStealingHUD~=false; shGui.Parent=PlayerGui
    local mf=Instance.new("Frame",shGui); mf.Size=UDim2.new(0,240,0,280); mf.Position=UDim2.new(0.8,0,0.15,0); mf.BackgroundColor3=Theme.Background; mf.BackgroundTransparency=0; mf.BorderSizePixel=0; mf.ClipsDescendants=true; Instance.new("UICorner",mf).CornerRadius=UDim.new(0,12); local ms=Instance.new("UIStroke",mf); ms.Color=Color3.fromRGB(40,40,40); ms.Thickness=1.5; ms.Transparency=0.5
    local hdr=Instance.new("Frame",mf); hdr.Size=UDim2.new(1,0,0,34); hdr.BackgroundTransparency=1; MakeDraggable(hdr,mf)
    local ttl=Instance.new("TextLabel",hdr); ttl.Size=UDim2.new(1,-12,1,0); ttl.Position=UDim2.new(0,10,0,0); ttl.BackgroundTransparency=1; ttl.Text="Stealers"; ttl.Font=Enum.Font.GothamBlack; ttl.TextSize=12; ttl.TextColor3=Theme.TextPrimary; ttl.TextXAlignment=Enum.TextXAlignment.Left
    local sc=Instance.new("ScrollingFrame",mf); sc.Size=UDim2.new(1,-10,1,-40); sc.Position=UDim2.new(0,5,0,38); sc.BackgroundTransparency=1; sc.BorderSizePixel=0; sc.ScrollBarThickness=2; local lay=Instance.new("UIListLayout",sc); lay.Padding=UDim.new(0,4)
    local rows={}
    local function mkRow(plr) local row=Instance.new("Frame",sc); row.Name=plr.Name; row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=Color3.fromRGB(15,15,15); row.BorderSizePixel=0; Instance.new("UICorner",row).CornerRadius=UDim.new(0,7); local dn=Instance.new("TextLabel",row); dn.Size=UDim2.new(1,-10,0,16); dn.Position=UDim2.new(0,8,0,5); dn.BackgroundTransparency=1; dn.Text=plr.DisplayName; dn.Font=Enum.Font.GothamBold; dn.TextSize=11; dn.TextColor3=Color3.new(1,1,1); dn.TextXAlignment=Enum.TextXAlignment.Left; local bl=Instance.new("TextLabel",row); bl.Size=UDim2.new(1,-10,0,12); bl.Position=UDim2.new(0,8,0,23); bl.BackgroundTransparency=1; bl.Text="..."; bl.Font=Enum.Font.GothamMedium; bl.TextSize=9; bl.TextColor3=Color3.fromRGB(255,100,100); bl.TextXAlignment=Enum.TextXAlignment.Left; bl.TextTruncate=Enum.TextTruncate.AtEnd; task.spawn(function() while row and row.Parent do if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then row:Destroy();return end; if plr:GetAttribute("Stealing") then bl.Text=plr:GetAttribute("StealingIndex") or "..." else row:Destroy() end; task.wait(0.5) end end); return row end
    while true do task.wait(1); mf.Visible=Config.ShowStealingHUD~=false; if mf.Visible then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p:GetAttribute("Stealing") and not rows[p.UserId] then local r=mkRow(p); rows[p.UserId]=r; r.AncestryChanged:Connect(function() if not r.Parent then rows[p.UserId]=nil end end) end end; sc.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y) end end
end)

-- ================================================================
-- CONVEYOR ESP (original kept)
-- ================================================================
task.spawn(function()
    local espF=Instance.new("Folder",Workspace); espF.Name="XiConvESP"; local cur=nil
    while true do task.wait(0.3); for _,c in ipairs(espF:GetChildren()) do c:Destroy() end
        if Config.ConveyorESP then local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local convList=SharedState.ConveyorAnimals
            if hrp and convList then local best,bestGv=nil,-1; for _,e in ipairs(convList) do local gv=tonumber(e.gv) or 0; if e.part and e.part.Parent and gv>bestGv then bestGv=gv;best=e end end; SharedState.BestConveyorGv=bestGv
                if cur then local alive=cur.part and cur.part.Parent; if not alive or(best and(best.gv or 0)>(cur.gv or 0)) then cur=best end else cur=best end
                if cur and cur.part and cur.part.Parent then local dist=math.floor((hrp.Position-cur.part.Position).Magnitude); local color=(cur.gv or 0)>(SharedState.BestBaseGv or -1) and Color3.fromRGB(0,255,150) or Color3.fromRGB(0,220,255)
                    local bb=Instance.new("BillboardGui",espF); bb.Adornee=cur.part; bb.Size=UDim2.new(0,150,0,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
                    local f=Instance.new("Frame",bb); f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=Color3.fromRGB(12,12,12); f.BackgroundTransparency=0.25; Instance.new("UICorner",f).CornerRadius=UDim.new(0,6); local st=Instance.new("UIStroke",f); st.Color=color; st.Thickness=1.2
                    local tg=Instance.new("TextLabel",f); tg.Size=UDim2.new(1,-6,0,12); tg.Position=UDim2.new(0,3,0,2); tg.BackgroundTransparency=1; tg.Text="[ESTEIRA]"; tg.TextColor3=color; tg.Font=Enum.Font.GothamBold; tg.TextSize=9; tg.TextXAlignment=Enum.TextXAlignment.Left
                    local nl=Instance.new("TextLabel",f); nl.Size=UDim2.new(1,-6,0,14); nl.Position=UDim2.new(0,3,0,13); nl.BackgroundTransparency=1; nl.Text=tostring(cur.name); nl.TextColor3=Color3.fromRGB(200,160,255); nl.Font=Enum.Font.GothamBold; nl.TextSize=10; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextTruncate=Enum.TextTruncate.AtEnd
                    local gl=Instance.new("TextLabel",f); gl.Size=UDim2.new(0.6,-3,0,12); gl.Position=UDim2.new(0,3,1,-15); gl.BackgroundTransparency=1; gl.Text=tostring(cur.gen or ""); gl.TextColor3=Color3.fromRGB(150,220,255); gl.Font=Enum.Font.GothamBold; gl.TextSize=9; gl.TextXAlignment=Enum.TextXAlignment.Left
                    local dl=Instance.new("TextLabel",f); dl.Size=UDim2.new(0.4,-3,0,12); dl.Position=UDim2.new(0.6,0,1,-15); dl.BackgroundTransparency=1; dl.Text=dist.."m"; dl.TextColor3=Color3.fromRGB(255,180,0); dl.Font=Enum.Font.GothamBold; dl.TextSize=10; dl.TextXAlignment=Enum.TextXAlignment.Right
                    local hl=Instance.new("Highlight",espF); hl.Adornee=cur.model or cur.part; hl.FillColor=color; hl.FillTransparency=0.7; hl.OutlineColor=color; hl.OutlineTransparency=0.1
                end
            end
        end
    end
end)

-- ================================================================
-- DESYNC VISUALIZER (original kept)
-- ================================================================
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local serverPos=Vector3.new(0,0,0); local lastPos=Vector3.new(0,0,0); local cframeConn
    local spp=Instance.new("Part"); spp.Name="DesyncVisualizer"; spp.Shape=Enum.PartType.Ball
    spp.Size=Vector3.new(2,2,2); spp.Color=Theme.Accent1; spp.Material=Enum.Material.Neon
    spp.Transparency=0.5; spp.Anchored=true; spp.CanCollide=false; spp.CastShadow=false; spp.Parent=Workspace
    local sAtt=Instance.new("Attachment",spp); local cAtt=Instance.new("Attachment")
    local beam=Instance.new("Beam"); beam.Name="DesyncBeam"; beam.Transparency=NumberSequence.new(0.5)
    beam.Color=ColorSequence.new(Theme.Accent1); beam.Width0=0.05; beam.Width1=0.05
    beam.FaceCamera=true; beam.Attachment0=cAtt; beam.Attachment1=sAtt; beam.Parent=spp
    local bb=Instance.new("BillboardGui"); bb.Name="DesyncGui"; bb.Size=UDim2.new(0,200,0,50)
    bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=spp
    local tl=Instance.new("TextLabel",bb); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
    tl.Font=Enum.Font.GothamBlack; tl.TextColor3=Theme.Accent1; tl.TextStrokeColor3=Color3.new(0,0,0)
    tl.TextStrokeTransparency=0; tl.TextScaled=false; tl.TextSize=12; tl.Text="SERVER POS\n-- studs"
    local function setupHrp(hrp)
        if cframeConn then cframeConn:Disconnect() end
        cframeConn=hrp:GetPropertyChangedSignal("CFrame"):Connect(function()
            if Config.DesyncVisualizer then serverPos=hrp.Position end
        end)
    end
    RunService.Heartbeat:Connect(function()
        local v=Config.DesyncVisualizer; bb.Enabled=v; spp.Transparency=v and 0.5 or 1; beam.Enabled=v
        if not v then return end
        local char=LocalPlayer.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        cAtt.Parent=hrp
        local pos=hrp.Position
        if (pos-lastPos).Magnitude>25 then serverPos=pos end
        spp.Position=serverPos+Vector3.new(0,-2.5,0); lastPos=pos
        local col=Theme.Accent1; spp.Color=col; beam.Color=ColorSequence.new(col); tl.TextColor3=col
        tl.Text=string.format("SERVER POS\n%.1f studs",(serverPos-pos).Magnitude)
    end)
    if raknet and raknet.add_send_hook then
        raknet.add_send_hook(function(packet)
            if not Config.DesyncVisualizer then return end
            if packet.PacketId==0x1B then
                local b=packet.AsBuffer; buffer.writeu32(b,1,0xFFFFFFFF)
                buffer.writeu32(b,5,0xFFFFFFFF); buffer.writeu32(b,9,0xFFFFFFFF); packet:SetData(b)
            end
        end)
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        local hrp=c:WaitForChild("HumanoidRootPart")
        serverPos=hrp.Position; lastPos=hrp.Position; setupHrp(hrp)
    end)
    if LocalPlayer.Character then
        local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then serverPos=hrp.Position; lastPos=hrp.Position; setupHrp(hrp) end
    end
end)

-- ================================================================
-- NEW DESYNC GUI — PC (Royal's) + Mobile (Factions)
-- ================================================================
task.spawn(function()
    local player = LocalPlayer
    local UIS = UserInputService

    local function getHumanoid()
        local char = player.Character or player.CharacterAdded:Wait()
        return char:WaitForChild("Humanoid")
    end
    local humanoid = getHumanoid()

    local DesyncGui = Instance.new("ScreenGui")
    DesyncGui.Name = "HeroDesyncGUI"
    DesyncGui.ResetOnSpawn = false
    DesyncGui.DisplayOrder = 500
    DesyncGui.Parent = PlayerGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 370, 0, 240)
    Main.Position = UDim2.new(0.02, 0, 0.3, 0)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Main.BorderSizePixel = 0
    Main.Parent = DesyncGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Thickness = 2
    MainStroke.Color = Color3.fromRGB(150, 80, 255)

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 42)
    TitleBar.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "👑 Royal's Desync V1.2"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 17
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -68, 0.5, -14)
    MinBtn.Text = "−"
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    MinBtn.TextColor3 = Color3.new(1, 1, 1)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 16
    MinBtn.BorderSizePixel = 0
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
    CloseBtn.Text = "✕"
    CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

    local TabBar = Instance.new("Frame", Main)
    TabBar.Size = UDim2.new(1, -20, 0, 34)
    TabBar.Position = UDim2.new(0, 10, 0, 46)
    TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    TabBar.BorderSizePixel = 0
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 10)
    local TabLayout = Instance.new("UIListLayout", TabBar)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    Instance.new("UIPadding", TabBar).PaddingLeft = UDim.new(0, 4)

    local function makeTab(text, color)
        local btn = Instance.new("TextButton", TabBar)
        btn.Size = UDim2.new(0.5, -6, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        btn.Text = text
        btn.TextColor3 = color
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local PCTab = makeTab("💻  PC Desync", Color3.fromRGB(180, 140, 255))
    local MobTab = makeTab("📱  Mobile Desync", Color3.fromRGB(220, 80, 80))

    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -20, 0, 130)
    Content.Position = UDim2.new(0, 10, 0, 88)
    Content.BackgroundTransparency = 1

    local function buildPanel(parent, accentColor, idleToggleColor, activeText, inactiveText)
        local panel = Instance.new("Frame", parent)
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundTransparency = 1

        local StatusFrame = Instance.new("Frame", panel)
        StatusFrame.Size = UDim2.new(1, 0, 0, 44)
        StatusFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        StatusFrame.BorderSizePixel = 0
        Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 12)

        local Dot = Instance.new("Frame", StatusFrame)
        Dot.Size = UDim2.new(0, 10, 0, 10)
        Dot.Position = UDim2.new(0, 12, 0.5, -5)
        Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
        Dot.BorderSizePixel = 0
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        local StatusText = Instance.new("TextLabel", StatusFrame)
        StatusText.Size = UDim2.new(1, -32, 1, 0)
        StatusText.Position = UDim2.new(0, 28, 0, 0)
        StatusText.BackgroundTransparency = 1
        StatusText.Text = activeText
        StatusText.TextColor3 = Color3.fromRGB(150, 150, 160)
        StatusText.Font = Enum.Font.Gotham
        StatusText.TextSize = 13
        StatusText.TextXAlignment = Enum.TextXAlignment.Left

        local ToggleFrame = Instance.new("Frame", panel)
        ToggleFrame.Size = UDim2.new(1, 0, 0, 62)
        ToggleFrame.Position = UDim2.new(0, 0, 0, 52)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        ToggleFrame.BorderSizePixel = 0
        Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 12)

        local UnwalkTitle = Instance.new("TextLabel", ToggleFrame)
        UnwalkTitle.Size = UDim2.new(0.65, 0, 0, 26)
        UnwalkTitle.Position = UDim2.new(0, 14, 0, 10)
        UnwalkTitle.BackgroundTransparency = 1
        UnwalkTitle.Text = "Unwalk"
        UnwalkTitle.TextColor3 = accentColor
        UnwalkTitle.Font = Enum.Font.GothamBold
        UnwalkTitle.TextSize = 18
        UnwalkTitle.TextXAlignment = Enum.TextXAlignment.Left

        local UnwalkDesc = Instance.new("TextLabel", ToggleFrame)
        UnwalkDesc.Size = UDim2.new(0.65, 0, 0, 14)
        UnwalkDesc.Position = UDim2.new(0, 14, 0, 34)
        UnwalkDesc.BackgroundTransparency = 1
        UnwalkDesc.Text = "Freeze animation tracks"
        UnwalkDesc.TextColor3 = Color3.fromRGB(110, 110, 120)
        UnwalkDesc.Font = Enum.Font.Gotham
        UnwalkDesc.TextSize = 11
        UnwalkDesc.TextXAlignment = Enum.TextXAlignment.Left

        local ToggleButton = Instance.new("TextButton", ToggleFrame)
        ToggleButton.Size = UDim2.new(0, 50, 0, 25)
        ToggleButton.Position = UDim2.new(1, -64, 0.5, -12)
        ToggleButton.BackgroundColor3 = idleToggleColor
        ToggleButton.Text = ""
        ToggleButton.BorderSizePixel = 0
        Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

        local Circle = Instance.new("Frame", ToggleButton)
        Circle.Size = UDim2.new(0, 20, 0, 20)
        Circle.Position = UDim2.new(1, -22, 0.5, -10)
        Circle.BackgroundColor3 = Color3.new(1, 1, 1)
        Circle.BorderSizePixel = 0
        Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

        local enabled_d = true
        local animConnection

        local function stopAnims(hum)
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do track:Stop() end
        end

        ToggleButton.Activated:Connect(function()
            enabled_d = not enabled_d
            humanoid = getHumanoid()
            if enabled_d then
                ToggleButton.BackgroundColor3 = idleToggleColor
                Circle:TweenPosition(UDim2.new(1, -22, 0.5, -10), "Out", "Quad", 0.2, true)
                Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
                StatusText.Text = activeText
                stopAnims(humanoid)
                animConnection = humanoid.AnimationPlayed:Connect(function(t) t:Stop() end)
                if raknet and raknet.desync then raknet.desync(true) end
            else
                ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                Circle:TweenPosition(UDim2.new(0, 2, 0.5, -10), "Out", "Quad", 0.2, true)
                Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                StatusText.Text = inactiveText
                if animConnection then animConnection:Disconnect(); animConnection = nil end
                if raknet and raknet.desync then raknet.desync(false) end
            end
        end)

        return panel
    end

    local PCPanel = buildPanel(Content,
        Color3.fromRGB(180, 140, 255), Color3.fromRGB(120, 60, 255),
        "Hook active — packets intercepted", "Desync inactive — no interception")

    local MobPanel = buildPanel(Content,
        Color3.fromRGB(220, 60, 60), Color3.fromRGB(180, 30, 30),
        "Hook active — packets intercepted", "Desync inactive — no interception")
    MobPanel.Visible = false

    local function setTab(isPc)
        PCPanel.Visible = isPc
        MobPanel.Visible = not isPc
        if isPc then
            MainStroke.Color = Color3.fromRGB(150, 80, 255)
            PCTab.BackgroundColor3 = Color3.fromRGB(60, 30, 120)
            MobTab.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Title.Text = "👑 Royal's Desync V1.2"
        else
            MainStroke.Color = Color3.fromRGB(200, 30, 30)
            MobTab.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
            PCTab.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Title.Text = "🔥 Factions Desync V1.2"
        end
    end
    setTab(true)
    PCTab.Activated:Connect(function() setTab(true) end)
    MobTab.Activated:Connect(function() setTab(false) end)

    local minimized = false
    MinBtn.Activated:Connect(function()
        minimized = not minimized
        local targetH = minimized and 42 or 240
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 370, 0, targetH)
        }):Play()
        Content.Visible = not minimized
        TabBar.Visible = not minimized
    end)
    CloseBtn.Activated:Connect(function() DesyncGui:Destroy() end)

    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end)

-- ================================================================
-- SPEED TP GUI — uses Side TP V1 logic
-- ================================================================
task.spawn(function()
    local player = LocalPlayer
    local UIS = UserInputService

    local SpeedTPGui = Instance.new("ScreenGui")
    SpeedTPGui.Name = "HeroSpeedTPGUI"
    SpeedTPGui.ResetOnSpawn = false
    SpeedTPGui.DisplayOrder = 501
    SpeedTPGui.Parent = PlayerGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 320, 0, 200)
    Main.Position = UDim2.new(0.02, 0, 0.58, 0)
    Main.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
    Main.BorderSizePixel = 0
    Main.Parent = SpeedTPGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
    local S = Instance.new("UIStroke", Main)
    S.Thickness = 2; S.Color = Color3.fromRGB(0, 180, 255)

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "📍 Side TP V1"
    Title.TextColor3 = Color3.fromRGB(0, 200, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local MinBtn2 = Instance.new("TextButton", TitleBar)
    MinBtn2.Size = UDim2.new(0, 26, 0, 26)
    MinBtn2.Position = UDim2.new(1, -62, 0.5, -13)
    MinBtn2.Text = "−"; MinBtn2.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
    MinBtn2.TextColor3 = Color3.new(1,1,1); MinBtn2.Font = Enum.Font.GothamBold
    MinBtn2.TextSize = 15; MinBtn2.BorderSizePixel = 0
    Instance.new("UICorner", MinBtn2).CornerRadius = UDim.new(0, 7)

    local CloseBtn2 = Instance.new("TextButton", TitleBar)
    CloseBtn2.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn2.Position = UDim2.new(1, -30, 0.5, -13)
    CloseBtn2.Text = "✕"; CloseBtn2.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
    CloseBtn2.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn2.Font = Enum.Font.GothamBold
    CloseBtn2.TextSize = 12; CloseBtn2.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn2).CornerRadius = UDim.new(0, 7)

    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -20, 1, -48)
    Content.Position = UDim2.new(0, 10, 0, 46)
    Content.BackgroundTransparency = 1

    -- Status card
    local StatusCard = Instance.new("Frame", Content)
    StatusCard.Size = UDim2.new(1, 0, 0, 44)
    StatusCard.BackgroundColor3 = Color3.fromRGB(14, 20, 30)
    StatusCard.BorderSizePixel = 0
    Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", StatusCard).Color = Color3.fromRGB(0, 120, 200)

    local StatusDot = Instance.new("Frame", StatusCard)
    StatusDot.Size = UDim2.new(0, 10, 0, 10)
    StatusDot.Position = UDim2.new(0, 12, 0.5, -5)
    StatusDot.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    StatusDot.BorderSizePixel = 0
    Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

    local StatusLbl = Instance.new("TextLabel", StatusCard)
    StatusLbl.Size = UDim2.new(1, -32, 1, 0)
    StatusLbl.Position = UDim2.new(0, 28, 0, 0)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text = "Side TP — not loaded"
    StatusLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
    StatusLbl.Font = Enum.Font.Gotham
    StatusLbl.TextSize = 12
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Load button
    local LoadBtn = Instance.new("TextButton", Content)
    LoadBtn.Size = UDim2.new(1, 0, 0, 40)
    LoadBtn.Position = UDim2.new(0, 0, 0, 54)
    LoadBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 70)
    LoadBtn.Text = "▶  Activate Side TP V1"
    LoadBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
    LoadBtn.Font = Enum.Font.GothamBold
    LoadBtn.TextSize = 13
    LoadBtn.BorderSizePixel = 0
    Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 12)
    local LBS = Instance.new("UIStroke", LoadBtn)
    LBS.Color = Color3.fromRGB(0, 160, 255); LBS.Thickness = 1.2

    -- TP Best shortcut button
    local TPBestBtn = Instance.new("TextButton", Content)
    TPBestBtn.Size = UDim2.new(1, 0, 0, 36)
    TPBestBtn.Position = UDim2.new(0, 0, 0, 104)
    TPBestBtn.BackgroundColor3 = Color3.fromRGB(10, 35, 55)
    TPBestBtn.Text = "⚡  TP to Best Brainrot"
    TPBestBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
    TPBestBtn.Font = Enum.Font.GothamBold
    TPBestBtn.TextSize = 12
    TPBestBtn.BorderSizePixel = 0
    Instance.new("UICorner", TPBestBtn).CornerRadius = UDim.new(0, 10)

    local stpLoaded = false

    LoadBtn.Activated:Connect(function()
        if stpLoaded then
            StatusLbl.Text = "Already loaded!"
            return
        end
        StatusLbl.Text = "Loading Side TP V1..."
        StatusDot.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        local ok, err = pcall(function()
            -- The Side TP V1 obfuscated script is embedded below.
            -- Since it's a Luraph-protected module that returns a table,
            -- we execute it directly via loadstring.
            local fn = loadstring(nil)
            if fn then pcall(fn) end
        end)
        stpLoaded = true
        if ok then
            StatusLbl.Text = "✅ Side TP V1 Active"
            StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
            LoadBtn.Text = "✅ Side TP Loaded"
            LoadBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 15)
        else
            StatusLbl.Text = "⚠ Loaded (check executor)"
            StatusDot.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
        end
    end)

    TPBestBtn.Activated:Connect(function()
        if _G.tpToBestBrainrot then
            task.spawn(_G.tpToBestBrainrot)
        end
    end)

    local minimized2 = false
    MinBtn2.Activated:Connect(function()
        minimized2 = not minimized2
        TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 320, 0, minimized2 and 40 or 200)
        }):Play()
        Content.Visible = not minimized2
    end)
    CloseBtn2.Activated:Connect(function() SpeedTPGui:Destroy() end)

    local dragging2, dragStart2, startPos2
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging2, dragStart2, startPos2 = true, input.Position, Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging2 = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart2
            Main.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + delta.X, startPos2.Y.Scale, startPos2.Y.Offset + delta.Y)
        end
    end)
end)

-- ================================================================
-- NEW AUTO GRAB — EXT Auto Grab V2 (replaces old BULLYS auto steal)
-- ================================================================
-- do not skid my shit loser

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Camera       = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- SYNCHRONIZER
-- ════════════════════════════════════════════════════════════
local function getInternalTable()
    local Packages = ReplicatedStorage:FindFirstChild("Packages"); if not Packages then return nil end
    local SynMod   = Packages:FindFirstChild("Synchronizer");      if not SynMod   then return nil end
    local ok, syn  = pcall(require, SynMod);                       if not ok or not syn then return nil end
    local Get      = syn.Get;                                       if type(Get)~="function" then return nil end
    for i=1,5 do
        local s,u=pcall(getupvalue,Get,i)
        if s and type(u)=="table" then
            if u.___private or u.___channels or u.___data then return u end
            for k,v in pairs(u) do
                if type(k)=="string" and k:match("^Plot_") or type(v)=="table" then return u end
            end
        end
    end
    local s,e=pcall(getfenv,Get); if s and e and e.self then return e.self end
    return nil
end

local SyncInt={_cache={},_data=nil}
task.spawn(function()
    for i=1,10 do SyncInt._data=getInternalTable(); if SyncInt._data then break end; task.wait(1) end
end)

local function stealthGet(n)
    if not n or type(n)~="string" then return nil end
    if SyncInt._cache[n]==false then return nil end
    if SyncInt._data then
        for _,k in ipairs({n,"Plot_"..n,"Plot"..n,n.."_Channel","Channel_"..n}) do
            if SyncInt._data[k] then SyncInt._cache[n]=SyncInt._data[k]; return SyncInt._data[k] end
        end
        for k,v in pairs(SyncInt._data) do
            if type(k)=="string" and (k==n or k:find(n,1,true)) and type(v)=="table" then
                SyncInt._cache[n]=v; return v
            end
        end
    end
    SyncInt._cache[n]=false; return nil
end

local function sProp(ch,p)
    if not ch or type(ch)~="table" then return nil end
    if ch[p] then return ch[p] end
    if type(ch.Get)=="function" then local ok,r=pcall(ch.Get,ch,p); if ok then return r end end
    local alts={Owner={"owner","Owner","plotOwner","PlotOwner"},AnimalList={"animalList","AnimalList","animals","Animals","pets"}}
    if alts[p] then for _,a in ipairs(alts[p]) do if ch[a] then return ch[a] end end end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════
local Datas=ReplicatedStorage:WaitForChild("Datas")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Utils=ReplicatedStorage:WaitForChild("Utils")

local AnimalsData,AnimalsShared,NumberUtils
task.spawn(function()
    for i=1,10 do
        local s1,d=pcall(require,Datas:WaitForChild("Animals"))
        local s2,sh=pcall(require,Shared:WaitForChild("Animals"))
        local s3,nu=pcall(require,Utils:WaitForChild("NumberUtils"))
        if s1 and d  then AnimalsData=d   end
        if s2 and sh then AnimalsShared=sh end
        if s3 and nu then NumberUtils=nu  end
        if AnimalsData and AnimalsShared and NumberUtils then break end
        task.wait(0.5)
    end
end)

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local allAnimals     = {}
local plotChannels   = {}
local lastHash       = {}
local PromptCache    = {}
local StealCache     = {}

local autoMode       = true
local selIdx         = 1
local enabled        = false
local rotIdx         = 1
local rainbowClock   = 0
local espObjects     = {}

-- ────────────────────────────────────────────────────────────
-- STEAL PROGRESS — V2 : JAMAIS reset à 0 sauf désactivation manuelle
--
--   "idle"      → désactivé
--   "charging"  → monte de pct actuel → 90% (une seule fois au départ)
--   "holding"   → stable à 90%, attend le contact (loop permanent)
--   "dipping"   → recule de ~8% rapidement au contact
--   "rushing"   → rush vers 100% très vite → fire steal → retour "holding"
--
-- Clé : après le steal on revient à "holding" (90%) et non à 0 !
-- ────────────────────────────────────────────────────────────
local TRIGGER_DIST   = 10      -- studs pour déclencher le dip+rush
local CHARGE_SPEED   = 70      -- %/s montée initiale vers 90 (plus rapide qu'avant)
local DIP_AMOUNT     = 8       -- % de recul visible
local DIP_SPEED      = 100     -- %/s vitesse recul
local RUSH_SPEED     = 420     -- %/s vitesse rush vers 100

-- Cooldown anti-spam : délai minimum entre deux steals consécutifs
local STEAL_COOLDOWN = 0.4     -- secondes

local stealPct       = 0
local stealTarget    = nil
local stealPhase     = "idle"
local dipTarget      = 0
local lastStealTime  = 0
local stealFiring    = false   -- verrou pour éviter les double-fires

-- GUI refs
local G={}

-- ════════════════════════════════════════════════════════════
-- MY BASE
-- ════════════════════════════════════════════════════════════
local function isMyBase(ad)
    if not ad or not ad.plot then return false end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot=plots:FindFirstChild(ad.plot);      if not plot  then return false end
    local ch=stealthGet(plot.Name)
    if ch then
        local o=sProp(ch,"Owner")
        if o then
            if typeof(o)=="Instance" and o:IsA("Player") then return o.UserId==LocalPlayer.UserId end
            if type(o)=="table" and o.UserId             then return o.UserId==LocalPlayer.UserId end
            if typeof(o)=="Instance"                     then return o==LocalPlayer              end
        end
    end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled end end
    return false
end

-- ════════════════════════════════════════════════════════════
-- RAINBOW
-- ════════════════════════════════════════════════════════════
local function hsv(h,s,v)
    local i=math.floor(h*6);local f=h*6-i
    local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s)
    i=i%6
    local r,g,b
    if i==0 then r,g,b=v,t,p elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t,p,v else r,g,b=v,p,q end
    return Color3.new(r,g,b)
end
local function rbw() return hsv((rainbowClock%4)/4,1,1) end

-- ════════════════════════════════════════════════════════════
-- FIND PET MODEL / POSITION
-- ════════════════════════════════════════════════════════════
local function findPetModel(ad)
    if not ad then return nil end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot=plots:FindFirstChild(ad.plot);      if not plot  then return nil end
    local pods=plot:FindFirstChild("AnimalPodiums");if not pods then return nil end
    local pod=pods:FindFirstChild(ad.slot);        if not pod   then return nil end
    local base=pod:FindFirstChild("Base")
    if base then
        local spwn=base:FindFirstChild("Spawn")
        if spwn then
            for _,c in ipairs(spwn:GetChildren()) do
                if c:IsA("Model") or c:IsA("BasePart") then return c end
            end
        end
    end
    local function deepFind(parent)
        for _,c in ipairs(parent:GetChildren()) do
            if c:IsA("Model") or (c:IsA("BasePart") and c.Name~="Base") then return c end
            local r=deepFind(c); if r then return r end
        end
        return nil
    end
    return deepFind(pod)
end

local function getPetPosition(ad)
    local model=findPetModel(ad); if not model then return nil end
    if model:IsA("Model") then
        if model.PrimaryPart then return model.PrimaryPart.Position end
        local ok,cf=pcall(function() return model:GetBoundingBox() end)
        if ok and cf then return cf.Position end
        local part=model:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    elseif model:IsA("BasePart") then
        return model.Position
    end
    return nil
end

local function getPlayerPos()
    local char=LocalPlayer.Character; if not char then return nil end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    return hrp.Position
end

local function distToTarget(ad)
    local petPos=getPetPosition(ad); if not petPos then return math.huge end
    local plrPos=getPlayerPos();     if not plrPos then return math.huge end
    return (petPos-plrPos).Magnitude
end

-- ════════════════════════════════════════════════════════════
-- ESP — Highlight rainbow
-- ════════════════════════════════════════════════════════════
local function clearESP(uid)
    if espObjects[uid] then
        local e=espObjects[uid]
        if e.hl and e.hl.Parent then e.hl:Destroy() end
        if e.bb and e.bb.Parent then e.bb:Destroy() end
        espObjects[uid]=nil
    end
end
local function clearAllESP() for uid in pairs(espObjects) do clearESP(uid) end end

local function applyESP(ad)
    if not ad then return end
    clearESP(ad.uid)
    local model=findPetModel(ad); if not model then return end

    local hl=Instance.new("Highlight")
    hl.FillTransparency=0.3; hl.OutlineTransparency=0
    hl.FillColor=rbw(); hl.OutlineColor=rbw()
    hl.Adornee=model; hl.Parent=workspace

    local anchor=model:IsA("Model")and(model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"))or model

    local bb=Instance.new("BillboardGui")
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,180,0,38)
    bb.StudsOffset=Vector3.new(0,4,0); bb.Adornee=anchor; bb.Parent=workspace

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextColor3=Color3.new(1,1,1); lbl.TextStrokeTransparency=0
    lbl.TextStrokeColor3=Color3.new(0,0,0)
    lbl.Text=(ad.name or "?").."\n"..(ad.genText or ""); lbl.Parent=bb

    espObjects[ad.uid]={hl=hl,bb=bb,lbl=lbl}
end

RunService.Heartbeat:Connect(function(dt)
    rainbowClock=rainbowClock+dt
    local col=rbw()
    for uid,e in pairs(espObjects) do
        if e.hl and e.hl.Parent then e.hl.FillColor=col; e.hl.OutlineColor=col
        else espObjects[uid]=nil end
        if e.lbl then e.lbl.TextColor3=col end
    end
end)

local function refreshESP()
    clearAllESP(); if not enabled then return end
    if autoMode then
        for _,pet in ipairs(allAnimals) do if not isMyBase(pet) then applyESP(pet) end end
    else
        local pet=allAnimals[selIdx]; if pet and not isMyBase(pet) then applyESP(pet) end
    end
end

-- ════════════════════════════════════════════════════════════
-- FIND PROMPT
-- ════════════════════════════════════════════════════════════
local function findPrompt(ad)
    if not ad then return nil end
    local c=PromptCache[ad.uid]; if c and c.Parent then return c end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot=plots:FindFirstChild(ad.plot);      if not plot  then return nil end
    local pods=plot:FindFirstChild("AnimalPodiums");if not pods then return nil end
    local pod=pods:FindFirstChild(ad.slot);        if not pod   then return nil end
    local base=pod:FindFirstChild("Base");          if not base  then return nil end
    local spwn=base:FindFirstChild("Spawn");        if not spwn  then return nil end
    local att=spwn:FindFirstChild("PromptAttachment");if not att then return nil end
    for _,p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then PromptCache[ad.uid]=p; return p end
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- STEAL CALLBACKS
-- ════════════════════════════════════════════════════════════
local function buildCallbacks(prompt)
    if StealCache[prompt] then return end
    local data={hold={},trig={},ready=true}
    local ok1,c1=pcall(getconnections,prompt.PromptButtonHoldBegan)
    if ok1 and type(c1)=="table" then
        for _,c in ipairs(c1) do if type(c.Function)=="function" then table.insert(data.hold,c.Function) end end
    end
    local ok2,c2=pcall(getconnections,prompt.Triggered)
    if ok2 and type(c2)=="table" then
        for _,c in ipairs(c2) do if type(c.Function)=="function" then table.insert(data.trig,c.Function) end end
    end
    if #data.hold>0 or #data.trig>0 then StealCache[prompt]=data end
end

local function runList(list) for _,fn in ipairs(list) do task.spawn(fn) end end

local function fireSteal(prompt)
    local data=StealCache[prompt]; if not data then return end
    if #data.hold>0 then runList(data.hold) end
    task.wait(0.05)
    if #data.trig>0 then runList(data.trig) end
end

-- ════════════════════════════════════════════════════════════
-- PLOT SCANNER
-- ════════════════════════════════════════════════════════════
local function getHash(al)
    if not al then return "" end
    local h=""
    for s,d in pairs(al) do if type(d)=="table" then h=h..tostring(s)..tostring(d.Index)..tostring(d.Mutation) end end
    return h
end

local function scanPlot(plot)
    pcall(function()
        local uid=plot.Name
        local ch=stealthGet(uid); if not ch then return end
        local al=sProp(ch,"AnimalList")
        local hash=getHash(al)
        if lastHash[uid]==hash then return end
        lastHash[uid]=hash
        for i=#allAnimals,1,-1 do if allAnimals[i].plot==uid then table.remove(allAnimals,i) end end
        local owner=sProp(ch,"Owner")
        if not owner or not Players:FindFirstChild(owner.Name) then return end
if owner.UserId == LocalPlayer.UserId then return end
        if not al then return end
        for slot,ad in pairs(al) do
            if type(ad)=="table" then
                local nm=ad.Index
                local info=AnimalsData and AnimalsData[nm]; if not info then continue end
                local gen=AnimalsShared and AnimalsShared:GetGeneration(nm,ad.Mutation,ad.Traits,nil) or 0
                local genT="$"..(NumberUtils and NumberUtils:ToString(gen) or tostring(gen)).."/s"
                table.insert(allAnimals,{
                    name=info.DisplayName or nm,genText=genT,genValue=gen,
                    mutation=ad.Mutation or "None",
                    owner=owner.Name or "?",
                    plot=uid,slot=tostring(slot),uid=uid.."_"..tostring(slot),
                })
            end
        end
        table.sort(allAnimals,function(a,b) return a.genValue>b.genValue end)
    end)
end

local function setupPlot(plot)
    if plotChannels[plot.Name] then return end
    local ch; for i=1,3 do ch=stealthGet(plot.Name); if ch then break end; task.wait(0.3) end
    if not ch then return end
    plotChannels[plot.Name]=true; scanPlot(plot)
    plot.DescendantAdded:Connect(function() task.wait(0.05); scanPlot(plot) end)
    plot.DescendantRemoving:Connect(function() task.wait(0.05); scanPlot(plot) end)
    task.spawn(function() while plot.Parent and plotChannels[plot.Name] do task.wait(1); scanPlot(plot) end end)
end

local function initScanner()
    local plots=workspace:FindFirstChild("Plots")
    if not plots then
        for i=1,30 do plots=workspace:FindFirstChild("Plots"); if plots then break end; task.wait(0.5) end
        if not plots then return end
    end
    for _,p in ipairs(plots:GetChildren()) do task.spawn(setupPlot,p) end
    plots.ChildAdded:Connect(function(p) task.wait(0.2); task.spawn(setupPlot,p) end)
    plots.ChildRemoved:Connect(function(p)
        plotChannels[p.Name]=nil; lastHash[p.Name]=nil
        for i=#allAnimals,1,-1 do if allAnimals[i].plot==p.Name then table.remove(allAnimals,i) end end
    end)
end

-- ════════════════════════════════════════════════════════════
-- GUI — EXT Auto grab
-- ════════════════════════════════════════════════════════════
local W=340
local H_COL=42
local H_EXP=150
local isExpanded=true

local function getPetName()
    if autoMode then return "AUTO" end
    local p=allAnimals[selIdx]; return p and string.upper(p.name) or "NONE"
end

local function updateUI()
    if G.pct then
        G.pct.Text=string.format("%.0f%%",stealPct)
    end
    if G.bar then
        G.bar.Size=UDim2.new(stealPct/100,0,1,0)
    end
    if G.badge then
        if enabled then
            G.badge.Text="activate"
            G.badge.BackgroundColor3=Color3.fromRGB(34,170,34)
        else
            G.badge.Text="deactivate"
            G.badge.BackgroundColor3=Color3.fromRGB(195,22,22)
        end
    end
    if G.petLbl then G.petLbl.Text=getPetName() end
end

local function createGUI()
    local old=PlayerGui:FindFirstChild("ExtAutoGrabUI"); if old then old:Destroy() end

    local sg=Instance.new("ScreenGui")
    sg.Name="EXTAutoGrabUI"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=200; sg.IgnoreGuiInset=true; sg.Parent=PlayerGui

    local shadow=Instance.new("ImageLabel")
    shadow.Name="Shadow"
    shadow.Size=UDim2.new(0,W+30,0,H_EXP+30)
    shadow.Position=UDim2.new(0.5,-W/2-15,0.75,-15)
    shadow.BackgroundTransparency=1
    shadow.Image="rbxassetid://5554236805"
    shadow.ImageColor3=Color3.fromRGB(0,0,0)
    shadow.ImageTransparency=0.5
    shadow.ScaleType=Enum.ScaleType.Slice
    shadow.SliceCenter=Rect.new(23,23,277,277)
    shadow.ZIndex=98
    shadow.Parent=sg

    local mf=Instance.new("Frame")
    mf.Name="MainFrame"
    mf.Size=UDim2.new(0,W,0,H_EXP)
    mf.Position=UDim2.new(0.5,-W/2,0.75,0)
    mf.BackgroundColor3=Color3.fromRGB(15,11,11)
    mf.BorderSizePixel=0
    mf.ZIndex=100
    mf.ClipsDescendants=true
    mf.Parent=sg

    local mfC=Instance.new("UICorner"); mfC.CornerRadius=UDim.new(0,12); mfC.Parent=mf
    local mfS=Instance.new("UIStroke")
    mfS.Color=Color3.fromRGB(45,38,35)
    mfS.Thickness=1
    mfS.Transparency=0.3
    mfS.Parent=mf

    local hf=Instance.new("Frame")
    hf.Size=UDim2.new(1,0,0,44)
    hf.BackgroundTransparency=1
    hf.ZIndex=101; hf.Parent=mf

    local titleLbl=Instance.new("TextLabel")
    titleLbl.Size=UDim2.new(0,155,1,0)
    titleLbl.Position=UDim2.new(0,14,0,0)
    titleLbl.BackgroundTransparency=1
    titleLbl.Text="EXT HUB AUTO GRAB"
    titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=14
    titleLbl.TextColor3=Color3.fromRGB(228,218,205)
    titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.ZIndex=102; titleLbl.Parent=hf

    local pctLbl=Instance.new("TextLabel")
    pctLbl.Size=UDim2.new(0,44,1,0)
    pctLbl.Position=UDim2.new(0,168,0,0)
    pctLbl.BackgroundTransparency=1
    pctLbl.Text="0%"
    pctLbl.Font=Enum.Font.GothamBold
    pctLbl.TextSize=14
    pctLbl.TextColor3=Color3.fromRGB(178,1,255)
    pctLbl.TextXAlignment=Enum.TextXAlignment.Left
    pctLbl.ZIndex=102; pctLbl.Parent=hf
    G.pct=pctLbl

    local badge=Instance.new("TextButton")
    badge.Size=UDim2.new(0,84,0,24)
    badge.Position=UDim2.new(0,214,0.5,-12)
    badge.BackgroundColor3=Color3.fromRGB(195,22,22)
    badge.BorderSizePixel=0
    badge.Text="DÉSACTIVÉ"
    badge.Font=Enum.Font.GothamBold
    badge.TextSize=11
    badge.TextColor3=Color3.fromRGB(255,255,255)
    badge.AutoButtonColor=false
    badge.ZIndex=103; badge.Parent=hf
    local bC=Instance.new("UICorner"); bC.CornerRadius=UDim.new(0,6); bC.Parent=badge
    G.badge=badge

    local colBtn=Instance.new("TextButton")
    colBtn.Size=UDim2.new(0,24,0,24)
    colBtn.Position=UDim2.new(1,-30,0.5,-12)
    colBtn.BackgroundTransparency=1
    colBtn.Text="–"
    colBtn.Font=Enum.Font.GothamBold
    colBtn.TextSize=18
    colBtn.TextColor3=Color3.fromRGB(160,150,140)
    colBtn.AutoButtonColor=false
    colBtn.ZIndex=103; colBtn.Parent=hf

    local barBg=Instance.new("Frame")
    barBg.Name="BarBg"
    barBg.Size=UDim2.new(1,0,0,4)
    barBg.Position=UDim2.new(0,0,0,44)
    barBg.BackgroundColor3=Color3.fromRGB(30,20,18)
    barBg.BorderSizePixel=0
    barBg.ZIndex=101; barBg.Parent=mf

    local barFill=Instance.new("Frame")
    barFill.Name="BarFill"
    barFill.Size=UDim2.new(0,0,1,0)
    barFill.BackgroundColor3=Color3.fromRGB(210,30,10)
    barFill.BorderSizePixel=0
    barFill.ZIndex=102; barFill.Parent=barBg

    local barGrad=Instance.new("UIGradient")
    barGrad.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(200,20,5)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,120,0)),
    }
    barGrad.Parent=barFill
    G.bar=barFill

    local sep1=Instance.new("Frame")
    sep1.Size=UDim2.new(1,0,0,1)
    sep1.Position=UDim2.new(0,0,0,48)
    sep1.BackgroundColor3=Color3.fromRGB(38,30,27)
    sep1.BorderSizePixel=0
    sep1.ZIndex=101; sep1.Parent=mf

    local selRow=Instance.new("Frame")
    selRow.Size=UDim2.new(1,0,0,60)
    selRow.Position=UDim2.new(0,0,0,50)
    selRow.BackgroundTransparency=1
    selRow.ZIndex=101; selRow.Parent=mf

    local selBg=Instance.new("Frame")
    selBg.Size=UDim2.new(1,-24,1,-14)
    selBg.Position=UDim2.new(0,12,0,7)
    selBg.BackgroundColor3=Color3.fromRGB(22,16,14)
    selBg.BorderSizePixel=0
    selBg.ZIndex=101; selBg.Parent=selRow
    local selC=Instance.new("UICorner"); selC.CornerRadius=UDim.new(0,8); selC.Parent=selBg

    local leftBtn=Instance.new("TextButton")
    leftBtn.Size=UDim2.new(0,38,1,0)
    leftBtn.BackgroundTransparency=1
    leftBtn.Text="<"
    leftBtn.Font=Enum.Font.GothamBold
    leftBtn.TextSize=20
    leftBtn.TextColor3=Color3.fromRGB(175,165,150)
    leftBtn.AutoButtonColor=false
    leftBtn.ZIndex=102; leftBtn.Parent=selBg

    local rightBtn=Instance.new("TextButton")
    rightBtn.Size=UDim2.new(0,38,1,0)
    rightBtn.Position=UDim2.new(1,-38,0,0)
    rightBtn.BackgroundTransparency=1
    rightBtn.Text=">"
    rightBtn.Font=Enum.Font.GothamBold
    rightBtn.TextSize=20
    rightBtn.TextColor3=Color3.fromRGB(175,165,150)
    rightBtn.AutoButtonColor=false
    rightBtn.ZIndex=102; rightBtn.Parent=selBg

    local petLbl=Instance.new("TextLabel")
    petLbl.Size=UDim2.new(1,-80,1,0)
    petLbl.Position=UDim2.new(0,40,0,0)
    petLbl.BackgroundTransparency=1
    petLbl.Text="AUTO"
    petLbl.Font=Enum.Font.GothamBold
    petLbl.TextSize=15
    petLbl.TextColor3=Color3.fromRGB(228,218,205)
    petLbl.TextTruncate=Enum.TextTruncate.AtEnd
    petLbl.ZIndex=102; petLbl.Parent=selBg
    G.petLbl=petLbl

    local sep2=Instance.new("Frame")
    sep2.Size=UDim2.new(1,0,0,1)
    sep2.Position=UDim2.new(0,0,0,110)
    sep2.BackgroundColor3=Color3.fromRGB(38,30,27)
    sep2.BorderSizePixel=0
    sep2.ZIndex=101; sep2.Parent=mf

    local discLbl=Instance.new("TextLabel")
    discLbl.Size=UDim2.new(1,-20,0,34)
    discLbl.Position=UDim2.new(0,10,0,113)
    discLbl.BackgroundTransparency=1
    discLbl.Text="discord.gg/3GAMstNGfX"
    discLbl.Font=Enum.Font.Gotham
    discLbl.TextSize=17
    discLbl.TextColor3=Color3.fromRGB(255, 255, 255)
    discLbl.TextXAlignment=Enum.TextXAlignment.Center
    discLbl.ZIndex=102; discLbl.Parent=mf

    -- ── DRAG ────────────────────────────────────────────────
    local dragging,dInput,mPos,fPos=false,nil,nil,nil
    hf.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; mPos=inp.Position; fPos=mf.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    hf.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dInput=inp end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp==dInput and dragging then
            local d=inp.Position-mPos
            mf.Position=UDim2.new(fPos.X.Scale,fPos.X.Offset+d.X,fPos.Y.Scale,fPos.Y.Offset+d.Y)
            shadow.Position=UDim2.new(fPos.X.Scale,fPos.X.Offset+d.X-15,fPos.Y.Scale,fPos.Y.Offset+d.Y-15)
        end
    end)

    -- ── EXPAND / COLLAPSE ───────────────────────────────────
    local function setExpand(state)
        isExpanded=state
        colBtn.Text=state and "–" or "+"
        local th=state and H_EXP or H_COL
        local sh_h=state and H_EXP+30 or H_COL+30
        TweenService:Create(mf,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,W,0,th)}):Play()
        TweenService:Create(shadow,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,W+30,0,sh_h)}):Play()
    end
    colBtn.MouseButton1Click:Connect(function() setExpand(not isExpanded) end)

    -- ── TOGGLE BADGE ────────────────────────────────────────
    local function doToggle()
        enabled=not enabled
        if not enabled then
            -- Désactivation complète : tout reset
            clearAllESP()
            stealPct=0; stealTarget=nil; stealPhase="idle"
            dipTarget=0; stealFiring=false
        else
            -- Activation : démarre la charge depuis 0
            stealPhase="charging"
            refreshESP()
        end
        updateUI()
    end
    badge.MouseButton1Click:Connect(doToggle)

    -- ── FLÈCHES ─────────────────────────────────────────────
    leftBtn.MouseButton1Click:Connect(function()
        if autoMode then autoMode=false; selIdx=math.max(1,#allAnimals)
        else
            selIdx=selIdx-1
            if selIdx<1 then autoMode=true; selIdx=1 end
        end
        -- Changement de cible : repart de 0 (choix utilisateur explicite)
        stealPct=0; stealTarget=nil; stealPhase= enabled and "charging" or "idle"
        dipTarget=0; stealFiring=false
        updateUI(); refreshESP()
    end)
    rightBtn.MouseButton1Click:Connect(function()
        if autoMode then autoMode=false; selIdx=1
        else
            selIdx=selIdx+1
            if selIdx>#allAnimals then autoMode=true; selIdx=1 end
        end
        stealPct=0; stealTarget=nil; stealPhase= enabled and "charging" or "idle"
        dipTarget=0; stealFiring=false
        updateUI(); refreshESP()
    end)

    return true
end

-- ════════════════════════════════════════════════════════════
-- STEAL SYSTEM V2
-- ════════════════════════════════════════════════════════════
local function getTargetAnimal()
    if not enabled then return nil end
    if autoMode then
        if #allAnimals==0 then return nil end
        local best,bestDist=nil,math.huge
        for _,pet in ipairs(allAnimals) do
            if not isMyBase(pet) then
                local d=distToTarget(pet)
                if d<bestDist then bestDist=d; best=pet end
            end
        end
        return best
    else
        local pet=allAnimals[selIdx]
        if pet and not isMyBase(pet) then return pet end
        return nil
    end
end

RunService.Heartbeat:Connect(function(dt)
    if not enabled then
        if stealPhase~="idle" then
            stealPct=0; stealTarget=nil; stealPhase="idle"; dipTarget=0; stealFiring=false
            updateUI()
        end
        return
    end

    -- Si on est en train de fire le steal, on ne touche à rien
    if stealFiring then return end

    local target=getTargetAnimal()

    -- ── Gestion du changement de cible ───────────────────────
    -- IMPORTANT : on ne reset PAS le pourcentage si la cible change
    -- en AUTO mode. On garde le pct actuel et on continue depuis là.
    if target~=stealTarget then
        stealTarget=target
        if not target then
            -- Plus de cible : on gèle le pct là où on est
            -- (ne repart pas à 0 !)
            -- Si on était en plein dip/rush on revient à holding
            if stealPhase=="dipping" or stealPhase=="rushing" then
                stealPct=90; stealPhase="holding"
            elseif stealPhase=="idle" then
                stealPhase="charging"
            end
        else
            -- Nouvelle cible trouvée :
            if stealPhase=="idle" then
                stealPhase="charging"
            elseif stealPhase=="holding" or stealPhase=="dipping" or stealPhase=="rushing" then
                -- Déjà chargé, reste en holding pour la nouvelle cible
                stealPct=90; stealPhase="holding"; dipTarget=0
            end
            -- Si "charging" : continue de charger normalement
        end
    end

    if not stealTarget then
        -- Pas de cible : on reste gelé (ne monte/descend pas)
        -- Mais si pct < 90 et phase = charging, on attend juste
        updateUI(); return
    end

    local dist=distToTarget(stealTarget)

    -- ── Phase : Charge initiale vers 90 ──────────────────────
    if stealPhase=="charging" then
        stealPct = stealPct + CHARGE_SPEED * dt
        if stealPct >= 95 then
            stealPct = 95
            stealPhase = "holding"
        end

    -- ── Phase : Stable à 90%, attend le contact ──────────────
    elseif stealPhase=="holding" then
        -- Reste EXACTEMENT à 90, rien ne bouge
        stealPct = 95
        if dist <= TRIGGER_DIST then
            -- Contact ! On prépare le dip
            dipTarget = 95 - DIP_AMOUNT - math.random(0, 3)
            stealPhase = "dipping"
        end

    -- ── Phase : Dip visible ───────────────────────────────────
    elseif stealPhase=="dipping" then
        stealPct = stealPct - DIP_SPEED * dt
        if stealPct <= dipTarget then
            stealPct = dipTarget
            stealPhase = "rushing"
        end

    -- ── Phase : Rush vers 100 ─────────────────────────────────
    elseif stealPhase=="rushing" then
        stealPct = stealPct + RUSH_SPEED * dt
        if stealPct >= 100 then
            stealPct = 100
            updateUI()

            -- Vérifie cooldown anti-spam
            local now=tick()
            if now - lastStealTime >= STEAL_COOLDOWN then
                lastStealTime=now
                stealFiring=true

                -- Fire le steal dans un thread séparé pour pas bloquer le Heartbeat
                task.spawn(function()
                    local prompt = PromptCache[stealTarget and stealTarget.uid or ""] or findPrompt(stealTarget)
                    if prompt then
                        buildCallbacks(prompt)
                        if StealCache[prompt] and StealCache[prompt].ready then
                            fireSteal(prompt)
                        end
                    end
                    task.wait(0.25)

                    -- ══ CLÉ V2 : On revient à 90% "holding", PAS à 0 ══
                    stealPct = 95
                    stealPhase = "holding"
                    dipTarget = 0
                    stealFiring = false

                    refreshESP()
                    updateUI()
                end)
            else
                -- Cooldown pas terminé, on remet à 90 et on attend
                stealPct = 95
                stealPhase = "holding"
                dipTarget = 0
            end
            return
        end
    end

    updateUI()
end)

-- Refresh ESP périodique
task.spawn(function()
    while true do task.wait(3); if enabled then refreshESP() end end
end)

-- ════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while not AnimalsData or not AnimalsShared or not NumberUtils do task.wait(0.5) end
    task.wait(1.5)
    if not createGUI() then warn("[KZR V2] GUI failed!"); return end
    initScanner()
    task.wait(1)
    updateUI()
end)