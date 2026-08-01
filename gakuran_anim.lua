--==============================================================================
-- GAKURAN COMBAT ANIMATION & SOUND LOGGER
-- Monitors all playing animations and sounds in real-time
--==============================================================================

print("=== GAKURAN COMBAT ANIMATION MONITOR ACTIVE ===")
print("Perform attacks or get attacked by someone to log animation IDs!")

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local trackedAnimators = {}

local function hookAnimator(humanoid, ownerName)
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 2)
    if not animator or trackedAnimators[animator] then return end
    trackedAnimators[animator] = true

    animator.AnimationPlayed:Connect(function(animationTrack)
        local animId = animationTrack.Animation and animationTrack.Animation.AnimationId or "Unknown"
        print(string.format("[ANIM PLAYED] Player: %s | Name: %s | Id: %s", ownerName, animationTrack.Name, tostring(animId)))
    end)
end

local function trackPlayer(player)
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hookAnimator(hum, player.Name) end
    end
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hookAnimator(hum, player.Name) end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    trackPlayer(p)
end
Players.PlayerAdded:Connect(trackPlayer)
