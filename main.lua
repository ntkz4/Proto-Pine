-- main.lua

local player = require("player")
local camera = require("camera")
local world_items = require("world_items")
local bullet = require("bullet")
local hud = require("hud")
local weapons = require("weapons")
local loadout = require("loadout")
local map = require("map_loader")
local walls = require("walls")
local throwables = require("throwables")
local noise_system = require("noise_system")
local enemies = require("enemies")

function love.load()
    map.load("test_map") -- loads maps/test_map.lua
    player.load()
    camera.load()
    world_items.load()
    weapons.load()

    loadout.initDefault() -- or remove for blank loadout
    player.currentWeapon = loadout.get("primary")
end

function love.update(dt)
    player.update(dt)
    throwables.update(dt)
    camera.update(player.x, player.y)
    bullet.update(dt)
    noise_system.update(dt)
    enemies.update(dt)

end

function love.draw()
    camera.attach()
        map.draw()
        walls.draw()
        player.draw()
        bullet.draw()
        throwables.draw()
        noise_system.draw()
        enemies.draw()
    camera.detach()

    hud.draw(player)
end

function love.keypressed(key)
    player.keypressed(key)

    if key == 'r' then
    weapons.reload(player)
    elseif key == "h" then
    require("noise_system").toggleDebug()
    require("enemies").toggleVisionDebug()
    end
end

function love.mousepressed(x, y, button)
    player.mousepressed(x, y, button)
    
    if button == 1 then
        weapons.fire(player)
    elseif button == 2 then
        player.dropItem()
    end
end

function love.wheelmoved(x, y)
    player.wheelmoved(x, y)
end






