--==============================================================================
-- MATCHA HIGH-PERFORMANCE ANTI-FLING (Zero-Lag Physics Stepped)
-- Disables collision on other players every physics frame (RunService.Stepped).
-- Never touches LocalPlayer character, so you never fall through floors or clip walls.
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Minimal Screen Indicator
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

D("Square",{Size=Vector2.new(180,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(8,8,14),Filled=true,Visible=true})
D("Text",{Text="ANTI-FLING ACTIVE",Size=12,Position=Vector2.new(13,11),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Physics Step Callback (Zero yield, instant execution)
local function antiFlingStep()
    local pList = Players:GetPlayers()
    for i = 1, #pList do
        local p = pList[i]
        if p ~= LP and p.Character then
            local parts = p.Character:GetChildren()
            for j = 1, #parts do
                local part = parts[j]
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end

-- Bind directly to Roblox physics step signals for 100% smooth movement
pcall(function() RunService.Stepped:Connect(antiFlingStep) end)
pcall(function() RunService.PreSimulation:Connect(antiFlingStep) end)
pcall(function() RunService.RenderStepped:Connect(antiFlingStep) end)

-- Fallback tight loop in case executor blocks signals
task.spawn(function()
    while true do
        task.wait()
        pcall(antiFlingStep)
    end
end)
