--==============================================================================
-- MATCHA STANDALONE ANTI-FLING
-- Exact core anti-fling engine without MatchaUI/Loader
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local function antiFlingLoop()
    pcall(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name ~= LP.Name and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

-- Bind directly to Stepped for sub-frame collision disabling
pcall(function()
    RunService.Stepped:Connect(antiFlingLoop)
end)

-- Safe fallback loop for executor stability
task.spawn(function()
    while task.wait(0.01) do
        antiFlingLoop()
    end
end)
