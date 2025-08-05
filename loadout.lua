-- loadout.lua

local loadout = {
    primary = nil,      -- like rifles
    secondary = nil,    -- like pistols
    gadget1 = nil,      -- like medkits
    gadget2 = nil,
    gadget3 = nil
}

function loadout.set(slot, item)
    if loadout[slot] ~= nil then
        print("Replacing existing item in " .. slot)
    end
    loadout[slot] = item
end

function loadout.get(slot)
    return loadout[slot]
end

function loadout.clear()
    loadout.primary = nil
    loadout.secondary = nil
    loadout.gadget1 = nil
    loadout.gadget2 = nil
    loadout.gadget3 = nil
end

function loadout.initDefault()
    -- temp setup for testing
    loadout.primary = require("weapons.m1911")
    loadout.secondary = nil
    loadout.gadget1 = nil
    loadout.gadget2 = nil
    loadout.gadget3 = nil
end

return loadout
