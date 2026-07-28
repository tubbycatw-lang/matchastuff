--==============================================================================
-- MATCHA ANTI-FLING v1.0 (Clean Standalone)
-- Lightweight, GUI-free Anti-Fling for Matcha Executor
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

-- Safe Drawing Header Status
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

D("Square",{Size=Vector2.new(160,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(8,8,14),Filled=true,Visible=true})
D("Text",{Text="ANTI-FLING ACTIVE",Size=12,Position=Vector2.new(13,11),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Anti-Fling Core Logic
task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            pcall(function()
                                if part.AssemblyAngularVelocity.Magnitude > 30 then
                                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                end
                                if part.AssemblyLinearVelocity.Magnitude > 150 then
                                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end
end)
