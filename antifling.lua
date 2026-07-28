--==============================================================================
-- MATCHA PLAYER-ONLY ANTI-FLING (Clean & Independent)
-- Makes OTHER PLAYERS phase through you without falling through floors or walking through walls.
-- Never touches LocalPlayer character collisions.
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Safe Header Indicator
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

D("Square",{Size=Vector2.new(180,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(8,8,14),Filled=true,Visible=true})
D("Text",{Text="ANTI-FLING ACTIVE (PASSTHROUGH)",Size=11,Position=Vector2.new(12,11),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Player-Only Collision Disabler
local function antiFlingLoop()
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanTouch = false
                    end
                end
            end
        end
    end)
end

-- Fast spawn loop for executor compatibility
task.spawn(function()
    while task.wait(0.01) do
        antiFlingLoop()
    end
end)

-- Stepped event hook if supported
pcall(function()
    RunService.Stepped:Connect(antiFlingLoop)
end)
