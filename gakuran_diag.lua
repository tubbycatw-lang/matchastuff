--==============================================================================
-- GAKURAN STRICT TARGETED PROBE (EXCLUDES KOHL & CMDR & VIP)
--==============================================================================

print("=== GAKURAN CLEAN PROBE START ===")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

print("\n--- NON-ADMIN REMOTES ---")
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
        local fullname = v:GetFullName()
        if not fullname:find("Kohl") and not fullname:find("Cmdr") and not fullname:find("VIP") then
            print("  [Game Remote] " .. fullname .. " (" .. v.ClassName .. ")")
        end
    end
end

print("\n--- REPLICATEDSTORAGE ROOT FOLDERS ---")
for _, v in pairs(ReplicatedStorage:GetChildren()) do
    if not v.Name:find("Kohl") and not v.Name:find("Cmdr") then
        print("  [Folder/Item] " .. v.Name .. " (" .. v.ClassName .. ")")
    end
end

print("\n--- MY CHARACTER TOOLS ---")
if LP.Character then
    for _, item in pairs(LP.Character:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            print("  [Char Tool/Model] " .. item.Name .. " (" .. item.ClassName .. ")")
        end
    end
end

print("=== GAKURAN CLEAN PROBE END ===")
