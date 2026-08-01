--==============================================================================
-- GAKURAN SCRIPT SUITE (AUTO PARRY & PIANO MUSIC PLAYER)
-- Built for Matcha Executor & WabiSabi UI Library
--==============================================================================

local WabiSabiRaw = game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua")
local WabiSabi = loadstring(WabiSabiRaw)()

-- Fallback if table returned directly or inside module
local UI = WabiSabi
if type(WabiSabi) == "table" and WabiSabi.CreateWindow then
    UI = WabiSabi
elseif type(WabiSabi) == "table" and WabiSabi.Library then
    UI = WabiSabi.Library
end

-- Fallback simple custom GUI if WabiSabi fails to load in Matcha environment
local Window
if UI and UI.CreateWindow then
    Window = UI:CreateWindow({
        Title = "Gakuran Hub | Auto Parry & Music",
        Size = UDim2.new(0, 480, 0, 360),
        Theme = "Dark"
    })
end

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace")
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

-- Built-in Songs (Piano Key Notes)
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
-- GUI CREATION (WabiSabi OR Pure ScreenGui Fallback)
--==============================================================================
if Window then
    local CombatTab = Window:CreateTab({ Name = "Combat" })

    CombatTab:CreateToggle({
        Title = "Enable Auto Parry",
        Default = false,
        Callback = function(Value) Flags.AutoParry = Value end
    })

    CombatTab:CreateSlider({
        Title = "Parry Distance Range",
        Min = 5, Max = 30, Default = 15,
        Callback = function(Value) Flags.ParryDistance = Value end
    })

    CombatTab:CreateButton({
        Title = "Manual Test Parry",
        Callback = function() performParry() end
    })

    local MusicTab = Window:CreateTab({ Name = "Auto Music" })

    MusicTab:CreateToggle({
        Title = "Enable Auto Play Music",
        Default = false,
        Callback = function(Value) Flags.AutoMusic = Value end
    })

    MusicTab:CreateDropdown({
        Title = "Select Song",
        Options = {"Megalovania", "Fur Elise", "Rush B"},
        Default = "Megalovania",
        Callback = function(Value) Flags.SongChoice = Value end
    })
else
    -- Pure ScreenGui Fallback if WabiSabi library loadstring failed
    local screen = Instance.new("ScreenGui")
    screen.Name = "GakuranGui"
    screen.ResetOnSpawn = false
    
    local CoreGui = game:GetService("CoreGui")
    screen.Parent = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 180)
    frame.Position = UDim2.new(0.05, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Gakuran Hub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    title.Parent = frame

    local btnParry = Instance.new("TextButton")
    btnParry.Size = UDim2.new(0.9, 0, 0, 35)
    btnParry.Position = UDim2.new(0.05, 0, 0.25, 0)
    btnParry.Text = "Auto Parry: OFF"
    btnParry.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnParry.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnParry.Parent = frame

    btnParry.MouseButton1Click:Connect(function()
        Flags.AutoParry = not Flags.AutoParry
        btnParry.Text = "Auto Parry: " .. (Flags.AutoParry and "ON" or "OFF")
        btnParry.BackgroundColor3 = Flags.AutoParry and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    end)

    local btnMusic = Instance.new("TextButton")
    btnMusic.Size = UDim2.new(0.9, 0, 0, 35)
    btnMusic.Position = UDim2.new(0.05, 0, 0.55, 0)
    btnMusic.Text = "Auto Music: OFF"
    btnMusic.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnMusic.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMusic.Parent = frame

    btnMusic.MouseButton1Click:Connect(function()
        Flags.AutoMusic = not Flags.AutoMusic
        btnMusic.Text = "Auto Music: " .. (Flags.AutoMusic and "ON" or "OFF")
        btnMusic.BackgroundColor3 = Flags.AutoMusic and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    end)
end
