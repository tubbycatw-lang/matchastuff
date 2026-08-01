--==============================================================================
-- GAKURAN ULTRA-STRICT PROBE (REPLICATEDSTORAGE CHILDREN ONLY)
--==============================================================================

print("=== GAKURAN CLEAN PROBE START ===")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

print("\n--- REPLICATEDSTORAGE ROOT ITEMS ---")
for _, v in pairs(ReplicatedStorage:GetChildren()) do
    if not v.Name:find("Kohl") and not v.Name:find("Cmdr") then
        print("  [" .. v.ClassName .. "] game.ReplicatedStorage." .. v.Name)
        -- Print 1 level down if it's a folder/model
        if v:IsA("Folder") or v:IsA("Model") then
            for _, sub in pairs(v:GetChildren()) do
                if not sub.Name:find("Kohl") and not sub.Name:find("Cmdr") and not sub.Name:find("VIP") then
                    print("     ↳ [" .. sub.ClassName .. "] " .. sub.Name)
                end
            end
        end
    end
end

print("\n--- MY CHARACTER TOOLS & ITEMS ---")
if LP.Character then
    for _, item in pairs(LP.Character:GetChildren()) do
        print("  [" .. item.ClassName .. "] " .. item.Name)
    end
end

print("\n--- MY BACKPACK ITEMS ---")
if LP:FindFirstChild("Backpack") then
    for _, item in pairs(LP.Backpack:GetChildren()) do
        print("  [" .. item.ClassName .. "] " .. item.Name)
    end
end

print("=== GAKURAN CLEAN PROBE END ===")
