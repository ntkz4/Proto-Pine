-- weapons.lua

local weapons = {}
local registered = {}
local noise = require("noise_system")

local function loadWeaponsFromFolder(folder)
    local lfs = love.filesystem
    if not lfs.getInfo(folder, "directory") then return end

    for _, file in ipairs(lfs.getDirectoryItems(folder)) do
        if file:match("%.lua$") then
            local id = file:gsub("%.lua$", "")
            local path = folder .. "/" .. id
            local success, weapon = pcall(require, path)

            if success and type(weapon) == "table" then
                table.insert(weapons.all, weapon)
                weapons.by_id[weapon.id or id] = weapon
            else
                print("Failed to load weapon: " .. path)
            end
        end
    end
end

function weapons.load()
    local files = love.filesystem.getDirectoryItems("weapons")
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local name = file:gsub("%.lua$", "")
            registered[name] = require("weapons." .. name)
        end
    end
end

function weapons.get(name)
    return registered[name]
end

function weapons.fire(player)
    local w = player.currentWeapon
    if not w then return end

    -- init ammo tracking if needed
    if not player.ammo.current then
        player.ammo.current = w.magazineSize or 12
    end

    if player.ammo.current <= 0 then
        print("Click! no ammo")
        return
    end

    player.ammo.current = player.ammo.current - 1

    local cx = player.x + player.width / 2
    local cy = player.y + player.height / 2

    require("bullet").spawn(cx, cy, player.angle, {
        speed = w.bulletSpeed,
        damage = w.damage,
        length = w.bulletLength or 24,
        life = w.bulletLife or 1,
        color = w.bulletColor or {1, 0.8, 0.2},
        piercing = w.piercing or false
    })

    local noise = require("noise_system")
    if player.currentWeapon and player.currentWeapon.fireNoise then
        noise.emit(
            player.x + player.width / 2,
            player.y + player.height / 2,
            player.currentWeapon.fireNoise,
            { loud = (player.currentWeapon.fireNoise >= 200) } -- 🔥 important
        )
    end
end

function weapons.reload(player)
	 local magSize = player.currentWeapon.magazineSize
        local needed = magSize - player.ammo.current
        local canLoad = math.min(needed, player.ammo.reserve)

        player.ammo.current = player.ammo.current + canLoad
        player.ammo.reserve = player.ammo.reserve - canLoad

    if player.currentWeapon and player.currentWeapon.reloadNoise then
        noise.emit(
            player.x + player.width / 2,
            player.y + player.height / 2,
            player.currentWeapon.reloadNoise,
            { loud = false } -- quiet by design
        )
    end
end

function weapons.drawDebug(x, y)
    for _, weapon in ipairs(weapons.all) do
        love.graphics.print(weapon.name or weapon.id, x, y)
        y = y + 20
    end
end

return weapons
