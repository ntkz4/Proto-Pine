-- map_loader.lua

local map_loader = {
    thrownItems = {},
    current = nil
}

local walls = require("walls")
local world_items = require("world_items")

function map_loader.load(name)
    local path = "maps/" .. name
    local ok, data = pcall(require, path)

    if ok and type(data) == "table" then
        map_loader.current = data
        map_loader.thrownItems = {}
        walls.load(data.walls)
        print("Map loaded:", data.name)

        -- load enemies
        if data.enemies then
            local enemies = require("enemies")
            for _, e in ipairs(data.enemies) do
                enemies.spawn(e.x, e.y, e)
            end
        end
    else
        print("Failed to load map:", name)
    end
end


function map_loader.update(dt)
    for i = #map_loader.thrownItems, 1, -1 do
        local t = map_loader.thrownItems[i]
        t.x = t.x + t.vx * dt
        t.y = t.y + t.vy * dt
        t.time = t.time + dt

        if t.time > t.maxTime then
            -- return thrown object to actual map items
            table.remove(map_loader.thrownItems, i)
            if map_loader.current and map_loader.current.items then
                table.insert(map_loader.current.items, {
                    id = t.id,
                    x = t.x,
                    y = t.y
                })
            end
        end
    end
end

function map_loader.draw()
    if not map_loader.current then return end
    local m = map_loader.current

    -- background
    love.graphics.setColor(m.color or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", 0, 0, m.width, m.height)

    walls.draw()

    -- draw map items
    for _, item in ipairs(m.items or {}) do
        local def = world_items.get(item.id)
        if def then
            love.graphics.setColor(def.color or {1, 1, 1})
            love.graphics.rectangle("fill", item.x, item.y, def.width or 8, def.height or 8)
        end
    end

    -- draw active thrown items
    for _, t in ipairs(map_loader.thrownItems) do
        local def = world_items.get(t.id)
        if def then
            love.graphics.setColor(def.color or {1, 1, 1})
            love.graphics.rectangle("fill", t.x, t.y, def.width or 8, def.height or 8)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function map_loader.get()
    return map_loader.current
end

return map_loader
