--==============================================================================
-- GAKURAN HUB (AUTO PARRY & PIANO MUSIC) - FAST & LIGHTWEIGHT PURE GUI
-- Built for Matcha Executor
--==============================================================================

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService")
}

local LP = Services.Players.LocalPlayer
local CombatRemote = Services.ReplicatedStorage:FindFirstChild("Shared") 
    and Services.ReplicatedStorage.Shared:FindFirstChild("Network") 
    and Services.ReplicatedStorage.Shared.Network:FindFirstChild("CombatClientRemoteEvent")

local PianoRemote = Services.ReplicatedStorage:FindFirstChild("Remotes") 
    and Services.ReplicatedStorage.Remotes:FindFirstChild("InstrumentPiano")

-- Settings State
local Flags = {
    AutoParry = false,
    ParryDistance = 15,
    AutoMusic = false,
    MusicSpeed = 0.1,
    SongChoice = "Megalovania"
}

-- Built-in Songs
local Songs = {
    ["Megalovania"] = "d d D a g f d f g c c D a g f d f g b b D a g f d f g",
    ["Fur Elise"] = "e D e D e b d c a c e a b e g a b e D e D e b d c a",
    ["Rush B"] = "a a a f c a f c a e e e f c g f c a"
}

--==============================================================================
-- AUTO PARRY ENGINE
--==============================================================================
local parryCooldown = false

local function performParry()
    if parryCooldown then return end
    parryCooldown = true

    pcall(function()
        if CombatRemote then
            CombatRemote:FireServer("Parry")
            CombatRemote:FireServer("Block", true)
            task.wait(0.25)
            CombatRemote:FireServer("Block", false)
        end
    end)

    task.delay(0.35, function()
        parryCooldown = false
    end)
end

Services.RunService.Heartbeat:Connect(function()
    if not Flags.AutoParry then return end
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

    local myPos = myChar.HumanoidRootPart.Position

    for _, enemy in pairs(Services.Players:GetPlayers()) do
        if enemy ~= LP and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local enemyHrp = enemy.Character.HumanoidRootPart
            local dist = (enemyHrp.Position - myPos).Magnitude

            if dist <= Flags.ParryDistance then
                local enemyHum = enemy.Character:FindFirstChildOfClass("Humanoid")
                if enemyHum then
                    local animator = enemyHum:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            local animName = track.Animation and track.Animation.Name:lower() or ""
                            if animName:find("m1") or animName:find("m2") or animName:find("attack") or animName:find("hit") or animName:find("punch") or animName:find("swing") then
                                performParry()
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

--==============================================================================
-- PIANO AUTO MUSIC PLAYER ENGINE
--==============================================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.AutoMusic and PianoRemote then
            local songNotes = Songs[Flags.SongChoice]
            if songNotes then
                for note in songNotes:gmatch("%S+") do
                    if not Flags.AutoMusic then break end
                    pcall(function()
                        PianoRemote:FireServer("PlayKey", note)
                    end)
                    task.wait(Flags.MusicSpeed)
                end
            end
        end
    end
end)

--==============================================================================
-- PURE STANDALONE DARK THEME GUI (NO EXTERNAL LIBRARIES)
--==============================================================================
if game:GetService("CoreGui"):FindFirstChild("GakuranSuiteGui") then
    game:GetService("CoreGui").GakuranSuiteGui:Destroy()
end

local screen = Instance.new("ScreenGui")
screen.Name = "GakuranSuiteGui"
screen.ResetOnSpawn = false
screen.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 240)
main.Position = UDim2.new(0.05, 0, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 38)
header.Text = "  GAKURAN HUB  |  MATCHA"
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.TextColor3 = Color3.fromRGB(240, 240, 255)
header.TextXAlignment = Enum.TextXAlignment.Left
header.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

-- 1. Auto Parry Toggle
local btnParry = Instance.new("TextButton")
btnParry.Size = UDim2.new(0.9, 0, 0, 42)
btnParry.Position = UDim2.new(0.05, 0, 0.22, 0)
btnParry.Text = "AUTO PARRY: OFF"
btnParry.Font = Enum.Font.GothamBold
btnParry.TextSize = 13
btnParry.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
btnParry.TextColor3 = Color3.fromRGB(255, 255, 255)
btnParry.Parent = main

local btnCorner1 = Instance.new("UICorner")
btnCorner1.CornerRadius = UDim.new(0, 6)
btnCorner1.Parent = btnParry

btnParry.MouseButton1Click:Connect(function()
    Flags.AutoParry = not Flags.AutoParry
    btnParry.Text = "AUTO PARRY: " .. (Flags.AutoParry and "ON" or "OFF")
    btnParry.BackgroundColor3 = Flags.AutoParry and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(180, 50, 60)
end)

-- 2. Auto Music Toggle
local btnMusic = Instance.new("TextButton")
btnMusic.Size = UDim2.new(0.9, 0, 0, 42)
btnMusic.Position = UDim2.new(0.05, 0, 0.44, 0)
btnMusic.Text = "AUTO PIANO MUSIC: OFF"
btnMusic.Font = Enum.Font.GothamBold
btnMusic.TextSize = 13
btnMusic.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
btnMusic.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMusic.Parent = main

local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 6)
btnCorner2.Parent = btnMusic

btnMusic.MouseButton1Click:Connect(function()
    Flags.AutoMusic = not Flags.AutoMusic
    btnMusic.Text = "AUTO PIANO MUSIC: " .. (Flags.AutoMusic and "ON" or "OFF")
    btnMusic.BackgroundColor3 = Flags.AutoMusic and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(180, 50, 60)
end)

-- 3. Manual Test Parry Button
local btnTest = Instance.new("TextButton")
btnTest.Size = UDim2.new(0.9, 0, 0, 36)
btnTest.Position = UDim2.new(0.05, 0, 0.66, 0)
btnTest.Text = "MANUAL TEST PARRY"
btnTest.Font = Enum.Font.GothamMedium
btnTest.TextSize = 12
btnTest.BackgroundColor3 = Color3.fromRGB(45, 50, 70)
btnTest.TextColor3 = Color3.fromRGB(220, 220, 240)
btnTest.Parent = main

local btnCorner3 = Instance.new("UICorner")
btnCorner3.CornerRadius = UDim.new(0, 6)
btnCorner3.Parent = btnTest

btnTest.MouseButton1Click:Connect(function()
    performParry()
end)

-- Status Footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 24)
footer.Position = UDim2.new(0, 0, 0.88, 0)
footer.Text = "Status: Operational (Matcha VM)"
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextColor3 = Color3.fromRGB(140, 140, 160)
footer.BackgroundTransparency = 1
footer.Parent = main
