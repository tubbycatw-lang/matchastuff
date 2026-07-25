--==============================================================================
-- MATCHA MM2 MASTER DEVELOPER SUITE (v8.0 BULLETPROOF MATCHA BUILD)
-- Target Game: Murder Mystery 2 (Place ID: 142823291)
-- Environment: Mobile / Restricted Lua VM (Matcha Safe - No PlayerAdded / No UIS)
-- Features: Role ESP, Gun ESP + Snapline, Coin ESP, Telemetry
--==============================================================================

local TargetPlaceId = 142823291
if game.PlaceId ~= TargetPlaceId then
    warn("[Matcha Suite] Aborted: Incorrect PlaceId.")
    return
end

-- Core Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Vec2 = Vector2.new

--==============================================================================
-- 1. PRIVACY-PRESERVING TELEMETRY (Hashed Audit Log)
--==============================================================================
local function HashString(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

pcall(function()
    local rawIP = "0.0.0.0"
    pcall(function() rawIP = game:HttpGet("https://api.ipify.org") end)

    local uid = tostring(LocalPlayer and LocalPlayer.UserId or 0)
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    print("\n[+] ============= MATCHA SUITE TELEMETRY LOG ============= [+]")
    print("[+] Status     : Verified User")
    print("[+] Username   : " .. username)
    print("[+] Hashed UID : " .. HashString(uid))
    print("[+] Hashed IP  : " .. HashString(rawIP))
    print("[+] Date/Time  : " .. timestamp)
    print("[+] Engine     : Pure Lua VM / Matcha Sandbox")
    print("[+] ======================================================= [+]\n")
end)

--==============================================================================
-- 2. SAFE DRAWING WRAPPER
--==============================================================================
local function SafeCreate(drawType, props)
    local ok, obj = pcall(function() return Drawing.new(drawType) end)
    if not ok or not obj then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

-- Status Indicator Box on Top Left
local StatusBox = SafeCreate("Square", { Size = Vec2(180, 26), Position = Vec2(15, 15), Color = Color3.fromRGB(15, 15, 20), Filled = true, Visible = true })
local StatusText = SafeCreate("Text", { Text = "MATCHA MM2 SUITE: ACTIVE", Size = 13, Position = Vec2(22, 21), Color = Color3.fromRGB(0, 255, 180), Visible = true })

--==============================================================================
-- 3. GAME OBJECT DETECTORS
--==============================================================================
local function GetPlayerRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    local function HasItem(name)
        if char and char:FindFirstChild(name) then return true end
        if backpack and backpack:FindFirstChild(name) then return true end
        return false
    end

    if HasItem("Knife") then return "Murderer", Color3.fromRGB(255, 50, 50) end
    if HasItem("Gun") then return "Sheriff", Color3.fromRGB(50, 150, 255) end
    return "Innocent", Color3.fromRGB(50, 255, 50)
end

local function FindDroppedGun()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Tool") and (child.Name == "GunDrop" or child.Name == "Gun") then
            return child:FindFirstChild("Handle") or child
        elseif child.Name == "GunDrop" then
            return child:FindFirstChild("Handle") or child
        end
    end
    return nil
end

local function FindActiveCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin_Container" or obj.Name == "CoinContainer" or obj.Name == "Coin" then
            if obj:IsA("BasePart") then
                table.insert(coins, obj)
            elseif obj:IsA("Model") and obj:FindFirstChild("Coin") then
                table.insert(coins, obj.Coin)
            end
        end
    end
    return coins
end

--==============================================================================
-- 4. ESP DRAWING MANAGERS
--==============================================================================
local PlayerESPCache = {}
local GunBox = SafeCreate("Square", { Size = Vec2(18, 18), Color = Color3.fromRGB(255, 255, 0), Visible = false })
local GunLabel = SafeCreate("Text", { Size = 14, Color = Color3.fromRGB(255, 255, 0), Center = true, Visible = false })
local GunTracer = SafeCreate("Line", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 0), Visible = false })

local function BindPlayer(player)
    if not player or player == LocalPlayer or PlayerESPCache[player] then return end
    PlayerESPCache[player] = {
        Box = SafeCreate("Square", { Thickness = 1, Visible = false }),
        Label = SafeCreate("Text", { Size = 13, Center = true, Visible = false })
    }
end

-- Pre-allocate Coin Markers
local CoinDrawings = {}
for i = 1, 25 do
    CoinDrawings[i] = SafeCreate("Text", { Text = "🪙 COIN", Size = 11, Color = Color3.fromRGB(255, 215, 0), Center = true, Visible = false })
end

--==============================================================================
-- 5. MAIN RENDER ENGINE (Bulletproof Polling Loop)
--==============================================================================
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            -- Auto-bind any new players without relying on PlayerAdded event
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not PlayerESPCache[p] then
                    BindPlayer(p)
                end
            end

            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local viewportSize = Camera.ViewportSize
            local screenBottom = Vec2(viewportSize.X / 2, viewportSize.Y)

            -- A. UPDATE PLAYER ROLE ESP
            for player, cache in pairs(PlayerESPCache) do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local sPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local role, color = GetPlayerRole(player)
                        local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                        local boxH = math.clamp(1000 / sPos.Z, 12, 140)
                        local boxW = boxH * 0.65

                        if cache.Box then
                            cache.Box.Size = Vec2(boxW, boxH)
                            cache.Box.Position = Vec2(sPos.X - boxW / 2, sPos.Y - boxH / 2)
                            cache.Box.Color = color
                            cache.Box.Visible = true
                        end

                        if cache.Label then
                            cache.Label.Text = string.format("%s [%s] (%dm)", player.Name, role, dist)
                            cache.Label.Position = Vec2(sPos.X, sPos.Y - (boxH / 2) - 15)
                            cache.Label.Color = color
                            cache.Label.Visible = true
                        end
                    else
                        if cache.Box then cache.Box.Visible = false end
                        if cache.Label then cache.Label.Visible = false end
                    end
                else
                    if cache.Box then cache.Box.Visible = false end
                    if cache.Label then cache.Label.Visible = false end
                end
            end

            -- B. UPDATE DROPPED GUN ESP & TRACER
            local gunHandle = FindDroppedGun()
            if gunHandle then
                local gPos = gunHandle.Position
                local sPos, onScreen = Camera:WorldToViewportPoint(gPos)

                if onScreen then
                    local dist = myHrp and math.floor((myHrp.Position - gPos).Magnitude) or 0
                    if GunBox then
                        GunBox.Position = Vec2(sPos.X - 9, sPos.Y - 9)
                        GunBox.Visible = true
                    end
                    if GunLabel then
                        GunLabel.Text = string.format("GUN DROP (%dm)", dist)
                        GunLabel.Position = Vec2(sPos.X, sPos.Y - 24)
                        GunLabel.Visible = true
                    end
                    if GunTracer then
                        GunTracer.From = screenBottom
                        GunTracer.To = Vec2(sPos.X, sPos.Y)
                        GunTracer.Visible = true
                    end
                else
                    if GunBox then GunBox.Visible = false end
                    if GunLabel then GunLabel.Visible = false end
                    if GunTracer then GunTracer.Visible = false end
                end
            else
                if GunBox then GunBox.Visible = false end
                if GunLabel then GunLabel.Visible = false end
                if GunTracer then GunTracer.Visible = false end
            end

            -- C. UPDATE COIN ESP
            local coins = FindActiveCoins()
            for i, label in ipairs(CoinDrawings) do
                local coinPart = coins[i]
                if coinPart then
                    local sPos, onScreen = Camera:WorldToViewportPoint(coinPart.Position)
                    if onScreen then
                        local dist = myHrp and math.floor((myHrp.Position - coinPart.Position).Magnitude) or 0
                        label.Text = string.format("🪙 (%dm)", dist)
                        label.Position = Vec2(sPos.X, sPos.Y)
                        label.Visible = true
                    else
                        label.Visible = false
                    end
                else
                    label.Visible = false
                end
            end
        end)
    end
end)
