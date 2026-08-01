--==============================================================================
-- GAKURAN DIAGNOSTIC PROBE
-- Scans Remotes, ReplicatedStorage, Character Tools & Sounds
--==============================================================================

print("=== GAKURAN PROBE START ===")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

print("[GAKURAN] Current Game PlaceId:", game.PlaceId)

print("\n--- REMOTES IN REPLICATEDSTORAGE ---")
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        print("  [Remote] " .. v:GetFullName() .. " (" .. v.ClassName .. ")")
    end
end

print("\n--- MY CHARACTER & BACKPACK TOOLS ---")
if LP.Character then
    for _, item in pairs(LP.Character:GetChildren()) do
        print("  [CharItem] " .. item.Name .. " (" .. item.ClassName .. ")")
    end
end
if LP:FindFirstChild("Backpack") then
    for _, item in pairs(LP.Backpack:GetChildren()) do
        print("  [BackpackItem] " .. item.Name .. " (" .. item.ClassName .. ")")
    end
end

print("\n--- SOUND OBJECTS IN WORKSPACE / REPLICATEDSTORAGE ---")
for _, s in pairs(game:GetDescendants()) do
    if s:IsA("Sound") and (s.Parent.Name:lower():find("music") or s.Name:lower():find("music") or s.Name:lower():find("audio")) then
        print("  [Sound] " .. s:GetFullName() .. " | SoundId: " .. tostring(s.SoundId))
    end
end

print("=== GAKURAN PROBE END ===")
