return {
    Cost = 50,
    DisplayName = "Carrot Seed",
    Icon = "rbxassetid://109414843021135",

    ServerData = {
        CurrentStock = 10,
        MaxStock = 15,
        getRandomStock = function()
            return math.random(1,3)
        end,
    }
}