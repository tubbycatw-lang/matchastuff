--==============================================================================
-- GAKURAN HUB (AUTO PARRY & PIANO MUSIC)
-- 100% Standalone - Zero Dependencies - Matcha Ultra-Safe
--==============================================================================

local ok, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer

-- Matcha may sandbox Instance.new - find the working constructor
local new = Instance and Instance.new
if not new then
    -- Try to grab it from game
    pcall(function()
        new = game.Instance and game.Instance.new
    end)
end
if not new then
    -- Try via load
    pcall(function()
        new = loadstring("return Instance.new")()
    end)
end
if not new then
    -- Last resort: clone an existing instance
    -- We'll use a different approach entirely - Drawing API
    print("[GAKURAN] Instance.new not available, trying Drawing API...")
end

-- Test if new works
local testOk = false
if new then
    pcall(function()
        local t = new("Folder")
        t:Destroy()
        testOk = true
    end)
end

if not testOk then
    print("[GAKURAN] Instance.new doesn't work in this environment")
    print("[GAKURAN] Checking available globals...")
    
    -- Print what globals exist for debugging
    local interesting = {"Instance", "Drawing", "drawing", "syn", "fluxus", "krnl", "getgenv", "gethui", "game"}
    for _, name in pairs(interesting) do
        local val = nil
        pcall(function() val = getfenv()[name] end)
        if val == nil then
            pcall(function() val = getgenv()[name] end)
        end
        print("[GAKURAN]   " .. name .. " = " .. tostring(val))
    end
    
    -- Try Drawing API as fallback UI
    local hasDrawing = false
    pcall(function()
        if Drawing and Drawing.new then
            hasDrawing = true
        end
    end)
    
    if hasDrawing then
        print("[GAKURAN] Drawing API available! Using Drawing UI...")
    else
        print("[GAKURAN] No UI API available. Running headless (keybind mode)...")
    end
end

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

local Songs = {
    Megalovania = "d d D a g f d f g c c D a g f d f g b b D a g f d f g",
    FurElise = "e D e D e b d c a c e a b e g a b e D e D e b d c a",
    RushB = "a a a f c a f c a e e e f c g f c a"
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
            local notes = Songs["Megalovania"]
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
-- GUI
--==============================================================================

if testOk and new then
    -- Instance.new works! Build normal GUI
    
    -- Destroy old
    pcall(function()
        local cg = game:GetService("CoreGui")
        local old = cg:FindFirstChild("GakuranHub")
        if old then old:Destroy() end
    end)
    pcall(function()
        local old = LP.PlayerGui:FindFirstChild("GakuranHub")
        if old then old:Destroy() end
    end)
    
    local sg = new("ScreenGui")
    sg.Name = "GakuranHub"
    sg.ResetOnSpawn = false
    
    local guiOk = false
    pcall(function() sg.Parent = gethui(); guiOk = true end)
    if not guiOk then pcall(function() sg.Parent = game:GetService("CoreGui"); guiOk = true end) end
    if not guiOk then pcall(function() sg.Parent = LP.PlayerGui; guiOk = true end) end
    
    if not guiOk then
        print("[GAKURAN] Could not parent GUI!")
        return
    end
    
    local main = new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 310, 0, 260)
    main.Position = UDim2.new(0.05, 0, 0.3, 0)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    pcall(function() local c = new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = main end)
    
    local hdr = new("TextLabel")
    hdr.Size = UDim2.new(1, 0, 0, 36)
    hdr.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    hdr.BorderSizePixel = 0
    hdr.Text = "  GAKURAN HUB  |  MATCHA"
    hdr.TextColor3 = Color3.fromRGB(230, 230, 255)
    hdr.TextSize = 14
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    pcall(function() hdr.Font = Enum.Font.GothamBold end)
    hdr.Parent = main
    pcall(function() local c = new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = hdr end)
    
    local function makeBtn(name, yOff, text, color)
        local btn = new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.Position = UDim2.new(0.05, 0, 0, yOff)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        pcall(function() btn.Font = Enum.Font.GothamBold end)
        btn.Parent = main
        pcall(function() local c = new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn end)
        return btn
    end
    
    local parryBtn = makeBtn("ParryBtn", 44, "AUTO PARRY: OFF", Color3.fromRGB(160, 45, 55))
    parryBtn.MouseButton1Click:Connect(function()
        AutoParry = not AutoParry
        parryBtn.Text = "AUTO PARRY: " .. (AutoParry and "ON" or "OFF")
        parryBtn.BackgroundColor3 = AutoParry and Color3.fromRGB(35, 150, 80) or Color3.fromRGB(160, 45, 55)
    end)
    
    local musicBtn = makeBtn("MusicBtn", 92, "AUTO MUSIC: OFF", Color3.fromRGB(160, 45, 55))
    musicBtn.MouseButton1Click:Connect(function()
        AutoMusic = not AutoMusic
        musicBtn.Text = "AUTO MUSIC: " .. (AutoMusic and "ON" or "OFF")
        musicBtn.BackgroundColor3 = AutoMusic and Color3.fromRGB(35, 150, 80) or Color3.fromRGB(160, 45, 55)
    end)
    
    local testBtn = makeBtn("TestBtn", 140, "MANUAL TEST PARRY", Color3.fromRGB(40, 45, 65))
    testBtn.MouseButton1Click:Connect(function()
        performParry()
        print("[GAKURAN] Manual parry fired!")
    end)
    
    -- Close button
    local closeBtn = new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Parent = main
    pcall(function() local c = new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = closeBtn end)
    closeBtn.MouseButton1Click:Connect(function()
        AutoParry = false; AutoMusic = false
        pcall(function() parryConn:Disconnect() end)
        sg:Destroy()
    end)
    
    -- Footer
    local ft = new("TextLabel")
    ft.Size = UDim2.new(1, 0, 0, 22)
    ft.Position = UDim2.new(0, 0, 1, -24)
    ft.BackgroundTransparency = 1
    ft.Text = "Combat: " .. (CombatRemote and "OK" or "X") .. " | Piano: " .. (PianoRemote and "OK" or "X")
    ft.TextColor3 = Color3.fromRGB(120, 120, 145)
    ft.TextSize = 10
    pcall(function() ft.Font = Enum.Font.Gotham end)
    ft.Parent = main
    
    print("[GAKURAN] GUI loaded!")

else
    -- Instance.new doesn't work - KEYBIND MODE
    print("[GAKURAN] Running in KEYBIND MODE (no GUI)")
    print("[GAKURAN] Press F5 = Toggle Auto Parry")
    print("[GAKURAN] Press F6 = Toggle Auto Music")
    print("[GAKURAN] Press F7 = Manual Parry")
    
    local UIS
    pcall(function() UIS = game:GetService("UserInputService") end)
    
    if UIS then
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.F5 then
                AutoParry = not AutoParry
                print("[GAKURAN] Auto Parry: " .. tostring(AutoParry))
            elseif input.KeyCode == Enum.KeyCode.F6 then
                AutoMusic = not AutoMusic
                print("[GAKURAN] Auto Music: " .. tostring(AutoMusic))
            elseif input.KeyCode == Enum.KeyCode.F7 then
                performParry()
                print("[GAKURAN] Manual parry!")
            end
        end)
    end
    
    print("[GAKURAN] Keybind mode active!")
end

print("[GAKURAN] Hub loaded successfully!")

end)

if not ok then
    print("[GAKURAN] FATAL: " .. tostring(err))
end
