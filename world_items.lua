-- world_items.lua

local world_items = {
    all = {}, -- stores every loaded item
    by_id = {} -- lookup by id
}

-- helper to load all .lua files in a folder
local function loadItemsFromFolder(folder)
    local lfs = love.filesystem
    if not lfs.getInfo(folder, "directory") then return end

    for _, file in ipairs(lfs.getDirectoryItems(folder)) do
        if file:match("%.lua$") then
            local id = file:gsub("%.lua$", "")
            local path = folder .. "/" .. id
            local success, item = pcall(require, path)

            if success and type(item) == "table" then
                table.insert(world_items.all, item)
                world_items.by_id[item.id or id] = item
            else
                print("Failed to load item: " .. path)
            end
        end
    end
end

function world_items.load()
    loadItemsFromFolder("items_distractions")
    loadItemsFromFolder("items_gadgets")
end

function world_items.get(id)
    return world_items.by_id[id]
end

return world_items
