--==============================================================================
-- SHORT GAKURAN DIAGNOSTIC PROBE
-- Only prints Remotes and Music Sounds
--==============================================================================

print("=== SHORT GAKURAN DIAG START ===")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("--- REMOTES ---")
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        print("[Remote] " .. v.Name .. " --> " .. v:GetFullName())
    end
end

print("\n--- MUSIC / AUDIO SOUNDS ---")
for _, s in pairs(game:GetDescendants()) do
    if s:IsA("Sound") then
        print("[Sound] " .. s.Name .. " | ID: " .. tostring(s.SoundId))
    end
end
print("=== SHORT GAKURAN DIAG END ===")
