-- enemies.lua

local enemies = {}
local noise_system = require("noise_system")
enemies.list = {}
enemies.debugVision = false
local enemy_behavior = require("enemy_behavior")
local alert_behavior = require("alert_behavior")


function enemies.spawn(x, y, opts)   
    local patrolDistance = 80 -- how far they walk back and forth    opts = opts or {}

    table.insert(enemies.list, {
        hp = 100,              -- 💥 default health
        dead = false,          -- 💀 flag for death
        x = x,
        y = y,
        startX = x,
        startY = y,
        width = 24,
        height = 24,
        color = {1, 0, 0},
        heardNoise = false,
        frozen = false,
        frozenTimer = 0,
        state = opts.state or "idle",
        lastSeen = nil,           -- {x, y}
        suspicion = 0,            -- how long they've seen you
        suspicionThreshold = 1.5,  -- time to enter ENGAGED
        stateTimer = 0,

        targetX = nil,
        targetY = nil, -- can be: idle, alert, search, etc

        patrolSpeed = 40,
        patrolA = { x = x - patrolDistance, y = y }, -- thanks chatgpt. byte. you knew ahead of time just what i needed.
        patrolB = { x = x + patrolDistance, y = y },
        patrolTarget = "B",

        angle = 0,
        swayTime = 0,
        swayOffset = 0,

        rotateTest = false,         -- toggle on for testing
        rotationSpeed = math.pi,    -- radians/sec (180°/sec)
        visionAngle = math.rad(60),   -- cone angle (60 deg)
        visionDistance = 200          -- how far enemy can see

    })

    alert_behavior.init(enemies.list[#enemies.list])
end

local function angleLerp(a, b, t)
    local diff = ((b - a + math.pi) % (2 * math.pi)) - math.pi
    return a + diff * t
end

local function smoothRotateToAngle(current, target, speed, dt)
    return angleLerp(current, target, math.min(speed * dt, 1))
end

function enemies.toggleVisionDebug()
    enemies.debugVision = not enemies.debugVision
    print("Enemy Vision Debug:", enemies.debugVision and "ON" or "OFF")
end

function enemies.investigate(x, y)
    for _, e in ipairs(enemies.list) do
        if e.state == "idle" then
            local dx = x - (e.x + e.width / 2)
            local dy = y - (e.y + e.height / 2)
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < 200 then -- hearing range
                e.state = "investigate"
                e.targetX = x
                e.targetY = y
                e.stateTimer = 0
            end
        end
    end
end

function enemies.update(dt)
    -- update each enemy
for _, e in ipairs(enemies.list) do
    e.swayTime = e.swayTime + dt
    e.swayOffset = math.sin(e.swayTime * 2) * 2

    enemy_behavior.update(e, dt)

    if e.rotateTest and e.state == "patrol" then
        e.angle = (e.angle + e.rotationSpeed * dt) % (2 * math.pi)
    end
        if e.speak then
        e.speak.timer = e.speak.timer - dt
        if e.speak.timer <= 0 then
            e.speak = nil
        end
    end
    
        -- patrol logic
        if e.state == "patrol" then
            local target = (e.patrolTarget == "A") and e.patrolA or e.patrolB
            local dx = target.x - e.x
            local dy = target.y - e.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 2 then
                local dirX = dx / dist
                local dirY = dy / dist

                e.x = e.x + dirX * e.patrolSpeed * dt
                e.y = e.y + dirY * e.patrolSpeed * dt

                if not e.rotateTest then
                    local targetAngle = math.atan2(dirY, dirX)
                    e.angle = smoothRotateToAngle(e.angle, targetAngle, e.rotationSpeed or 2, dt)
                end
            else
                e.patrolTarget = (e.patrolTarget == "A") and "B" or "A"
            end
        end
    end
end


function enemies.draw()
    for _, e in ipairs(enemies.list) do
        local cx = e.x + e.width / 2
        local cy = e.y + e.height / 2

        -- draw FOV cone in world space
        if enemies.debugVision then
            local fov = e.visionAngle or math.rad(60)
            local dist = e.visionDistance or 200
            local segments = 24

            local verts = { cx, cy }
            for i = 0, segments do
                local angle = e.angle - fov / 2 + (i / segments) * fov
                local x = cx + math.cos(angle) * dist
                local y = cy + math.sin(angle) * dist
                table.insert(verts, x)
                table.insert(verts, y)
            end

            love.graphics.setColor(1, 1, 0, 0.2)
            love.graphics.polygon("fill", verts)
        end

        if e.dead then
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(e.angle or 0)
            love.graphics.rectangle("fill", -e.width / 2, -e.height / 4, e.width, e.height / 2)
            love.graphics.pop()
            goto continue
        end

        -- draw enemy body with rotation + sway
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(e.angle or 0)
        love.graphics.setColor(e.color)
        love.graphics.rectangle("fill", -e.width / 2, -e.height / 2, e.width, e.height)
        love.graphics.pop()

        if e.speak then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(e.speak.text, e.x, e.y - 40)
        end

        if enemies.debugVision and e.patrolA and e.patrolB then
            love.graphics.setColor(0, 1, 1)
            love.graphics.circle("fill", e.patrolA.x, e.patrolA.y, 4)
            love.graphics.circle("fill", e.patrolB.x, e.patrolB.y, 4)
            love.graphics.line(e.patrolA.x, e.patrolA.y, e.patrolB.x, e.patrolB.y)
        end

        -- draw state label above
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(e.state or "???", e.x, e.y - 20)

        if e.voiceLineTimer and e.voiceLineTimer < 0.5 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("...", e.x, e.y - 32)
        end

        ::continue::

        -- draw heard noise circle (optional)
        if e.heardNoise then
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("line", cx, cy, 40)
        end
    end

    love.graphics.setColor(1, 1, 1) -- reset
end

return enemies
