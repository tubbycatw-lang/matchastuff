--==============================================================================
-- MATCHA / GAKURAN REPLICATEDSTORAGE & LOCALPLAYER STRUCT DUMPER
--==============================================================================

local setclipboard = setclipboard or set_clipboard or toclipboard or (Syn and Syn.write_clipboard)

local function getHierarchy(parent, indent, maxDepth, currentDepth)
    currentDepth = currentDepth or 1
    indent = indent or ""
    if currentDepth > maxDepth then return "" end

    local str = ""
    for _, child in ipairs(parent:GetChildren()) do
        local cName = child.Name
        local cClass = child.ClassName

        -- Skip Kohl's Admin and Cmdr noise
        if not cName:find("Kohl") and not cName:find("Cmdr") and not cName:find("VIP") and cName ~= "AlphaWings" then
            str = str .. indent .. "[" .. cClass .. "] " .. cName .. "\n"
            if #child:GetChildren() > 0 and currentDepth < maxDepth then
                str = str .. getHierarchy(child, indent .. "  ", maxDepth, currentDepth + 1)
            end
        end
    end
    return str
end

local dump = "=== GAKURAN GAME STRUCTURE DUMP ===\n\n"

dump = dump .. "--- REPLICATEDSTORAGE ---\n"
dump = dump .. getHierarchy(game:GetService("ReplicatedStorage"), "  ", 3) .. "\n"

local LP = game:GetService("Players").LocalPlayer
dump = dump .. "--- LOCALPLAYER BACKPACK ---\n"
if LP:FindFirstChild("Backpack") then
    dump = dump .. getHierarchy(LP.Backpack, "  ", 3) .. "\n"
end

dump = dump .. "--- LOCALPLAYER CHARACTER ---\n"
if LP.Character then
    dump = dump .. getHierarchy(LP.Character, "  ", 3) .. "\n"
end

print(dump)

if setclipboard then
    setclipboard(dump)
    print("SUCCESS: Full structure dumped and COPIED TO YOUR CLIPBOARD! Press Ctrl+V to paste here.")
else
    print("FINISHED DUMPING TO CONSOLE.")
end
