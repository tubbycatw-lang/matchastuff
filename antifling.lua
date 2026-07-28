--==============================================================================
-- MATCHA STANDALONE ANTI-FLING (Restored Stable Build)
-- Pure zero-error passthrough anti-fling loop
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

pcall(function()
    RunService.Stepped:Connect(antiFlingLoop)
end)

task.spawn(function()
    while task.wait(0.01) do
        antiFlingLoop()
    end
end)
