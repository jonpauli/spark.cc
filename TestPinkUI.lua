--[[
    TestPinkUI.lua

    demo script for PinkUI -- it loads the library, builds a window, a watermark,
    a keybind list and a handful of every element so you can check the finished
    product, including the config window and the ui settings window that sit to
    the right of the main window.

    the toggles actually do something:
        speed hack      sets walkspeed to 60 and keeps it after respawn
        infinite jump   spacebar/mobile jump button keeps jumping
        walk speed      applies a custom walkspeed
        jump power      applies a custom jump power
        teleport mode   walk = off, click = click the ground, instant = click a player
        player esp      boxes around other players, uses the colour + distance + style
        fullbright      brightens lighting while on, restores it when off/unloaded

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
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- keybinds fire their callback while being created, so ignore those runs
local KeybindsReady = false

local Features = {
    Speed = true,
    InfiniteJump = false,
    WalkSpeed = 16,
    JumpPower = 50,

    TeleportMode = "walk",

    Esp = true,
    EspColor = Color3.fromRGB(255, 163, 190),
    EspDistance = 500,
    BoxStyle = "2d",
}

local function Humanoid()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChildOfClass("Humanoid") or nil
end

local function OwnRoot()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart") or nil
end

local function IsMouseClick(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

-- movement ---------------------------------------------------------------------

local function ApplyToCharacter(Character)
    local HumanoidInstance = Character:WaitForChild("Humanoid", 10)

    if not HumanoidInstance then
        return
    end

    HumanoidInstance.WalkSpeed = Features.Speed and 60 or Features.WalkSpeed
    HumanoidInstance.JumpPower = Features.JumpPower
end

local function ApplyMovement()
    local HumanoidInstance = Humanoid()

    if HumanoidInstance then
        HumanoidInstance.WalkSpeed = Features.Speed and 60 or Features.WalkSpeed
        HumanoidInstance.JumpPower = Features.JumpPower
    end
end

LocalPlayer.CharacterAdded:Connect(ApplyToCharacter)

local JumpConnection = nil

local function ApplyInfiniteJump()
    if Features.InfiniteJump then
        if not JumpConnection then
            JumpConnection = UserInputService.JumpRequest:Connect(function()
                local HumanoidInstance = Humanoid()

                if HumanoidInstance then
                    HumanoidInstance.Jump = true
                end
            end)
        end
    elseif JumpConnection then
        JumpConnection:Disconnect()
        JumpConnection = nil
    end
end

-- teleport ---------------------------------------------------------------------

local function PlayerFromPart(Part)
    local Model = Part and Part.Parent

    while Model do
        local Player = Players:GetPlayerFromCharacter(Model)

        if Player then
            return Player
        end

        Model = Model.Parent
    end

    return nil
end

local function TeleportTo(Position)
    local Root = OwnRoot()

    if Root then
        Root.CFrame = CFrame.new(Position + Vector3.new(0, 3.2, 0))
    end
end

local function TeleportUnderMouse()
    local Camera = Workspace.CurrentCamera
    local Root = OwnRoot()

    if not Camera or not Root then
        return
    end

    local Mouse = UserInputService:GetMouseLocation()
    local Ray = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { LocalPlayer.Character }

    local Result = Workspace:Raycast(Ray.Origin, Ray.Direction * 2000, Params)

    if not Result then
        return
    end

    if Features.TeleportMode == "instant" then
        local Player = PlayerFromPart(Result.Instance)

        if Player then
            local Target = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

            if Target then
                Root.CFrame = CFrame.new(Target.Position + Vector3.new(0, 3.2, 0))
                return
            end
        end
    end

    Root.CFrame = CFrame.new(Result.Position + Vector3.new(0, 3.2, 0))
end

local TeleportConnection = nil

local function ApplyTeleport()
    if TeleportConnection then
        TeleportConnection:Disconnect()
        TeleportConnection = nil
    end

    if Features.TeleportMode == "walk" then
        return
    end

    TeleportConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed or not IsMouseClick(Input) then
            return
        end

        if UserInputService:GetFocusedTextBox() or Library.MenuOpen then
            return
        end

        TeleportUnderMouse()
    end)
end

-- esp --------------------------------------------------------------------------

local EspGui = nil
local Boxes = { }

local function EnsureEspGui()
    if EspGui then
        return EspGui
    end

    EspGui = Instance.new("ScreenGui")
    EspGui.Name = "PinkUIEsp"
    EspGui.IgnoreGuiInset = true
    EspGui.ResetOnSpawn = false
    EspGui.DisplayOrder = 5
    EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EspGui.Parent = (gethui and gethui()) or LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")

    return EspGui
end

local function CreateBox()
    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.BorderSizePixel = 0
    Holder.Visible = false
    Holder.Parent = EnsureEspGui()

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Parent = Holder

    local Shadow = Instance.new("Frame")
    Shadow.BackgroundTransparency = 1
    Shadow.BorderSizePixel = 0
    Shadow.Visible = false
    Shadow.Parent = Holder

    local ShadowStroke = Instance.new("UIStroke")
    ShadowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ShadowStroke.Thickness = 1
    ShadowStroke.Transparency = 0.5
    ShadowStroke.Parent = Shadow

    local Corners = { }

    for Index = 0, 3 do
        local Right = Index % 2 == 1
        local Bottom = Index >= 2
        local Anchor = Vector2.new(Right and 1 or 0, Bottom and 1 or 0)
        local Position = UDim2.fromScale(Right and 1 or 0, Bottom and 1 or 0)

        local Horizontal = Instance.new("Frame")
        Horizontal.AnchorPoint = Anchor
        Horizontal.Position = Position
        Horizontal.Size = UDim2.fromOffset(10, 1)
        Horizontal.BorderSizePixel = 0
        Horizontal.Visible = false
        Horizontal.Parent = Holder

        local Vertical = Instance.new("Frame")
        Vertical.AnchorPoint = Anchor
        Vertical.Position = Position
        Vertical.Size = UDim2.fromOffset(1, 10)
        Vertical.BorderSizePixel = 0
        Vertical.Visible = false
        Vertical.Parent = Holder

        table.insert(Corners, Horizontal)
        table.insert(Corners, Vertical)
    end

    return {
        Holder = Holder,
        Stroke = Stroke,
        Shadow = Shadow,
        ShadowStroke = ShadowStroke,
        Corners = Corners,
    }
end

local function HideBox(Box)
    Box.Holder.Visible = false
    Box.Shadow.Visible = false

    for _, Line in Box.Corners do
        Line.Visible = false
    end
end

local function UpdateBox(Box, X, Y, Width, Height, Colour, Style)
    local Holder = Box.Holder

    Holder.Position = UDim2.fromOffset(X, Y)
    Holder.Size = UDim2.fromOffset(Width, Height)
    Holder.Visible = true

    Box.Stroke.Enabled = Style ~= "corner"
    Box.Stroke.Color = Colour
    Box.Stroke.Thickness = (Style == "3d") and 2 or 1

    Box.Shadow.Visible = Style == "3d"

    if Style == "3d" then
        Box.Shadow.Position = UDim2.fromOffset(3, 3)
        Box.Shadow.Size = UDim2.fromScale(1, 1)
        Box.ShadowStroke.Color = Colour
    end

    for _, Line in Box.Corners do
        Line.Visible = Style == "corner"
        Line.BackgroundColor3 = Colour
    end
end

local function Project(Position)
    local Camera = Workspace.CurrentCamera

    if not Camera then
        return nil, false
    end

    local Point, OnScreen = Camera:WorldToViewportPoint(Position)

    return Vector2.new(Point.X, Point.Y), OnScreen and Point.Z > 0
end

local function ApplyEsp()
    if Features.Esp then
        EnsureEspGui()
    else
        for _, Box in Boxes do
            HideBox(Box)
        end
    end
end

local EspConnection = nil

local function UpdateEsp()
    if not Features.Esp then
        for _, Box in Boxes do
            HideBox(Box)
        end

        return
    end

    local Root = OwnRoot()

    if not Root then
        return
    end

    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            local TargetRoot = Character and Character:FindFirstChild("HumanoidRootPart")
            local Head = Character and Character:FindFirstChild("Head")
            local TargetHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local Box = Boxes[Player]

            if TargetRoot and Head and TargetHumanoid and TargetHumanoid.Health > 0 then
                local Distance = (TargetRoot.Position - Root.Position).Magnitude

                if Distance <= Features.EspDistance then
                    local Top, TopVisible = Project(Head.Position + Vector3.new(0, 0.7, 0))
                    local Bottom, BottomVisible = Project(TargetRoot.Position - Vector3.new(0, 2.6, 0))

                    if Top and Bottom and TopVisible and BottomVisible then
                        local Height = math.abs(Bottom.Y - Top.Y)

                        if Height > 6 then
                            if not Box then
                                Box = CreateBox()
                                Boxes[Player] = Box
                            end

                            local Width = math.max(Height * 0.55, 12)

                            UpdateBox(Box, Top.X - Width / 2, math.min(Top.Y, Bottom.Y), Width, Height, Features.EspColor, Features.BoxStyle)
                            continue
                        end
                    end
                end
            end

            if Box then
                HideBox(Box)
            end
        end
    end
end

EspConnection = RunService.RenderStepped:Connect(UpdateEsp)

Players.PlayerRemoving:Connect(function(Player)
    local Box = Boxes[Player]

    if Box then
        Box.Holder:Destroy()
        Boxes[Player] = nil
    end
end)

local function Shutdown()
    Features.Esp = false
    Features.InfiniteJump = false
    Features.TeleportMode = "walk"

    ApplyEsp()
    ApplyInfiniteJump()
    ApplyTeleport()

    if EspConnection then
        EspConnection:Disconnect()
        EspConnection = nil
    end

    if EspGui then
        EspGui:Destroy()
        EspGui = nil
    end

    table.clear(Boxes)
end

-- ui ---------------------------------------------------------------------------

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
        Default = Features.Speed,
        Tooltip = "walkspeed 60, kept after respawn",
        Callback = function(Value)
            Features.Speed = Value
            ApplyMovement()
            Library:Notification({ Name = "speed hack " .. (Value and "on" or "off") })
        end
    })

    Speed:Keybind({
        Name = "speed hack",
        Flag = "speed_bind",
        Default = Enum.KeyCode.LeftAlt,
        Callback = function(State)
            if not KeybindsReady then
                return
            end

            Speed:Set(State)
        end
    })

    Movement:Toggle({
        Name = "infinite jump",
        Flag = "infjump",
        Default = false,
        Tooltip = "keeps jumping while the jump button is held",
        Callback = function(Value)
            Features.InfiniteJump = Value
            ApplyInfiniteJump()
            Library:Notification({ Name = "infinite jump " .. (Value and "on" or "off") })
        end
    })

    Movement:Slider({
        Name = "walk speed",
        Flag = "walkspeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Decimals = 0,
        Tooltip = "used when speed hack is off",
        Callback = function(Value)
            Features.WalkSpeed = Value
            ApplyMovement()
        end
    })

    Movement:Textbox({
        Name = "jump power",
        Flag = "jumppower",
        Placeholder = "50",
        Numeric = true,
        Default = "50",
        Tooltip = "humanoid.jump power, 50 is default",
        Callback = function(Value)
            Features.JumpPower = tonumber(Value) or 50
            ApplyMovement()
        end
    })

    Movement:Dropdown({
        Name = "teleport mode",
        Flag = "telemode",
        Items = { "walk", "click", "instant" },
        Default = "walk",
        Tooltip = "click = click the ground, instant = click a player",
        Callback = function(Value)
            Features.TeleportMode = Value
            ApplyTeleport()
            Library:Notification({ Name = "teleport mode: " .. tostring(Value) })
        end
    })

    -- actions
    Actions:Button({
        Name = "notify me",
        Tooltip = "spam this to see repeats collapse into x2 x3",
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

    Actions:Button({
        Name = "corner notice",
        Tooltip = "per-call notification position",
        Callback = function()
            Library:Notification({ Name = "this one sits top left", Position = "top left", Time = 4 })
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
        Default = Features.Esp,
        Tooltip = "boxes around other players",
        Callback = function(Value)
            Features.Esp = Value
            ApplyEsp()
            Library:Notification({ Name = "esp " .. (Value and "on" or "off") })
        end
    })

    Esp:Colorpicker({
        Flag = "esp_color",
        Default = Features.EspColor,
        Callback = function(Color)
            Features.EspColor = Color
            Library:Notification({ Name = "esp color #" .. Color:ToHex(), Time = 2 })
        end
    })

    Visuals:Slider({
        Name = "max distance",
        Flag = "esp_dist",
        Min = 50,
        Max = 2000,
        Default = 500,
        Decimals = 0,
        Callback = function(Value)
            Features.EspDistance = Value
        end
    })

    Visuals:Dropdown({
        Name = "box style",
        Flag = "box",
        Items = { "2d", "3d", "corner" },
        Default = "2d",
        Callback = function(Value)
            Features.BoxStyle = Value
        end
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
            Shutdown()
            Library:Exit()
        end
    })

    -- builds the settings page plus the config window and the ui settings window
    Library:InitWindow()

    ApplyMovement()
    ApplyInfiniteJump()
    ApplyTeleport()
    ApplyEsp()

    KeybindsReady = true
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
Library:Notification({ Name = "esp on, 2d boxes", Time = 5 })
