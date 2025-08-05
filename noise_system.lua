-- noise_system.lua

local noise_system = {}
noise_system.events = {}

noise_system.debug = false

function noise_system.toggleDebug()
    noise_system.debug = not noise_system.debug
    print("Noise Debug:", noise_system.debug and "ON" or "OFF")
end

function noise_system.emit(x, y, radius, opts)
    if type(opts) ~= "table" then opts = {} end

    table.insert(noise_system.events, {
        x = x,
        y = y,
        radius = radius,
        loud = opts.loud or (radius >= 200), -- fallback to radius logic
        time = 0,
        maxTime = 0.5
    })
end


function noise_system.update(dt)
    for i = #noise_system.events, 1, -1 do
        local n = noise_system.events[i]
        n.time = n.time + dt
        if n.time >= n.maxTime then
            table.remove(noise_system.events, i)
        end
    end
end

function noise_system.draw()
    if not noise_system.debug then return end -- 🔥 this line matters!

    for _, n in ipairs(noise_system.events) do
        local alpha = 1 - (n.time / n.maxTime)
        love.graphics.setColor(1, 1, 0, alpha)
        love.graphics.circle("line", n.x, n.y, n.radius)
    end

    love.graphics.setColor(1, 1, 1)
end

function noise_system.getEvents()
    return noise_system.events
end

return noise_system
