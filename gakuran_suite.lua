--==============================================================================
-- GAKURAN SCRIPT SUITE (AUTO PARRY & PIANO MUSIC PLAYER)
-- Built for Matcha Executor & WabiSabi UI Library
--==============================================================================

-- 1. Load WabiSabi UI Library
local WabiSabi = loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()

-- Create Main Window
local Window = WabiSabi:CreateWindow({
    Title = "Gakuran Hub | Auto Parry & Music",
    Size = UDim2.new(0, 480, 0, 360),
    Theme = "Dark"
})

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
-- 2. AUTO PARRY ENGINE
-- Detects enemy combat animations & distance, triggers parry
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

-- Detect Combat Remote Events directly from server
if CombatRemote then
    CombatRemote.OnClientEvent:Connect(function(...)
        if not Flags.AutoParry then return end
        local args = {...}
        if type(args[1]) == "string" and (args[1]:lower():find("attack") or args[1]:lower():find("swing")) then
            performParry()
        end
    end)
end

--==============================================================================
-- 3. PIANO AUTO MUSIC PLAYER ENGINE
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
-- 4. GUI TAB STRUCTURE
--==============================================================================

-- Tab 1: Combat Options
local CombatTab = Window:CreateTab({ Name = "Combat" })

CombatTab:CreateToggle({
    Title = "Enable Auto Parry",
    Default = false,
    Callback = function(Value)
        Flags.AutoParry = Value
    end
})

CombatTab:CreateSlider({
    Title = "Parry Distance Range (Studs)",
    Min = 5,
    Max = 30,
    Default = 15,
    Callback = function(Value)
        Flags.ParryDistance = Value
    end
})

CombatTab:CreateButton({
    Title = "Manual Test Parry",
    Callback = function()
        performParry()
    end
})

-- Tab 2: Auto Music Player
local MusicTab = Window:CreateTab({ Name = "Auto Music" })

MusicTab:CreateToggle({
    Title = "Enable Auto Play Music",
    Default = false,
    Callback = function(Value)
        Flags.AutoMusic = Value
    end
})

MusicTab:CreateDropdown({
    Title = "Select Song",
    Options = {"Megalovania", "Fur Elise", "Rush B"},
    Default = "Megalovania",
    Callback = function(Value)
        Flags.SongChoice = Value
    end
})

MusicTab:CreateSlider({
    Title = "Note Speed (Seconds)",
    Min = 0.05,
    Max = 0.5,
    Default = 0.1,
    Callback = function(Value)
        Flags.MusicSpeed = Value
    end
})

-- Notification
WabiSabi:Notify({
    Title = "Gakuran Suite Loaded",
    Content = "Auto Parry & Auto Music ready!",
    Duration = 4
})
