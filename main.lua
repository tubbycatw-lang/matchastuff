--==============================================================================
-- MATCHA MM2 MASTER DEVELOPER SUITE (v7.0 ALL-IN-ONE BUILD)
-- Target Game: Murder Mystery 2 (Place ID: 142823291)
-- Environment: Mobile / Lightweight Lua VM (Matcha Safe)
-- Features: Role ESP, Gun ESP + Snapline, Coin ESP, Interactive UI, Telemetry
--==============================================================================

local TargetPlaceId = 142823291
if game.PlaceId ~= TargetPlaceId then
    warn("[Matcha Suite] Aborted: Incorrect PlaceId.")
    return
end

-- Core Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Vec2 = Vector2.new

--==============================================================================
-- 1. CONFIGURATION & TOGGLE STATE
--==============================================================================
local Config = {
    RoleESP = true,
    GunESP = true,
    GunTracer = true,
    CoinESP = true,
    TelemetryLogged = false
}

--==============================================================================
-- 2. PRIVACY-PRESERVING TELEMETRY (Hashed Audit Log)
--==============================================================================
local function HashString(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

local function PerformTelemetryAudit()
    if Config.TelemetryLogged then return end
    Config.TelemetryLogged = true

    local rawIP = "0.0.0.0"
    pcall(function()
        rawIP = game:HttpGet("https://api.ipify.org")
    end)

    local uid = tostring(LocalPlayer.UserId or 0)
    local username = LocalPlayer.Name or "Unknown"
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local hashedIP = HashString(rawIP)
    local hashedUID = HashString(uid)

    print("\n[+] ============= MATCHA SUITE TELEMETRY LOG ============= [+]")
    print("[+] Status     : Verified User")
    print("[+] Username   : " .. username)
    print("[+] Hashed UID : " .. hashedUID)
    print("[+] Hashed IP  : " .. hashedIP)
    print("[+] Date/Time  : " .. timestamp)
    print("[+] Engine     : Pure Lua VM / Matcha Sandbox")
    print("[+] ======================================================= [+]\n")
end

PerformTelemetryAudit()

--==============================================================================
-- 3. SAFE DRAWING WRAPPER
--==============================================================================
local function SafeCreate(drawType, props)
    local obj = Drawing.new(drawType)
    if not obj then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

--==============================================================================
-- 4. INTERACTIVE ON-SCREEN DRAWING UI MENU
--==============================================================================
local Menu = {}
local UIButtons = {}

local MenuBg = SafeCreate("Square", {
    Size = Vec2(170, 150),
    Position = Vec2(20, 40),
    Color = Color3.fromRGB(20, 20, 25),
    Filled = true,
    Visible = true
})

local MenuHeader = SafeCreate("Text", {
    Text = "MATCHA MM2 SUITE",
    Size = 14,
    Position = Vec2(30, 45),
    Color = Color3.fromRGB(0, 255, 200),
    Visible = true
})

local function CreateToggleButton(label, yOffset, configKey)
    local btnBg = SafeCreate("Square", {
        Size = Vec2(150, 22),
        Position = Vec2(30, yOffset),
        Color = Config[configKey] and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(60, 40, 40),
        Filled = true,
        Visible = true
    })

    local btnText = SafeCreate("Text", {
        Text = label .. ": " .. (Config[configKey] and "ON" or "OFF"),
        Size = 12,
        Position = Vec2(35, yOffset + 4),
        Color = Color3.fromRGB(255, 255, 255),
        Visible = true
    })

    table.insert(UIButtons, {
        Bg = btnBg,
        Text = btnText,
        Key = configKey,
        Label = label,
        Min = Vec2(30, yOffset),
        Max = Vec2(180, yOffset + 22)
    })
end

CreateToggleButton("Role ESP", 68, "RoleESP")
CreateToggleButton("Gun ESP", 94, "GunESP")
CreateToggleButton("Coin ESP", 120, "CoinESP")

-- Touch / Click Handler for Mobile UI Toggles
local function HandleClick(pos)
    for _, btn in ipairs(UIButtons) do
        if pos.X >= btn.Min.X and pos.X <= btn.Max.X and pos.Y >= btn.Min.Y and pos.Y <= btn.Max.Y then
            Config[btn.Key] = not Config[btn.Key]
            pcall(function()
                btn.Bg.Color = Config[btn.Key] and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(60, 40, 40)
                btn.Text.Text = btn.Label .. ": " .. (Config[btn.Key] and "ON" or "OFF")
            end)
            break
        end
    end
end

pcall(function()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            HandleClick(input.Position)
        end
    end)
end)

--==============================================================================
-- 5. GAME OBJECT DETECTORS (Extracted from MM2 Dump)
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
    -- MM2 Spawns coins in Map container or Workspace
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
-- 6. ESP DRAWING MANAGERS
--==============================================================================
local PlayerESPCache = {}
local GunBox = SafeCreate("Square", { Size = Vec2(18, 18), Color = Color3.fromRGB(255, 255, 0), Visible = false })
local GunLabel = SafeCreate("Text", { Size = 14, Color = Color3.fromRGB(255, 255, 0), Center = true, Visible = false })
local GunTracer = SafeCreate("Line", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 0), Visible = false })

local function BindPlayer(player)
    if player == LocalPlayer then return end
    PlayerESPCache[player] = {
        Box = SafeCreate("Square", { Thickness = 1, Visible = false }),
        Label = SafeCreate("Text", { Size = 13, Center = true, Visible = false })
    }
end

local function UnbindPlayer(player)
    if PlayerESPCache[player] then
        pcall(function() PlayerESPCache[player].Box:Remove() end)
        pcall(function() PlayerESPCache[player].Label:Remove() end)
        PlayerESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do BindPlayer(p) end
Players.PlayerAdded:Connect(BindPlayer)
Players.PlayerRemoving:Connect(UnbindPlayer)

-- Coin Drawing Cache
local CoinDrawings = {}
for i = 1, 20 do
    CoinDrawings[i] = SafeCreate("Text", { Text = "🪙 COIN", Size = 11, Color = Color3.fromRGB(255, 215, 0), Center = true, Visible = false })
end

--==============================================================================
-- 7. MAIN RENDER LOOP (Matcha-Safe Polling Engine)
--==============================================================================
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local viewportSize = Camera.ViewportSize
            local screenBottom = Vec2(viewportSize.X / 2, viewportSize.Y)

            -- A. UPDATE PLAYER ROLE ESP
            for player, cache in pairs(PlayerESPCache) do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")

                if Config.RoleESP and hrp and hum and hum.Health > 0 then
                    local sPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local role, color = GetPlayerRole(player)
                        local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                        local boxH = math.clamp(1000 / sPos.Z, 12, 140)
                        local boxW = boxH * 0.65

                        cache.Box.Size = Vec2(boxW, boxH)
                        cache.Box.Position = Vec2(sPos.X - boxW / 2, sPos.Y - boxH / 2)
                        cache.Box.Color = color
                        cache.Box.Visible = true

                        cache.Label.Text = string.format("%s [%s] (%dm)", player.Name, role, dist)
                        cache.Label.Position = Vec2(sPos.X, sPos.Y - (boxH / 2) - 15)
                        cache.Label.Color = color
                        cache.Label.Visible = true
                    else
                        cache.Box.Visible = false
                        cache.Label.Visible = false
                    end
                else
                    cache.Box.Visible = false
                    cache.Label.Visible = false
                end
            end

            -- B. UPDATE DROPPED GUN ESP & TRACER
            local gunHandle = FindDroppedGun()
            if Config.GunESP and gunHandle then
                local gPos = gunHandle.Position
                local sPos, onScreen = Camera:WorldToViewportPoint(gPos)

                if onScreen then
                    local dist = myHrp and math.floor((myHrp.Position - gPos).Magnitude) or 0
                    GunBox.Position = Vec2(sPos.X - 9, sPos.Y - 9)
                    GunBox.Visible = true

                    GunLabel.Text = string.format("GUN DROP (%dm)", dist)
                    GunLabel.Position = Vec2(sPos.X, sPos.Y - 24)
                    GunLabel.Visible = true

                    GunTracer.From = screenBottom
                    GunTracer.To = Vec2(sPos.X, sPos.Y)
                    GunTracer.Visible = true
                else
                    GunBox.Visible = false
                    GunLabel.Visible = false
                    GunTracer.Visible = false
                end
            else
                GunBox.Visible = false
                GunLabel.Visible = false
                GunTracer.Visible = false
            end

            -- C. UPDATE COIN ESP
            if Config.CoinESP then
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
            else
                for _, label in ipairs(CoinDrawings) do label.Visible = false end
            end
        end)
    end
end)
