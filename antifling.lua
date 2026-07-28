--==============================================================================
-- MATCHA ANTI-FLING PLUS (v2.2 Stable)
-- Completely removed PhysicalProperties to prevent Matcha LuaVM errors
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Load UI Library
pcall(function()
    loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
end)

local Library = WabiSabi

local antiFlingActive = true

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
            SubTitle = "v2.2",
            Size     = Vector2.new(450, 220),
            Resize   = true,
        })

        local MainTab = Window:AddTab({ Title = "Protection", Icon = "shield" })

        MainTab:AddToggle({
            Id       = "anti_fling_toggle",
            Title    = "Anti-Fling Passthrough",
            Default  = true,
            Callback = function(value)
                antiFlingActive = value
                if Library and Library.Notify then
                    Library:Notify({
                        Title    = "Anti-Fling Plus",
                        Content  = value and "Protection Enabled" or "Protection Disabled",
                        Duration = 2
                    })
                end
            end
        })

        if Library and Library.Notify then
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
