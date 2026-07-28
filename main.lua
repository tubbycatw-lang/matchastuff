--==============================================================================
-- MATCHA MM2 SUITE v13.0 — INTEGRATED ANTI-FLING & DOT-PRODUCT W2S
-- Includes:
--   1. Clean Anti-Fling (Disables player collision & suppresses fling physics)
--   2. MM2 Role ESP & Gun Drop Tracer
--   3. Matcha-safe W2S Math & Status Header
--==============================================================================

local TargetPlaceId = 142823291
if game.PlaceId ~= TargetPlaceId then return end

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer
local Cam       = Workspace.CurrentCamera

-- Telemetry
local function fnv1a(s)
    local h = 2166136261
    for i = 1, #s do h = bit32.band(bit32.bxor(h,string.byte(s,i))*16777619,0xFFFFFFFF) end
    return ("%08x"):format(h)
end
pcall(function()
    local ip = "0.0.0.0"
    pcall(function() ip = game:HttpGet("https://api.ipify.org") end)
    print(("[+] MM2 v13.0 | %s | uid:%s | ip:%s | %s"):format(
        LP.Name, fnv1a(tostring(LP.UserId)), fnv1a(ip),
        os.date("!%Y-%m-%dT%H:%M:%SZ")))
end)

--==============================================================================
-- W2S using pure Vector3:Dot() — no blocked Instance methods
--==============================================================================
local function W2S(worldPos)
    local cf  = Cam.CFrame
    local fov = Cam.FieldOfView
    local vp  = Cam.ViewportSize

    local delta = worldPos - cf.Position

    local depth = delta:Dot(cf.LookVector)
    if depth <= 0 then return Vector2.new(0, 0), false end

    local relX  = delta:Dot(cf.RightVector)
    local relY  = delta:Dot(cf.UpVector)

    local aspect = vp.X / vp.Y
    local htfov  = math.tan(math.rad(fov * 0.5))

    local ndcX = relX / (depth * htfov * aspect)
    local ndcY = relY / (depth * htfov)

    local sx = (ndcX + 1) * 0.5 * vp.X
    local sy = (1 - ndcY) * 0.5 * vp.Y

    local onScr = sx >= -50 and sx <= vp.X + 50 and sy >= -50 and sy <= vp.Y + 50
    return Vector2.new(sx, sy), onScr
end

--==============================================================================
-- DRAWING HELPER
--==============================================================================
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

-- Clean Minimal Header Status
D("Square",{Size=Vector2.new(240,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(8,8,14),Filled=true,Visible=true})
D("Text",{Text="MM2 SUITE v13.0 | ANTI-FLING ON",Size=12,Position=Vector2.new(13,11),Color=Color3.fromRGB(0,255,180),Visible=true})

local GunBox  = D("Square",{Size=Vector2.new(16,16),Color=Color3.fromRGB(255,220,0),Thickness=2,Visible=false})
local GunLbl  = D("Text",{Size=13,Color=Color3.fromRGB(255,220,0),Center=true,Outline=true,Visible=false})
local GunLine = D("Line",{Thickness=1.5,Color=Color3.fromRGB(255,220,0),Visible=false})

--==============================================================================
-- ANTI-FLING LOGIC (Clean & Lightweight, no ugly GUI)
--==============================================================================
local function ProcessAntiFling()
    pcall(function()
        local myChar = LP.Character
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name ~= LP.Name and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        -- Clamp fling angular/linear velocities
                        pcall(function()
                            if part.AssemblyAngularVelocity.Magnitude > 30 then
                                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            end
                            if part.AssemblyLinearVelocity.Magnitude > 150 then
                                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            end
                        end)
                    end
                end
            end
        end
    end)
end

--==============================================================================
-- ESP TABLE
--==============================================================================
local ESP = {}

local function MakeESP(p)
    if p.Name == LP.Name then return end
    if ESP[p] then return end
    ESP[p] = {
        box   = D("Square", {Thickness = 1.5, Visible = false}),
        label = D("Text",   {Size = 12, Center = true, Outline = true, Visible = false}),
    }
end
local function KillESP(p)
    local e = ESP[p]; if not e then return end
    pcall(function() e.box:Remove() end)
    pcall(function() e.label:Remove() end)
    ESP[p] = nil
end

for _,p in ipairs(Players:GetPlayers()) do MakeESP(p) end
pcall(function() Players.PlayerAdded:Connect(MakeESP) end)
pcall(function() Players.PlayerRemoving:Connect(KillESP) end)

--==============================================================================
-- ROLE DETECTION
--==============================================================================
local function GetRole(player)
    local char = player.Character
    local bp   = player:FindFirstChild("Backpack")
    if char then
        if char:FindFirstChild("Knife") then return "MURDERER", Color3.fromRGB(255,50,50) end
        if char:FindFirstChild("Gun")   then return "SHERIFF",  Color3.fromRGB(80,160,255) end
    end
    if bp then
        if bp:FindFirstChild("Knife") then return "MURDERER", Color3.fromRGB(255,50,50) end
        if bp:FindFirstChild("Gun")   then return "SHERIFF",  Color3.fromRGB(80,160,255) end
    end
    return "Innocent", Color3.fromRGB(80,220,80)
end

--==============================================================================
-- GUN DROP
--==============================================================================
local function FindDroppedGun()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c.Name == "Gun" and c.ClassName == "Tool" then
            return c:FindFirstChild("Handle") or c
        end
    end
    return nil
end

--==============================================================================
-- MAIN LOOP
--==============================================================================
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            Cam = Workspace.CurrentCamera

            -- Run Anti-Fling continuously
            ProcessAntiFling()

            local myChar = LP.Character
            local myHRP  = myChar and (
                myChar:FindFirstChild("HumanoidRootPart") or
                myChar:FindFirstChild("UpperTorso") or
                myChar:FindFirstChild("Torso")
            )
            local vp     = Cam.ViewportSize
            local bottom = Vector2.new(vp.X / 2, vp.Y)

            -- Sync player list
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Name ~= LP.Name and not ESP[p] then MakeESP(p) end
            end

            -- PLAYER ESP
            for player, e in pairs(ESP) do
                local char = player.Character
                local hrp  = char and (
                    char:FindFirstChild("HumanoidRootPart") or
                    char:FindFirstChild("UpperTorso") or
                    char:FindFirstChild("Torso")
                )
                local hum   = char and char:FindFirstChild("Humanoid")
                local alive = hum and hum.Health and hum.Health > 0

                if hrp and alive then
                    local sp, onScr = W2S(hrp.Position)

                    if onScr then
                        local role, col = GetRole(player)
                        local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                        local bh = math.clamp(1200 / math.max(dist, 1), 16, 160)
                        local bw = bh * 0.55

                        if e.box then
                            e.box.Size     = Vector2.new(bw, bh)
                            e.box.Position = Vector2.new(sp.X - bw/2, sp.Y - bh/2)
                            e.box.Color    = col
                            e.box.Visible  = true
                        end
                        if e.label then
                            e.label.Text     = player.Name .. " [" .. role .. "] " .. dist .. "m"
                            e.label.Position = Vector2.new(sp.X, sp.Y - bh/2 - 15)
                            e.label.Color    = col
                            e.label.Visible  = true
                        end
                    else
                        if e.box   then e.box.Visible   = false end
                        if e.label then e.label.Visible = false end
                    end
                else
                    if e.box   then e.box.Visible   = false end
                    if e.label then e.label.Visible = false end
                end
            end

            -- GUN DROP ESP
            local gun = FindDroppedGun()
            if gun then
                local sp, onScr = W2S(gun.Position)
                if onScr then
                    local dist = myHRP and math.floor((myHRP.Position - gun.Position).Magnitude) or 0
                    if GunBox  then GunBox.Position=Vector2.new(sp.X-8,sp.Y-8); GunBox.Visible=true end
                    if GunLbl  then GunLbl.Text="GUN DROP ("..dist.."m)"; GunLbl.Position=Vector2.new(sp.X,sp.Y-24); GunLbl.Visible=true end
                    if GunLine then GunLine.From=bottom; GunLine.To=Vector2.new(sp.X,sp.Y); GunLine.Visible=true end
                else
                    if GunBox  then GunBox.Visible=false end
                    if GunLbl  then GunLbl.Visible=false end
                    if GunLine then GunLine.Visible=false end
                end
            else
                if GunBox  then GunBox.Visible=false end
                if GunLbl  then GunLbl.Visible=false end
                if GunLine then GunLine.Visible=false end
            end
        end)
    end
end)
