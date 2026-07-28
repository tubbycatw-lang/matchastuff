--==============================================================================
-- MATCHA ANTI-FLING PLUS (Premium UI Suite)
-- Built for Matcha External LuaVM
-- Features:
--   1. Passthrough Anti-Fling (RunService.Stepped, Zero-Yield)
--   2. Heavy Body Density Toggle
--   3. Smooth Matcha UI Overlay
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Load UI Library
local ok = pcall(function()
    loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
end)

local Library = WabiSabi

local antiFlingActive = true
local heavyPhysActive = false
local HeavyPhys = PhysicalProperties.new(100, 1, 1, 1, 1)

-- Core Passthrough Anti-Fling (Stepped, Zero Yield)
local function antiFlingStep()
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

        -- Heavy Mass Density on LocalPlayer if toggled
        if heavyPhysActive and LP.Character then
            for _, part in ipairs(LP.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CustomPhysicalProperties = HeavyPhys end)
                end
            end
        end
    end)
end

-- Connect physics step
pcall(function() RunService.Stepped:Connect(antiFlingStep) end)

-- Secondary tight loop
task.spawn(function()
    while true do
        task.wait(0.01)
        if antiFlingActive then
            antiFlingStep()
        end
    end
end)

-- Render GUI Window
if Library then
    pcall(function()
        local Window = Library:CreateWindow({
            Title    = "Anti-Fling Plus",
            SubTitle = "v2.0",
            Size     = Vector2.new(460, 280),
            Resize   = true,
        })

        local MainTab = Window:AddTab({ Title = "Protection", Icon = "shield" })

        MainTab:AddToggle({
            Id       = "anti_fling_toggle",
            Title    = "Anti-Fling Passthrough",
            Default  = true,
            Callback = function(value)
                antiFlingActive = value
                if Library.Notify then
                    Library:Notify({
                        Title    = "Anti-Fling Plus",
                        Content  = value and "Protection Enabled" or "Protection Disabled",
                        Duration = 2
                    })
                end
            end
        })

        MainTab:AddToggle({
            Id       = "heavy_density_toggle",
            Title    = "Heavy Body Mass Density",
            Default  = false,
            Callback = function(value)
                heavyPhysActive = value
                if Library.Notify then
                    Library:Notify({
                        Title    = "Anti-Fling Plus",
                        Content  = value and "Heavy Mass ON" or "Heavy Mass OFF",
                        Duration = 2
                    })
                end
            end
        })

        if Library.Notify then
            Library:Notify({
                Title    = "Anti-Fling Plus",
                Content  = "Menu Loaded Successfully.",
                Duration = 3
            })
        end
    end)
else
    -- Fallback Screen Indicator if UI lib fails
    pcall(function()
        local ok, box = pcall(Drawing.new, "Square")
        if ok and box then
            box.Size = Vector2.new(190, 20)
            box.Position = Vector2.new(8, 8)
            box.Color = Color3.fromRGB(8, 8, 14)
            box.Filled = true
            box.Visible = true
        end
        local ok2, txt = pcall(Drawing.new, "Text")
        if ok2 and txt then
            txt.Text = "ANTI-FLING PLUS ACTIVE"
            txt.Size = 12
            txt.Position = Vector2.new(13, 11)
            txt.Color = Color3.fromRGB(0, 255, 180)
            txt.Visible = true
        end
    end)
end
