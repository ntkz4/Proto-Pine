-- player.lua

local player = {}
local camera = require("camera")
local map = require("map_loader")
local world_items = require("world_items")
local enemies =  require("enemies")

player.x = 50
player.y = 50
player.width = 32
player.height = 32
player.speedTiers = {
    { name = "Crouch",   speed = 40,  noise = 10 },
    { name = "Walk",    speed = 90, noise = 20 },
    { name = "Run",     speed = 140, noise = 50 },
    { name = "Sprint",  speed = 200, noise = 80 },
    { name = "BOOH 💀", speed = 280, noise = 120 },
}
player.speedTierIndex = 2 -- default: "Walk"
player.footstepTimer = 0
player.footstepCooldown = 0.5 -- dynamically changes per tier
player.currentWeapon = nil
player.heldItem = nil -- id of the item being held
player.ammo = {
    reserve = 999999999,
}

function player.load()
-- this part load sprites, animations later.
end

function player.update(dt)
    local moveX, moveY = 0, 0

    -- controls movement
    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end

    -- normalize diagonal movement
    if moveX ~= 0 and moveY ~= 0 then
        local len = math.sqrt(moveX^2 + moveY^2)
        moveX, moveY = moveX / len, moveY / len
    end

    local sprinting = love.keyboard.isDown("lshift")
    local tierIndex = sprinting and #player.speedTiers or player.speedTierIndex
    local tier = player.speedTiers[tierIndex]

    local moveSpeed = tier.speed
    local moveNoise = tier.noise

    -- get movement input
    local moving = (moveX ~= 0 or moveY ~= 0)

    -- wall collision
    local newX = player.x + moveX * moveSpeed * dt
    local newY = player.y + moveY * moveSpeed * dt

    local centerX = newX + player.width / 2
    local centerY = newY + player.height / 2
    local collides = require("walls").collides(centerX, centerY)

    if not collides then
        player.x = newX
        player.y = newY
    end

    -- footsteps
    if moving and moveNoise > 0 then
        player.footstepTimer = player.footstepTimer - dt
        local stepRate = math.max(0.1, 0.8 - (moveSpeed / 300)) -- faster = lower interval

        if player.footstepTimer <= 0 then
            player.footstepTimer = stepRate

            -- emit footstep noise
            require("noise_system").emit(
                player.x + player.width / 2,
                player.y + player.height / 2,
                moveNoise, -- footsteps use tier noise radius
                { loud = false }
            )
        end
    else
        player.footstepTimer = 0 -- reset when not moving
    end

    -- rotate towards mouse
    local mouseX, mouseY = love.mouse.getPosition()
    local screenCenterX = player.x - camera.x + player.width / 2
    local screenCenterY = player.y - camera.y + player.height / 2
    local dx = mouseX - screenCenterX
    local dy = mouseY - screenCenterY
    player.angle = math.atan2(dy, dx)
end

function player.draw()
    love.graphics.setColor(1,1,1) -- white

    -- draw rotated around center
    love.graphics.push()
    love.graphics.translate(player.x + player.width / 2, player.y + player.height / 2)
    love.graphics.rotate(player.angle)
    love.graphics.rectangle("fill", -player.width / 2, -player.height / 2, player.width, player.height)
    love.graphics.pop()
end

function player.keypressed(key)
    if key == "e" and not player.heldItem then
        local map = require("map_loader").get()
        local world_items = require("world_items")
        if map and map.items then
            for i = #map.items, 1, -1 do
                local item = map.items[i]
                local def = world_items.get(item.id)
                local dx = (player.x + player.width/2) - (item.x + (def.width or 8)/2)
                local dy = (player.y + player.height/2) - (item.y + (def.height or 8)/2)
                local dist = math.sqrt(dx*dx + dy*dy)

                if dist <= 32 then
                    player.heldItem = item.id
                    table.remove(map.items, i)
                    break
                end
            end
        end
    end

    if key == "k" then
        for _, e in ipairs(enemies.list) do
            if not e.dead then
                -- Optional: only kill the *closest* one
                local px = require("player").x
                local py = require("player").y
                local dist = math.sqrt((e.x - px)^2 + (e.y - py)^2)
                if dist < 50 then -- close range
                    e.dead = true
                    e.state = "dead"
                    e.color = {0.2, 0.2, 0.2}
                    e.speak = { text = "Guh...", timer = 1 }
                    print("Guard executed.")
                    break -- only kill one
                end
            end
        end
    end
end


function player.mousepressed(x, y, button)
    if button == 1 and player.heldItem then
        local worldX = x + camera.x
        local worldY = y + camera.y

        local px = player.x + player.width / 2
        local py = player.y + player.height / 2

        local dx = worldX - px
        local dy = worldY - py
        local dist = math.sqrt(dx*dx + dy*dy)

        local minSpeed, maxSpeed = 150, 500
        local throwSpeed = math.min(maxSpeed, math.max(minSpeed, dist * 2))
        local angle = math.atan2(dy, dx)

        require("throwables").spawn(player.heldItem, px, py, angle, throwSpeed)
        player.heldItem = nil-- left click
    elseif button == 2 then -- right click
        player.dropItem()
    end
end

function player.wheelmoved(x, y)
    if y > 0 then
        player.speedTierIndex = math.min(#player.speedTiers, player.speedTierIndex + 1)
    elseif y < 0 then
        player.speedTierIndex = math.max(1, player.speedTierIndex - 1)
    end

    local tier = player.speedTiers[player.speedTierIndex]
    print("Movement Mode:", tier.name)
end


return player

