--[[
  ╔══════════════════════════════════════════════════════════╗
  ║  PULSAR HUB  ·  The Strongest Battlegrounds              ║
  ║  Fluent UI  ·  Night-Hub style                           ║
  ║  Edit UI freely — tabs / toggles / sections are modular  ║
  ╚══════════════════════════════════════════════════════════╝
]]

repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInput      = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")

local LP   = Players.LocalPlayer
local Cam  = workspace.CurrentCamera

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local State = {
    -- Combat
    AutoFarm        = false,
    AutoKill        = false,
    AutoBlock       = false,
    AutoCombo       = false,
    AutoAttack      = false,
    AutoUltimate    = false,
    AutoDash        = false,
    KillAura        = false,
    KillAuraRange   = 20,
    TargetMode      = "Nearest", -- Nearest | LowestHP | Selected
    SelectedTarget  = nil,
    FarmOffsetY     = 3,
    BlockDistance   = 12,

    -- Visuals
    ESP             = false,
    ESP_Name        = true,
    ESP_Health      = true,
    ESP_Distance    = true,
    ESP_Tracers     = false,
    ESP_Box         = false,
    Aimbot          = false,
    AimbotFOV       = 120,
    AimbotSmooth    = 0.25,
    ShowFOV         = false,

    -- Movement
    WalkSpeed       = 16,
    JumpPower       = 50,
    SpeedEnabled    = false,
    JumpEnabled     = false,
    InfiniteJump    = false,
    Fly             = false,
    FlySpeed        = 50,
    NoClip          = false,

    -- Misc
    AntiAFK         = true,
    AntiFling       = false,
    AntiRagdoll     = false,
    AutoEscape      = false,
    EscapeHP        = 25,
    FPSBoost        = false,
    Fullbright      = false,
    NoFog           = false,

    -- Internal
    Connections     = {},
    ESP_Objects     = {},
}

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function char()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function hum()
    local c = char()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function hrp()
    local c = char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function isAlive(plr)
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getTarget()
    if State.TargetMode == "Selected" and State.SelectedTarget
        and isAlive(State.SelectedTarget) then
        return State.SelectedTarget
    end

    local best, bestVal = nil, math.huge
    local myHRP = hrp()
    if not myHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isAlive(plr) then
            local th = plr.Character:FindFirstChild("HumanoidRootPart")
            if th then
                if State.TargetMode == "LowestHP" then
                    local hp = plr.Character:FindFirstChildOfClass("Humanoid").Health
                    if hp < bestVal then
                        bestVal = hp
                        best = plr
                    end
                else -- Nearest
                    local d = (myHRP.Position - th.Position).Magnitude
                    if d < bestVal then
                        bestVal = d
                        best = plr
                    end
                end
            end
        end
    end
    return best
end

local function fireRemote(name, ...)
    local ok, remote = pcall(function()
        return ReplicatedStorage:FindFirstChild(name, true)
    end)
    if ok and remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            else
                remote:InvokeServer(...)
            end
        end)
    end
end

-- Generic M1 / attack simulation (works across most TSB builds)
local function doM1()
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function doBlock(on)
    pcall(function()
        -- F key is block in TSB
        if on then
            VirtualInput:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        else
            VirtualInput:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end
    end)
end

local function doUltimate()
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.G, false, game)
    end)
end

local function doDash()
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

----------------------------------------------------------------
-- LOAD FLUENT UI
----------------------------------------------------------------
local Fluent, SaveManager, InterfaceManager

local function loadFluent()
    local sources = {
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",
    }
    for _, url in ipairs(sources) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and lib then
            Fluent = lib
            break
        end
    end
    if not Fluent then
        error("[Pulsar] Failed to load Fluent UI library")
    end

    pcall(function()
        SaveManager = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
        ))()
    end)
    pcall(function()
        InterfaceManager = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
        ))()
    end)
end

loadFluent()

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title          = "Pulsar Hub",
    SubTitle       = "The Strongest Battlegrounds",
    TabWidth       = 160,
    Size           = UDim2.fromOffset(580, 460),
    Acrylic        = true,
    Theme          = "Darker",
    MinimizeKey    = Enum.KeyCode.LeftControl,
})

-- Tabs (Night-Hub style categories)
local Tabs = {
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "swords" }),
    Farm     = Window:AddTab({ Title = "Farm",     Icon = "crosshair" }),
    Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "person-standing" }),
    Misc     = Window:AddTab({ Title = "Misc",     Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "wrench" }),
}

----------------------------------------------------------------
-- COMBAT TAB
----------------------------------------------------------------
do
    local sec = Tabs.Combat:AddSection("Auto Combat")

    sec:AddToggle("AutoBlock", {
        Title = "Auto Block",
        Description = "Blocks when an enemy is close",
        Default = false,
        Callback = function(v) State.AutoBlock = v end,
    })

    sec:AddSlider("BlockDist", {
        Title = "Block Distance",
        Description = "Studs to start blocking",
        Default = 12,
        Min = 4,
        Max = 30,
        Rounding = 0,
        Callback = function(v) State.BlockDistance = v end,
    })

    sec:AddToggle("AutoCombo", {
        Title = "Auto Combo",
        Description = "Runs M1 + skill chain on target",
        Default = false,
        Callback = function(v) State.AutoCombo = v end,
    })

    sec:AddToggle("AutoAttack", {
        Title = "Auto Attack (M1)",
        Description = "Spam basic attacks",
        Default = false,
        Callback = function(v) State.AutoAttack = v end,
    })

    sec:AddToggle("AutoUltimate", {
        Title = "Auto Ultimate (G)",
        Description = "Fires ultimate when ready",
        Default = false,
        Callback = function(v) State.AutoUltimate = v end,
    })

    sec:AddToggle("AutoDash", {
        Title = "Auto Dash (Q)",
        Description = "Dashes toward target in combat",
        Default = false,
        Callback = function(v) State.AutoDash = v end,
    })

    sec:AddToggle("KillAura", {
        Title = "Kill Aura",
        Description = "Attacks anyone in range",
        Default = false,
        Callback = function(v) State.KillAura = v end,
    })

    sec:AddSlider("AuraRange", {
        Title = "Kill Aura Range",
        Default = 20,
        Min = 5,
        Max = 50,
        Rounding = 0,
        Callback = function(v) State.KillAuraRange = v end,
    })
end

----------------------------------------------------------------
-- FARM TAB
----------------------------------------------------------------
do
    local sec = Tabs.Farm:AddSection("Kill Farm")

    sec:AddToggle("AutoFarm", {
        Title = "Auto Farm",
        Description = "TP + attack target continuously",
        Default = false,
        Callback = function(v) State.AutoFarm = v end,
    })

    sec:AddToggle("AutoKill", {
        Title = "Auto Kill (focus)",
        Description = "Lock + finish selected / priority target",
        Default = false,
        Callback = function(v) State.AutoKill = v end,
    })

    sec:AddDropdown("TargetMode", {
        Title = "Target Priority",
        Description = "How the farm picks enemies",
        Values = { "Nearest", "LowestHP", "Selected" },
        Default = "Nearest",
        Callback = function(v) State.TargetMode = v end,
    })

    sec:AddSlider("FarmOffset", {
        Title = "Farm Height Offset",
        Description = "Y offset above target (studs)",
        Default = 3,
        Min = 0,
        Max = 15,
        Rounding = 1,
        Callback = function(v) State.FarmOffsetY = v end,
    })

    -- Player picker
    local function refreshPlayers()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                table.insert(list, p.Name)
            end
        end
        if #list == 0 then table.insert(list, "(none)") end
        return list
    end

    sec:AddDropdown("SelectTarget", {
        Title = "Select Target",
        Values = refreshPlayers(),
        Default = refreshPlayers()[1] or "(none)",
        Callback = function(name)
            State.SelectedTarget = Players:FindFirstChild(name)
        end,
    })

    sec:AddButton({
        Title = "Refresh Player List",
        Callback = function()
            Fluent:Notify({
                Title = "Pulsar",
                Content = "Re-open Select Target to see updated list",
                Duration = 3,
            })
        end,
    })

    sec:AddButton({
        Title = "Clear Target",
        Callback = function()
            State.SelectedTarget = nil
            Fluent:Notify({ Title = "Pulsar", Content = "Target cleared", Duration = 2 })
        end,
    })
end

----------------------------------------------------------------
-- VISUALS TAB
----------------------------------------------------------------
do
    local sec = Tabs.Visuals:AddSection("ESP")

    sec:AddToggle("ESP", {
        Title = "Player ESP",
        Default = false,
        Callback = function(v)
            State.ESP = v
            if not v then
                for _, obj in pairs(State.ESP_Objects) do
                    pcall(function() obj:Destroy() end)
                end
                State.ESP_Objects = {}
            end
        end,
    })

    sec:AddToggle("ESPName", {
        Title = "Show Names",
        Default = true,
        Callback = function(v) State.ESP_Name = v end,
    })

    sec:AddToggle("ESPHealth", {
        Title = "Show Health",
        Default = true,
        Callback = function(v) State.ESP_Health = v end,
    })

    sec:AddToggle("ESPDist", {
        Title = "Show Distance",
        Default = true,
        Callback = function(v) State.ESP_Distance = v end,
    })

    sec:AddToggle("ESPBox", {
        Title = "Bounding Box",
        Default = false,
        Callback = function(v) State.ESP_Box = v end,
    })

    sec:AddToggle("ESPTracers", {
        Title = "Tracers",
        Default = false,
        Callback = function(v) State.ESP_Tracers = v end,
    })

    local aim = Tabs.Visuals:AddSection("Aimbot")

    aim:AddToggle("Aimbot", {
        Title = "Aimbot",
        Description = "Smooth lock onto target head",
        Default = false,
        Callback = function(v) State.Aimbot = v end,
    })

    aim:AddSlider("AimFOV", {
        Title = "FOV",
        Default = 120,
        Min = 30,
        Max = 360,
        Rounding = 0,
        Callback = function(v) State.AimbotFOV = v end,
    })

    aim:AddSlider("AimSmooth", {
        Title = "Smoothness",
        Default = 0.25,
        Min = 0.05,
        Max = 1,
        Rounding = 2,
        Callback = function(v) State.AimbotSmooth = v end,
    })
end

----------------------------------------------------------------
-- MOVEMENT TAB
----------------------------------------------------------------
do
    local sec = Tabs.Movement:AddSection("Speed & Jump")

    sec:AddToggle("SpeedOn", {
        Title = "Walk Speed",
        Default = false,
        Callback = function(v)
            State.SpeedEnabled = v
            local h = hum()
            if h then h.WalkSpeed = v and State.WalkSpeed or 16 end
        end,
    })

    sec:AddSlider("WalkSpeed", {
        Title = "Speed Value",
        Default = 16,
        Min = 16,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            State.WalkSpeed = v
            if State.SpeedEnabled then
                local h = hum()
                if h then h.WalkSpeed = v end
            end
        end,
    })

    sec:AddToggle("JumpOn", {
        Title = "Jump Power",
        Default = false,
        Callback = function(v)
            State.JumpEnabled = v
            local h = hum()
            if h then
                h.UseJumpPower = true
                h.JumpPower = v and State.JumpPower or 50
            end
        end,
    })

    sec:AddSlider("JumpPower", {
        Title = "Jump Value",
        Default = 50,
        Min = 50,
        Max = 300,
        Rounding = 0,
        Callback = function(v)
            State.JumpPower = v
            if State.JumpEnabled then
                local h = hum()
                if h then h.JumpPower = v end
            end
        end,
    })

    sec:AddToggle("InfJump", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(v) State.InfiniteJump = v end,
    })

    local fly = Tabs.Movement:AddSection("Fly & Clip")

    fly:AddToggle("Fly", {
        Title = "Fly",
        Description = "WASD + Space / Shift",
        Default = false,
        Callback = function(v) State.Fly = v end,
    })

    fly:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Callback = function(v) State.FlySpeed = v end,
    })

    fly:AddToggle("NoClip", {
        Title = "NoClip",
        Default = false,
        Callback = function(v) State.NoClip = v end,
    })
end

----------------------------------------------------------------
-- MISC TAB
----------------------------------------------------------------
do
    local sec = Tabs.Misc:AddSection("Protection")

    sec:AddToggle("AntiAFK", {
        Title = "Anti-AFK",
        Default = true,
        Callback = function(v) State.AntiAFK = v end,
    })

    sec:AddToggle("AntiFling", {
        Title = "Anti-Fling",
        Default = false,
        Callback = function(v) State.AntiFling = v end,
    })

    sec:AddToggle("AntiRagdoll", {
        Title = "Anti-Ragdoll",
        Default = false,
        Callback = function(v) State.AntiRagdoll = v end,
    })

    sec:AddToggle("AutoEscape", {
        Title = "Auto Escape (low HP)",
        Description = "TP to spawn when HP is critical",
        Default = false,
        Callback = function(v) State.AutoEscape = v end,
    })

    sec:AddSlider("EscapeHP", {
        Title = "Escape HP %",
        Default = 25,
        Min = 5,
        Max = 80,
        Rounding = 0,
        Callback = function(v) State.EscapeHP = v end,
    })

    local perf = Tabs.Misc:AddSection("Performance")

    perf:AddToggle("FPSBoost", {
        Title = "FPS Boost",
        Description = "Lowers graphics for more FPS",
        Default = false,
        Callback = function(v)
            State.FPSBoost = v
            if v then
                pcall(function()
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                            obj.Enabled = false
                        end
                    end
                end)
            end
        end,
    })

    perf:AddToggle("Fullbright", {
        Title = "Fullbright",
        Default = false,
        Callback = function(v)
            State.Fullbright = v
            if v then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1
                Lighting.GlobalShadows = true
            end
        end,
    })

    perf:AddToggle("NoFog", {
        Title = "No Fog",
        Default = false,
        Callback = function(v)
            State.NoFog = v
            Lighting.FogEnd = v and 100000 or 1000
        end,
    })

    local tp = Tabs.Misc:AddSection("Teleport")

    tp:AddButton({
        Title = "TP to Target",
        Callback = function()
            local t = getTarget()
            local my = hrp()
            if t and my and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                my.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end
        end,
    })

    tp:AddButton({
        Title = "TP to Random Player",
        Callback = function()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and isAlive(p) then table.insert(list, p) end
            end
            if #list > 0 then
                local t = list[math.random(1, #list)]
                local my = hrp()
                if my and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                    my.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end
        end,
    })

    tp:AddButton({
        Title = "Rejoin Server",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, LP)
        end,
    })

    tp:AddButton({
        Title = "Server Hop",
        Callback = function()
            pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
                for _, s in ipairs(servers.data or {}) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                        break
                    end
                end
            end)
        end,
    })
end

----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------
do
    local sec = Tabs.Settings:AddSection("UI")

    sec:AddParagraph({
        Title = "Pulsar Hub",
        Content = "Fluent UI · Night-Hub style\nLeft Ctrl = minimize\nEdit this file freely for your GitHub repo.",
    })

    sec:AddButton({
        Title = "Unload Hub",
        Callback = function()
            for _, c in pairs(State.Connections) do
                pcall(function() c:Disconnect() end)
            end
            Window:Destroy()
        end,
    })

    if SaveManager and InterfaceManager then
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("PulsarTSB")
        SaveManager:SetFolder("PulsarTSB")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end
end

----------------------------------------------------------------
-- LOOPS / HEARTBEAT
----------------------------------------------------------------

-- Anti-AFK
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if State.AntiAFK then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local h = hum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Main heartbeat
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    local myHRP = hrp()
    local myHum = hum()
    if not myHRP or not myHum then return end

    -- Speed / Jump keep
    if State.SpeedEnabled then
        myHum.WalkSpeed = State.WalkSpeed
    end
    if State.JumpEnabled then
        myHum.UseJumpPower = true
        myHum.JumpPower = State.JumpPower
    end

    -- NoClip
    if State.NoClip then
        for _, part in ipairs(char():GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Fly
    if State.Fly then
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then
            myHRP.Velocity = dir.Unit * State.FlySpeed
        else
            myHRP.Velocity = Vector3.zero
        end
    end

    -- Anti-Fling
    if State.AntiFling then
        if myHRP.AssemblyLinearVelocity.Magnitude > 150 then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- Anti-Ragdoll
    if State.AntiRagdoll then
        pcall(function()
            local rag = char():FindFirstChild("Ragdoll") or char():FindFirstChild("RagdollTrigger")
            if rag then rag:Destroy() end
            myHum.PlatformStand = false
        end)
    end

    -- Auto Escape
    if State.AutoEscape then
        local pct = (myHum.Health / myHum.MaxHealth) * 100
        if pct <= State.EscapeHP then
            pcall(function()
                myHRP.CFrame = CFrame.new(0, 50, 0) -- generic spawn-ish height
            end)
        end
    end

    local target = getTarget()

    -- Auto Farm
    if (State.AutoFarm or State.AutoKill) and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th then
            myHRP.CFrame = th.CFrame * CFrame.new(0, State.FarmOffsetY, 3)
            doM1()
        end
    end

    -- Kill Aura
    if State.KillAura then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isAlive(plr) then
                local th = plr.Character:FindFirstChild("HumanoidRootPart")
                if th and (myHRP.Position - th.Position).Magnitude <= State.KillAuraRange then
                    doM1()
                end
            end
        end
    end

    -- Auto Block
    if State.AutoBlock and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th and (myHRP.Position - th.Position).Magnitude <= State.BlockDistance then
            doBlock(true)
        else
            doBlock(false)
        end
    end

    -- Auto Attack
    if State.AutoAttack and target then
        doM1()
    end

    -- Auto Combo (M1 spam + occasional dash)
    if State.AutoCombo and target then
        doM1()
        if math.random() < 0.08 then doDash() end
    end

    -- Auto Ultimate
    if State.AutoUltimate then
        -- fire periodically; real ult-ready detection is character-dependent
        if math.random() < 0.02 then doUltimate() end
    end

    -- Auto Dash toward target
    if State.AutoDash and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th and (myHRP.Position - th.Position).Magnitude > 8
            and (myHRP.Position - th.Position).Magnitude < 40 then
            if math.random() < 0.05 then doDash() end
        end
    end

    -- Aimbot
    if State.Aimbot and target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local screen, onScreen = Cam:WorldToViewportPoint(head.Position)
            if onScreen then
                local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if dist <= State.AimbotFOV then
                    local goal = CFrame.new(Cam.CFrame.Position, head.Position)
                    Cam.CFrame = Cam.CFrame:Lerp(goal, State.AimbotSmooth)
                end
            end
        end
    end
end))

-- ESP loop
table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    if not State.ESP then return end
    local myHRP = hrp()
    if not myHRP then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isAlive(plr) then
            local c = plr.Character
            local th = c:FindFirstChild("HumanoidRootPart")
            local head = c:FindFirstChild("Head")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not th or not head then continue end

            local key = plr.Name
            if not State.ESP_Objects[key] then
                local bill = Instance.new("BillboardGui")
                bill.Name = "PulsarESP"
                bill.Adornee = head
                bill.Size = UDim2.new(0, 200, 0, 50)
                bill.StudsOffset = Vector3.new(0, 2.5, 0)
                bill.AlwaysOnTop = true
                bill.Parent = head

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextStrokeTransparency = 0.4
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Parent = bill

                local highlight = Instance.new("Highlight")
                highlight.FillTransparency = 0.7
                highlight.OutlineColor = Color3.fromRGB(120, 80, 255)
                highlight.FillColor = Color3.fromRGB(120, 80, 255)
                highlight.Parent = c

                State.ESP_Objects[key] = { bill = bill, label = label, hl = highlight }
            end

            local pack = State.ESP_Objects[key]
            if pack and pack.label then
                local parts = {}
                if State.ESP_Name then table.insert(parts, plr.Name) end
                if State.ESP_Health and h then
                    table.insert(parts, string.format("[%d/%d]", math.floor(h.Health), math.floor(h.MaxHealth)))
                end
                if State.ESP_Distance then
                    table.insert(parts, string.format("%dst", math.floor((myHRP.Position - th.Position).Magnitude)))
                end
                pack.label.Text = table.concat(parts, "  ")
            end
        else
            -- cleanup dead / left
            local key = plr.Name
            if State.ESP_Objects[key] then
                pcall(function()
                    State.ESP_Objects[key].bill:Destroy()
                    State.ESP_Objects[key].hl:Destroy()
                end)
                State.ESP_Objects[key] = nil
            end
        end
    end
end))

-- Character respawn keep
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if State.SpeedEnabled then
        local h = hum()
        if h then h.WalkSpeed = State.WalkSpeed end
    end
end)

----------------------------------------------------------------
-- NOTIFY
----------------------------------------------------------------
Fluent:Notify({
    Title   = "Pulsar Hub",
    Content = "Loaded · The Strongest Battlegrounds\nLeft Ctrl to toggle UI",
    Duration = 5,
})

print("[Pulsar] TSB Hub loaded — Fluent UI ready")
