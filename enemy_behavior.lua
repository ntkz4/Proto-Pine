--enemies_behavior.lua

local behavior = {}
local alert_behavior = require("alert_behavior")

-- Interpolate between two angles (clockwise or counter-clockwise)
local function angleLerp(a, b, t)
    local diff = ((b - a + math.pi) % (2 * math.pi)) - math.pi
    return a + diff * t
end

-- Rotate toward a target angle with max angular speed (radians/sec)
local function smoothRotateToAngle(current, target, speed, dt)
    return angleLerp(current, target, math.min(speed * dt, 1))
end

local function hasLineOfSight(x1, y1, x2, y2)
    local walls = require("walls")
    return not walls.raycast(x1, y1, x2, y2)
end

function behavior.canSee(enemy, tx, ty)
    local ex = enemy.x + enemy.width / 2
    local ey = enemy.y + enemy.height / 2
    local dx = tx - ex
    local dy = ty - ey
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist > enemy.visionDistance then return false end

    local angleTo = math.atan2(dy, dx)
    local angleDiff = math.abs((angleTo - enemy.angle + math.pi) % (2 * math.pi) - math.pi)
    if angleDiff > (enemy.visionAngle / 2) then return false end

    return hasLineOfSight(ex, ey, tx, ty)
end

function behavior.update(enemy, dt)
    require("body_detection").checkForDeadBodies(enemy)
    local player = require("player")

    if behavior.canSee(enemy, player.x + player.width / 2, player.y + player.height / 2) then
        enemy.lastSeen = { x = player.x + player.width / 2, y = player.y + player.height / 2 }
        enemy.state = "alert"
        enemy.color = {1, 1, 0}
    end

    -- 🧊 FROZEN in place — shocked from loud sound
    if enemy.frozen then
        enemy.frozenTimer = enemy.frozenTimer - dt

        -- 🧭 Rotate toward frozen angle
        if enemy.facingNoiseAngle then
            enemy.desiredAngle = enemy.facingNoiseAngle
        end

        if enemy.desiredAngle then
            enemy.angle = smoothRotateToAngle(enemy.angle, enemy.desiredAngle, enemy.rotationSpeed or math.rad(180), dt)
        end

        if enemy.frozenTimer <= 0 then
            enemy.frozen = false
            enemy.facingNoiseAngle = nil
            enemy.desiredAngle = nil
            enemy.state = "investigate"

            -- 🧭 Go toward noise source (if saved)
            if enemy.noiseTarget then
                enemy.targetX = enemy.noiseTarget.x
                enemy.targetY = enemy.noiseTarget.y
                enemy.noiseTarget = nil
            else
                enemy.targetX = enemy.lastSeen and enemy.lastSeen.x or enemy.x
                enemy.targetY = enemy.lastSeen and enemy.lastSeen.y or enemy.y
            end

            enemy.color = {1, 1, 0}
        end
        return
    end

    -- 🧠 Can see player?
    local function canSeePlayer(e)
        local ex = e.x + e.width / 2
        local ey = e.y + e.height / 2
        local px = player.x + player.width / 2
        local py = player.y + player.height / 2
        local dx, dy = px - ex, py - ey
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > e.visionDistance then return false end
        local angleToPlayer = math.atan2(dy, dx)
        local angleDiff = math.abs((angleToPlayer - e.angle + math.pi) % (2 * math.pi) - math.pi)
        if angleDiff > (e.visionAngle / 2) then return false end
        if require("walls").raycast(ex, ey, px, py) then return false end
        return true
    end

    -- 🧠 Perception Check
    if canSeePlayer(enemy) then
        local px = player.x + player.width / 2
        local py = player.y + player.height / 2
        enemy.lastSeen = { x = px, y = py }
        enemy.suspicion = (enemy.suspicion or 0) + dt

    if enemy.suspicion >= enemy.suspicionThreshold then
        if enemy.state ~= "engaged" then
            enemy.state = "engaged"
            enemy.color = {1, 0, 0}
            enemy.engagedTimer = 0
            enemy.maxEngagedTime = math.random(120, 180)
        end
        elseif enemy.state == "idle" or enemy.state == "investigate" then
            enemy.state = "alert"
            enemy.color = {1, 1, 0}
        end
    else
        if (enemy.state == "idle" or enemy.state == "investigate") and enemy.lastSeen then
            enemy.state = "investigate"
            enemy.targetX = enemy.lastSeen.x
            enemy.targetY = enemy.lastSeen.y
            enemy.suspicion = 0
            enemy.color = {1, 0.5, 0}
        end
    end

    -- 👂 Noise reaction system (now runs in ALL states + always re-evaluates loud sounds)
    for _, noise in ipairs(require("noise_system").getEvents()) do
        local ex = enemy.x + enemy.width / 2
        local ey = enemy.y + enemy.height / 2
        local dx, dy = noise.x - ex, noise.y - ey
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist <= noise.radius and not enemy.dead and not enemy.frozen then
            -- engaged guards DO hear, but don’t switch state
            if enemy.state == "engaged" then
                if noise.loud then
                    -- 👂 use sound to reinforce position
                    enemy.targetX = noise.x
                    enemy.targetY = noise.y
                    enemy.speak = { text = "I heard that!", timer = 1.5 }
                    -- 🧠 keep in engaged, don’t freeze
                end
                -- ignore quiet noise
            elseif not enemy.heardNoise then
                if noise.loud then
                    -- 🧊 freeze them if not already in combat
                    enemy.frozen = true
                    enemy.frozenTimer = 0.8
                    enemy.state = "idle"
                    enemy.speak = { text = "What the...", timer = 2 }
                    enemy.color = {1, 0.8, 0.3}
                    enemy.facingNoiseAngle = math.atan2(dy, dx)
                    enemy.noiseTarget = { x = noise.x, y = noise.y }
                else
                    enemy.state = "investigate"
                    enemy.targetX = noise.x
                    enemy.targetY = noise.y
                    enemy.stateTimer = 0
                end
            end
        end
    end


    -- 🚦 FSM
    if enemy.state == "idle" then
        enemy.desiredAngle = nil

        elseif enemy.state == "patrol" then
        local target = enemy.patrolTarget == "A" and enemy.patrolA or enemy.patrolB
        local dx = target.x - enemy.x
        local dy = target.y - enemy.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 2 then
            local dirX = dx / dist
            local dirY = dy / dist
            enemy.x = enemy.x + dirX * (enemy.patrolSpeed or 40) * dt
            enemy.y = enemy.y + dirY * (enemy.patrolSpeed or 40) * dt
            enemy.desiredAngle = math.atan2(dirY, dirX)
        else
            -- Switch to next patrol point
            enemy.patrolTarget = enemy.patrolTarget == "A" and "B" or "A"
        end

    elseif enemy.state == "investigate" then
        local dx = enemy.targetX - enemy.x
        local dy = enemy.targetY - enemy.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 2 then
            local dirX = dx / dist
            local dirY = dy / dist
            enemy.x = enemy.x + dirX * 30 * dt
            enemy.y = enemy.y + dirY * 30 * dt
            enemy.desiredAngle = math.atan2(dirY, dirX)
        else
            enemy.stateTimer = (enemy.stateTimer or 0) + dt
            if enemy.stateTimer > 1.5 then
                enemy.state = "alert"
                enemy.targetX, enemy.targetY = nil, nil
                enemy.stateTimer = 0
                enemy.color = {1, 1, 0}
                enemy.heardNoise = false
                enemy.desiredAngle = nil
            end
        end

    elseif enemy.state == "alert" then
        if enemy.lastSeen then
            local dx = enemy.lastSeen.x - enemy.x
            local dy = enemy.lastSeen.y - enemy.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local dirX = dx / dist
            local dirY = dy / dist

            if dist > 4 then
                enemy.x = enemy.x + dirX * 40 * dt
                enemy.y = enemy.y + dirY * 40 * dt
            end

            enemy.desiredAngle = math.atan2(dirY, dirX)
        end

        alert_behavior.update(enemy, dt)

    elseif enemy.state == "engaged" then
        -- ⏳ Track how long since they last saw player
        if canSeePlayer(enemy) then
            enemy.timeSinceSeen = 0
        else
            enemy.timeSinceSeen = (enemy.timeSinceSeen or 0) + dt
        end

        -- ⏱️ Calm down after timer or if they lose sight long enough
        if enemy.timeSinceSeen and enemy.timeSinceSeen > 3 then
            enemy.state = "search"
            enemy.searchOrigin = { x = enemy.x, y = enemy.y }
            enemy.targetX = enemy.lastSeen and enemy.lastSeen.x or enemy.x
            enemy.targetY = enemy.lastSeen and enemy.lastSeen.y or enemy.y
            enemy.desiredAngle = nil
            enemy.color = {1, 0.8, 0.2}
            print("[Guard] Lost sight! Searching last known area...")
            return
        end

        -- chase player
        local px = player.x + player.width / 2
        local py = player.y + player.height / 2
        local dx = px - enemy.x
        local dy = py - enemy.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 2 then
            local dirX = dx / dist
            local dirY = dy / dist
            enemy.x = enemy.x + dirX * 60 * dt
            enemy.y = enemy.y + dirY * 60 * dt
            enemy.desiredAngle = math.atan2(dirY, dirX)
        end

    elseif enemy.state == "search" then
        if not enemy.searchTimer then
            enemy.searchTimer = 0
            enemy.searchDuration = 3 + math.random() * 2 -- 3–5 seconds
        end

        enemy.searchTimer = enemy.searchTimer + dt

        -- slowly spin/look around while standing
        if enemy.searchTimer % 1 < dt then
            local jitter = math.rad(math.random(-40, 40))
            enemy.desiredAngle = (enemy.angle or 0) + jitter
        end

        if enemy.searchTimer >= enemy.searchDuration then
            enemy.state = "alert"
            enemy.searchTimer = nil
            enemy.searchDuration = nil
            enemy.color = {1, 1, 0}
            print("[Guard] Couldn't find target. Back to alert.")
        end
    end -- ✅ this `end` closes the big FSM block

    -- 🔁 Global rotation
    if enemy.desiredAngle then
        enemy.angle = smoothRotateToAngle(
            enemy.angle,
            enemy.desiredAngle,
            enemy.rotationSpeed or math.rad(180),
            dt
        )
    end
end

return behavior
