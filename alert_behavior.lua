-- alert_behavior.lua
local alert = {}

function alert.init(enemy)
    enemy.alertTimer = 0
    enemy.lookAroundTimer = 0
    enemy.voiceLineTimer = math.random(2, 5)
end

function alert.update(enemy, dt)
    enemy.alertTimer = enemy.alertTimer + dt
    enemy.lookAroundTimer = enemy.lookAroundTimer + dt
    enemy.voiceLineTimer = enemy.voiceLineTimer - dt

    -- 👀 Look around randomly
    if enemy.lookAroundTimer > 2 then
        local jitter = math.rad(math.random(-45, 45))
        enemy.desiredAngle = (enemy.desiredAngle or enemy.angle) + jitter
        enemy.lookAroundTimer = 0
    end

    -- 💬 Voice lines (can be sound effects later)
    if enemy.voiceLineTimer <= 0 then
        local lines = {
            "I saw something!",
            "Stay sharp...",
            "Where'd they go?",
            "Eyes open!",
            "Check that corner!"
        }
        print("[Guard]: " .. lines[math.random(#lines)])
        enemy.voiceLineTimer = math.random(3, 6)
    end

    -- 🚶 Small pacing movement (optional flavor)
    if math.random() < 0.01 then
        local step = 8
        local dir = math.random() * 2 * math.pi
        enemy.x = enemy.x + math.cos(dir) * step
        enemy.y = enemy.y + math.sin(dir) * step
    end
end

return alert
