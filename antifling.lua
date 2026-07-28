--==============================================================================
-- MATCHA EXACT ANTI-FLING (Rebuilt from shystemcito)
-- No MatchaUI, No Loader, Pure Anti-Fling Execution
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Safe Header Status
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

D("Square",{Size=Vector2.new(160,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(8,8,14),Filled=true,Visible=true})
D("Text",{Text="ANTI-FLING ACTIVE",Size=12,Position=Vector2.new(13,11),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Exact logic from shystemcito's AntiFling
local function antiFlingLoop()
    pcall(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.RotVelocity = Vector3.new(0, 0, 0)
                        pcall(function()
                            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                        end)
                    end
                end
            end
        end
    end)
end

-- Use task.spawn polling since RunService.Stepped / Heartbeat can freeze on Matcha
task.spawn(function()
    while task.wait(0.01) do
        antiFlingLoop()
    end
end)

-- Also attach to Stepped if available
pcall(function()
    RunService.Stepped:Connect(antiFlingLoop)
end)
