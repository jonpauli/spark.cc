if getgenv().VergilLibrary and type(getgenv().VergilLibrary) == "table" and getgenv().VergilLibrary.Exit then
    getgenv().VergilLibrary:Exit()
end

cloneref = cloneref or function(Object) return Object end

--#region Services
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))
--#endregion

local GetHui = gethui or function() return CoreGui end
local LocalPlayer = Players.LocalPlayer

Library = {
    Flags = { },
    SetFlags = { },
    MenuKeybind = tostring(Enum.KeyCode.RightShift),

    Directory = "Vergil",
    Folders = {
        Assets = "/Assets",
        Configs = "/Configs"
    },

    Name = "Vergil",
    FontSize = 12,
    FontUrl = "https://github.com/bluescan/proggyfonts/raw/master/ProggyOriginal/ProggyClean.ttf",

    Animation = {
        Time = 0.2,
        Style = "Quart",
        Direction = "Out",

        FadeTime = 0.4,
        FadeStyle = "Sine",
    },

    BlurEnabled = true,
    BlurSize = 12,
    SnowEnabled = true,
    SnowAmount = 90,

    Theme = {
        ["Background"]     = Color3.fromRGB(24, 24, 24),
        ["Window"]         = Color3.fromRGB(21, 21, 21),
        ["Hover"]          = Color3.fromRGB(32, 32, 32),
        ["Border"]         = Color3.fromRGB(36, 36, 35),
        ["Outline"]        = Color3.fromRGB(41, 41, 41),
        ["Button Outline"] = Color3.fromRGB(66, 66, 66),
        ["Text"]           = Color3.fromRGB(255, 255, 255),
        ["Dim Text"]       = Color3.fromRGB(175, 175, 175),
        ["Inactive Text"]  = Color3.fromRGB(121, 121, 120),
        ["Option Text"]    = Color3.fromRGB(113, 114, 115),
        ["Accent"]         = Color3.fromRGB(255, 163, 190),
        ["Element Accent"] = Color3.fromRGB(255, 193, 212),
    },

    Connections = { },
    Threads = { },
    Themed = { },
    OpenFrames = { },
    Floating = { },
    Landing = { },
    ShadowWanted = { },
    KeyList = nil,
    MenuOpen = true,
    Order = 0,
    Font = nil,
    Holder = nil,
    PopupHolder = nil,
    DragHolder = nil,
}
Library.__index = Library

local Flags = Library.Flags
local SetFlags = Library.SetFlags
local Theme = Library.Theme
local ConfigsFolder = Library.Directory .. Library.Folders.Configs

--#region Helpers
local StrokeInner = Enum.BorderStrokePosition.Inner

local function New(Class, Props)
    local Object = Instance.new(Class)
    Object.Name = "\0"

    if Object:IsA("GuiObject") then
        Object.BorderSizePixel = 0

        if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
            Object.FontFace = Library.Font
            Object.TextSize = Library.FontSize
            Object.TextColor3 = Theme.Text
