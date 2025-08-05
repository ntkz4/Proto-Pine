-- body_detection.lua
local M = {}

function M.checkForDeadBodies(observer)
    local enemies = require("enemies").list
    local walls = require("walls")

    for _, other in ipairs(enemies) do
        if other ~= observer and other.dead and other.state == "dead" and not other.discovered then
            local ex = observer.x + observer.width / 2
            local ey = observer.y + observer.height / 2
            local ox = other.x + other.width / 2
            local oy = other.y + other.height / 2

            local dx, dy = ox - ex, oy - ey
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Distance check
            if dist <= observer.visionDistance then
                -- Angle check
                local angleToBody = math.atan2(dy, dx)
                local angleDiff = math.abs((angleToBody - observer.angle + math.pi) % (2 * math.pi) - math.pi)
                if angleDiff <= (observer.visionAngle / 2) then
                    -- LOS check
                    if not walls.raycast(ex, ey, ox, oy) then
                        -- Dead body is visible!
                        print("[Guard] I found a body!")
                        observer.state = "alert"
                        observer.lastSeen = { x = ox, y = oy }
                        observer.color = {1, 1, 0}
                        observer.speak = { text = "Holy shit!", timer = 3 }
                        other.discovered = true
                        return
                    end
                end
            end
        end
    end
end

return M
