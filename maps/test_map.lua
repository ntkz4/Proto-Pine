return {
    name = "Test Map",
    width = 700,
    height = 500,
    color = {0.3, 0.3, 0.3},

    items = {
        { id = "bottle", x = 200, y = 200 },
        { id = "bottle", x = 300, y = 250 },
        -- add more if you want
    },
    walls = {
        { x = 100, y = 100, w = 200, h = 32, material = "wood", breakable = false },
        { x = 400, y = 200, w = 32, h = 150, material = "glass", breakable = true },
    },
    enemies = {
        {
            x = 600, y = 300,
            state = "patrol",
            patrolA = { x = 550, y = 300 },
            patrolB = { x = 650, y = 300 }
        },
        {
            x = 700, y = 400,
            state = "patrol",
            patrolA = { x = 700, y = 380 },
            patrolB = { x = 700, y = 420 }
        }
    }
}
