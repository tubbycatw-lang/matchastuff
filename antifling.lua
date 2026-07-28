--==============================================================================
-- MATCHA ADVANCED ANTI-FLING v2.0
-- 4-Layer Physics Protection:
--   1. Immovable Physical Properties (High Density/Mass)
--   2. Proximity Noclip (Disables collisions when players get within 15 studs)
--   3. Velocity Dampening (Zeroes out unnatural assembly linear/angular velocity)
--   4. Position Lock / Instant Fling Cancellation
--==============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer

-- Safe Screen Drawing Status
local function D(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    return obj
end

D("Square",{Size=Vector2.new(180,20),Position=Vector2.new(8,8),Color=Color3.fromRGB(10,10,18),Filled=true,Visible=true})
D("Text",{Text="ANTI-FLING v2.0 ACTIVE",Size=12,Position=Vector2.new(13,11),Color=Color3.fromRGB(0,255,180),Visible=true})

-- Physical Properties: High Density (100) makes character immovable by physics collisions
local HeavyPhys = PhysicalProperties.new(100, 1, 1, 1, 1)

local lastSafeCFrame = nil
local lastSafeTime   = tick()

task.spawn(function()
    while task.wait(0.01) do
        pcall(function()
            local myChar = LP.Character
            if not myChar then return end

            local myHRP = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
            local myHum = myChar:FindFirstChild("Humanoid")

            if not myHRP or not myHum or myHum.Health <= 0 then return end

            -- 1. Apply Heavy Mass to Local Character Parts
            for _, part in ipairs(myChar:GetChildren()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CustomPhysicalProperties = HeavyPhys
                    end)
                end
            end

            -- Track safe ground CFrame for recovery
            if myHRP.AssemblyLinearVelocity.Magnitude < 30 then
                if tick() - lastSafeTime > 0.2 then
                    lastSafeCFrame = myHRP.CFrame
                    lastSafeTime   = tick()
                end
            end

            -- 2. Check all other players in server
            local nearbyPlayer = false
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    local otherHRP = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
                    
                    -- Disable collisions on other player parts
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            -- Neutralize spinning/flinging parts on other player
                            pcall(function()
                                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                if part.AssemblyLinearVelocity.Magnitude > 100 then
                                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                            end)
                        end
                    end

                    -- Check distance to local player
                    if otherHRP and myHRP then
                        local dist = (myHRP.Position - otherHRP.Position).Magnitude
                        if dist <= 18 then
                            nearbyPlayer = true
                        end
                    end
                end
            end

            -- 3. If a player is nearby, disable collision on local character to prevent fling transfer
            if nearbyPlayer then
                for _, part in ipairs(myChar:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end

            -- 4. Fling Detection & Instant Neutralization
            local linVel = myHRP.AssemblyLinearVelocity
            local angVel = myHRP.AssemblyAngularVelocity

            -- If linear velocity or angular velocity spikes unnaturally (being flung)
            if linVel.Magnitude > 80 or angVel.Magnitude > 30 then
                myHRP.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                -- If velocity is massive (>150), recover to last safe position immediately
                if linVel.Magnitude > 150 and lastSafeCFrame then
                    myHRP.CFrame = lastSafeCFrame
                end
            end
        end)
    end
end)
