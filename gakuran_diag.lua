--==============================================================================
-- GAKURAN COMBAT DETECTOR
-- Filters out Kohl's admin and dumps game-specific combat remotes/sounds
--==============================================================================

print("=== GAKURAN COMBAT SEARCH START ===")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

print("\n--- NON-KOHLS REMOTES & FUNCTIONS ---")
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction")) then
        if not v:GetFullName():find("Kohl") and not v:GetFullName():find("Cmdr") then
            print("  [Game Remote] " .. v:GetFullName() .. " (" .. v.ClassName .. ")")
        end
    end
end

print("\n--- REPLICATEDSTORAGE FOLDERS ---")
for _, v in pairs(ReplicatedStorage:GetChildren()) do
    if not v.Name:find("Kohl") and not v.Name:find("Cmdr") then
        print("  [RS Folder/Item] " .. v.Name .. " (" .. v.ClassName .. ")")
    end
end

print("\n--- CHARACTER ANIMATIONS PLAYING ---")
if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
    local anims = LP.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()
    for _, track in pairs(anims) do
        print("  [Playing Anim] " .. track.Name .. " | ID: " .. tostring(track.Animation and track.Animation.AnimationId))
    end
end

print("=== GAKURAN COMBAT SEARCH END ===")
