--[[
  PULSAR HUB — The Strongest Battlegrounds
  Fluent UI hosted on YOUR repo (full control)
  Toggle: Left Ctrl
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

local VirtualInput
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera

----------------------------------------------------------------
-- YOUR REPO — change only if you rename the repo/user
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
    if not src then
        error("HttpGet failed for " .. path .. ": " .. tostring(err))
    end
    local fn, err2 = loadstring(src)
    if type(fn) ~= "function" then
        error("loadstring failed for " .. path .. ": " .. tostring(err2 or fn))
    end
    return fn()
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local S = {
    AutoFarm=false, AutoKill=false, AutoBlock=false, AutoCombo=false,
    AutoAttack=false, AutoUltimate=false, AutoDash=false, KillAura=false,
    KillAuraRange=20, TargetMode="Nearest", FarmOffsetY=3, BlockDistance=12,
    ESP=false, ESP_Name=true, ESP_Health=true, ESP_Distance=true,
    Aimbot=false, AimbotFOV=120, AimbotSmooth=0.25,
    WalkSpeed=16, JumpPower=50, SpeedOn=false, JumpOn=false,
    InfJump=false, Fly=false, FlySpeed=50, NoClip=false,
    AntiAFK=true, AntiFling=false, AntiRagdoll=false,
    AutoEscape=false, EscapeHP=25, FPSBoost=false, Fullbright=false,
    Conns={}, ESP_Objs={},
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

local function doM1()
    if not VirtualInput then return end
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.04)
        VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
end

local function doKey(key, down)
    if not VirtualInput then return end
    pcall(function() VirtualInput:SendKeyEvent(down, key, false, game) end)
end

----------------------------------------------------------------
-- LOAD FLUENT FROM YOUR REPO
----------------------------------------------------------------
local Fluent = loadFromRepo("FluentLib.lua")
print("[Pulsar] Fluent loaded from your repo")

local SaveManager, InterfaceManager
pcall(function() SaveManager = loadFromRepo("SaveManager.lua") end)
pcall(function() InterfaceManager = loadFromRepo("InterfaceManager.lua") end)

----------------------------------------------------------------
-- WINDOW (edit Title / Theme / Size here freely)
----------------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title       = "Pulsar Hub",
    SubTitle    = "The Strongest Battlegrounds",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(560, 420),
    Acrylic     = true,
    Theme       = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "swords" }),
    Farm     = Window:AddTab({ Title = "Farm",     Icon = "crosshair" }),
    Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "person-standing" }),
    Misc     = Window:AddTab({ Title = "Misc",     Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "wrench" }),
}

----------------------------------------------------------------
-- COMBAT
----------------------------------------------------------------
do
    local sec = Tabs.Combat:AddSection("Auto Combat")
    sec:AddToggle("AutoBlock", {
        Title = "Auto Block", Description = "Blocks when enemy is close",
        Default = false, Callback = function(v) S.AutoBlock = v end,
    })
    sec:AddSlider("BlockDist", {
        Title = "Block Distance", Default = 12, Min = 4, Max = 30, Rounding = 0,
        Callback = function(v) S.BlockDistance = v end,
    })
    sec:AddToggle("AutoCombo", {
        Title = "Auto Combo", Description = "M1 + dash chain",
        Default = false, Callback = function(v) S.AutoCombo = v end,
    })
    sec:AddToggle("AutoAttack", {
        Title = "Auto Attack (M1)", Default = false,
        Callback = function(v) S.AutoAttack = v end,
    })
    sec:AddToggle("AutoUltimate", {
        Title = "Auto Ultimate (G)", Default = false,
        Callback = function(v) S.AutoUltimate = v end,
    })
    sec:AddToggle("AutoDash", {
        Title = "Auto Dash (Q)", Default = false,
        Callback = function(v) S.AutoDash = v end,
    })
    sec:AddToggle("KillAura", {
        Title = "Kill Aura", Default = false,
        Callback = function(v) S.KillAura = v end,
    })
    sec:AddSlider("AuraRange", {
        Title = "Kill Aura Range", Default = 20, Min = 5, Max = 50, Rounding = 0,
        Callback = function(v) S.KillAuraRange = v end,
    })
end

----------------------------------------------------------------
-- FARM
----------------------------------------------------------------
do
    local sec = Tabs.Farm:AddSection("Kill Farm")
    sec:AddToggle("AutoFarm", {
        Title = "Auto Farm", Description = "TP + attack target",
        Default = false, Callback = function(v) S.AutoFarm = v end,
    })
    sec:AddToggle("AutoKill", {
        Title = "Auto Kill", Default = false,
        Callback = function(v) S.AutoKill = v end,
    })
    sec:AddDropdown("TargetMode", {
        Title = "Target Priority",
        Values = { "Nearest", "LowestHP" },
        Default = "Nearest",
        Callback = function(v) S.TargetMode = v end,
    })
    sec:AddSlider("FarmOffset", {
        Title = "Farm Height Offset", Default = 3, Min = 0, Max = 15, Rounding = 1,
        Callback = function(v) S.FarmOffsetY = v end,
    })
    sec:AddButton({
        Title = "TP to Target",
        Callback = function()
            local t, my = getTarget(), hrp()
            if t and my and t.Character then
                local th = t.Character:FindFirstChild("HumanoidRootPart")
                if th then my.CFrame = th.CFrame * CFrame.new(0, 0, 3) end
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
                if my and th then my.CFrame = th.CFrame * CFrame.new(0, 0, 3) end
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
        Title = "FOV", Default = 120, Min = 30, Max = 360, Rounding = 0,
        Callback = function(v) S.AimbotFOV = v end,
    })
    aim:AddSlider("AimSmooth", {
        Title = "Smoothness", Default = 0.25, Min = 0.05, Max = 1, Rounding = 2,
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
        Title = "Speed Value", Default = 16, Min = 16, Max = 200, Rounding = 0,
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
        Title = "Jump Value", Default = 50, Min = 50, Max = 300, Rounding = 0,
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
        Title = "Fly", Description = "WASD + Space/Shift",
        Default = false, Callback = function(v) S.Fly = v end,
    })
    fly:AddSlider("FlySpeed", {
        Title = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0,
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
        Content = "Fluent is loaded from YOUR GitHub repo.\nEdit FluentLib.lua to restyle the UI.\nLeft Ctrl = minimize",
    })
    sec:AddButton({
        Title = "Unload Hub",
        Callback = function()
            for _, c in pairs(S.Conns) do pcall(function() c:Disconnect() end) end
            Window:Destroy()
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
-- LOOPS
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

table.insert(S.Conns, RunService.Heartbeat:Connect(function()
    local myHRP, myHum = hrp(), hum()
    if not myHRP or not myHum then return end

    if S.SpeedOn then myHum.WalkSpeed = S.WalkSpeed end
    if S.JumpOn then myHum.UseJumpPower = true; myHum.JumpPower = S.JumpPower end

    if S.NoClip then
        for _, part in ipairs(char():GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
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
        myHRP.Velocity = dir.Magnitude > 0 and dir.Unit * S.FlySpeed or Vector3.zero
    end

    if S.AntiFling and myHRP.AssemblyLinearVelocity.Magnitude > 150 then
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end
    if S.AntiRagdoll then pcall(function() myHum.PlatformStand = false end) end
    if S.AutoEscape then
        local pct = (myHum.Health / myHum.MaxHealth) * 100
        if pct <= S.EscapeHP then pcall(function() myHRP.CFrame = CFrame.new(0, 50, 0) end) end
    end

    local target = getTarget()

    if (S.AutoFarm or S.AutoKill) and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th then
            myHRP.CFrame = th.CFrame * CFrame.new(0, S.FarmOffsetY, 3)
            doM1()
        end
    end

    if S.KillAura then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and alive(pl) then
                local th = pl.Character:FindFirstChild("HumanoidRootPart")
                if th and (myHRP.Position - th.Position).Magnitude <= S.KillAuraRange then
                    doM1()
                end
            end
        end
    end

    if S.AutoBlock and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th and (myHRP.Position - th.Position).Magnitude <= S.BlockDistance then
            doKey(Enum.KeyCode.F, true)
        else
            doKey(Enum.KeyCode.F, false)
        end
    end

    if S.AutoAttack and target then doM1() end
    if S.AutoCombo and target then
        doM1()
        if math.random() < 0.08 then
            doKey(Enum.KeyCode.Q, true); task.wait(0.04); doKey(Enum.KeyCode.Q, false)
        end
    end
    if S.AutoUltimate and math.random() < 0.02 then
        doKey(Enum.KeyCode.G, true); task.wait(0.04); doKey(Enum.KeyCode.G, false)
    end
    if S.AutoDash and target and target.Character then
        local th = target.Character:FindFirstChild("HumanoidRootPart")
        if th then
            local d = (myHRP.Position - th.Position).Magnitude
            if d > 8 and d < 40 and math.random() < 0.05 then
                doKey(Enum.KeyCode.Q, true); task.wait(0.04); doKey(Enum.KeyCode.Q, false)
            end
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
                    hl.FillTransparency = 0.7
                    hl.OutlineColor = Color3.fromRGB(100, 80, 255)
                    hl.FillColor = Color3.fromRGB(100, 80, 255)
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
    Content = "Loaded from YOUR repo\nLeft Ctrl to toggle",
    Duration = 5,
})

print("[Pulsar] TSB Hub loaded — Fluent from your repo")

end)

if not okAll then
    warn("[Pulsar] FATAL: " .. tostring(errAll))
    print("[Pulsar] FATAL: " .. tostring(errAll))
end
