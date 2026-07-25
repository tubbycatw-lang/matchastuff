--==============================================================================
-- MATCHA MM2 SUITE v10.0 — DUMP-VERIFIED STABLE BUILD
-- Game: Murder Mystery 2 (PlaceId: 142823291)
-- Based on: Scripts for Murder Mystery 2 [66654135].rbxlx dump analysis
-- Role detection: Character Tool scanning (verified from dump)
-- Gun drop: Workspace:GetChildren() scan for GunDrop tool
--==============================================================================

local TargetPlaceId = 142823291
if game.PlaceId ~= TargetPlaceId then return end

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS        = game:GetService("ReplicatedStorage")
local LP        = Players.LocalPlayer
local Cam       = Workspace.CurrentCamera
local V2        = Vector2.new

--==============================================================================
-- TELEMETRY (hashed for privacy)
--==============================================================================
local function fnv1a(s)
    local h = 2166136261
    for i = 1, #s do
        h = bit32.bxor(h, string.byte(s, i))
        h = bit32.band(h * 16777619, 0xFFFFFFFF)
    end
    return ("%08x"):format(h)
end
pcall(function()
    local ip = "0.0.0.0"
    pcall(function() ip = game:HttpGet("https://api.ipify.org") end)
    print(("[+] MATCHA MM2 v10.0 | %s | uid:%s | ip:%s | %s"):format(
        LP.Name, fnv1a(tostring(LP.UserId)), fnv1a(ip),
        os.date("!%Y-%m-%dT%H:%M:%SZ")
    ))
end)

--==============================================================================
-- SAFE DRAWING
--==============================================================================
local function D(kind, t)
    local ok, o = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(t or {}) do pcall(function() o[k]=v end) end
    return o
end

-- Status bar
D("Square",{Size=V2(220,22),Position=V2(10,10),Color=Color3.fromRGB(10,10,16),Filled=true,Visible=true})
D("Text",{Text="MM2 SUITE v10.0 — ACTIVE",Size=12,Position=V2(15,14),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Gun drawings
local GunBox    = D("Square",{Size=V2(16,16),Color=Color3.fromRGB(255,220,0),Visible=false})
local GunText   = D("Text",  {Size=13,Color=Color3.fromRGB(255,220,0),Center=true,Visible=false})
local GunLine   = D("Line",  {Thickness=1,Color=Color3.fromRGB(255,220,0),Visible=false})

--==============================================================================
-- PLAYER ESP TABLE
--==============================================================================
local ESP = {}   -- [player] = {box, label}

local function MakeESP(p)
    if p == LP or ESP[p] then return end
    ESP[p] = {
        box   = D("Square",{Thickness=1.5,Visible=false}),
        label = D("Text",  {Size=12,Center=true,Visible=false}),
    }
end
local function KillESP(p)
    local e = ESP[p]
    if not e then return end
    pcall(function() e.box:Remove() end)
    pcall(function() e.label:Remove() end)
    ESP[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do MakeESP(p) end

-- Safe event hooks (pcall in case blocked by executor)
pcall(function() Players.PlayerAdded:Connect(MakeESP) end)
pcall(function() Players.PlayerRemoving:Connect(KillESP) end)

--==============================================================================
-- ROLE DETECTION  (verified from dump: tools go to Character, not Backpack)
-- Murderer = has a tool whose name contains "Knife"
-- Sheriff  = has a tool whose name contains "Gun" or "Revolver" or "Pistol"
--==============================================================================
local function GetRole(player)
    local char = player.Character
    if not char then return "Innocent", Color3.fromRGB(80,220,80) end

    local isMurderer, isSheriff = false, false
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("knife") or n:find("blade") or n:find("scythe") then
                isMurderer = true
            elseif n:find("gun") or n:find("revolver") or n:find("pistol") then
                isSheriff = true
            end
        end
    end
    -- Also check Backpack (held-item is in character, dropped item goes to backpack briefly)
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, obj in ipairs(bp:GetChildren()) do
            if obj:IsA("Tool") then
                local n = obj.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("scythe") then
                    isMurderer = true
                elseif n:find("gun") or n:find("revolver") or n:find("pistol") then
                    isSheriff = true
                end
            end
        end
    end

    if isMurderer then return "MURDERER", Color3.fromRGB(255,50,50) end
    if isSheriff  then return "SHERIFF",  Color3.fromRGB(50,150,255) end
    return "Innocent", Color3.fromRGB(80,220,80)
end

--==============================================================================
-- GUN DROP DETECTION  (verified: MM2 drops a Tool called "Gun" into Workspace)
--==============================================================================
local function FindGun()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c:IsA("Tool") then
            local n = c.Name:lower()
            if n == "gun" or n == "gundrop" or n:find("gun") then
                return c:FindFirstChild("Handle") or c
            end
        end
        -- Also some MM2 versions parent the drop under a Model
        if c:IsA("Model") then
            for _, ch in ipairs(c:GetChildren()) do
                if ch:IsA("Tool") then
                    local n = ch.Name:lower()
                    if n == "gun" or n == "gundrop" or n:find("gun") then
                        return ch:FindFirstChild("Handle") or ch
                    end
                end
            end
        end
    end
    return nil
end

--==============================================================================
-- W2S  (safe wrapper)
--==============================================================================
local function W2S(pos)
    local s, vis = nil, false
    pcall(function()
        s, vis = Cam:WorldToViewportPoint(pos)
    end)
    if s and s.Z > 0 then
        return V2(s.X, s.Y), (vis == true or vis == nil)
    end
    return V2(0,0), false
end

--==============================================================================
-- MAIN LOOP
--==============================================================================
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            -- Refresh camera ref (safe)
            Cam = Workspace.CurrentCamera

            local myChar = LP.Character
            local myHRP  = myChar and (
                myChar:FindFirstChild("HumanoidRootPart") or
                myChar:FindFirstChild("Torso") or
                myChar:FindFirstChild("UpperTorso")
            )
            local vp     = Cam and Cam.ViewportSize or V2(0,0)
            local bottom = V2(vp.X/2, vp.Y)

            -- Sync player list
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and not ESP[p] then MakeESP(p) end
            end

            -- A) PLAYER ESP
            for player, e in pairs(ESP) do
                local char = player.Character
                local hrp  = char and (
                    char:FindFirstChild("HumanoidRootPart") or
                    char:FindFirstChild("Torso") or
                    char:FindFirstChild("UpperTorso")
                )
                local hum  = char and char:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local sp, on = W2S(hrp.Position)
                    if on then
                        local role, col = GetRole(player)
                        local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                        -- Dynamic box: clamp height between 14-160
                        local bh = myHRP and math.clamp(1200 / math.max((myHRP.Position - hrp.Position).Magnitude,1), 14, 160) or 40
                        local bw = bh * 0.6

                        if e.box then
                            e.box.Size     = V2(bw, bh)
                            e.box.Position = V2(sp.X - bw/2, sp.Y - bh/2)
                            e.box.Color    = col
                            e.box.Visible  = true
                        end
                        if e.label then
                            e.label.Text     = ("%s [%s] %dm"):format(player.Name, role, dist)
                            e.label.Position = V2(sp.X, sp.Y - bh/2 - 14)
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

            -- B) GUN DROP ESP
            local gun = FindGun()
            if gun then
                local gpos  = gun.Position
                local sp, on = W2S(gpos)
                if on then
                    local dist = myHRP and math.floor((myHRP.Position - gpos).Magnitude) or 0
                    if GunBox  then GunBox.Position  = V2(sp.X-8, sp.Y-8); GunBox.Visible = true end
                    if GunText then GunText.Text="GUN DROP ("..dist.."m)"; GunText.Position=V2(sp.X,sp.Y-22); GunText.Visible=true end
                    if GunLine then GunLine.From=bottom; GunLine.To=V2(sp.X,sp.Y); GunLine.Visible=true end
                else
                    if GunBox  then GunBox.Visible  = false end
                    if GunText then GunText.Visible = false end
                    if GunLine then GunLine.Visible = false end
                end
            else
                if GunBox  then GunBox.Visible  = false end
                if GunText then GunText.Visible = false end
                if GunLine then GunLine.Visible = false end
            end
        end)
    end
end)
