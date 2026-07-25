--==============================================================================
-- MATCHA MM2 MASTER DEVELOPER SUITE (v9.0 DIAGNOSTIC & STABLE BUILD)
-- Target Game: Murder Mystery 2 (Place ID: 142823291)
-- Environment: Mobile / Restricted Lua VM (Matcha Safe)
--==============================================================================

local TargetPlaceId = 142823291
if game.PlaceId ~= TargetPlaceId then
    warn("[Matcha Suite] Aborted: Incorrect PlaceId.")
    return
end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Vec2 = Vector2.new

--==============================================================================
-- 1. TELEMETRY & AUDIT LOG
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

    print("[+] MATCHA SUITE v9.0 ACTIVE | User: " .. username .. " | UID: " .. HashString(uid) .. " | IP: " .. HashString(rawIP))
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

-- Top-Left HUD Status Bar
local StatusBox = SafeCreate("Square", { Size = Vec2(260, 45), Position = Vec2(15, 15), Color = Color3.fromRGB(15, 15, 22), Filled = true, Visible = true })
local StatusHeader = SafeCreate("Text", { Text = "MATCHA MM2 SUITE v9.0", Size = 13, Position = Vec2(22, 19), Color = Color3.fromRGB(0, 255, 180), Visible = true })
local StatusStats = SafeCreate("Text", { Text = "Players: 0 | Gun: None | Coins: 0", Size = 11, Position = Vec2(22, 38), Color = Color3.fromRGB(200, 200, 200), Visible = true })

--==============================================================================
-- 3. WORLD TO SCREEN PROJECTION (Dynamic Camera Safe)
--==============================================================================
local function WorldToScreen(worldPos)
    local cam = Workspace.CurrentCamera
    if not cam then return Vec2(0,0), false end

    local sPos, onScreen = nil, false
    local ok = pcall(function()
        sPos, onScreen = cam:WorldToViewportPoint(worldPos)
    end)

    if ok and sPos then
        -- Depth check for extra safety
        local visible = (onScreen == true or onScreen == nil) and (sPos.Z > 0)
        return Vec2(sPos.X, sPos.Y), visible
    end
    return Vec2(0,0), false
end

--==============================================================================
-- 4. OBJECT DETECTORS
--==============================================================================
local function GetPlayerRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    local function HasTool(pattern)
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and (item.Name:find(pattern) or item.Name == pattern) then return true end
            end
        end
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and (item.Name:find(pattern) or item.Name == pattern) then return true end
            end
        end
        return false
    end

    if HasTool("Knife") or HasTool("Blade") or HasTool("Scythe") then
        return "Murderer", Color3.fromRGB(255, 50, 50)
    elseif HasTool("Gun") or HasTool("Revolver") or HasTool("Pistol") then
        return "Sheriff", Color3.fromRGB(50, 150, 255)
    end
    return "Innocent", Color3.fromRGB(50, 255, 50)
end

local function FindDroppedGun()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Tool") and (child.Name == "GunDrop" or child.Name == "Gun" or child.Name:find("Gun")) then
            return child:FindFirstChild("Handle") or child
        elseif child.Name == "GunDrop" or child.Name == "Gun" then
            return child:FindFirstChild("Handle") or child
        end
    end
    -- Check subfolders in Workspace (e.g. Map/Normal)
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child.Name == "GunDrop" or (child:IsA("Tool") and child.Name == "GunDrop") then
            return child:IsA("BasePart") and child or (child:FindFirstChild("Handle") or child)
        end
    end
    return nil
end

local function FindActiveCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "Coin_Container" or obj.Name == "CoinContainer" or obj.Name == "Coin" or obj.Name == "MainCoin") and obj:IsA("BasePart") then
            table.insert(coins, obj)
        end
    end
    return coins
end

--==============================================================================
-- 5. ESP CACHES
--==============================================================================
local PlayerESPCache = {}
local GunBox = SafeCreate("Square", { Size = Vec2(18, 18), Color = Color3.fromRGB(255, 255, 0), Visible = false })
local GunLabel = SafeCreate("Text", { Size = 14, Color = Color3.fromRGB(255, 255, 0), Center = true, Visible = false })
local GunTracer = SafeCreate("Line", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 0), Visible = false })

local function BindPlayer(player)
    if not player or player == LocalPlayer or PlayerESPCache[player] then return end
    PlayerESPCache[player] = {
        Box = SafeCreate("Square", { Thickness = 1.5, Visible = false }),
        Label = SafeCreate("Text", { Size = 13, Center = true, Visible = false })
    }
end

local CoinDrawings = {}
for i = 1, 30 do
    CoinDrawings[i] = SafeCreate("Text", { Text = "🪙 COIN", Size = 11, Color = Color3.fromRGB(255, 215, 0), Center = true, Visible = false })
end

--==============================================================================
-- 6. MAIN RENDER ENGINE
--==============================================================================
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end

            -- Auto-bind active players
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not PlayerESPCache[p] then
                    BindPlayer(p)
                end
            end

            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local viewportSize = cam.ViewportSize
            local screenBottom = Vec2(viewportSize.X / 2, viewportSize.Y)

            local activePlayersCount = 0

            -- A. UPDATE PLAYER ROLE ESP
            for player, cache in pairs(PlayerESPCache) do
                local char = player.Character
                local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
                local hum = char and char:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local sPos, onScreen = WorldToScreen(hrp.Position)
                    if onScreen then
                        activePlayersCount = activePlayersCount + 1
                        local role, color = GetPlayerRole(player)
                        local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                        local boxH = math.clamp(1200 / (myHrp and (myHrp.Position - hrp.Position).Magnitude or 50), 15, 160)
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

            -- B. UPDATE DROPPED GUN ESP
            local gunHandle = FindDroppedGun()
            local gunStatus = "None"
            if gunHandle then
                gunStatus = "Found"
                local gPos = gunHandle.Position
                local sPos, onScreen = WorldToScreen(gPos)

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
            local activeCoinsCount = #coins
            for i, label in ipairs(CoinDrawings) do
                local coinPart = coins[i]
                if coinPart then
                    local sPos, onScreen = WorldToScreen(coinPart.Position)
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

            -- D. UPDATE TOP HUD DIAGNOSTIC COUNTERS
            if StatusStats then
                StatusStats.Text = string.format("Players: %d | Gun: %s | Coins: %d", activePlayersCount, gunStatus, activeCoinsCount)
            end
        end)
    end
end)
