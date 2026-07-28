--==============================================================================
-- MATCHA ANTI-FLING + WABI SABI GUI
-- Anti-Fling starts OFF — toggle it from the menu
--==============================================================================

-- Load WabiSabi UI Library
loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
local Library = WabiSabi

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local antiFlingEnabled  = false
local steppedConnection = nil

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

-- Fallback loop thread
task.spawn(function()
    while true do
        task.wait(0.01)
        if antiFlingEnabled then
            antiFlingLoop()
        end
    end
end)

-- GUI
local Window = Library:CreateWindow({
    Title    = "Matcha Suite",
    SubTitle = "v1.0",
    Size     = Vector2.new(500, 300),
    Resize   = true,
})

local Protection = Window:AddTab({ Title = "Protection", Icon = "shield" })

Protection:AddToggle({
    Id       = "anti_fling",
    Title    = "Anti-Fling",
    Default  = false,
    Callback = function(state)
        antiFlingEnabled = state
        if state then
            if not steppedConnection then
                pcall(function()
                    steppedConnection = RunService.Stepped:Connect(antiFlingLoop)
                end)
            end
            Library:Notify({ Title = "Anti-Fling", Content = "Protection ON — players phase through you", Duration = 3 })
        else
            if steppedConnection then
                pcall(function() steppedConnection:Disconnect() end)
                steppedConnection = nil
            end
            Library:Notify({ Title = "Anti-Fling", Content = "Protection OFF", Duration = 3 })
        end
    end
})

Library:Notify({ Title = "Matcha Suite", Content = "Menu loaded. Toggle Anti-Fling to enable.", Duration = 4 })
