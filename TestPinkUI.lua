--[[
    TestPinkUI.lua

    demo script for PinkUI -- it loads the library, builds a window, a watermark,
    a keybind list and a handful of every element so you can check the finished
    product, including the config window and the ui settings window that sit to
    the right of the main window.

    how to run from github:
        1. put PinkUI.lua and this file in a public repo
        2. paste the raw link of PinkUI.lua into RAW_URL below
        3. run: loadstring(game:HttpGet("<raw link of TestPinkUI.lua>"))()

    how to run locally:
        set RAW_URL to "" and keep PinkUI.lua in the executor's workspace folder
]]

-- raw link to PinkUI.lua
-- leave it as "" to load the library from the executor's workspace folder
local RAW_URL = "https://raw.githubusercontent.com/jonpauli/spark.cc/refs/heads/main/PinkUI.lua"

-- libraries are fetched with a cache buster, otherwise the raw cdn can serve an
-- old copy for a few minutes after you push and the old bugs come back
local function FreshUrl(Url)
    local Separator = Url:find("?", 1, true) and "&" or "?"
    return Url .. Separator .. "v=" .. tostring(os.time()) .. tostring(math.random(100, 999))
end

local function LooksLikePinkUI(Source)
    return type(Source) == "string" and #Source > 1000 and Source:find("VergilLibrary", 1, true) ~= nil
end

local Library = getgenv().VergilLibrary
local LoadError = nil

if type(Library) ~= "table" or type(Library.InitWindow) ~= "function" then
    local Reader = nil

    if RAW_URL ~= "" then
        local Url = FreshUrl(RAW_URL)

        Reader = function()
            return game:HttpGet(Url)
        end
    elseif isfile and isfile("PinkUI.lua") then
        Reader = function()
            return readfile("PinkUI.lua")
        end
    end

    if not Reader then
        LoadError = "no RAW_URL set and no PinkUI.lua in the executor workspace"
    else
        local Ok, Source = pcall(Reader)

        if not Ok then
            LoadError = "could not download PinkUI.lua: " .. tostring(Source)
        elseif not LooksLikePinkUI(Source) then
            LoadError = "PinkUI.lua came back empty or as an error page"
        else
            local Chunk, CompileError = loadstring(Source)

            if not Chunk then
                LoadError = "PinkUI.lua did not compile: " .. tostring(CompileError)
            else
                local Ran, Result = pcall(Chunk)

                if not Ran then
                    LoadError = "PinkUI.lua failed to run: " .. tostring(Result)
                elseif type(Result) == "table" then
                    Library = Result
                else
                    Library = getgenv().VergilLibrary
                end
            end
        end
    end
end

if type(Library) ~= "table" then
    error("[PinkUI] " .. tostring(LoadError or "library not loaded"), 0)
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local function Humanoid()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChildOfClass("Humanoid") or nil
end

local function Build()
    -- window
    local Window = Library:Window({
        Name = "PinkUI",
        Rank = "test",
        Size = UDim2.fromOffset(498, 598),
    })

    -- extras (created before InitWindow so their toggles show up in settings)
    Library:Watermark({ Name = "PinkUI", SubName = "demo" })
    Library:KeybindList({ Name = "keybinds" })

    -- pages
    local MainPage = Window:Page({ Name = "main" })
    local VisualPage = Window:Page({ Name = "visuals" })

    local Movement = MainPage:Section({ Name = "movement", Side = 1 })
    local Actions = MainPage:Section({ Name = "actions", Side = 2 })
    local Visuals = VisualPage:Section({ Name = "esp", Side = 1 })
    local World = VisualPage:Section({ Name = "world", Side = 2 })

    -- movement
    local Speed = Movement:Toggle({
        Name = "speed hack",
        Flag = "speed",
        Default = true,
        Callback = function(Value)
            Library:Notification({ Name = "speed hack " .. (Value and "on" or "off") })

            local HumanoidInstance = Humanoid()
            if HumanoidInstance then
                HumanoidInstance.WalkSpeed = Value and 60 or 16
            end
        end
    })

    Speed:Keybind({ Name = "speed hack", Flag = "speed_bind", Default = Enum.KeyCode.LeftAlt })

    Movement:Toggle({
        Name = "infinite jump",
        Flag = "infjump",
        Callback = function(Value)
            Library:Notification({ Name = "infinite jump " .. (Value and "on" or "off") })
        end
    })

    Movement:Slider({
        Name = "walk speed",
        Flag = "walkspeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Decimals = 1,
        Callback = function(Value)
            local HumanoidInstance = Humanoid()
            if HumanoidInstance then
                HumanoidInstance.WalkSpeed = Value
            end
        end
    })

    Movement:Dropdown({
        Name = "teleport mode",
        Flag = "telemode",
        Items = { "walk", "click", "instant" },
        Default = "walk",
        Callback = function(Value)
            Library:Notification({ Name = "teleport mode: " .. tostring(Value) })
        end
    })

    Movement:Textbox({
        Name = "jump power",
        Flag = "jumppower",
        Placeholder = "50",
        Numeric = true,
        Default = "50",
        Callback = function(Value)
            local HumanoidInstance = Humanoid()
            if HumanoidInstance then
                HumanoidInstance.JumpPower = tonumber(Value) or 50
            end
        end
    })

    -- actions
    Actions:Button({
        Name = "notify me",
        Callback = function()
            Library:Notification({ Name = "hello from PinkUI", Time = 4 })
        end
    })

    Actions:Button({
        Name = "center window",
        Callback = function()
            Window:Center()
            Library:Notification({ Name = "window centered", Time = 3 })
        end
    })

    Actions:Label({ Name = "label with a color picker" }):Colorpicker({
        Flag = "label_color",
        Default = Color3.fromRGB(255, 163, 190),
        Callback = function(Color)
            Library:Notification({ Name = "label color #" .. Color:ToHex(), Time = 3 })
        end
    })

    -- visuals
    local Esp = Visuals:Toggle({
        Name = "player esp",
        Flag = "esp",
        Default = true,
        Callback = function(Value)
            Library:Notification({ Name = "esp " .. (Value and "on" or "off") })
        end
    })

    Esp:Colorpicker({
        Flag = "esp_color",
        Default = Color3.fromRGB(255, 163, 190),
        Callback = function(Color)
            Library:Notification({ Name = "esp color #" .. Color:ToHex(), Time = 2 })
        end
    })

    Visuals:Slider({
        Name = "max distance",
        Flag = "esp_dist",
        Min = 50,
        Max = 2000,
        Default = 500,
        Decimals = 1,
        Callback = function() end
    })

    Visuals:Dropdown({
        Name = "box style",
        Flag = "box",
        Items = { "2d", "3d", "corner" },
        Default = "2d",
        Callback = function() end
    })

    -- world (the callback also runs while building, so only touch lighting when on)
    local OriginalBrightness = Lighting.Brightness
    local OriginalAmbient = Lighting.Ambient

    World:Toggle({
        Name = "fullbright",
        Flag = "fullbright",
        Callback = function(Value)
            if Value then
                Lighting.Brightness = 3
                Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            else
                Lighting.Brightness = OriginalBrightness
                Lighting.Ambient = OriginalAmbient
            end
        end
    })

    World:Button({
        Name = "unload ui",
        Callback = function()
            Lighting.Brightness = OriginalBrightness
            Lighting.Ambient = OriginalAmbient
            Library:Exit()
        end
    })

    -- builds the settings page plus the config window and the ui settings window
    Library:InitWindow()
end

local Ok, Err = xpcall(Build, debug.traceback)

if not Ok then
    warn("[PinkUI] test script failed:\n" .. tostring(Err))

    pcall(function()
        Library:Notification({ Name = "test failed, check the console", Time = 8 })
    end)

    return
end

Library:Notification({ Name = "loaded, right shift toggles the menu", Time = 5 })
Library:Notification({ Name = "config + ui settings are on the right", Time = 5 })
