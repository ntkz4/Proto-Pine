-- bullet.lua

local bullet = {}
bullet.active = {}

function bullet.spawn(x, y, angle, opts)
    opts = opts or {}

    local b = {
        x = x,
        y = y,
        angle = angle,
        speed = opts.speed or 600,
        length = opts.length or 16,
        life = opts.life or 1,
        damage = opts.damage or 10,
        color = opts.color or {1, 1, 1},
        piercing = opts.piercing or false
    }

    table.insert(bullet.active, b)
end

function bullet.update(dt)
    for i = #bullet.active, 1, -1 do
        local b = bullet.active[i]

        b.x = b.x + math.cos(b.angle) * b.speed * dt
        b.y = b.y + math.sin(b.angle) * b.speed * dt
        b.life = b.life - dt

        if b.life <= 0 then
            table.remove(bullet.active, i)
        end
    end
end

function bullet.draw()
    love.graphics.setLineWidth(2)
    for _, b in ipairs(bullet.active) do
        love.graphics.setColor(b.color)
        local endX = b.x + math.cos(b.angle) * b.length
        local endY = b.y + math.sin(b.angle) * b.length
        love.graphics.line(b.x, b.y, endX, endY)
    end
    love.graphics.setColor(1, 1, 1)
end

return bullet
