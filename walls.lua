-- walls.lua

local walls = {}
walls.list = {}

local materialData = {
    wood = { color = {0.6, 0.4, 0.2}, piercing = false, noise = 0.8 },
    metal = { color = {0.7, 0.7, 0.7}, piercing = false, noise = 1.0 },
    glass = { color = {0.5, 0.8, 1.0}, piercing = true, noise = 1.2, breakable = true }
}

function walls.load(data)
    walls.list = {}
    if not data then return end

    for _, wall in ipairs(data) do
        local mat = materialData[wall.material] or {}
        wall.color = mat.color or {0.8, 0.8, 0.8}
        wall.piercing = mat.piercing or false
        wall.noise = mat.noise or 1.0
        wall.breakable = wall.breakable or mat.breakable or false
        table.insert(walls.list, wall)
    end
end

function walls.draw()
    for _, wall in ipairs(walls.list) do
        love.graphics.setColor(wall.color)
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end
    love.graphics.setColor(1, 1, 1)
end

function walls.getList()
    return walls.list
end

-- basic collision with point
function walls.collides(x, y)
    for _, wall in ipairs(walls.list) do
        if x > wall.x and x < wall.x + wall.w and
           y > wall.y and y < wall.y + wall.h then
            return true, wall
        end
    end
    return false
end
function walls.raycast(x1, y1, x2, y2)
    for _, wall in ipairs(walls.list) do -- ✅ use walls.list, not walls.data
        local x, y, w, h = wall.x, wall.y, wall.w, wall.h
        if checkLineRect(x1, y1, x2, y2, x, y, w, h) then
            return true -- blocked
        end
    end
    return false
end

-- helper: line-rect intersection
function checkLineRect(x1, y1, x2, y2, rx, ry, rw, rh)
    return  lineIntersects(x1, y1, x2, y2, rx, ry, rx+rw, ry) or     -- top
            lineIntersects(x1, y1, x2, y2, rx+rw, ry, rx+rw, ry+rh) or -- right
            lineIntersects(x1, y1, x2, y2, rx+rw, ry+rh, rx, ry+rh) or -- bottom
            lineIntersects(x1, y1, x2, y2, rx, ry+rh, rx, ry)          -- left
end

function lineIntersects(x1,y1,x2,y2, x3,y3,x4,y4)
    local den = (x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4)
    if den == 0 then return false end

    local t = ((x1 - x3)*(y3 - y4) - (y1 - y3)*(x3 - x4)) / den
    local u = -((x1 - x2)*(y1 - x3) - (y1 - y2)*(x1 - x3)) / den

    return t >= 0 and t <= 1 and u >= 0 and u <= 1
end


return walls
