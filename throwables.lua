-- throwables.lua

local throwables = {}
throwables.active = {}

function throwables.spawn(id, x, y, angle, speed)
    table.insert(throwables.active, {
        id = id,
        x = x,
        y = y,
        angle = angle,
        speed = math.min(500, math.max(150, speed)), -- clamp between min/max
        radius = 5,
        decay = 200,       -- units per second lost
        minSpeed = 50,     -- drop when under this
        life = 0
    })
end

function throwables.update(dt)
    for i = #throwables.active, 1, -1 do
        local t = throwables.active[i]

        -- movement
        local dx = math.cos(t.angle)
        local dy = math.sin(t.angle)
        t.x = t.x + dx * t.speed * dt
        t.y = t.y + dy * t.speed * dt

        -- decay
        t.speed = t.speed - t.decay * dt
        if t.speed < 0 then t.speed = 0 end

        t.life = t.life + dt

        -- land back into world
        if t.speed < t.minSpeed then
            local map = require("map_loader").get()
            if map and map.items then
                table.insert(map.items, {
                    id = t.id,
                    x = t.x,
                    y = t.y
                })
            end

            -- emit noise if item defines it
            local def = require("world_items").get(t.id)
            if def and def.noise and def.noise > 0 then
            local centerX = t.x + (def.width or 8) / 2
            local centerY = t.y + (def.height or 8) / 2
            require("noise_system").emit(centerX, centerY, def.noise)

            end
            table.remove(throwables.active, i)
        end
    end
end

function throwables.draw()
    local world_items = require("world_items")
    for _, t in ipairs(throwables.active) do
        local def = world_items.get(t.id)
        if def then
            love.graphics.setColor(def.color or {1, 1, 1})
            love.graphics.rectangle("fill", t.x, t.y, def.width or 8, def.height or 8)
        end
    end
end

return throwables
