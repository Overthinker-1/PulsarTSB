--[[
  PULSAR HUB — The Strongest Battlegrounds
  Fluent from YOUR repo | Mobile-friendly toggle | Transparent acrylic
]]

print("[Pulsar] starting...")

local okAll, errAll = pcall(function()

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")

local VirtualInput
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

----------------------------------------------------------------
local REPO = "https://raw.githubusercontent.com/Overthinker-1/PulsarTSB/main"

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 50 then return res end
    return nil, res
end

local function loadFromRepo(path)
    local url = REPO .. "/" .. path
    print("[Pulsar] loading " .. path)
    local src, err = httpGet(url)
    if not src then error("HttpGet failed " .. path .. ": " .. tostring(err)) end
    local fn, err2 = loadstring(src)
    if type(fn) ~= "function" then error("loadstring failed " .. path .. ": " .. tostring(err2 or fn)) end
    return fn()
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local S = {
    AutoFarm=false, AutoKill=false, AutoBlock=false, AutoCombo=false,
    AutoAttack=false, AutoUltimate=false, AutoDash=false, KillAura=false,
    KillAuraRange=18, TargetMode="Nearest", FarmOffsetY=2.5, BlockDistance=10,
    ESP=false, ESP_Name=true, ESP_Health=true, ESP_Distance=true,
    Aimbot=false, AimbotFOV=140, AimbotSmooth=0.2,
    WalkSpeed=16, JumpPower=50, SpeedOn=false, JumpOn=false,
    InfJump=false, Fly=false, FlySpeed=45, NoClip=false,
    AntiAFK=true, AntiFling=false, AntiRagdoll=false,
    AutoEscape=false, EscapeHP=25, FPSBoost=false, Fullbright=false,
    Conns={}, ESP_Objs={},
    HoldingBlock=false, LastM1=0, LastDash=0, LastUlt=0,
}

local function char() return LP.Character end
local function hum() local c=char() return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c=char() return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(p)
    local c=p.Character; if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid"); return h and h.Health>0
end

local function getTarget()
    local best, bestVal = nil, math.huge
    local my = hrp(); if not my then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) then
            local th=p.Character:FindFirstChild("HumanoidRootPart")
            if th then
                if S.TargetMode=="LowestHP" then
                    local hp=p.Character:FindFirstChildOfClass("Humanoid").Health
                    if hp<bestVal then bestVal=hp; best=p end
                else
                    local d=(my.Position-th.Position).Magnitude
                    if d<bestVal then bestVal=d; best=p end
                end
            end
        end
    end
    return best
end

-- Safer input: prefer tool Activate on mobile, mouse only on PC
local function doM1()
    local now = tick()
    if now - S.LastM1 < 0.12 then return end
    S.LastM1 = now
    local c = char()
    if not c then return end
    -- Try equipped tool first (works better on mobile, less joystick steal)
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        return
    end
    if VirtualInput and not IS_MOBILE then
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.03)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    elseif VirtualInput then
        -- Mobile: short key pulse instead of mouse when possible
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.02)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

local function keyDown(key)
    if not VirtualInput then return end
    pcall(function() VirtualInput:SendKeyEvent(true, key, false, game) end)
end
local function keyUp(key)
    if not VirtualInput then return end
    pcall(function() VirtualInput:SendKeyEvent(false, key, false, game) end)
end

----------------------------------------------------------------
-- LOAD FLUENT
----------------------------------------------------------------
local Fluent = loadFromRepo("FluentLib.lua")
print("[Pulsar] Fluent loaded")

local SaveManager, InterfaceManager
pcall(function() SaveManager = loadFromRepo("SaveManager.lua") end)
pcall(function() InterfaceManager = loadFromRepo("InterfaceManager.lua") end)

----------------------------------------------------------------
-- WINDOW — transparent acrylic like Night Hub
----------------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title       = "Pulsar Hub",
    SubTitle    = "The Strongest Battlegrounds",
    TabWidth    = 150,
    Size        = UDim2.fromOffset(520, 400),
    Acrylic     = true,          -- blur background
    Theme       = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

-- Try force more transparency on Fluent root after create
task.defer(function()
    pcall(function()
        for _, gui in ipairs(CoreGui:GetDescendants()) do
            if gui:IsA("Frame") and (gui.Name == "Main" or gui.Name == "Background" or gui.Name == "AcrylicPaint") then
                if gui.BackgroundTransparency < 0.35 then
                    gui.BackgroundTransparency = math.max(gui.BackgroundTransparency, 0.25)
                end
            end
        end
    end)
end)

local Tabs = {
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "swords" }),
    Farm     = Window:AddTab({ Title = "Farm",     Icon = "crosshair" }),
    Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "person-standing" }),
    Misc     = Window:AddTab({ Title = "Misc",     Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "wrench" }),
}

----------------------------------------------------------------
-- FLOATING OPEN / CLOSE BUTTON (mobile + PC)
----------------------------------------------------------------
local function makeToggleButton()
    local sg = Instance.new("ScreenGui")
    sg.Name = "PulsarToggle"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

    local btn = Instance.new("TextButton")
    btn.Name = "OpenClose"
    btn.Size = UDim2.new(0, 52, 0, 52)
    btn.Position = UDim2.new(1, -70, 0.5, -26)
    btn.AnchorPoint = Vector2.new(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    btn.BackgroundTransparency = 0.25
    btn.Text = "P"
    btn.TextColor3 = Color3.fromRGB(140, 160, 255)
    btn.TextSize = 22
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 120, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = btn

    -- Draggable
    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local open = true
    btn.MouseButton1Click:Connect(function()
        -- If was a drag > 8px, ignore click
        open = not open
        pcall(function()
            if open then
                Window:Minimize() -- Fluent may use different API
            end
        end)
        -- Fallback: toggle ScreenGui visibility under Fluent
        pcall(function()
            for _, g in ipairs(CoreGui:GetChildren()) do
                if g:IsA("ScreenGui") and g.Name:lower():find("fluent") then
                    g.Enabled = open
                end
            end
        end)
        pcall(function()
            for _, g in ipairs(LP.PlayerGui:GetChildren()) do
                if g:IsA("ScreenGui") and (g.Name:lower():find("fluent") or g.Name:lower():find("pulsar")) then
                    if g.Name ~= "PulsarToggle" then g.Enabled = open end
                end
            end
        end)
        btn.Text = open and "P" or "+"
        btn.TextColor3 = open and Color3.fromRGB(140, 160, 255) or Color3.fromRGB(180, 180, 200)
    end)

    return sg, btn
end

local toggleGui, toggleBtn = makeToggleButton()

----------------------------------------------------------------
-- COMBAT
----------------------------------------------------------------
do
    local sec = Tabs.Combat:AddSection("Auto Combat")
    sec:AddToggle("AutoBlock", {
        Title = "Auto Block",
        Description = "Hold F when enemy is close",
        Default = false,
        Callback = function(v)
            S.AutoBlock = v
            if not v then keyUp(Enum.KeyCode.F); S.HoldingBlock = false end
        end,
    })
    sec:AddSlider("BlockDist", {
        Title = "Block Distance", Default = 10, Min = 4, Max = 25, Rounding = 0,
        Callback = function(v) S.BlockDistance = v end,
    })
    sec:AddToggle("AutoCombo", {
        Title = "Auto Combo",
        Description = "M1 spam near target",
        Default = false, Callback = function(v) S.AutoCombo = v end,
    })
    sec:AddToggle("AutoAttack", {
        Title = "Auto Attack (M1)",
        Default = false, Callback = function(v) S.AutoAttack = v end,
    })
    sec:AddToggle("AutoUltimate", {
        Title = "Auto Ultimate (G)",
        Default = false, Callback = function(v) S.AutoUltimate = v end,
    })
    sec:AddToggle("AutoDash", {
        Title = "Auto Dash (Q)",
        Default = false, Callback = function(v) S.AutoDash = v end,
    })
    sec:AddToggle("KillAura", {
        Title = "Kill Aura",
        Default = false, Callback = function(v) S.KillAura = v end,
    })
    sec:AddSlider("AuraRange", {
        Title = "Kill Aura Range", Default = 18, Min = 6, Max = 40, Rounding = 0,
        Callback = function(v) S.KillAuraRange = v end,
    })
end

----------------------------------------------------------------
-- FARM
----------------------------------------------------------------
do
    local sec = Tabs.Farm:AddSection("Kill Farm")
    sec:AddToggle("AutoFarm", {
        Title = "Auto Farm",
        Description = "Move near target + attack",
        Default = false, Callback = function(v) S.AutoFarm = v end,
    })
    sec:AddToggle("AutoKill", {
        Title = "Auto Kill",
        Description = "Same as farm, aggressive",
        Default = false, Callback = function(v) S.AutoKill = v end,
    })
    sec:AddDropdown("TargetMode", {
        Title = "Target Priority",
        Values = { "Nearest", "LowestHP" },
        Default = "Nearest",
        Callback = function(v) S.TargetMode = v end,
    })
    sec:AddSlider("FarmOffset", {
        Title = "Height Offset", Default = 2.5, Min = 0, Max = 12, Rounding = 1,
        Callback = function(v) S.FarmOffsetY = v end,
    })
    sec:AddButton({
        Title = "TP to Target",
        Callback = function()
            local t, my = getTarget(), hrp()
            if t and my and t.Character then
                local th = t.Character:FindFirstChild("HumanoidRootPart")
                if th then
                    my.CFrame = th.CFrame * CFrame.new(0, 1, 3.5)
                end
            end
        end,
    })
    sec:AddButton({
        Title = "TP to Random Player",
        Callback = function()
            local list = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP and alive(pl) then table.insert(list, pl) end
            end
            if #list > 0 then
                local t = list[math.random(1, #list)]
                local my = hrp()
                local th = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                if my and th then my.CFrame = th.CFrame * CFrame.new(0, 1, 3.5) end
            end
        end,
    })
end

----------------------------------------------------------------
-- VISUALS
----------------------------------------------------------------
do
    local sec = Tabs.Visuals:AddSection("ESP")
    sec:AddToggle("ESP", {
        Title = "Player ESP", Default = false,
        Callback = function(v)
            S.ESP = v
            if not v then
                for _, obj in pairs(S.ESP_Objs) do
                    pcall(function() obj.bill:Destroy() end)
                    pcall(function() obj.hl:Destroy() end)
                end
                S.ESP_Objs = {}
            end
        end,
    })
    sec:AddToggle("ESPName", { Title = "Show Names", Default = true, Callback = function(v) S.ESP_Name = v end })
    sec:AddToggle("ESPHealth", { Title = "Show Health", Default = true, Callback = function(v) S.ESP_Health = v end })
    sec:AddToggle("ESPDist", { Title = "Show Distance", Default = true, Callback = function(v) S.ESP_Distance = v end })

    local aim = Tabs.Visuals:AddSection("Aimbot")
    aim:AddToggle("Aimbot", {
        Title = "Aimbot", Description = "Smooth lock on head",
        Default = false, Callback = function(v) S.Aimbot = v end,
    })
    aim:AddSlider("AimFOV", {
        Title = "FOV", Default = 140, Min = 40, Max = 360, Rounding = 0,
        Callback = function(v) S.AimbotFOV = v end,
    })
    aim:AddSlider("AimSmooth", {
        Title = "Smoothness", Default = 0.2, Min = 0.05, Max = 1, Rounding = 2,
        Callback = function(v) S.AimbotSmooth = v end,
    })
end

----------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------
do
    local sec = Tabs.Movement:AddSection("Speed & Jump")
    sec:AddToggle("SpeedOn", {
        Title = "Walk Speed", Default = false,
        Callback = function(v)
            S.SpeedOn = v
            local h = hum(); if h then h.WalkSpeed = v and S.WalkSpeed or 16 end
        end,
    })
    sec:AddSlider("WalkSpeed", {
        Title = "Speed Value", Default = 16, Min = 16, Max = 120, Rounding = 0,
        Callback = function(v)
            S.WalkSpeed = v
            if S.SpeedOn then local h = hum(); if h then h.WalkSpeed = v end end
        end,
    })
    sec:AddToggle("JumpOn", {
        Title = "Jump Power", Default = false,
        Callback = function(v)
            S.JumpOn = v
            local h = hum()
            if h then h.UseJumpPower = true; h.JumpPower = v and S.JumpPower or 50 end
        end,
    })
    sec:AddSlider("JumpPower", {
        Title = "Jump Value", Default = 50, Min = 50, Max = 200, Rounding = 0,
        Callback = function(v)
            S.JumpPower = v
            if S.JumpOn then local h = hum(); if h then h.JumpPower = v end end
        end,
    })
    sec:AddToggle("InfJump", {
        Title = "Infinite Jump", Default = false,
        Callback = function(v) S.InfJump = v end,
    })

    local fly = Tabs.Movement:AddSection("Fly & Clip")
    fly:AddToggle("Fly", {
        Title = "Fly", Description = "WASD + Space/Shift (PC)",
        Default = false,
        Callback = function(v)
            S.Fly = v
            if not v then
                local r = hrp()
                if r then r.Velocity = Vector3.zero end
            end
        end,
    })
    fly:AddSlider("FlySpeed", {
        Title = "Fly Speed", Default = 45, Min = 10, Max = 150, Rounding = 0,
        Callback = function(v) S.FlySpeed = v end,
    })
    fly:AddToggle("NoClip", {
        Title = "NoClip", Default = false,
        Callback = function(v) S.NoClip = v end,
    })
end

----------------------------------------------------------------
-- MISC
----------------------------------------------------------------
do
    local sec = Tabs.Misc:AddSection("Protection")
    sec:AddToggle("AntiAFK", { Title = "Anti-AFK", Default = true, Callback = function(v) S.AntiAFK = v end })
    sec:AddToggle("AntiFling", { Title = "Anti-Fling", Default = false, Callback = function(v) S.AntiFling = v end })
    sec:AddToggle("AntiRagdoll", { Title = "Anti-Ragdoll", Default = false, Callback = function(v) S.AntiRagdoll = v end })
    sec:AddToggle("AutoEscape", {
        Title = "Auto Escape (low HP)", Default = false,
        Callback = function(v) S.AutoEscape = v end,
    })
    sec:AddSlider("EscapeHP", {
        Title = "Escape HP %", Default = 25, Min = 5, Max = 80, Rounding = 0,
        Callback = function(v) S.EscapeHP = v end,
    })

    local perf = Tabs.Misc:AddSection("Performance")
    perf:AddToggle("FPSBoost", {
        Title = "FPS Boost", Default = false,
        Callback = function(v)
            S.FPSBoost = v
            if v then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end
        end,
    })
    perf:AddToggle("Fullbright", {
        Title = "Fullbright", Default = false,
        Callback = function(v)
            S.Fullbright = v
            if v then
                Lighting.Brightness = 2; Lighting.ClockTime = 14
                Lighting.FogEnd = 1e5; Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1; Lighting.GlobalShadows = true
            end
        end,
    })

    local tp = Tabs.Misc:AddSection("Server")
    tp:AddButton({
        Title = "Rejoin Server",
        Callback = function() TeleportService:Teleport(game.PlaceId, LP) end,
    })
    tp:AddButton({
        Title = "Server Hop",
        Callback = function()
            pcall(function()
                local data = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=50"
                ))
                for _, s in ipairs(data.data or {}) do
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
-- SETTINGS
----------------------------------------------------------------
do
    local sec = Tabs.Settings:AddSection("UI")
    sec:AddParagraph({
        Title = "Pulsar Hub",
        Content = "Floating P button = open/close\nLeft Ctrl = minimize (PC)\nFluent from your GitHub",
    })
    sec:AddButton({
        Title = "Unload Hub",
        Callback = function()
            for _, c in pairs(S.Conns) do pcall(function() c:Disconnect() end) end
            pcall(function() toggleGui:Destroy() end)
            keyUp(Enum.KeyCode.F)
            pcall(function() Window:Destroy() end)
        end,
    })
    if SaveManager and InterfaceManager then
        pcall(function()
            InterfaceManager:SetLibrary(Fluent)
            SaveManager:SetLibrary(Fluent)
            InterfaceManager:SetFolder("PulsarTSB")
            SaveManager:SetFolder("PulsarTSB")
            InterfaceManager:BuildInterfaceSection(Tabs.Settings)
            SaveManager:BuildConfigSection(Tabs.Settings)
            SaveManager:LoadAutoloadConfig()
        end)
    end
end

----------------------------------------------------------------
-- LOOPS (less aggressive = less joystick break)
----------------------------------------------------------------
pcall(function()
    local vu = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if S.AntiAFK then vu:CaptureController(); vu:ClickButton2(Vector2.new()) end
    end)
end)

UserInputService.JumpRequest:Connect(function()
    if S.InfJump then
        local h = hum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Combat / movement tick — throttled
local accum = 0
table.insert(S.Conns, RunService.Heartbeat:Connect(function(dt)
    accum = accum + dt
    local myHRP, myHum = hrp(), hum()
    if not myHRP or not myHum then return end

    if S.SpeedOn then myHum.WalkSpeed = S.WalkSpeed end
    if S.JumpOn then myHum.UseJumpPower = true; myHum.JumpPower = S.JumpPower end

    if S.NoClip then
        for _, part in ipairs(char():GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if S.Fly then
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        -- Mobile fly: use move direction
        if IS_MOBILE and dir.Magnitude < 0.1 then
            local md = myHum.MoveDirection
            if md.Magnitude > 0 then dir = md end
        end
        myHRP.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * S.FlySpeed or Vector3.new(0, myHRP.AssemblyLinearVelocity.Y, 0)
    end

    if S.AntiFling and myHRP.AssemblyLinearVelocity.Magnitude > 160 then
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end
    if S.AntiRagdoll then pcall(function() myHum.PlatformStand = false end) end
    if S.AutoEscape then
        local pct = (myHum.Health / math.max(myHum.MaxHealth, 1)) * 100
        if pct <= S.EscapeHP then
            pcall(function() myHRP.CFrame = myHRP.CFrame + Vector3.new(0, 40, 0) end)
        end
    end

    -- Throttle combat to ~10Hz so mobile joystick stays alive
    if accum < 0.1 then return end
    accum = 0

    local target = getTarget()
    local tHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

    if (S.AutoFarm or S.AutoKill) and tHRP then
        local dist = (myHRP.Position - tHRP.Position).Magnitude
        if dist > 5 then
            -- Smooth approach instead of hard CFrame every frame (less rubberband / less input steal)
            local goal = tHRP.CFrame * CFrame.new(0, S.FarmOffsetY, 3.2)
            myHRP.CFrame = myHRP.CFrame:Lerp(goal, 0.35)
        end
        doM1()
    end

    if S.KillAura then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and alive(pl) then
                local th = pl.Character:FindFirstChild("HumanoidRootPart")
                if th and (myHRP.Position - th.Position).Magnitude <= S.KillAuraRange then
                    doM1()
                    break
                end
            end
        end
    end

    if S.AutoBlock and tHRP then
        local d = (myHRP.Position - tHRP.Position).Magnitude
        if d <= S.BlockDistance then
            if not S.HoldingBlock then
                keyDown(Enum.KeyCode.F)
                S.HoldingBlock = true
            end
        else
            if S.HoldingBlock then
                keyUp(Enum.KeyCode.F)
                S.HoldingBlock = false
            end
        end
    elseif S.HoldingBlock then
        keyUp(Enum.KeyCode.F)
        S.HoldingBlock = false
    end

    if S.AutoAttack and target then doM1() end
    if S.AutoCombo and tHRP then
        doM1()
        local now = tick()
        if now - S.LastDash > 1.2 then
            local d = (myHRP.Position - tHRP.Position).Magnitude
            if d > 6 and d < 28 then
                S.LastDash = now
                keyDown(Enum.KeyCode.Q); task.delay(0.05, function() keyUp(Enum.KeyCode.Q) end)
            end
        end
    end
    if S.AutoUltimate then
        local now = tick()
        if now - S.LastUlt > 8 then
            S.LastUlt = now
            keyDown(Enum.KeyCode.G); task.delay(0.05, function() keyUp(Enum.KeyCode.G) end)
        end
    end
    if S.AutoDash and tHRP then
        local now = tick()
        local d = (myHRP.Position - tHRP.Position).Magnitude
        if d > 8 and d < 35 and now - S.LastDash > 1.5 then
            S.LastDash = now
            keyDown(Enum.KeyCode.Q); task.delay(0.05, function() keyUp(Enum.KeyCode.Q) end)
        end
    end

    if S.Aimbot and target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local screen, onScreen = Cam:WorldToViewportPoint(head.Position)
            if onScreen then
                local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if dist <= S.AimbotFOV then
                    Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, head.Position), S.AimbotSmooth)
                end
            end
        end
    end
end))

table.insert(S.Conns, RunService.RenderStepped:Connect(function()
    if not S.ESP then return end
    local myHRP = hrp(); if not myHRP then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and alive(pl) then
            local c = pl.Character
            local th = c and c:FindFirstChild("HumanoidRootPart")
            local head = c and c:FindFirstChild("Head")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if th and head then
                local key = pl.Name
                if not S.ESP_Objs[key] then
                    local bill = Instance.new("BillboardGui")
                    bill.Name = "PulsarESP"; bill.Adornee = head
                    bill.Size = UDim2.new(0, 200, 0, 50)
                    bill.StudsOffset = Vector3.new(0, 2.5, 0)
                    bill.AlwaysOnTop = true; bill.Parent = head
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextStrokeTransparency = 0.4
                    label.Font = Enum.Font.GothamBold; label.TextSize = 14
                    label.Parent = bill
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.75
                    hl.OutlineColor = Color3.fromRGB(110, 130, 255)
                    hl.FillColor = Color3.fromRGB(90, 100, 220)
                    hl.Parent = c
                    S.ESP_Objs[key] = { bill = bill, label = label, hl = hl }
                end
                local pack = S.ESP_Objs[key]
                if pack and pack.label then
                    local parts = {}
                    if S.ESP_Name then table.insert(parts, pl.Name) end
                    if S.ESP_Health and h then
                        table.insert(parts, string.format("[%d/%d]", math.floor(h.Health), math.floor(h.MaxHealth)))
                    end
                    if S.ESP_Distance then
                        table.insert(parts, string.format("%dst", math.floor((myHRP.Position - th.Position).Magnitude)))
                    end
                    pack.label.Text = table.concat(parts, "  ")
                end
            end
        else
            local key = pl.Name
            if S.ESP_Objs[key] then
                pcall(function() S.ESP_Objs[key].bill:Destroy() end)
                pcall(function() S.ESP_Objs[key].hl:Destroy() end)
                S.ESP_Objs[key] = nil
            end
        end
    end
end))

Fluent:Notify({
    Title = "Pulsar Hub",
    Content = "P button (right side) opens/closes menu",
    Duration = 6,
})

print("[Pulsar] TSB Hub loaded OK")

end)

if not okAll then
    warn("[Pulsar] FATAL: " .. tostring(errAll))
    print("[Pulsar] FATAL: " .. tostring(errAll))
end
