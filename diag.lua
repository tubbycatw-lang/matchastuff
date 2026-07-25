--==============================================================================
-- MATCHA MM2 DIAGNOSTIC PROBE v1.0
-- Paste this ALONE first to identify what Matcha can/cannot access
--==============================================================================

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer
local Cam       = Workspace.CurrentCamera

print("=== MATCHA MM2 DIAGNOSTIC START ===")

-- 1. Check players in server
local allPlayers = Players:GetPlayers()
print("[PLAYERS] Count: " .. #allPlayers)
for _, p in ipairs(allPlayers) do
    print("  - " .. p.Name .. " (me=" .. tostring(p == LP) .. ")")
end

-- 2. Check local character
local myChar = LP.Character
local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
print("[MY CHAR] " .. tostring(myChar ~= nil) .. " | HRP: " .. tostring(myHRP ~= nil))
if myHRP then
    print("  HRP Position: " .. tostring(myHRP.Position))
end

-- 3. Check camera
print("[CAMERA] " .. tostring(Cam ~= nil))
if Cam then
    print("  ViewportSize: " .. tostring(Cam.ViewportSize))
    print("  CFrame: " .. tostring(Cam.CFrame))
end

-- 4. Test WorldToViewportPoint on each other player
for _, p in ipairs(allPlayers) do
    if p ~= LP then
        local char = p.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        print("[ESP TEST] " .. p.Name .. " char=" .. tostring(char ~= nil) .. " hrp=" .. tostring(hrp ~= nil))
        if hrp then
            local ok, sp, on = pcall(function()
                return Cam:WorldToViewportPoint(hrp.Position)
            end)
            print("  W2VP ok=" .. tostring(ok) .. " onScreen=" .. tostring(on) .. " pos=" .. tostring(sp))
        end
    end
end

-- 5. Test Drawing creation
print("[DRAWING] Testing Square...")
local ok1, box = pcall(Drawing.new, "Square")
print("  Square ok=" .. tostring(ok1))
if ok1 and box then
    pcall(function() box.Visible = true end)
    pcall(function() box.Size = Vector2.new(50, 50) end)
    pcall(function() box.Position = Vector2.new(100, 100) end)
    pcall(function() box.Color = Color3.fromRGB(255,0,0) end)
    print("  Square properties set. Should see red box at 100,100 on screen!")
end

print("[DRAWING] Testing Text...")
local ok2, txt = pcall(Drawing.new, "Text")
print("  Text ok=" .. tostring(ok2))
if ok2 and txt then
    pcall(function() txt.Visible = true end)
    pcall(function() txt.Text = "DIAGNOSTIC TEXT" end)
    pcall(function() txt.Size = 18 end)
    pcall(function() txt.Position = Vector2.new(100, 160) end)
    pcall(function() txt.Color = Color3.fromRGB(0,255,0) end)
    print("  Text set. Should see green DIAGNOSTIC TEXT at 100,160!")
end

-- 6. Check what tools players have
print("[TOOLS] Checking all player tools...")
for _, p in ipairs(allPlayers) do
    local char = p.Character
    local bp   = p:FindFirstChild("Backpack")
    local tools = {}
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then table.insert(tools, "char:" .. c.Name) end
        end
    end
    if bp then
        for _, c in ipairs(bp:GetChildren()) do
            if c:IsA("Tool") then table.insert(tools, "bp:" .. c.Name) end
        end
    end
    if #tools > 0 then
        print("  " .. p.Name .. ": " .. table.concat(tools, ", "))
    else
        print("  " .. p.Name .. ": NO TOOLS")
    end
end

-- 7. Check Workspace for GunDrop
print("[GUN DROP] Scanning Workspace...")
local found = false
for _, c in ipairs(Workspace:GetChildren()) do
    if c:IsA("Tool") or c.Name:lower():find("gun") or c.Name:lower():find("drop") then
        print("  Found: " .. c.Name .. " (" .. c.ClassName .. ")")
        found = true
    end
end
if not found then print("  No gun drops found in Workspace root") end

print("=== DIAGNOSTIC END ===")
