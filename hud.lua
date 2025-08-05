local hud = {}

local camera = require("camera")

function hud.draw(player)
    -- get player center in screen coordinates
    local screenPlayerX = player.x - camera.x + player.width / 2
    local screenPlayerY = player.y - camera.y + player.height / 2

    -- get mouse position (already in screen coords)
    local mouseX, mouseY = love.mouse.getPosition()

    -- draw ammo info if weapon exists
    love.graphics.setColor(1, 1, 1)
    local hudY = love.graphics.getHeight() - 40

    if player.currentWeapon then
        local magSize = player.currentWeapon.magazineSize or 0
        local current = player.ammo.current or 0
        local reserve = player.ammo.reserve or 0
        local weaponName = player.currentWeapon.name or "???"

        local ammoText = string.format("%s | Ammo: %d / %d", weaponName, current, reserve)
        love.graphics.print(ammoText, 20, hudY)
        hudY = hudY + 20 -- offset for next line
    end

    love.graphics.print("Holding: " .. (player.heldItem or "Nothing"), 20, hudY)

    -- movement status
local tier = player.speedTiers[
    love.keyboard.isDown("lshift") and #player.speedTiers or player.speedTierIndex
]
love.graphics.print("Speed: " .. tier.name, 20, 100)


    -- draw green line from player to mouse
    love.graphics.setColor(0, 1, 0)
    love.graphics.setLineWidth(1)
    love.graphics.line(screenPlayerX, screenPlayerY, mouseX, mouseY)

    -- reset color
    love.graphics.setColor(1, 1, 1)
end

return hud
