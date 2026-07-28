--==============================================================================
-- MATCHA ANTI-FLING SUITE (WabiSabi Official UI Framework)
-- Uses official Matcha UI Library: https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Load official WabiSabi UI Library
local ok, err = pcall(function()
    loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
end)

local Library = WabiSabi

local antiFlingActive = true
local steppedConnection = nil

local function antiFlingLoop()
    if not antiFlingActive then return end
    pcall(function()
        local pList = Players:GetPlayers()
        for i = 1, #pList do
            local p = pList[i]
            if p.Name ~= LP.Name and p.Character then
                local parts = p.Character:GetChildren()
                for j = 1, #parts do
                    local part = parts[j]
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

-- Connect physics step
steppedConnection = RunService.Stepped:Connect(antiFlingLoop)

-- Fallback loop for safety
task.spawn(function()
    while true do
        task.wait(0.01)
        if antiFlingActive then
            antiFlingLoop()
        end
    end
end)

-- Create Menu UI if WabiSabi loaded successfully
if Library then
    pcall(function()
        local Window = Library:CreateWindow({
            Title    = "Matcha Anti-Fling",
            SubTitle = "v1.0",
            Size     = Vector2.new(450, 260),
            Resize   = true,
        })

        local ProtectionTab = Window:AddTab({ Title = "Protection", Icon = "shield" })

        ProtectionTab:AddToggle({
            Id       = "anti_fling_toggle",
            Title    = "Anti-Fling Protection",
            Default  = true,
            Callback = function(value)
                antiFlingActive = value
                if Library.Notify then
                    Library:Notify({
                        Title    = "Anti-Fling",
                        Content  = value and "Protection Enabled" or "Protection Disabled",
                        Duration = 2
                    })
                end
            end
        })

        if Library.Notify then
            Library:Notify({
                Title    = "Matcha Suite",
                Content  = "Anti-Fling menu loaded.",
                Duration = 3
            })
        end
    end)
end
