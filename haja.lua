--[[=====================================================================
    HAJA UI  ·  v1.0.0
    A premium, clean, mobile + PC ready UI library for Roblox.

    > Better than Rayfield. Smoother. Cleaner. Prettier.
    > Works on phones, tablets, and PC out of the box.
    > Zero dependencies. Single file. Drop-in via loadstring.

    Quick start:
        local Haja = loadstring(game:HttpGet("https://raw.githubusercontent.com/goofinator654-wq/Haja/main/haja.lua"))()

        local Window = Haja:CreateWindow({
            Title       = "Haja Hub",
            SubTitle    = "v1.0 · Premium",
            SaveCfgKey  = "haja_demo",     -- optional config saving key
            Theme       = "Midnight",       -- "Midnight", "Obsidian", "Aurora"
            Size        = UDim2.fromOffset(560, 380),  -- optional
        })

        local Main = Window:CreateTab("Main", "rbxassetid://3926307971")

        Main:CreateSection("Combat")

        Main:CreateToggle({
            Name    = "Kill Aura",
            Flag    = "killaura",            -- used for config saving
            Default = false,
            Callback = function(v) print("Kill Aura:", v) end,
        })

        Main:CreateSlider({
            Name    = "Speed",
            Min     = 16,
            Max     = 300,
            Default = 16,
            Suffix  = "st/s",
            Callback = function(v) print("Speed:", v) end,
        })

        Main:CreateButton({
            Name    = "Rejoin",
            Callback = function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
            end,
        })

        Main:CreateDropdown({
            Name    = "Target",
            Options = { "Closest", "Random", "Lowest HP" },
            Default = "Closest",
            Callback = function(opt) print("Target mode:", opt) end,
        })

        Main:CreateKeybind({
            Name    = "Toggle UI",
            Default = Enum.KeyCode.RightControl,
            Callback = function() Window:Toggle() end,
        })

        Main:CreateTextbox({
            Name    = "Webhook URL",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(text) print("Webhook:", text) end,
        })

        Main:CreateParagraph({ Title = "Info", Content = "Haja UI is the cleanest library out there." })

        Haja:Notify({ Title = "Welcome", Content = "Thanks for using Haja UI!", Duration = 5 })
=====================================================================]]

--////////////////////////////////////////////////////////////////////////
--  SERVICES / UTILITIES
--////////////////////////////////////////////////////////////////////////

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Haja = {}
Haja.__index = Haja

Haja.Version = "1.0.1"
Haja.Themes  = {
    Midnight  = {
        Accent        = Color3.fromRGB(124, 92, 255),
        AccentDim     = Color3.fromRGB(94, 68, 200),
        Background    = Color3.fromRGB(16, 16, 22),
        Sidebar       = Color3.fromRGB(12, 12, 17),
        Element       = Color3.fromRGB(26, 26, 34),
        ElementHover  = Color3.fromRGB(36, 36, 46),
        Stroke        = Color3.fromRGB(44, 44, 56),
        Text          = Color3.fromRGB(240, 240, 245),
        SubText       = Color3.fromRGB(150, 150, 165),
    },
    Obsidian  = {
        Accent        = Color3.fromRGB(255, 255, 255),
        AccentDim     = Color3.fromRGB(190, 190, 190),
        Background    = Color3.fromRGB(10, 10, 10),
        Sidebar       = Color3.fromRGB(8, 8, 8),
        Element       = Color3.fromRGB(22, 22, 22),
        ElementHover  = Color3.fromRGB(32, 32, 32),
        Stroke        = Color3.fromRGB(40, 40, 40),
        Text          = Color3.fromRGB(245, 245, 245),
        SubText       = Color3.fromRGB(140, 140, 140),
    },
    Aurora    = {
        Accent        = Color3.fromRGB(64, 220, 180),
        AccentDim     = Color3.fromRGB(40, 170, 140),
        Background    = Color3.fromRGB(14, 20, 22),
        Sidebar       = Color3.fromRGB(10, 15, 17),
        Element       = Color3.fromRGB(24, 32, 34),
        ElementHover  = Color3.fromRGB(34, 44, 46),
        Stroke        = Color3.fromRGB(42, 54, 56),
        Text          = Color3.fromRGB(235, 245, 243),
        SubText       = Color3.fromRGB(140, 160, 158),
    },
}

--////////////////////////////////////////////////////////////////////////
--  INTERNAL STATE
--////////////////////////////////////////////////////////////////////////

local Theme = Haja.Themes.Midnight
local Window = {}
Window.__index = Window
local Windows = {}
local Flags = {}
local ConfigFolder = "HajaUI"
local Connections = {}

local function theme() return Theme end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function safeDestroy(inst)
    if inst then pcall(function() inst:Destroy() end) end
end

local function round(n, inc)
    inc = inc or 1
    return math.floor(n / inc + 0.5) * inc
end

local function make(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or theme().Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, px)
    return make("UIPadding", {
        PaddingTop = UDim.new(0, px or 10),
        PaddingBottom = UDim.new(0, px or 10),
        PaddingLeft = UDim.new(0, px or 10),
        PaddingRight = UDim.new(0, px or 10),
        Parent = parent,
    })
end

-- Ripple effect for buttons (premium touch)
local function ripple(parent, inputPos)
    local absPos = parent.AbsolutePosition
    local absSize = parent.AbsoluteSize
    local localPos = Vector2.new(inputPos.X - absPos.X, inputPos.Y - absPos.Y)

    local circle = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(localPos.X, localPos.Y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = theme().Text,
        BackgroundTransparency = 0.75,
        BorderSizePixel = 0,
        ZIndex = parent.ZIndex + 5,
        Parent = parent,
    })
    corner(circle, 999)

    local maxDim = math.max(absSize.X, absSize.Y) * 2.2
    tween(circle, { Size = UDim2.fromOffset(maxDim, maxDim), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
    task.delay(0.5, function() safeDestroy(circle) end)
end

--////////////////////////////////////////////////////////////////////////
--  CONFIG SAVING (flags)
--////////////////////////////////////////////////////////////////////////

local function saveConfig(key)
    if not key then return end
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        local data = {}
        for flag, value in pairs(Flags) do
            if typeof(value) ~= "Instance" and typeof(value) ~= "function" and typeof(value) ~= "table" then
                data[flag] = value
            elseif typeof(value) == "table" then
                data[flag] = value
            end
        end
        writefile(ConfigFolder .. "/" .. tostring(key) .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadConfig(key)
    if not key then return {} end
    local ok, result = pcall(function()
        local path = ConfigFolder .. "/" .. tostring(key) .. ".json"
        if isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
        return {}
    end)
    return ok and result or {}
end

-- Debounced auto-save: fires shortly after a flag changes (client-safe,
-- unlike game:BindToClose which is server-only)
local savePending = false
local function scheduleAutoSave()
    if savePending then return end
    savePending = true
    task.delay(0.5, function()
        savePending = false
        for _, w in ipairs(Windows) do
            saveConfig(w._cfgKey)
        end
    end)
end

--////////////////////////////////////////////////////////////////////////
--  WINDOW
--////////////////////////////////////////////////////////////////////////

function Haja:CreateWindow(cfg)
    cfg = cfg or {}
    Theme = Haja.Themes[cfg.Theme] or Haja.Themes.Midnight
    local T = theme()

    local mobile = isMobile()

    local windowSize = cfg.Size or UDim2.fromOffset(560, 380)
    if mobile then
        -- fill most of the screen on phones, with breathing room
        local cam = workspace.CurrentCamera.ViewportSize
        windowSize = UDim2.fromOffset(math.min(cam.X * 0.92, 480), math.min(cam.Y * 0.72, 400))
    end

    -- Root GUI
    local gui = make("ScreenGui", {
        Name = "HajaUI_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = (function()
            local ok = pcall(function()
                if gethui then return gethui() end
                return CoreGui
            end)
            if ok then
                return gethui and gethui() or CoreGui
            end
            return LocalPlayer:WaitForChild("PlayerGui")
        end)(),
    })

    -- Main container
    local main = make("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = windowSize,
        BackgroundColor3 = T.Background,
        BorderSizePixel = 0,
        Active = true,
        Parent = gui,
    })
    corner(main, 14)
    stroke(main, T.Stroke, 1, 0.2)

    -- subtle gradient overlay for depth
    make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 220)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.96),
            NumberSequenceKeypoint.new(1, 0.99),
        }),
        Parent = main,
    })

    -- Drop shadow
    local shadow = make("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 60, 1, 60),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1,
        Parent = main,
    })

    -- Sidebar
    local sidebar = make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, mobile and 52 or 140, 1, 0),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    corner(sidebar, 14)

    -- clip sidebar's right corners
    make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 14, 1, 0),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    local logo = make("ImageLabel", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(0.5, 0, 0, 14),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Image = cfg.Logo or "rbxassetid://10723407389",
        Parent = sidebar,
    })

    local logoText = make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 48),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Haja",
        TextColor3 = T.Text,
        TextSize = mobile and 14 or 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = not mobile,
        Parent = sidebar,
    })

    local tabBar = make("Frame", {
        Position = UDim2.new(0, 0, 0, mobile and 56 or 76),
        Size = UDim2.new(1, 0, 1, -(mobile and 56 or 76)),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    make("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = tabBar,
    })

    -- Content area
    local content = make("Frame", {
        Name = "Content",
        Position = UDim2.new(0, mobile and 52 or 140, 0, 0),
        Size = UDim2.new(1, -(mobile and 52 or 140), 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })

    -- Titlebar
    local titlebar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = content,
    })

    local title = make("TextLabel", {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -160, 1, 0),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Haja",
        TextColor3 = T.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titlebar,
    })

    local subtitle = make("TextLabel", {
        Position = UDim2.new(0, 17, 0, 24),
        Size = UDim2.new(1, -160, 0, 14),
        BackgroundTransparency = 1,
        Text = cfg.SubTitle or "",
        TextColor3 = T.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titlebar,
    })

    -- Top-right buttons (minimize / close)
    local function iconButton(symbol, xOffset, onClick)
        local btn = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOffset, 0.5, 0),
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = T.Element,
            BackgroundTransparency = 0.4,
            Text = symbol,
            TextColor3 = T.SubText,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = titlebar,
        })
        corner(btn, 8)
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundTransparency = 0, TextColor3 = T.Text })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundTransparency = 0.4, TextColor3 = T.SubText })
        end)
        btn.Activated:Connect(onClick)
        return btn
    end

    local minimized = false
    iconButton("—", -10, function()
        minimized = not minimized
        tween(main, { Size = minimized and UDim2.new(0, main.AbsoluteSize.X, 0, 44) or windowSize })
    end)

    iconButton("✕", -44, function()
        tween(main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.25)
        task.delay(0.25, function()
            gui:Destroy()
        end)
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        table.clear(Connections)
    end)

    -- Draggable (PC + mobile)
    do
        local dragging, dragStart, startPos = false, nil, nil
        local dragInput, dragPos

        local function canDrag()
            return true
        end

        titlebar.InputBegan:Connect(function(input)
            if canDrag() and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        titlebar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Resize handle (PC only)
    if not mobile then
        local handle = make("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Parent = main,
        })

        do
            local resizing, resizeStart, startSize = false, nil, nil
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = true
                    resizeStart = input.Position
                    startSize = main.Size
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Position - resizeStart
                    main.Size = UDim2.new(
                        0, math.clamp(startSize.X.Offset + delta.X, 420, 900),
                        0, math.clamp(startSize.Y.Offset + delta.Y, 300, 650)
                    )
                end
            end)
        end
    end

    -- Search bar in content area (filters elements across tabs? For now, current tab)
    local searchBox = make("TextBox", {
        Position = UDim2.new(1, -150, 0, 12),
        Size = UDim2.fromOffset(135, 28),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = T.Element,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = mobile and "Search…" or "Search elements...",
        PlaceholderColor3 = T.SubText,
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titlebar,
    })
    corner(searchBox, 8)
    padding(searchBox, 8)

    -- Pages container
    local pages = make("Frame", {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        BackgroundTransparency = 1,
        Parent = content,
    })

    local Window = setmetatable({}, Window)
    Window._gui = gui
    Window._main = main
    Window._sidebar = sidebar
    Window._tabBar = tabBar
    Window._pages = pages
    Window._title = cfg.Title or "Haja"
    Window._cfgKey = cfg.SaveCfgKey
    Window._tabs = {}
    Window._mobile = mobile
    Window._minimized = false
    Window._theme = T

    -- Loading config into Flags
    local saved = loadConfig(Window._cfgKey)
    for k, v in pairs(saved) do
        Flags[k] = v
    end

    function Window:Toggle(state)
        if state == nil then state = not gui.Enabled end
        self._visible = state
        gui.Enabled = state
    end

    -- Search matches elements by Name within the ACTIVE tab
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text)
        for _, tab in ipairs(Window._tabs) do
            if tab._active then
                for _, el in ipairs(tab._elements) do
                    if el._frame then
                        local match = query == "" or string.find(string.lower(el._name or ""), query, 1, true) ~= nil
                        el._frame.Visible = match
                    end
                end
            end
        end
    end)

    function Window:Destroy()
        gui:Destroy()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    end

    function Window:SetTitle(text)
        title.Text = text
        logoText.Text = text
    end

    table.insert(Windows, Window)
    return Window
end

--////////////////////////////////////////////////////////////////////////
--  TAB
--////////////////////////////////////////////////////////////////////////

function Window:CreateTab(name, icon)
    local T = self._theme
    local tab = {}
    tab._name = name
    tab._active = false
    tab._elements = {}

    -- Sidebar button
    local btn = make("TextButton", {
        Size = UDim2.new(1, -12, 0, self._mobile and 40 or 34),
        BackgroundColor3 = T.Element,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #self._tabs + 1,
        Parent = self._tabBar,
    })
    corner(btn, 9)

    local btnLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = btn,
    })
    make("UIPadding", {
        PaddingLeft = UDim.new(0, self._mobile and 8 or 10),
        Parent = btn,
    })

    local iconLabel = make("ImageLabel", {
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Image = icon or "",
        ImageColor3 = T.SubText,
        LayoutOrder = 1,
        Parent = btn,
    })

    local nameLabel = make("TextLabel", {
        Size = UDim2.new(1, -(self._mobile and 34 or 46), 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.SubText,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        Parent = btn,
    })
    if self._mobile then
        nameLabel.Visible = false
    end

    -- Page container (scrolling)
    local page = make("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        ScrollBarImageTransparency = 0.4,
        Visible = false,
        Parent = self._pages,
    })

    local pagePad = make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        Parent = page,
    })

    local listLayout = make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })

    tab._button = btn
    tab._page = page
    tab._icon = iconLabel
    tab._nameLabel = nameLabel
    tab._layout = listLayout

    -- Auto canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 28)
    end)

    local function activate()
        for _, t in ipairs(self._tabs) do
            t._active = false
            t._page.Visible = false
            tween(t._button, { BackgroundTransparency = 1 })
            t._icon.ImageColor3 = T.SubText
            t._nameLabel.TextColor3 = T.SubText
        end
        tab._active = true
        page.Visible = true
        -- reset search filter so switching tabs never leaves elements hidden
        for _, el in ipairs(tab._elements) do
            if el._frame then el._frame.Visible = true end
        end
        tween(btn, { BackgroundTransparency = 0.65 })
        tab._icon.ImageColor3 = T.Accent
        tab._nameLabel.TextColor3 = T.Text
    end

    btn.Activated:Connect(activate)

    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        task.defer(activate)
    end

    -- Element factory with shared scaffolding
    local function newElement(order)
        local frame = make("Frame", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = T.Element,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = page,
        })
        corner(frame, 9)
        local st = stroke(frame, T.Stroke, 1, 0.55)

        frame.MouseEnter:Connect(function()
            tween(frame, { BackgroundTransparency = 0.15 })
            tween(st, { Transparency = 0.3 })
        end)
        frame.MouseLeave:Connect(function()
            tween(frame, { BackgroundTransparency = 0.35 })
            tween(st, { Transparency = 0.55 })
        end)

        local label = make("TextLabel", {
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = T.Text,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })

        return frame, label
    end

    --================================================================
    --  ELEMENT: Section
    --================================================================
    function tab:CreateSection(text)
        local holder = make("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = #self._elements + 1,
            Parent = self._page,
        })
        make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = string.upper(text or ""),
            TextColor3 = T.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })
        make("Frame", { -- divider
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Stroke,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Parent = holder,
        })
        return holder
    end

    --================================================================
    --  ELEMENT: Paragraph
    --================================================================
    function tab:CreateParagraph(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundTransparency = 0.55
        label.Text = cfg.Title or ""
        label.TextColor3 = T.Accent

        local body = make("TextLabel", {
            Position = UDim2.fromOffset(12, 20),
            Size = UDim2.new(1, -24, 1, -26),
            BackgroundTransparency = 1,
            Text = cfg.Content or "",
            TextColor3 = T.SubText,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = frame,
        })

        -- auto height
        task.defer(function()
            local h = body.TextBounds.Y
            frame.Size = UDim2.new(1, 0, 0, h + 32)
        end)

        table.insert(self._elements, { _name = cfg.Title, _frame = frame })
        return frame
    end

    --================================================================
    --  ELEMENT: Button
    --================================================================
    function tab:CreateButton(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Button"

        local hit = make("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = frame,
        })

        local indicator = make("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Parent = frame,
        })
        corner(indicator, 6)
        make("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "›",
            TextColor3 = T.Accent,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            Parent = indicator,
        })

        hit.Activated:Connect(function(x, y)
            if cfg.Callback then task.spawn(cfg.Callback) end
            tween(indicator, { BackgroundTransparency = 0.3 })
            task.delay(0.15, function()
                tween(indicator, { BackgroundTransparency = 0.85 })
            end)
        end)

        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return frame
    end

    --================================================================
    --  ELEMENT: Toggle
    --================================================================
    function tab:CreateToggle(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Toggle"

        local state = cfg.Default or false
        if cfg.Flag and Flags[cfg.Flag] ~= nil then
            state = Flags[cfg.Flag]
        end

        local knobTrack = make("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = state and T.Accent or T.ElementHover,
            BorderSizePixel = 0,
            Parent = frame,
        })
        corner(knobTrack, 11)
        stroke(knobTrack, T.Stroke, 1, 0.5)

        local knob = make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = knobTrack,
        })
        corner(knob, 9)

        local function set(v, fire)
            state = v
            if cfg.Flag then Flags[cfg.Flag] = v end
            tween(knobTrack, { BackgroundColor3 = v and T.Accent or T.ElementHover })
            tween(knob, { Position = v and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
            if fire and cfg.Callback then task.spawn(cfg.Callback, v) end
        end

        local hit = make("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = frame,
        })
        hit.Activated:Connect(function()
            set(not state, true)
        end)

        -- apply saved state without firing callback
        if state and cfg.Flag and Flags[cfg.Flag] then
            set(state, false)
        end

        local api = {}
        function api:Set(v) set(v, true) end
        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return api
    end

    --================================================================
    --  ELEMENT: Slider
    --================================================================
    function tab:CreateSlider(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        frame.Size = UDim2.new(1, 0, 0, 56)

        local min, max = cfg.Min or 0, cfg.Max or 100
        local value = cfg.Default or min
        if cfg.Flag and Flags[cfg.Flag] ~= nil then value = Flags[cfg.Flag] end
        value = math.clamp(value, min, max)

        label.Text = cfg.Name or "Slider"
        label.Size = UDim2.new(1, -90, 0, 20)

        local valueLabel = make("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 0),
            Size = UDim2.fromOffset(80, 20),
            BackgroundTransparency = 1,
            Text = tostring(value) .. (cfg.Suffix or ""),
            TextColor3 = T.Accent,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = frame,
        })

        local track = make("Frame", {
            Position = UDim2.fromOffset(12, 32),
            Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = T.ElementHover,
            BorderSizePixel = 0,
            Parent = frame,
        })
        corner(track, 3)

        local fill = make("Frame", {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(fill, 3)

        local knob = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 3,
            Parent = track,
        })
        corner(knob, 7)
        stroke(knob, T.Accent, 2)

        local function set(v, fire)
            v = math.clamp(v, min, max)
            value = v
            if cfg.Flag then Flags[cfg.Flag] = v end
            local alpha = (v - min) / (max - min)
            tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.06)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            valueLabel.Text = tostring(round(v, cfg.Increment or 1)) .. (cfg.Suffix or "")
            if fire and cfg.Callback then task.spawn(cfg.Callback, v) end
        end

        local dragging = false
        local function inputToValue(x)
            local rel = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
            set(min + (max - min) * math.clamp(rel, 0, 1), true)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                inputToValue(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                inputToValue(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local api = {}
        function api:Set(v) set(v, true) end
        function api:Get() return value end
        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return api
    end

    --================================================================
    --  ELEMENT: Dropdown
    --================================================================
    function tab:CreateDropdown(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Dropdown"

        local options = cfg.Options or {}
        local selected = cfg.Default or (options[1] or "")
        if cfg.Flag and Flags[cfg.Flag] ~= nil then selected = Flags[cfg.Flag] end

        local open = false

        local valueBtn = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(150, 26),
            BackgroundColor3 = T.ElementHover,
            BorderSizePixel = 0,
            Text = tostring(selected),
            TextColor3 = T.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            Parent = frame,
        })
        corner(valueBtn, 7)

        local arrow = make("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Text = "▾",
            TextColor3 = T.SubText,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            Parent = valueBtn,
        })

        local dropHolder = make("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 1, 4),
            Size = UDim2.new(0, 150, 0, 0),
            BackgroundColor3 = T.Background,
            BorderSizePixel = 0,
            ZIndex = 20,
            ClipsDescendants = true,
            Parent = frame,
        })
        corner(dropHolder, 7)
        stroke(dropHolder, T.Stroke, 1, 0.3)

        local list = make("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(),
            ZIndex = 20,
            Parent = dropHolder,
        })
        make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
        padding(list, 4)

        local function rebuild()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for i, opt in ipairs(options) do
                local optBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = opt == selected and T.Accent or T.Element,
                    BackgroundTransparency = opt == selected and 0.2 or 0.5,
                    Text = tostring(opt),
                    TextColor3 = opt == selected and Color3.fromRGB(255, 255, 255) or T.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    ZIndex = 21,
                    LayoutOrder = i,
                    Parent = list,
                })
                corner(optBtn, 5)
                optBtn.Activated:Connect(function()
                    selected = opt
                    if cfg.Flag then Flags[cfg.Flag] = opt end
                    valueBtn.Text = tostring(opt)
                    if cfg.Callback then task.spawn(cfg.Callback, opt) end
                    open = false
                    tween(dropHolder, { Size = UDim2.new(0, 150, 0, 0) })
                    rebuild()
                end)
            end
            list.CanvasSize = UDim2.new(0, 0, 0, #options * 26 + 8)
        end
        rebuild()

        valueBtn.Activated:Connect(function()
            open = not open
            local h = open and math.min(#options * 26 + 8, 130) or 0
            tween(dropHolder, { Size = UDim2.new(0, 150, 0, h) })
        end)

        local api = {}
        function api:Set(opt)
            if table.find(options, opt) then
                selected = opt
                valueBtn.Text = tostring(opt)
                if cfg.Callback then task.spawn(cfg.Callback, opt) end
                rebuild()
            end
        end
        function api:Refresh(newOptions)
            options = newOptions or options
            rebuild()
        end
        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return api
    end

    --================================================================
    --  ELEMENT: Keybind
    --================================================================
    function tab:CreateKeybind(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Keybind"

        local key = cfg.Default or Enum.KeyCode.RightControl
        local listening = false

        local keyBtn = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(70, 26),
            BackgroundColor3 = T.ElementHover,
            BorderSizePixel = 0,
            Text = key.Name,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            Parent = frame,
        })
        corner(keyBtn, 7)

        keyBtn.Activated:Connect(function()
            listening = true
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = T.Accent
        end)

        connect(UserInputService.InputBegan, function(input, gpe)
            if listening and not gpe then
                local nk = input.KeyCode
                if nk ~= Enum.KeyCode.Unknown then
                    key = nk
                    keyBtn.Text = key.Name
                    keyBtn.BackgroundColor3 = T.ElementHover
                    listening = false
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    listening = false
                    keyBtn.Text = key.Name
                    keyBtn.BackgroundColor3 = T.ElementHover
                end
                return
            end

            if input.KeyCode == key and not gpe then
                if cfg.Callback then task.spawn(cfg.Callback) end
            end
        end)

        local api = {}
        function api:Set(k) key = k; keyBtn.Text = k.Name end
        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return api
    end

    --================================================================
    --  ELEMENT: Textbox
    --================================================================
    function tab:CreateTextbox(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Textbox"

        local box = make("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(170, 26),
            BackgroundColor3 = T.ElementHover,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = cfg.Placeholder or "Type here...",
            PlaceholderColor3 = T.SubText,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = true,
            Parent = frame,
        })
        corner(box, 7)
        padding(box, 8)

        local function commit()
            local t = box.Text
            if cfg.Flag then Flags[cfg.Flag] = t end
            if cfg.Callback then task.spawn(cfg.Callback, t) end
        end

        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then commit() end
        end)

        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return { Set = function(_, t) box.Text = t end }
    end

    --================================================================
    --  ELEMENT: ColorPicker
    --================================================================
    function tab:CreateColorPicker(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        label.Text = cfg.Name or "Color"

        local color = cfg.Default or Color3.fromRGB(124, 92, 255)

        local preview = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(34, 22),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = frame,
        })
        corner(preview, 6)
        stroke(preview, T.Stroke, 1, 0.4)

        local open = false
        local holder = make("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 1, 6),
            Size = UDim2.fromOffset(180, 0),
            BackgroundColor3 = T.Background,
            BorderSizePixel = 0,
            ZIndex = 20,
            ClipsDescendants = true,
            Parent = frame,
        })
        corner(holder, 8)
        stroke(holder, T.Stroke, 1, 0.3)

        local function rebuildPicker()
            for _, c in ipairs(holder:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            local swatches = {
                Color3.fromRGB(124, 92, 255), Color3.fromRGB(64, 220, 180),
                Color3.fromRGB(255, 105, 140), Color3.fromRGB(255, 190, 80),
                Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(40, 40, 40), Color3.fromRGB(0, 255, 140),
            }
            for i, c in ipairs(swatches) do
                local sw = make("TextButton", {
                    Position = UDim2.fromOffset(6 + ((i - 1) % 4) * 42, 6 + math.floor((i - 1) / 4) * 30),
                    Size = UDim2.fromOffset(38, 26),
                    BackgroundColor3 = c,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 21,
                    Parent = holder,
                })
                corner(sw, 5)
                sw.Activated:Connect(function()
                    color = c
                    preview.BackgroundColor3 = c
                    if cfg.Callback then task.spawn(cfg.Callback, c) end
                end)
            end
        end
        rebuildPicker()

        preview.Activated:Connect(function()
            open = not open
            tween(holder, { Size = UDim2.fromOffset(180, open and 70 or 0) })
        end)

        local api = {}
        function api:Set(c)
            color = c
            preview.BackgroundColor3 = c
            if cfg.Callback then task.spawn(cfg.Callback, c) end
        end
        function api:Get() return color end
        table.insert(self._elements, { _name = cfg.Name, _frame = frame })
        return api
    end

    --================================================================
    --  ELEMENT: Label
    --================================================================
    function tab:CreateLabel(cfg)
        cfg = cfg or {}
        local frame, label = newElement(#self._elements + 1)
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 20)
        label.Text = cfg.Text or cfg.Name or ""
        label.TextColor3 = T.SubText
        table.insert(self._elements, { _name = cfg.Text, _frame = frame })
        return {
            Set = function(_, t) label.Text = t end,
        }
    end

    return tab
end

--////////////////////////////////////////////////////////////////////////
--  NOTIFICATIONS
--////////////////////////////////////////////////////////////////////////

local notifyGui
local function getNotifyGui()
    if notifyGui and notifyGui.Parent then return notifyGui end
    notifyGui = make("ScreenGui", {
        Name = "HajaNotify",
        ResetOnSpawn = false,
        DisplayOrder = 1000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (function()
            local ok = pcall(function() if gethui then return gethui() end end)
            if ok and gethui then return gethui() end
            pcall(function() return CoreGui end)
            return LocalPlayer:WaitForChild("PlayerGui")
        end)(),
    })
    local holder = make("Frame", {
        Name = "Holder",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(300, 400),
        BackgroundTransparency = 1,
        Parent = notifyGui,
    })
    make("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    notifyGui._holder = holder
    return notifyGui
end

function Haja:Notify(cfg)
    cfg = cfg or {}
    local T = theme()
    local gui = getNotifyGui()
    local holder = gui._holder

    local note = make("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = T.Background,
        BorderSizePixel = 0,
        LayoutOrder = 0,
        Parent = holder,
    })
    corner(note, 10)
    stroke(note, T.Accent, 1, 0.4)

    make("Frame", { -- accent bar
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.fromOffset(10, 8),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = note,
    })
    corner(note:FindFirstChildOfClass("Frame"), 2)

    make("TextLabel", {
        Position = UDim2.fromOffset(24, 10),
        Size = UDim2.new(1, -34, 0, 18),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Notification",
        TextColor3 = T.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = note,
    })

    make("TextLabel", {
        Position = UDim2.fromOffset(24, 30),
        Size = UDim2.new(1, -34, 1, -38),
        BackgroundTransparency = 1,
        Text = cfg.Content or "",
        TextColor3 = T.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = note,
    })

    -- enter animation
    note.Size = UDim2.new(1, 0, 0, 0)
    tween(note, { Size = UDim2.new(1, 0, 0, 64) }, 0.25, Enum.EasingStyle.Back)

    local duration = cfg.Duration or 4
    task.delay(duration, function()
        tween(note, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.22, function() safeDestroy(note) end)
    end)
end

--////////////////////////////////////////////////////////////////////////
--  CONFIG SAVING (client-side — game:BindToClose is server-only,
--  so we save on every flag change instead of on leave)
--////////////////////////////////////////////////////////////////////////

local function autoSave()
    for _, w in ipairs(Windows) do
        saveConfig(w._cfgKey)
    end
end

-- expose helpers
Haja.SaveConfig = autoSave

Haja.IsMobile = isMobile
Haja.Version = Haja.Version

return Haja
