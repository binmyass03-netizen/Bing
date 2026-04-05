local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local logBuffer = {}
local maxBufferSize = 100
local flushInterval = 0.01

-- Theme Color
local themeColor = Color3.fromRGB(170, 0, 255)
local secondaryColor = Color3.fromRGB(200, 100, 255)

local oldPrint = print
local oldWarn = warn
local oldError = error

local function instantLog(message, logType)
    logType = logType or "INFO"
    
    if rconsoleprint then
        local timestamp = os.date("%H:%M:%S")
        local prefix = ""
        
        if logType == "WARN" then
            prefix = "⚠️ "
        elseif logType == "ERROR" then
            prefix = "❌ "
        else
            prefix = "✓ "
        end
        
        rconsoleprint(string.format("[%s] %s%s\n", timestamp, prefix, tostring(message)))
    end
    
    table.insert(logBuffer, {
        time = tick(),
        message = message,
        type = logType
    })
    
    if #logBuffer > maxBufferSize then
        table.remove(logBuffer, 1)
    end
end

print = function(...)
    local args = {...}
    local message = table.concat({...}, " ")
    oldPrint(...)
    instantLog(message, "INFO")
end

warn = function(...)
    local message = table.concat({...}, " ")
    oldWarn(...)
    instantLog(message, "WARN")
end

task.spawn(function()
    while task.wait(flushInterval) do
        if rconsoleclear and #logBuffer > 50 then
        end
    end
end)

local function optimizeLogs()
    if setfflag then
        pcall(function()
            setfflag("AbuseReportScreenshotPercentage", "0")
            setfflag("DFFlagDebugAnalytics", "false")
            setfflag("DFFlagDebugVisualizationsEnabled", "false")
            setfflag("FFlagDebugForceFutureIsBrightPhase2", "false")
            setfflag("FFlagDebugForceFutureIsBrightPhase3", "false")
            setfflag("DFFlagDebugEnableLogToCloudForAllPlayers", "false")
        end)
    end
    
    if rconsoleclear then
        rconsoleclear()
    end
    
    if rconsoleinfo then
        rconsoleinfo("⚡ NAZII SPEED - INSTANT LOG EDITION")
        rconsoleinfo("✓ Console forwarding: INSTANT MODE")
    end
    
    if setconsoletitle then
        setconsoletitle("NAZII SPEED - INSTANT LOGS")
    end
    
    instantLog("Executor optimization complete", "INFO")
end

optimizeLogs()

local fpsBoostEnabled = false
local hiddenObjects = {}

local function optimizeNetwork()
    instantLog("Applying network optimizations...", "INFO")
    
    pcall(function()
        settings().Network.IncomingReplicationLag = 0
        settings().Network.PhysicsSend = 255
        settings().Network.DataSendRate = 255
        settings().Network.ExperimentalPhysicsEnabled = true
        settings().Network.PhysicsReceive = 255
        
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(game:GetService("NetworkClient"), "OutgoingReplicationLag", 0)
            end)
        end
        
        if setfflag then
            pcall(function()
                setfflag("DFIntTaskSchedulerTargetFps", "9999")
                setfflag("DFIntTimestepArbiterThresholdCFLThou", "0")
            end)
        end
    end)
    
    pcall(function()
        settings().Physics.AllowSleep = true
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Skip
        settings().Physics.ThrottleAdjustTime = 0
    end)
    
    instantLog("Network optimizations applied", "INFO")
end

optimizeNetwork()

local function optimizeRendering()
    instantLog("Applying rendering optimizations...", "INFO")
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EnableFRM = false
        settings().Rendering.EnableVRMode = false
        
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
            end)
        end
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
        
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") 
                or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") 
                or effect:IsA("DepthOfFieldEffect") then
                effect.Enabled = false
            end
        end
        
        if setfpscap then
            setfpscap(999)
            instantLog("FPS cap set to 999", "INFO")
        end
    end)
    
    instantLog("Rendering optimizations applied", "INFO")
end

optimizeRendering()

local function toggleFPSBoost()
    fpsBoostEnabled = not fpsBoostEnabled
    
    if fpsBoostEnabled then
        instantLog("FPS BOOST ENABLED - Hiding environment", "INFO")
        
        local objectsHidden = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsDescendantOf(player.Character) then
                    return
                end
                
                local isPlayerChar = false
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr.Character and obj:IsDescendantOf(plr.Character) then
                        isPlayerChar = true
                        break
                    end
                end
                
                if not isPlayerChar then
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") 
                        or obj:IsA("UnionOperation") or obj:IsA("TrussPart") then
                        if obj.Transparency < 1 then
                            table.insert(hiddenObjects, {obj = obj, originalTransparency = obj.Transparency})
                            obj.Transparency = 1
                            obj.CanCollide = false
                            objectsHidden = objectsHidden + 1
                        end
                    end
                    
                    if obj:IsA("Decal") or obj:IsA("Texture") then
                        if obj.Transparency < 1 then
                            table.insert(hiddenObjects, {obj = obj, originalTransparency = obj.Transparency})
                            obj.Transparency = 1
                        end
                    end
                    
                    if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
                        if obj.Enabled then
                            table.insert(hiddenObjects, {obj = obj, originalEnabled = true})
                            obj.Enabled = false
                        end
                    end
                    
                    if obj:IsA("Light") or obj:IsA("SpotLight") or obj:IsA("PointLight") 
                        or obj:IsA("SurfaceLight") then
                        if obj.Enabled then
                            table.insert(hiddenObjects, {obj = obj, originalEnabled = true})
                            obj.Enabled = false
                        end
                    end
                    
                    if obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        if obj.Enabled then
                            table.insert(hiddenObjects, {obj = obj, originalEnabled = true})
                            obj.Enabled = false
                        end
                    end
                end
            end)
        end
        
        pcall(function()
            workspace.Terrain.WaterTransparency = 1
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
        end)
        
        instantLog(string.format("FPS BOOST ACTIVE - %d objects hidden", objectsHidden), "INFO")
        
    else
        instantLog("FPS BOOST DISABLED - Restoring environment", "INFO")
        
        local objectsRestored = 0
        
        for _, data in pairs(hiddenObjects) do
            pcall(function()
                if data.originalTransparency then
                    data.obj.Transparency = data.originalTransparency
                    if data.obj:IsA("BasePart") then
                        data.obj.CanCollide = true
                    end
                    objectsRestored = objectsRestored + 1
                elseif data.originalEnabled then
                    data.obj.Enabled = true
                    objectsRestored = objectsRestored + 1
                end
            end)
        end
        
        hiddenObjects = {}
        
        instantLog(string.format("Environment restored - %d objects", objectsRestored), "INFO")
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Zero then
        toggleFPSBoost()
    end
end)

local function createCleanLoadingScreen()
    local playerGui = player:WaitForChild("PlayerGui")
    
    if playerGui:FindFirstChild("YNSpeed") then
        playerGui.YNSpeed:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NAZIISpeed"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
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
    
    local ynText = Instance.new("TextLabel")
    ynText.Size = UDim2.new(0, 500, 0, 180)
    ynText.Position = UDim2.new(0, -550, 0.5, -90)
    ynText.BackgroundTransparency = 1
    ynText.Text = "NAZII"
    ynText.Font = Enum.Font.GothamBlack
    ynText.TextSize = 110
    ynText.TextColor3 = themeColor
    ynText.TextStrokeTransparency = 0.7
    ynText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ynText.TextTransparency = 0
    ynText.Parent = container
    
    local speedText = Instance.new("TextLabel")
    speedText.Size = UDim2.new(0, 500, 0, 180)
    speedText.Position = UDim2.new(1, 50, 0.5, -90)
    speedText.BackgroundTransparency = 1
    speedText.Text = "SPEED"
    speedText.Font = Enum.Font.GothamBlack
    speedText.TextSize = 110
    speedText.TextColor3 = Color3.fromRGB(0, 0, 0)
    speedText.TextStrokeTransparency = 0
    speedText.TextStrokeColor3 = themeColor
    speedText.TextTransparency = 0
    speedText.Parent = container
    
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
    versionText.Text = "discord.gg/AQZQWRdY"
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
        createBracket(0.2, 0.3, true, false),
        createBracket(0.2, 0.3, false, false),
        createBracket(0.8, 0.3, true, true),
        createBracket(0.8, 0.3, false, true),
        createBracket(0.2, 0.7, true, true),
        createBracket(0.2, 0.7, false, true),
        createBracket(0.8, 0.7, true, true),
        createBracket(0.8, 0.7, false, true),
    }
    
    task.spawn(function()
        task.wait(0.5)
        
        TweenService:Create(ynText, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -480, 0.5, -90)}):Play()
        
        task.wait(0.03)
        
        TweenService:Create(speedText, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, 20, 0.5, -90)}):Play()
        
        task.wait(0.2)
        
        TweenService:Create(bottomBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 800, 0, 4)}):Play()
        
        TweenService:Create(versionText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        
        task.wait(0.25)
        
        TweenService:Create(ynText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0, -600, 0.5, -90), TextTransparency = 1}):Play()
        
        TweenService:Create(speedText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
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
    end)
    
    return screenGui
end

local function createCleanHUD(screenGui)
    local hudBar = Instance.new("Frame")
    hudBar.Size = UDim2.new(0, 220, 0, 3)
    hudBar.Position = UDim2.new(0.5, -110, 0, 20)
    hudBar.BackgroundColor3 = themeColor
    hudBar.BorderSizePixel = 0
    hudBar.Parent = screenGui
    
    local hudText = Instance.new("TextLabel")
    hudText.Size = UDim2.new(0, 220, 0, 30)
    hudText.Position = UDim2.new(0.5, -110, 0, 25)
    hudText.BackgroundTransparency = 1
    hudText.Text = "NAZII SPEED"
    hudText.Font = Enum.Font.GothamBold
    hudText.TextSize = 18
    hudText.TextColor3 = themeColor
    hudText.TextStrokeTransparency = 0.5
    hudText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hudText.Parent = screenGui
    
    task.spawn(function()
        while task.wait(1.5) do
            TweenService:Create(hudBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Size = UDim2.new(0, 240, 0, 3)}):Play()
            task.wait(0.3)
            TweenService:Create(hudBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Size = UDim2.new(0, 220, 0, 3)}):Play()
        end
    end)
    
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0, 150, 0, 60)
    statsFrame.Position = UDim2.new(0, 15, 1, -75)
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.4
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = screenGui
    
    local statsAccent = Instance.new("Frame")
    statsAccent.Size = UDim2.new(1, 0, 0, 2)
    statsAccent.BackgroundColor3 = themeColor
    statsAccent.BorderSizePixel = 0
    statsAccent.Parent = statsFrame
    
    local statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(1, -10, 1, -5)
    statsText.Position = UDim2.new(0, 5, 0, 3)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3 = themeColor
    statsText.Font = Enum.Font.Code
    statsText.TextSize = 12
    statsText.TextXAlignment = Enum.TextXAlignment.Left
    statsText.TextYAlignment = Enum.TextYAlignment.Top
    statsText.Text = "FPS: --\nPING: --\nBOOST: OFF"
    statsText.Parent = statsFrame
    
    task.spawn(function()
        local lastTime = tick()
        while task.wait(0.1) do
            local fps = math.floor(1 / (tick() - lastTime))
            lastTime = tick()
            
            local ping = 0
            pcall(function()
                ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            
            local boostStatus = fpsBoostEnabled and "ON" or "OFF"
            local boostColor = fpsBoostEnabled and "🟢" or "🔴"
            
            statsText.Text = string.format("FPS: %d\nPING: %.0f\nBOOST: %s %s", fps, ping, boostColor, boostStatus)
        end
    end)
    
    local hintFrame = Instance.new("Frame")
    hintFrame.Size = UDim2.new(0, 200, 0, 30)
    hintFrame.Position = UDim2.new(0, 15, 1, -110)
    hintFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hintFrame.BackgroundTransparency = 0.5
    hintFrame.BorderSizePixel = 0
    hintFrame.Parent = screenGui
    
    local hintText = Instance.new("TextLabel")
    hintText.Size = UDim2.new(1, 0, 1, 0)
    hintText.BackgroundTransparency = 1
    hintText.Text = "FPS Boost ON | [0] to toggle"
    hintText.Font = Enum.Font.GothamBold
    hintText.TextSize = 13
    hintText.TextColor3 = themeColor
    hintText.Parent = hintFrame
    
    task.spawn(function()
        task.wait(10)
        TweenService:Create(hintFrame, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
        TweenService:Create(hintText, TweenInfo.new(1), {TextTransparency = 1}):Play()
    end)
end

game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

task.spawn(function()
    while task.wait(0.05) do
        for _, gui in pairs(player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "YNSpeed" then
                local name = gui.Name:lower()
                if name:match("loading") or name:match("intro") or name:match("welcome") then
                    pcall(function() gui:Destroy() end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.03) do
        for _, button in pairs(player.PlayerGui:GetDescendants()) do
            if (button:IsA("TextButton") or button:IsA("ImageButton")) and button.Visible then
                local text = button.Text:lower()
                if text:match("play") or text:match("continue") or text:match("start") or text:match("skip") then
                    pcall(function()
                        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                            connection:Fire()
                        end
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        collectgarbage("collect")
    end
end)

task.spawn(function()
    task.wait(1)
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Sound") and not obj:IsDescendantOf(player.Character) then
                obj:Stop()
                obj.Volume = 0
            end
        end
    end)
end)

task.spawn(function()
    task.wait(5)
    while task.wait(30) do
        local ping = 0
        local fps = 0
        
        pcall(function()
            ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
        end)
        
        instantLog(string.format("Performance: FPS=%d, PING=%.0f, BOOST=%s", fps, ping, fpsBoostEnabled and "ON" or "OFF"), "INFO")
    end
end)

instantLog("Starting NAZII SPEED initialization...", "INFO")

local screenGui = createCleanLoadingScreen()

task.wait(3)
createCleanHUD(screenGui)

instantLog("NAZII SPEED fully loaded", "INFO")
instantLog("Auto-enabling FPS Boost...", "INFO")
instantLog("Instant log forwarding: ACTIVE", "INFO")

toggleFPSBoost()

print("⚡ NAZII SPEED - INSTANT LOG EDITION")
print("⚡ Console logs are forwarded INSTANTLY")
print("⚡ FPS Boost auto-enabled on load | Press [0] to toggle")    