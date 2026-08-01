--==============================================================================
-- GAKURAN HUB (AUTO PARRY & PIANO MUSIC)
-- 100% Standalone - Zero External Dependencies - Matcha Safe
--==============================================================================

-- Wrap entire script in pcall for safety
local ok, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer

-- Find combat remote safely
local CombatRemote
pcall(function()
    local shared = RS:FindFirstChild("Shared")
    if shared then
        local net = shared:FindFirstChild("Network")
        if net then
            CombatRemote = net:FindFirstChild("CombatClientRemoteEvent")
        end
    end
end)

-- Find piano remote safely
local PianoRemote
pcall(function()
    local remotes = RS:FindFirstChild("Remotes")
    if remotes then
        PianoRemote = remotes:FindFirstChild("InstrumentPiano")
    end
end)

print("[GAKURAN] CombatRemote: " .. tostring(CombatRemote))
print("[GAKURAN] PianoRemote: " .. tostring(PianoRemote))

-- State
local AutoParry = false
local ParryDistance = 15
local AutoMusic = false
local MusicSpeed = 0.12

-- Songs (simple note sequences)
local Songs = {
    Megalovania = "d d D a g f d f g c c D a g f d f g b b D a g f d f g",
    FurElise = "e D e D e b d c a c e a b e g a b e D e D e b d c a",
    RushB = "a a a f c a f c a e e e f c g f c a"
}
local CurrentSong = "Megalovania"

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
    task.delay(0.35, function() parryCooldown = false end)
end

local parryConn
parryConn = RunService.Heartbeat:Connect(function()
    if not AutoParry then return end
    local myChar = LP.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local myPos = myHrp.Position

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if eHrp then
                local dist = (eHrp.Position - myPos).Magnitude
                if dist <= ParryDistance then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChildOfClass("Animator")
                        if animator then
                            pcall(function()
                                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                    local n = ""
                                    pcall(function() n = track.Animation.Name:lower() end)
                                    if n:find("m1") or n:find("m2") or n:find("attack") or n:find("hit") or n:find("punch") or n:find("swing") then
                                        performParry()
                                        return
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

--==============================================================================
-- AUTO MUSIC ENGINE
--==============================================================================
task.spawn(function()
    while task.wait(0.1) do
        if AutoMusic and PianoRemote then
            local notes = Songs[CurrentSong]
            if notes then
                for note in notes:gmatch("%S+") do
                    if not AutoMusic then break end
                    pcall(function() PianoRemote:FireServer("PlayKey", note) end)
                    task.wait(MusicSpeed)
                end
            end
        end
    end
end)

--==============================================================================
-- GUI - Pure Instance.new, no external libs, no Enums that might be nil
--==============================================================================

-- Destroy old GUI if exists
pcall(function()
    local old = LP.PlayerGui:FindFirstChild("GakuranHub")
    if old then old:Destroy() end
end)
pcall(function()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("GakuranHub")
    if old then old:Destroy() end
end)

-- Create ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "GakuranHub"
sg.ResetOnSpawn = false

-- Try to parent to gethui, CoreGui, or PlayerGui
local guiOk = false
pcall(function()
    if gethui then
        sg.Parent = gethui()
        guiOk = true
    end
end)
if not guiOk then
    pcall(function()
        sg.Parent = game:GetService("CoreGui")
        guiOk = true
    end)
end
if not guiOk then
    pcall(function()
        sg.Parent = LP.PlayerGui
        guiOk = true
    end)
end

if not guiOk then
    print("[GAKURAN] ERROR: Could not parent ScreenGui!")
    return
end

print("[GAKURAN] GUI parent: " .. tostring(sg.Parent))

-- Main Frame
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 310, 0, 260)
main.Position = UDim2.new(0.05, 0, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = sg

pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = main
end)

-- Header
local hdr = Instance.new("TextLabel")
hdr.Name = "Header"
hdr.Size = UDim2.new(1, 0, 0, 36)
hdr.Position = UDim2.new(0, 0, 0, 0)
hdr.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
hdr.BorderSizePixel = 0
hdr.Text = "  GAKURAN HUB  |  MATCHA"
hdr.TextColor3 = Color3.fromRGB(230, 230, 255)
hdr.TextSize = 14
hdr.TextXAlignment = Enum.TextXAlignment.Left
pcall(function() hdr.Font = Enum.Font.GothamBold end)
hdr.Parent = main

pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = hdr
end)

-- Helper: create a toggle button
local function makeToggle(name, yOffset, labelOn, labelOff, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(160, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = labelOff
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    pcall(function() btn.Font = Enum.Font.GothamBold end)
    btn.Parent = main

    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
    end)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and labelOn or labelOff
        btn.BackgroundColor3 = state and Color3.fromRGB(35, 150, 80) or Color3.fromRGB(160, 45, 55)
        callback(state)
    end)
    return btn
end

-- Toggle: Auto Parry
makeToggle("ParryBtn", 44, "AUTO PARRY: ON", "AUTO PARRY: OFF", function(v)
    AutoParry = v
    print("[GAKURAN] Auto Parry: " .. tostring(v))
end)

-- Toggle: Auto Music
makeToggle("MusicBtn", 92, "AUTO MUSIC: ON", "AUTO MUSIC: OFF", function(v)
    AutoMusic = v
    print("[GAKURAN] Auto Music: " .. tostring(v))
end)

-- Manual Test Parry Button
local testBtn = Instance.new("TextButton")
testBtn.Name = "TestBtn"
testBtn.Size = UDim2.new(0.9, 0, 0, 34)
testBtn.Position = UDim2.new(0.05, 0, 0, 140)
testBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
testBtn.BorderSizePixel = 0
testBtn.Text = "MANUAL TEST PARRY"
testBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
testBtn.TextSize = 12
pcall(function() testBtn.Font = Enum.Font.GothamMedium end)
testBtn.Parent = main

pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = testBtn
end)

testBtn.MouseButton1Click:Connect(function()
    performParry()
    print("[GAKURAN] Manual parry fired!")
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
pcall(function() closeBtn.Font = Enum.Font.GothamBold end)
closeBtn.Parent = main

pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = closeBtn
end)

closeBtn.MouseButton1Click:Connect(function()
    AutoParry = false
    AutoMusic = false
    pcall(function() parryConn:Disconnect() end)
    sg:Destroy()
    print("[GAKURAN] Hub closed.")
end)

-- Status Footer
local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Position = UDim2.new(0, 0, 1, -24)
footer.BackgroundTransparency = 1
footer.Text = "Combat: " .. (CombatRemote and "Found" or "NOT FOUND") .. " | Piano: " .. (PianoRemote and "Found" or "NOT FOUND")
footer.TextColor3 = Color3.fromRGB(120, 120, 145)
footer.TextSize = 10
pcall(function() footer.Font = Enum.Font.Gotham end)
footer.Parent = main

print("[GAKURAN] Hub loaded successfully!")

end) -- end of main pcall

if not ok then
    print("[GAKURAN] SCRIPT ERROR: " .. tostring(err))
end
