--[[=========================================================
    Haja UI · Example Script
    Shows every element + both config saving and notifications.
=========================================================]]

local Haja = loadstring(game:HttpGet("https://raw.githubusercontent.com/goofinator654-wq/Haja/main/haja.lua"))()

local Window = Haja:CreateWindow({
    Title      = "Haja Hub",
    SubTitle   = "v1.0 · Premium UI",
    Theme      = "Midnight",      -- "Midnight" | "Obsidian" | "Aurora"
    SaveCfgKey = "haja_demo",     -- optional; enables config saving
    Logo       = "rbxassetid://10723407389",
})

local Main    = Window:CreateTab("Main",    "rbxassetid://3926307971")
local Visuals = Window:CreateTab("Visuals", "rbxassetid://3926309567")
local Misc    = Window:CreateTab("Misc",    "rbxassetid://3926311105")

--=============================================================
-- MAIN
--=============================================================
Main:CreateSection("Combat")

Main:CreateToggle({
    Name     = "Kill Aura",
    Flag     = "killaura",
    Default  = false,
    Callback = function(v)
        print("[Haja] Kill Aura:", v)
    end,
})

Main:CreateSlider({
    Name     = "Attack Speed",
    Min      = 1,
    Max      = 50,
    Default  = 10,
    Suffix   = "x",
    Flag     = "attack_speed",
    Callback = function(v)
        print("[Haja] Attack Speed:", v)
    end,
})

Main:CreateDropdown({
    Name     = "Target Priority",
    Options  = { "Closest", "Lowest HP", "Highest HP", "Random" },
    Default  = "Closest",
    Flag     = "target_priority",
    Callback = function(opt)
        print("[Haja] Target mode:", opt)
    end,
})

Main:CreateSection("Movement")

Main:CreateSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 300,
    Default  = 16,
    Suffix   = " st/s",
    Flag     = "walkspeed",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Main:CreateButton({
    Name     = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

--=============================================================
-- VISUALS
--=============================================================
Visuals:CreateSection("Appearance")

Visuals:CreateToggle({
    Name     = "Fullbright",
    Flag     = "fullbright",
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = v and 3 or 1
        Lighting.ClockTime  = v and 14 or 12
        Lighting.FogEnd     = v and 1e6 or 500
        Lighting.GlobalShadows = not v
    end,
})

Visuals:CreateColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(124, 92, 255),
    Flag     = "esp_color",
    Callback = function(c)
        print("[Haja] ESP color set to", c)
    end,
})

Visuals:CreateParagraph({
    Title   = "About Visuals",
    Content = "These visual settings apply instantly. Colors persist between sessions when SaveCfgKey is set.",
})

--=============================================================
-- MISC
--=============================================================
Misc:CreateSection("Utility")

Misc:CreateKeybind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end,
})

Misc:CreateTextbox({
    Name        = "Custom Note",
    Placeholder = "Type something...",
    Flag        = "note",
    Callback    = function(text)
        print("[Haja] Note:", text)
    end,
})

Misc:CreateLabel({ Text = "Haja UI v" .. Haja.Version .. " · Made with <3" })

Misc:CreateButton({
    Name     = "Notify Test",
    Callback = function()
        Haja:Notify({
            Title    = "Hello!",
            Content  = "This is a Haja notification.",
            Duration = 4,
        })
    end,
})

--=============================================================
-- WELCOME
--=============================================================
Haja:Notify({
    Title    = "Haja UI loaded",
    Content  = "Thanks for using Haja — the cleanest UI library for Roblox.",
    Duration = 5,
})

Haja:Notify({
    Title    = Haja.IsMobile() and "Mobile mode" or "PC mode",
    Content  = Haja.IsMobile() and "Touch controls and mobile layout are active." or "Desktop layout with resizing is active.",
    Duration = 5,
})
