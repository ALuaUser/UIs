--[[
    LiteUI  v1.4.0
    A flat, minimal UI library for Roblox: cards, tabs, groups, panels, profiles.

    Host this file on GitHub and load it with:
        local Lite = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/LiteUI.lua"))()

    ── Quick start ──────────────────────────────────────────────
    local ui   = Lite.new({ Name = "MyHUD", Key = Enum.KeyCode.RightShift })
    local card = ui:Card({ Title = "Hello", Subtitle = "World", Value = "42" })
    local tab  = ui:Tabs({ "Main", "Utility", "Settings" })   -- window widens to fit the tab names
    tab.Main:Toggle({ Name = "Enabled", Flag = "enabled", Default = true, Callback = print })
    ui:Settings({ Panel = tab.Settings })
    ui:Show()

    ── API ──────────────────────────────────────────────────────
    Lite.new(opts)  opts: Name, Width(264, grows to fit tabs), Key, Theme("dark"), Opacity(.96),
                          Scale(1, 1.2 on phones), X, Y, Parent, DisplayOrder, Save(true), SaveFile, MobileButton(true),
                          Animations(true)
    Lite.Themes     dark, light, ocean, mocha, rose, forest  (add your own before Lite.new)
    Lite.UnloadAll()   destroys every LiteUI window instantly
    Lite.Animations    set false to turn every animation off (also a Settings toggle)

    Mobile: touch-friendly out of the box. Phones get a larger default size, bigger header
    buttons, long-press tooltips, tap-to-reveal buttons, a draggable "UI" show/hide button,
    sliders that don't fight scrolling, safe-area insets, and panels that never grow
    taller or wider than the screen.

    Window:  :Card(opts)  :Panel(opts)  :Tabs(names, opts)  :Settings(opts)  :Profiles(opts)
             :Notify{Title,Text,Duration,Tone}      toast, bottom-right
             :Prompt{Title,Text,Yes,No,Tone,Callback(bool)}   confirm dialog
             :Watermark{Text,FPS,Ping,Position}     small fps / ping badge
             :Show() :Hide() :Toggle() :Destroy() :Unload()
             :SetTheme(n) :SetOpacity(v) :SetScale(v) :SetKey(k) :SetWidth(px) :SetAccent(Color3|nil)
             :SetDraggable(bool)  :SetAnimations(bool)  :OnVisibility(fn(bool))  :OnDestroy(fn)
             :ExportConfig() :ImportConfig(json) :ResetConfig()      (controls update live)
             :SaveProfile(n) :LoadProfile(n) :DeleteProfile(n) :ListProfiles()
             .Flags (saved values)   .Alive

    Card:    :Set{Title,Subtitle,Value,Tone}  :SetTone(key | Color3)  :Minimize(bool)
             :SetPinned(bool) :IsPinned() :AddButton(text, fn) :Attach(panel, closed, open)
             opts: Title, Subtitle, Value, Tone, Closable, Minimizable, Pinnable, OnPin

    Tabs:    local tab, bar = ui:Tabs({"A","B"}, {MaxHeight=250, Default="A", MaxWidth=460})
             tab.A / tab.B are Panels.   bar:Select("B")
             Width grows so every tab name fits; past MaxWidth the tab bar scrolls.

    Panel:   :SetOpen(bool) :IsOpen()
             opts: Name, Open, Persist, MaxHeight (scrolls when taller)
             :Group{Name,Open,Persist}   collapsible group; has all the element methods below
             :Search{Placeholder}        filters the rows of this panel by name
             :Section(text)  :Label{Text,Tone}  :Paragraph(text)  :Separator()
             :Stat{Name,Value,Tone}  ->  :Set(value, tone)
             :Graph{Name,Min,Max,Height,Points,Tone}  ->  :Push(v)  :Clear()  :SetTone(key)
             :Button{Name,Callback,Tone}   :ButtonRow{ {Name,Callback,Tone}, ... }
             :Toggle{Name,Default,Flag,Callback,Keybind}   (Keybind adds a key chip)
             :Slider{Name,Min,Max,Step,Default,Flag,Format,Suffix,Input,Callback}
                       (click the number to type a value, unless you pass a Format)
             :Choice{Name,Options,Default,Flag,Callback}            (click to cycle)
             :Dropdown{Name,Options,Default,Multi,Flag,Callback}    (expands inline)
             :TextBox{Name,Placeholder,Default,Numeric,Min,Max,OnlyEnter,Flag,Callback}
             :ColorPicker{Name,Default,Flag,Callback}
             :Keybind{Name,Default,Flag,Callback,Press}
             :Bar{Name,Min,Max,Default,Format,Tone}  ->  :Set(v) :SetTone(key)
             :List{Max,Empty}  ->  :Push(name, value)  :Clear()

    Every element also takes  Tooltip = "text"  and returns an object with
             :SetVisible(bool)  :SetEnabled(bool)  :Destroy()  .Row

    Elements with a Flag are saved/restored, and their Callback is called once
    on load with the restored value.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local Lite = { Version = "1.4.0", Windows = {}, Animations = true }

----------------------------------------------------------------
-- Themes
----------------------------------------------------------------
Lite.Themes = {
    dark = {
        bg = Color3.fromRGB(20, 21, 24),
        line = Color3.fromRGB(255, 255, 255),
        text = Color3.fromRGB(236, 237, 240),
        sub = Color3.fromRGB(135, 139, 148),
        accent = Color3.fromRGB(120, 200, 150),
        warn = Color3.fromRGB(224, 175, 104),
        danger = Color3.fromRGB(228, 108, 108),
        track = Color3.fromRGB(46, 48, 55),
    },
    light = {
        bg = Color3.fromRGB(248, 248, 250),
        line = Color3.fromRGB(0, 0, 0),
        text = Color3.fromRGB(28, 29, 33),
        sub = Color3.fromRGB(112, 116, 126),
        accent = Color3.fromRGB(38, 148, 92),
        warn = Color3.fromRGB(190, 128, 40),
        danger = Color3.fromRGB(196, 62, 62),
        track = Color3.fromRGB(214, 216, 222),
    },
    ocean = {
        bg = Color3.fromRGB(14, 22, 34),
        line = Color3.fromRGB(180, 215, 255),
        text = Color3.fromRGB(226, 238, 252),
        sub = Color3.fromRGB(110, 140, 175),
        accent = Color3.fromRGB(90, 190, 230),
        warn = Color3.fromRGB(232, 184, 108),
        danger = Color3.fromRGB(232, 110, 110),
        track = Color3.fromRGB(32, 48, 68),
    },
    mocha = {
        bg = Color3.fromRGB(30, 24, 22),
        line = Color3.fromRGB(255, 240, 225),
        text = Color3.fromRGB(240, 230, 220),
        sub = Color3.fromRGB(150, 135, 125),
        accent = Color3.fromRGB(214, 160, 110),
        warn = Color3.fromRGB(232, 200, 110),
        danger = Color3.fromRGB(224, 110, 100),
        track = Color3.fromRGB(54, 45, 41),
    },
    rose = {
        bg = Color3.fromRGB(28, 20, 26),
        line = Color3.fromRGB(255, 230, 240),
        text = Color3.fromRGB(244, 232, 238),
        sub = Color3.fromRGB(150, 125, 140),
        accent = Color3.fromRGB(232, 130, 160),
        warn = Color3.fromRGB(230, 184, 110),
        danger = Color3.fromRGB(230, 100, 110),
        track = Color3.fromRGB(52, 38, 48),
    },
    forest = {
        bg = Color3.fromRGB(17, 24, 20),
        line = Color3.fromRGB(200, 255, 215),
        text = Color3.fromRGB(228, 240, 230),
        sub = Color3.fromRGB(120, 145, 128),
        accent = Color3.fromRGB(110, 200, 130),
        warn = Color3.fromRGB(222, 188, 110),
        danger = Color3.fromRGB(226, 108, 108),
        track = Color3.fromRGB(36, 50, 42),
    },
}

local Window, Card, Panel = {}, {}, {}
Window.__index, Card.__index, Panel.__index = Window, Card, Panel

local QUINT = Enum.EasingStyle.Quint
local GAP = 6 -- vertical gap between boxes and between panel elements

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function tween(obj, props, t, style, dir)
    t = t or 0.2
    if t == 0 or not Lite.Animations then
        for k, v in pairs(props) do
            obj[k] = v
        end
        return
    end
    TweenService:Create(
        obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function viewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

local function keyOf(v, fallback)
    if typeof(v) == "EnumItem" then
        return v
    end
    if type(v) == "string" then
        local ok, k = pcall(function()
            return Enum.KeyCode[v]
        end)
        if ok and k then
            return k
        end
    end
    return fallback
end

local function capitalize(s)
    return (tostring(s):gsub("^%l", string.upper))
end

-- soft press feedback: shrinks slightly on press, springs back on release
local function pressable(btn, amount)
    local sc = make("UIScale", { Scale = 1 }, btn)
    amount = amount or 0.96
    btn.InputBegan:Connect(function(input)
        if isPress(input) then
            tween(sc, { Scale = amount }, 0.08)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if isPress(input) then
            tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
        end
    end)
end

----------------------------------------------------------------
-- Window: construction, settings, theme
----------------------------------------------------------------
function Window:_load(defaults)
    local raw
    if self._saveOn then
        if type(isfile) == "function" and type(readfile) == "function" then
            local ok, res = pcall(function()
                if isfile(self._file) then
                    return readfile(self._file)
                end
            end)
            if ok then
                raw = res
            end
        end
        if not raw then
            raw = Players.LocalPlayer:GetAttribute(self._attr)
        end
    end

    local out = table.clone(defaults)
    if type(raw) == "string" then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok and type(data) == "table" then
            for k, def in pairs(defaults) do
                if type(data[k]) == type(def) then
                    out[k] = data[k]
                end
            end
        end
    end

    out.opacity = math.clamp(out.opacity, 0.5, 1)
    out.scale = math.clamp(out.scale, 0.5, 2)
    if not Lite.Themes[out.theme] then
        out.theme = "dark"
    end
    return out
end

function Window:_save()
    if not self._saveOn then
        return
    end
    self._saveToken += 1
    local mine = self._saveToken
    task.delay(0.4, function()
        if mine ~= self._saveToken then
            return
        end
        local ok, raw = pcall(HttpService.JSONEncode, HttpService, self.S)
        if not ok then
            return
        end
        pcall(Players.LocalPlayer.SetAttribute, Players.LocalPlayer, self._attr, raw)
        if type(writefile) == "function" then
            pcall(writefile, self._file, raw)
        end
    end)
end

function Window:_flagGet(key, default)
    if key == nil then
        return default
    end
    local v = self.S.flags[key]
    if v ~= nil and (default == nil or type(v) == type(default)) then
        return v
    end
    return default
end

function Window:_flagSet(key, value)
    if key == nil then
        return
    end
    self.S.flags[key] = value
    self:_save()
end

function Window:_color(key)
    if typeof(key) == "Color3" then
        return key
    end
    if key == "accent" and self._accent then
        return self._accent
    end
    local t = Lite.Themes[self.S.theme] or Lite.Themes.dark
    return t[key] or Lite.Themes.dark[key] or Color3.fromRGB(255, 0, 255)
end

function Window:_themed(obj, prop, key)
    local e = { obj = obj, prop = prop, key = key }
    table.insert(self._registry, e)
    obj[prop] = self:_color(key)
    return e
end

function Window:_setKey(entry, key, instant)
    entry.key = key
    tween(entry.obj, { [entry.prop] = self:_color(key) }, instant and 0 or 0.2)
end

function Window:_applyTheme(animate)
    local alive = {}
    for _, e in ipairs(self._registry) do
        if e.obj.Parent ~= nil then
            table.insert(alive, e)
            tween(e.obj, { [e.prop] = self:_color(e.key) }, animate and 0.25 or 0)
        end
    end
    self._registry = alive
end

function Lite.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Window)
    table.insert(Lite.Windows, self)

    self.Name = opts.Name or "LiteUI"
    self.Width = opts.Width or 264
    self.Alive = true
    self._conns, self._registry, self._boxes, self._binds = {}, {}, {}, {}
    self._onDestroy = {}
    self._onWidth = {}
    self._onVis = {}
    self._flagObjs = {}
    self._scrollers = {}
    self._panels = {}
    self._order = 0
    self._shown = false
    self._ready = false
    self._saveToken = 0
    self._saveOn = opts.Save ~= false
    self._file = opts.SaveFile or ("LiteUI_" .. self.Name .. ".json")
    self._attr = "LiteUI_" .. self.Name
    self._touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local keyDefault = keyOf(opts.Key, Enum.KeyCode.RightShift)
    self.S = self:_load({
        x = opts.X or (self._touchOnly and 64 or 18),
        y = opts.Y or (self._touchOnly and 40 or 120),
        opacity = opts.Opacity or 0.96,
        scale = opts.Scale or (self._touchOnly and 1.2 or 1),
        theme = opts.Theme or "dark",
        key = keyDefault.Name,
        accent = "",
        profiles = {},
        anim = opts.Animations ~= false,
        flags = {},
    })
    self.Flags = self.S.flags
    do
        local okA, cA = pcall(Color3.fromHex, self.S.accent)
        self._accent = okA and cA or nil
    end
    Lite.Animations = self.S.anim
    self._key = keyOf(self.S.key, keyDefault)

    local parent = opts.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
    local old = parent:FindFirstChild(self.Name)
    if old then
        old:Destroy()
    end

    self.Gui = make("ScreenGui", {
        Name = self.Name,
        ResetOnSpawn = false,
        DisplayOrder = opts.DisplayOrder or 100,
        IgnoreGuiInset = true,
        Enabled = false,
    }, parent)

    pcall(function()
        self.Gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    end)

    local vp = viewport()
    self.S.x = math.clamp(self.S.x, 0, math.max(vp.X - self.Width, 0))
    self.S.y = math.clamp(self.S.y, 0, math.max(vp.Y - 72, 0))
    self._rest = UDim2.fromOffset(self.S.x, self.S.y)

    -- CanvasGroup lets everything fade in/out together
    self.Root = make("CanvasGroup", {
        Name = "Root",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(self.Width, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = self._rest,
        GroupTransparency = 1,
    }, self.Gui)
    self._scale = make("UIScale", { Scale = self.S.scale }, self.Root)
    make("UIListLayout", {
        Padding = UDim.new(0, GAP),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Root)

    self.Gui.Destroying:Connect(function()
        self.Alive = false
        for i, w in ipairs(Lite.Windows) do
            if w == self then
                table.remove(Lite.Windows, i)
                break
            end
        end
        if self._auxGui then
            self._auxGui:Destroy()
        end
        for _, c in ipairs(self._conns) do
            c:Disconnect()
        end
        for _, fn in ipairs(self._onDestroy) do
            pcall(fn)
        end
    end)

    self:_installInput()
    if workspace.CurrentCamera then
        table.insert(self._conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:_onViewport()
        end))
    end
    if self._touchOnly and opts.MobileButton ~= false then
        self:_mobileButton()
    end
    task.defer(function()
        self._ready = true
    end)
    return self
end

function Window:OnDestroy(fn)
    table.insert(self._onDestroy, fn)
end

----------------------------------------------------------------
-- Window: input (hotkey, keybinds, drag + snap, sliders)
----------------------------------------------------------------
local SNAP, MARGIN, TOP_M = 16, 12, 44

function Window:_beginDrag(input)
    if self._noDrag then
        return
    end
    self._drag = {
        moved = false,
        sx = input.Position.X,
        sy = input.Position.Y,
        pos = self.Root.Position,
    }
end

function Window:_snap(x, y)
    local vp, sz = viewport(), self.Root.AbsoluteSize
    if x < SNAP + MARGIN then
        x = MARGIN
    elseif x + sz.X > vp.X - SNAP - MARGIN then
        x = vp.X - sz.X - MARGIN
    end
    if y < SNAP + TOP_M then
        y = TOP_M
    elseif y + sz.Y > vp.Y - SNAP - MARGIN then
        y = vp.Y - sz.Y - MARGIN
    end
    return x, y
end

function Window:_installInput()
    local function track(c)
        table.insert(self._conns, c)
    end

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if self._rebinding and input.UserInputType == Enum.UserInputType.Keyboard then
            local cb = self._rebinding
            self._rebinding = nil
            cb(input.KeyCode)
            return
        end
        if processed then
            return
        end
        if self._key ~= Enum.KeyCode.Unknown and input.KeyCode == self._key then
            self:Toggle()
            return
        end
        for _, b in ipairs(self._binds) do
            if b.Press and b.Value ~= Enum.KeyCode.Unknown and b.Value == input.KeyCode then
                task.spawn(b.Press)
            end
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if not isMove(input) then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_moveTip()
        end
        if self._slider then
            if not self._scrollLocked then
                self._scrollLocked = true
                self:_lockScroll(true)
            end
            self._slider(input.Position.X)
            return
        end
        local d = self._drag
        if not d then
            return
        end
        local dx, dy = input.Position.X - d.sx, input.Position.Y - d.sy
        if not d.moved and (dx * dx + dy * dy) > 9 then
            d.moved = true
        end
        if d.moved then
            local vp, sz = viewport(), self.Root.AbsoluteSize
            self._rest = UDim2.fromOffset(
                math.clamp(d.pos.X.Offset + dx, 0, math.max(vp.X - sz.X, 0)),
                math.clamp(d.pos.Y.Offset + dy, 0, math.max(vp.Y - sz.Y, 0))
            )
            self.Root.Position = self._rest
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if not isPress(input) then
            return
        end
        if self._slider then
            self._slider = nil
            if self._sliderRelease then
                self._sliderRelease()
                self._sliderRelease = nil
            end
            if self._scrollLocked then
                self._scrollLocked = false
                self:_lockScroll(false)
            end
            self:_save()
        end
        local d = self._drag
        self._drag = nil
        if d and d.moved then
            local x, y = self:_snap(self._rest.X.Offset, self._rest.Y.Offset)
            self._rest = UDim2.fromOffset(x, y)
            tween(self.Root, { Position = self._rest }, 0.2, QUINT)
            self.S.x, self.S.y = x, y
            self:_save()
        end
    end))
end

----------------------------------------------------------------
-- Window: show / hide / setters
----------------------------------------------------------------
function Window:Show()
    if not self.Alive then
        return
    end
    self._shown = true
    self.Gui.Enabled = true
    for _, fn in ipairs(self._onVis) do
        task.spawn(fn, true)
    end
    self.Root.Position = self._rest + UDim2.fromOffset(0, 14)
    tween(self.Root, { GroupTransparency = 0, Position = self._rest }, 0.42, QUINT)
end

function Window:Hide(onDone)
    if not self.Alive then
        return
    end
    self._shown = false
    for _, fn in ipairs(self._onVis) do
        task.spawn(fn, false)
    end
    tween(self.Root, {
        GroupTransparency = 1,
        Position = self._rest + UDim2.fromOffset(0, 12),
    }, 0.26, QUINT, Enum.EasingDirection.In)
    task.delay(0.26, function()
        if self.Alive and not self._shown then
            self.Gui.Enabled = false
        end
        if onDone then
            onDone()
        end
    end)
end

function Window:Toggle()
    if self._shown then
        self:Hide()
    else
        self:Show()
    end
end

function Window:Destroy()
    if not self.Alive then
        return
    end
    self:Hide(function()
        if self.Alive then
            self.Gui:Destroy()
        end
    end)
end

function Window:SetTheme(name)
    if not Lite.Themes[name] then
        return
    end
    self.S.theme = name
    self:_applyTheme(true)
    self:_save()
end

function Window:SetOpacity(v)
    self.S.opacity = math.clamp(v, 0.5, 1)
    for _, b in ipairs(self._boxes) do
        b.BackgroundTransparency = 1 - self.S.opacity
    end
    self:_save()
end

function Window:SetScale(v)
    self.S.scale = math.clamp(v, 0.5, 2)
    self._scale.Scale = self.S.scale
    self:_onViewport()
    self:_save()
end

function Window:SetAnimations(on)
    Lite.Animations = on and true or false
    self.S.anim = Lite.Animations
    self:_save()
end

function Window:_lockScroll(locked)
    for _, sc in ipairs(self._scrollers) do
        sc.ScrollingEnabled = not locked
    end
end

-- keep the window on screen after a panel opens or the screen changes
function Window:_keepOnScreen()
    self._kosToken = (self._kosToken or 0) + 1
    local mine = self._kosToken
    task.delay(0.4, function()
        if mine ~= self._kosToken or not self.Alive then
            return
        end
        local vp, sz = viewport(), self.Root.AbsoluteSize
        local x = math.clamp(self._rest.X.Offset, 0, math.max(vp.X - sz.X, 0))
        local y = math.clamp(self._rest.Y.Offset, 0, math.max(vp.Y - sz.Y, 0))
        if x ~= self._rest.X.Offset or y ~= self._rest.Y.Offset then
            self._rest = UDim2.fromOffset(x, y)
            if self._shown then
                tween(self.Root, { Position = self._rest }, 0.3, QUINT)
            end
        end
    end)
end

function Window:_onViewport()
    if not self.Alive then
        return
    end
    local vp = viewport()
    local maxW = math.max(math.floor((vp.X - 24) / self._scale.Scale), 200)
    if self.Width > maxW then
        self:SetWidth(maxW)
    end
    for _, p in ipairs(self._panels) do
        p:_apply()
    end
    self:_keepOnScreen()
end

function Window:SetKey(key)
    self._key = keyOf(key, Enum.KeyCode.Unknown)
    self.S.key = self._key.Name
    self:_save()
end

function Window:_box(name, height, class)
    self._order += 1
    local f = make(class or "Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1 - self.S.opacity,
        BorderSizePixel = 0,
        LayoutOrder = self._order,
        ClipsDescendants = true,
    }, self.Root)
    self:_themed(f, "BackgroundColor3", "bg")
    make("UICorner", { CornerRadius = UDim.new(0, 10) }, f)
    local st = make("UIStroke", { Thickness = 1, Transparency = 0.9 }, f)
    self:_themed(st, "Color", "line")
    table.insert(self._boxes, f)
    return f
end

----------------------------------------------------------------
-- Card
----------------------------------------------------------------
function Window:Card(opts)
    opts = opts or {}
    local win = self
    local W = self.Width
    local FULL_H, MINI_H = opts.Height or 72, 36

    self._cardCount = (self._cardCount or 0) + 1
    local card = setmetatable({
        Window = self,
        _buttons = {},
        _index = self._cardCount,
        _pinned = false,
        _mini = false,
        _full = FULL_H,
        _miniH = MINI_H,
        _width = W,
        _onPin = opts.OnPin,
    }, Card)

    local f = self:_box("Card", FULL_H)
    f.Active = true
    card.Frame = f

    card.TitleLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, win._touchOnly and -134 or -122, 0, 20),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(opts.Title or ""),
    }, f)
    self:_themed(card.TitleLabel, "TextColor3", "text")

    card.SubLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 37),
        Size = UDim2.new(1, win._touchOnly and -134 or -122, 0, 18),
        Font = Enum.Font.BuilderSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(opts.Subtitle or ""),
    }, f)
    self:_themed(card.SubLabel, "TextColor3", "sub")

    card.Divider = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, -94, 0.5, 0),
        Size = UDim2.fromOffset(1, 40),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, f)
    self:_themed(card.Divider, "BackgroundColor3", "line")

    card.ValueLabel = make("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -86, 0, 0),
        Size = UDim2.fromOffset(76, FULL_H),
        Font = Enum.Font.BuilderSansExtraBold,
        TextSize = 34,
        Text = tostring(opts.Value or "–"),
        AutoButtonColor = false,
    }, f)
    card._toneEntry = self:_themed(card.ValueLabel, "TextColor3", opts.Tone or "sub")

    card.PinLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -86, 0, FULL_H - 19),
        Size = UDim2.fromOffset(76, 12),
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 11,
        Text = "pinned",
        TextTransparency = 1,
    }, f)
    self:_themed(card.PinLabel, "TextColor3", "sub")

    -- hover reveals header buttons (always visible on touch-only devices)
    if not self._touchOnly then
        f.MouseEnter:Connect(function()
            for _, b in ipairs(card._buttons) do
                tween(b.Instance, { TextTransparency = 0 }, 0.15)
            end
        end)
        f.MouseLeave:Connect(function()
            for _, b in ipairs(card._buttons) do
                tween(b.Instance, { TextTransparency = 1 }, 0.15)
            end
        end)
    end

    f.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            card:_flash()
        end
    end)

    if opts.Draggable ~= false then
        f.InputBegan:Connect(function(input)
            if isPress(input) then
                win:_beginDrag(input)
            end
        end)
    end

    if opts.Pinnable ~= false then
        card.ValueLabel.MouseButton1Click:Connect(function()
            card:SetPinned(not card._pinned)
        end)
    end

    if opts.Closable ~= false then
        card:AddButton("×", function()
            win:Destroy()
        end)
    end
    if opts.Minimizable ~= false then
        card._miniBtn = card:AddButton("–", function()
            card:Minimize(not card._mini)
        end)
        if self:_flagGet("_mini:" .. card._index, false) then
            card:Minimize(true, true)
        end
    end

    return card
end

function Card:AddButton(text, callback)
    local win = self.Window
    local slot = #self._buttons
    local BTN = win._touchOnly and 28 or 18
    local b = make("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -(BTN + 4) - slot * (BTN + 2), 0, 3),
        Size = UDim2.fromOffset(BTN, BTN),
        Font = Enum.Font.BuilderSansBold,
        TextSize = win._touchOnly and 20 or 16,
        Text = text,
        TextTransparency = win._touchOnly and 0 or 1,
        AutoButtonColor = false,
        ZIndex = 5,
    }, self.Frame)
    win:_themed(b, "TextColor3", "sub")
    b.MouseEnter:Connect(function()
        tween(b, { TextColor3 = win:_color("text") }, 0.12)
    end)
    b.MouseLeave:Connect(function()
        tween(b, { TextColor3 = win:_color("sub") }, 0.12)
    end)
    if callback then
        b.MouseButton1Click:Connect(callback)
    end

    local obj = { Instance = b }
    function obj:SetText(t)
        b.Text = t
    end
    table.insert(self._buttons, obj)
    return obj
end

-- tap on touch devices briefly reveals the header buttons
function Card:_flash()
    for _, b in ipairs(self._buttons) do
        tween(b.Instance, { TextTransparency = 0 }, 0.15)
    end
    self._flashToken = (self._flashToken or 0) + 1
    local mine = self._flashToken
    task.delay(3, function()
        if mine == self._flashToken and not self.Window._touchOnly then
            for _, b in ipairs(self._buttons) do
                tween(b.Instance, { TextTransparency = 1 }, 0.2)
            end
        end
    end)
end

-- Adds a header button that opens/closes a panel and swaps its glyph
function Card:Attach(panel, closedGlyph, openGlyph)
    closedGlyph = closedGlyph or "▾"
    openGlyph = openGlyph or "▴"
    local btn
    btn = self:AddButton(panel:IsOpen() and openGlyph or closedGlyph, function()
        panel:SetOpen(not panel:IsOpen())
        btn:SetText(panel:IsOpen() and openGlyph or closedGlyph)
    end)
    return btn
end

function Card:SetTone(key, instant)
    self.Window:_setKey(self._toneEntry, key, instant)
end

function Card:Set(t)
    if t.Title ~= nil then
        self.TitleLabel.Text = tostring(t.Title)
    end
    if t.Subtitle ~= nil then
        self.SubLabel.Text = tostring(t.Subtitle)
    end
    if t.Value ~= nil then
        local v = tostring(t.Value)
        if v ~= self.ValueLabel.Text then
            self.ValueLabel.Text = v
            if self.Window._shown then
                self.ValueLabel.TextTransparency = 1
                self.ValueLabel.Position = UDim2.new(1, -86, 0, 8)
                tween(self.ValueLabel, {
                    TextTransparency = 0,
                    Position = UDim2.new(1, -86, 0, 0),
                }, 0.4, QUINT)
            end
        end
    end
    if t.Tone then
        self:SetTone(t.Tone)
    end
end

function Card:_updatePin(instant)
    tween(self.PinLabel, {
        TextTransparency = (self._pinned and not self._mini) and 0 or 1,
    }, instant and 0 or 0.2)
end

function Card:SetPinned(p)
    self._pinned = p and true or false
    self:_updatePin()
    if self._onPin then
        task.spawn(self._onPin, self._pinned)
    end
end

function Card:IsPinned()
    return self._pinned
end

function Card:Minimize(state, instant)
    self._mini = state and true or false
    local m = self._mini
    local d = instant and 0 or 0.3

    if self._miniBtn then
        self._miniBtn:SetText(m and "+" or "–")
    end
    tween(self.Frame, { Size = UDim2.new(1, 0, 0, m and self._miniH or self._full) }, d, QUINT)
    tween(self.TitleLabel, {
        Position = UDim2.fromOffset(16, m and 8 or 14),
        TextSize = m and 15 or 17,
    }, d, QUINT)
    tween(self.SubLabel, { TextTransparency = m and 1 or 0 }, instant and 0 or 0.2)
    tween(self.Divider, { Size = UDim2.fromOffset(1, m and 18 or 40) }, d, QUINT)
    tween(self.ValueLabel, {
        Size = UDim2.fromOffset(76, m and self._miniH or self._full),
        TextSize = m and 20 or 34,
    }, d, QUINT)
    self:_updatePin(instant)

    if not instant then
        self.Window:_flagSet("_mini:" .. self._index, self._mini)
    end
end

----------------------------------------------------------------
-- Panel
----------------------------------------------------------------
function Window:Panel(opts)
    opts = opts or {}
    local panel = setmetatable({ Window = self, _items = {} }, Panel)

    -- a CanvasGroup so the whole panel can fade as it opens and closes
    local f = self:_box(opts.Name or "Panel", 0, "CanvasGroup")
    f.Visible = false
    f.GroupTransparency = 1
    panel.Frame = f
    panel._max = opts.MaxHeight

    -- every panel scrolls, so nothing can run off a small screen
    local content = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = self._touchOnly and 4 or 3,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, f)
    self:_themed(content, "ScrollBarImageColor3", "sub")
    table.insert(self._scrollers, content)
    make("UIListLayout", {
        Padding = UDim.new(0, GAP),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    }, content)
    panel.Content = content

    local open = opts.Open == true
    if opts.Persist and opts.Name then
        panel._flagKey = "_open:" .. opts.Name
        open = self:_flagGet(panel._flagKey, open)
    end
    panel._open = open
    if open then
        f.Visible = true
        f.GroupTransparency = 0
    end
    table.insert(self._panels, panel)
    return panel
end

-- tallest this panel may get: its own MaxHeight, and never more than the screen allows
function Panel:_cap()
    local sc = self.Window._scale.Scale
    local cap = math.max(viewport().Y / sc - 190, 140)
    if self._max then
        cap = math.min(cap, self._max)
    end
    return cap
end

function Panel:_height()
    local n, h = 0, 16
    for _, it in ipairs(self._items) do
        if not (it.hidden or it.filtered or it.collapsed) then
            n += 1
            h += it.h
        end
    end
    if n == 0 then
        return 16
    end
    h += GAP * (n - 1)
    h = math.min(h, self:_cap())
    return h
end

function Panel:_apply(instant)
    local f = self.Frame
    local win = self.Window
    instant = instant or not win._ready
    local d = instant and 0 or 0.38

    if self._open then
        f.Visible = true
        tween(f, { Size = UDim2.new(1, 0, 0, self:_height()), GroupTransparency = 0 }, d, QUINT)
    else
        if not f.Visible then
            return
        end
        tween(f, { Size = UDim2.new(1, 0, 0, 0), GroupTransparency = 1 }, instant and 0 or 0.3, QUINT)
        if instant then
            f.Visible = false
        else
            task.delay(0.32, function()
                if not self._open then
                    f.Visible = false
                end
            end)
        end
    end
    if win._ready then
        win:_keepOnScreen()
    end
end

function Panel:SetOpen(open, instant)
    self._open = open and true or false
    if self._flagKey then
        self.Window:_flagSet(self._flagKey, self._open)
    end
    self:_apply(instant)
end

function Panel:IsOpen()
    return self._open
end

function Panel:_row(h)
    local item = { h = h }
    item.row = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, h),
        LayoutOrder = #self._items + 1,
    }, self.Content)
    table.insert(self._items, item)
    self:_apply()
    return item.row, item
end

local function rowLabel(win, row, text, width)
    local l = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, width, 1, 0),
        Font = Enum.Font.BuilderSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = text,
    }, row)
    win:_themed(l, "TextColor3", "sub")
    return l
end

local function smallButton(win, row, text, width)
    local b = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(width, 24),
        BorderSizePixel = 0,
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 13,
        Text = text,
        AutoButtonColor = false,
    }, row)
    win:_themed(b, "BackgroundColor3", "track")
    win:_themed(b, "TextColor3", "text")
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    pressable(b)
    return b
end

function Panel:Label(o)
    if type(o) == "string" then
        o = { Text = o }
    end
    o = o or {}
    local win = self.Window
    local row = self:_row(20)
    local l = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.BuilderSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = o.Text or "",
    }, row)
    win:_themed(l, "TextColor3", o.Tone or "sub")
    return {
        Instance = l,
        Set = function(_, t)
            l.Text = tostring(t)
        end,
    }
end

function Panel:Separator()
    local row = self:_row(1)
    local l = make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, row)
    self.Window:_themed(l, "BackgroundColor3", "line")
end

function Panel:Button(o)
    o = o or {}
    local win = self.Window
    local row = self:_row(26)
    local b = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 14,
        Text = o.Name or "Button",
        AutoButtonColor = false,
    }, row)
    win:_themed(b, "BackgroundColor3", "track")
    win:_themed(b, "TextColor3", o.Tone or "text")
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    pressable(b)
    b.MouseEnter:Connect(function()
        tween(b, { BackgroundTransparency = 0.4 }, 0.12)
    end)
    b.MouseLeave:Connect(function()
        tween(b, { BackgroundTransparency = 0 }, 0.12)
    end)
    b.MouseButton1Click:Connect(function()
        if o.Callback then
            task.spawn(o.Callback)
        end
    end)
    return {
        Instance = b,
        SetText = function(_, t)
            b.Text = t
        end,
    }
end

function Panel:Toggle(o)
    o = o or {}
    local win = self.Window
    local value = win:_flagGet(o.Flag, o.Default == true)
    local row = self:_row(26)
    local nameLbl = rowLabel(win, row, o.Name or "Toggle", 150)

    local track = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(34, 18),
        BorderSizePixel = 0,
    }, row)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local trackE = win:_themed(track, "BackgroundColor3", value and "accent" or "track")
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, value and 18 or 2, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BorderSizePixel = 0,
    }, track)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    win:_themed(knob, "BackgroundColor3", "text")

    local click = make("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }, row)

    local obj = { Value = value }
    function obj:Set(v, silent)
        v = v and true or false
        self.Value = v
        win:_setKey(trackE, v and "accent" or "track")
        tween(knob, { Position = UDim2.new(0, v and 18 or 2, 0.5, 0) }, 0.28, Enum.EasingStyle.Back)
        win:_flagSet(o.Flag, v)
        if not silent and o.Callback then
            task.spawn(o.Callback, v)
        end
    end
    click.MouseButton1Click:Connect(function()
        obj:Set(not obj.Value)
    end)

    if o.Keybind ~= nil and not win._touchOnly then
        local def = keyOf(o.Keybind, Enum.KeyCode.Unknown)
        local fk = o.Flag and (o.Flag .. "_key")
        local kc = keyOf(win:_flagGet(fk, def.Name), def)
        local function label()
            return kc == Enum.KeyCode.Unknown and "None" or kc.Name
        end
        nameLbl.Size = UDim2.new(0, 124, 1, 0)
        local chip = smallButton(win, row, label(), 64)
        chip.Position = UDim2.new(1, -42, 0.5, 0)
        chip.TextTruncate = Enum.TextTruncate.AtEnd
        local bind = {
            Value = kc,
            Press = function()
                obj:Set(not obj.Value)
            end,
        }
        table.insert(win._binds, bind)
        chip.MouseButton1Click:Connect(function()
            if win._rebinding then
                win._rebinding(Enum.KeyCode.Escape)
            end
            chip.Text = "…"
            win._rebinding = function(k)
                if k == Enum.KeyCode.Escape then
                    chip.Text = label()
                    return
                elseif k == Enum.KeyCode.Backspace then
                    k = Enum.KeyCode.Unknown
                end
                kc = k
                bind.Value = k
                win:_flagSet(fk, k.Name)
                chip.Text = label()
            end
        end)
    end

    if o.Flag and o.Callback then
        task.defer(o.Callback, value)
    end
    return obj
end

function Panel:Slider(o)
    o = o or {}
    local win = self.Window
    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 0
    local fmt = o.Format or function(v)
        return tostring(v) .. (o.Suffix or "")
    end

    local function norm(v)
        v = math.clamp(v, min, max)
        if step > 0 then
            v = min + math.floor((v - min) / step + 0.5) * step
        end
        return math.floor(v * 10000 + 0.5) / 10000
    end

    local value = norm(tonumber(win:_flagGet(o.Flag, o.Default or min)) or min)
    local row = self:_row(26)
    rowLabel(win, row, o.Name or "Slider", 80)

    local typeable = o.Input ~= false and o.Format == nil
    local out = make("TextBox", {
        TextEditable = typeable,
        ClearTextOnFocus = true,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)
    win:_themed(out, "TextColor3", "text")

    local hit = make("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(0, 84, 0, 0),
        Size = UDim2.new(1, -128, 1, 0),
    }, row)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4),
        BorderSizePixel = 0,
    }, hit)
    win:_themed(track, "BackgroundColor3", "track")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track)
    win:_themed(fill, "BackgroundColor3", "accent")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
    }, hit)
    win:_themed(knob, "BackgroundColor3", "text")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local obj = { Value = value }
    local function draw()
        local a = (max > min) and (obj.Value - min) / (max - min) or 0
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        out.Text = fmt(obj.Value)
    end
    function obj:Set(v, silent)
        self.Value = norm(v)
        draw()
        win:_flagSet(o.Flag, self.Value)
        if not silent and o.Callback then
            task.spawn(o.Callback, self.Value)
        end
    end
    draw()

    out.FocusLost:Connect(function()
        local n = tonumber(out.Text:match("-?%d*%.?%d+"))
        if n then
            obj:Set(n)
        else
            draw()
        end
    end)

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            tween(knob, { Size = UDim2.fromOffset(17, 17) }, 0.18, Enum.EasingStyle.Back)
            win._sliderRelease = function()
                tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.22, QUINT)
            end
            win._slider = function(x)
                local a = math.clamp((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1), 0, 1)
                obj:Set(min + a * (max - min))
            end
            win._slider(input.Position.X)
        end
    end)

    if o.Flag and o.Callback then
        task.defer(o.Callback, value)
    end
    return obj
end

function Panel:Choice(o)
    o = o or {}
    local win = self.Window
    local options = o.Options or {}
    local value = win:_flagGet(o.Flag, o.Default or options[1])
    if not table.find(options, value) then
        value = options[1]
    end

    local row = self:_row(26)
    rowLabel(win, row, o.Name or "Choice", 100)
    local btn = smallButton(win, row, capitalize(value or "-"), 96)

    local obj = { Value = value }
    function obj:Set(v, silent)
        if not table.find(options, v) then
            return
        end
        self.Value = v
        btn.Text = capitalize(v)
        win:_flagSet(o.Flag, v)
        if not silent and o.Callback then
            task.spawn(o.Callback, v)
        end
    end
    btn.MouseButton1Click:Connect(function()
        if #options == 0 then
            return
        end
        local idx = table.find(options, obj.Value) or 0
        obj:Set(options[idx % #options + 1])
    end)

    if o.Flag and o.Callback then
        task.defer(o.Callback, value)
    end
    return obj
end

function Panel:Keybind(o)
    o = o or {}
    local win = self.Window
    local default = keyOf(o.Default, Enum.KeyCode.Unknown)
    local kc = keyOf(win:_flagGet(o.Flag, default.Name), default)

    local row = self:_row(26)
    rowLabel(win, row, o.Name or "Keybind", 100)
    local function label()
        return kc == Enum.KeyCode.Unknown and "None" or kc.Name
    end
    local btn = smallButton(win, row, label(), 96)

    local obj = { Value = kc, Press = o.Press }
    function obj:Set(k, silent)
        kc = k
        self.Value = k
        btn.Text = label()
        win:_flagSet(o.Flag, k.Name)
        if not silent and o.Callback then
            task.spawn(o.Callback, k)
        end
    end

    btn.MouseButton1Click:Connect(function()
        if win._rebinding then
            win._rebinding(Enum.KeyCode.Escape)
        end
        btn.Text = "Press a key…"
        win._rebinding = function(k)
            if k == Enum.KeyCode.Backspace then
                obj:Set(Enum.KeyCode.Unknown)
            elseif k ~= Enum.KeyCode.Escape and k ~= Enum.KeyCode.Unknown then
                obj:Set(k)
            else
                btn.Text = label()
            end
        end
    end)

    table.insert(win._binds, obj)
    if o.Flag and o.Callback then
        task.defer(o.Callback, kc)
    end
    return obj
end

function Panel:List(o)
    o = o or {}
    local win = self.Window
    local max, rowH = o.Max or 5, 22
    local row, item = self:_row(rowH)

    local nameLbls, valLbls = {}, {}
    for i = 1, max do
        local y = (i - 1) * rowH
        local n = make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, -54, 0, rowH),
            Font = Enum.Font.BuilderSans,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
            Visible = false,
        }, row)
        win:_themed(n, "TextColor3", "text")
        local v = make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -50, 0, y),
            Size = UDim2.fromOffset(50, rowH),
            Font = Enum.Font.BuilderSansBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = "",
            Visible = false,
        }, row)
        win:_themed(v, "TextColor3", "sub")
        nameLbls[i], valLbls[i] = n, v
    end

    local empty = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, rowH),
        Font = Enum.Font.BuilderSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = o.Empty or "Nothing yet",
    }, row)
    win:_themed(empty, "TextColor3", "sub")

    local entries = {}
    local obj = {}
    local function render()
        for i = 1, max do
            local e = entries[i]
            nameLbls[i].Visible = e ~= nil
            valLbls[i].Visible = e ~= nil
            if e then
                nameLbls[i].Text = e.name
                valLbls[i].Text = tostring(e.value)
            end
        end
        empty.Visible = #entries == 0
        item.h = math.max(#entries, 1) * rowH
        row.Size = UDim2.new(1, 0, 0, item.h)
        self:_apply()
    end

    function obj:Push(name, value)
        for i, e in ipairs(entries) do
            if e.name == name then
                table.remove(entries, i)
                break
            end
        end
        table.insert(entries, 1, { name = tostring(name), value = value })
        while #entries > max do
            table.remove(entries)
        end
        render()
    end

    function obj:Clear()
        entries = {}
        render()
    end

    render()
    return obj
end

----------------------------------------------------------------
-- More elements: Section, Paragraph, TextBox, Bar, Dropdown, ColorPicker
----------------------------------------------------------------
function Panel:Section(text)
    local win = self.Window
    local row = self:_row(18)
    local l = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(text or ""),
    }, row)
    win:_themed(l, "TextColor3", "text")
    return {
        Instance = l,
        Set = function(_, t)
            l.Text = tostring(t)
        end,
    }
end

function Panel:Paragraph(o)
    if type(o) == "string" then
        o = { Text = o }
    end
    o = o or {}
    local win = self.Window
    local row, item = self:_row(18)
    local l = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.BuilderSans,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "",
    }, row)
    win:_themed(l, "TextColor3", o.Tone or "sub")

    local function set(t)
        l.Text = tostring(t)
        local size = TextService:GetTextSize(l.Text, 13, Enum.Font.BuilderSans, Vector2.new(win.Width - 28, 1000))
        item.h = math.max(math.ceil(size.Y), 16)
        row.Size = UDim2.new(1, 0, 0, item.h)
        self:_apply()
    end
    set(o.Text or "")
    return {
        Instance = l,
        Set = function(_, t)
            set(t)
        end,
    }
end

function Panel:TextBox(o)
    o = o or {}
    local win = self.Window
    local value = tostring(win:_flagGet(o.Flag, o.Default or ""))
    local row = self:_row(26)
    rowLabel(win, row, o.Name or "Text", 80)

    local box = make("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, -84, 0, 24),
        BorderSizePixel = 0,
        Font = Enum.Font.BuilderSans,
        TextSize = 13,
        Text = value,
        PlaceholderText = o.Placeholder or "",
        ClearTextOnFocus = o.ClearOnFocus == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    win:_themed(box, "BackgroundColor3", "track")
    win:_themed(box, "TextColor3", "text")
    win:_themed(box, "PlaceholderColor3", "sub")
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

    if o.Numeric then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local clean = box.Text:gsub("[^%d%.%-]", "")
            if clean ~= box.Text then
                box.Text = clean
            end
        end)
    end

    local obj = { Value = value, Instance = box }
    function obj:Set(v, silent)
        v = tostring(v)
        self.Value = v
        box.Text = v
        win:_flagSet(o.Flag, v)
        if not silent and o.Callback then
            task.spawn(o.Callback, v)
        end
    end
    box.FocusLost:Connect(function(enter)
        if o.OnlyEnter and not enter then
            box.Text = obj.Value
            return
        end
        local text = box.Text
        local num = tonumber(text)
        if o.Numeric and num and (o.Min or o.Max) then
            text = tostring(math.clamp(num, o.Min or -math.huge, o.Max or math.huge))
        end
        obj:Set(text)
    end)

    if o.Flag and o.Callback then
        task.defer(o.Callback, value)
    end
    return obj
end

function Panel:Bar(o)
    o = o or {}
    local win = self.Window
    local min, max = o.Min or 0, o.Max or 100
    local fmt = o.Format or function(v)
        return tostring(v)
    end

    local row = self:_row(26)
    rowLabel(win, row, o.Name or "Bar", 80)
    local out = make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)
    win:_themed(out, "TextColor3", "text")

    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 84, 0.5, 0),
        Size = UDim2.new(1, -128, 0, 6),
        BorderSizePixel = 0,
    }, row)
    win:_themed(track, "BackgroundColor3", "track")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track)
    local fillE = win:_themed(fill, "BackgroundColor3", o.Tone or "accent")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local obj = { Value = o.Default or min }
    function obj:Set(v)
        v = math.clamp(v, min, max)
        self.Value = v
        local a = max > min and (v - min) / (max - min) or 0
        tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.2)
        out.Text = fmt(v)
    end
    function obj:SetTone(key)
        win:_setKey(fillE, key)
    end
    obj:Set(obj.Value)
    return obj
end

function Panel:Dropdown(o)
    o = o or {}
    local win = self.Window
    local options = o.Options or {}
    local multi = o.Multi == true
    local ITEM_H, HEAD_H = 24, 26

    local value
    if multi then
        value = {}
        local saved = win:_flagGet(o.Flag, type(o.Default) == "table" and o.Default or {})
        for _, v in ipairs(saved) do
            if table.find(options, v) and not table.find(value, v) then
                table.insert(value, v)
            end
        end
    else
        value = win:_flagGet(o.Flag, o.Default or options[1])
        if not table.find(options, value) then
            value = options[1]
        end
    end

    local row, item = self:_row(HEAD_H)
    row.ClipsDescendants = true
    local lbl = rowLabel(win, row, o.Name or "Dropdown", 80)
    lbl.Size = UDim2.fromOffset(80, HEAD_H)

    local head = smallButton(win, row, "", 140)
    head.AnchorPoint = Vector2.new(1, 0)
    head.Position = UDim2.new(1, 0, 0, 1)

    local listF = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, HEAD_H + 4),
        Size = UDim2.new(1, 0, 0, #options * ITEM_H),
        Visible = false,
    }, row)

    local obj = { Value = value }
    local entries = {}

    local function isSel(opt)
        if multi then
            return table.find(value, opt) ~= nil
        end
        return value == opt
    end
    local function summary()
        if multi then
            if #value == 0 then
                return "None"
            elseif #value <= 2 then
                return table.concat(value, ", ")
            end
            return #value .. " selected"
        end
        return tostring(value)
    end
    local function refresh(instant)
        head.Text = summary()
        for i, opt in ipairs(options) do
            win:_setKey(entries[i], isSel(opt) and "accent" or "text", instant)
        end
    end

    local open = false
    local function setOpen(state)
        open = state
        item.h = open and (HEAD_H + 4 + #options * ITEM_H - 2) or HEAD_H
        if open then
            listF.Visible = true
        end
        tween(row, { Size = UDim2.new(1, 0, 0, item.h) }, 0.25, QUINT)
        if not open then
            task.delay(0.27, function()
                if not open then
                    listF.Visible = false
                end
            end)
        end
        self:_apply()
    end
    head.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    for i, opt in ipairs(options) do
        local b = make("TextButton", {
            Position = UDim2.fromOffset(0, (i - 1) * ITEM_H),
            Size = UDim2.new(1, 0, 0, ITEM_H - 2),
            BorderSizePixel = 0,
            Font = Enum.Font.BuilderSans,
            TextSize = 13,
            Text = tostring(opt),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
        }, listF)
        win:_themed(b, "BackgroundColor3", "track")
        entries[i] = win:_themed(b, "TextColor3", isSel(opt) and "accent" or "text")
        make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
        b.MouseButton1Click:Connect(function()
            if multi then
                local nv = table.clone(value)
                local idx = table.find(nv, opt)
                if idx then
                    table.remove(nv, idx)
                else
                    table.insert(nv, opt)
                end
                obj:Set(nv)
            else
                obj:Set(opt)
                setOpen(false)
            end
        end)
    end

    function obj:Set(v, silent)
        if multi then
            if type(v) ~= "table" then
                return
            end
            local nv = {}
            for _, x in ipairs(v) do
                if table.find(options, x) and not table.find(nv, x) then
                    table.insert(nv, x)
                end
            end
            value = nv
        else
            if not table.find(options, v) then
                return
            end
            value = v
        end
        self.Value = value
        refresh()
        win:_flagSet(o.Flag, multi and table.clone(value) or value)
        if not silent and o.Callback then
            task.spawn(o.Callback, value)
        end
    end

    refresh(true)
    if o.Flag and o.Callback then
        task.defer(o.Callback, value)
    end
    return obj
end

function Panel:ColorPicker(o)
    o = o or {}
    local win = self.Window
    local def = typeof(o.Default) == "Color3" and o.Default or Color3.fromRGB(120, 200, 150)
    local ok, saved = pcall(Color3.fromHex, tostring(win:_flagGet(o.Flag, def:ToHex())))
    local color = ok and saved or def
    local h, s, v = color:ToHSV()
    local HEAD_H, BAR_H = 26, 20

    local row, item = self:_row(HEAD_H)
    row.ClipsDescendants = true
    local lbl = rowLabel(win, row, o.Name or "Color", 150)
    lbl.Size = UDim2.fromOffset(150, HEAD_H)

    local swatch = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 3),
        Size = UDim2.fromOffset(44, 20),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = color,
    }, row)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, swatch)
    local sst = make("UIStroke", { Thickness = 1, Transparency = 0.8 }, swatch)
    win:_themed(sst, "Color", "line")

    local body = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, HEAD_H + 6),
        Size = UDim2.new(1, 0, 0, 3 * (BAR_H + 2)),
        Visible = false,
    }, row)

    local obj = { Value = color }
    local grads, knobs = {}, {}
    local commit -- forward

    local function miniSlider(i, setAlpha)
        local hit = make("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(0, (i - 1) * (BAR_H + 2)),
            Size = UDim2.new(1, 0, 0, BAR_H),
        }, body)
        local track = make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 8),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
        }, hit)
        make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        grads[i] = make("UIGradient", {}, track)
        local knob = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
        }, hit)
        make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        make("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.35 }, knob)
        knobs[i] = knob

        hit.InputBegan:Connect(function(input)
            if isPress(input) then
                win._slider = function(x)
                    setAlpha(math.clamp((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1), 0, 1))
                end
                win._slider(input.Position.X)
            end
        end)
    end

    local rainbow = {}
    for k = 0, 6 do
        table.insert(rainbow, ColorSequenceKeypoint.new(k / 6, Color3.fromHSV(k / 6, 1, 1)))
    end

    local function draw()
        local c = Color3.fromHSV(h, s, v)
        obj.Value = c
        swatch.BackgroundColor3 = c
        grads[1].Color = ColorSequence.new(rainbow)
        grads[2].Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
        grads[3].Color = ColorSequence.new(Color3.fromHSV(h, s, 0), Color3.fromHSV(h, s, 1))
        knobs[1].Position = UDim2.new(h, 0, 0.5, 0)
        knobs[2].Position = UDim2.new(s, 0, 0.5, 0)
        knobs[3].Position = UDim2.new(v, 0, 0.5, 0)
    end
    commit = function()
        draw()
        win:_flagSet(o.Flag, obj.Value:ToHex())
        if o.Callback then
            task.spawn(o.Callback, obj.Value)
        end
    end

    miniSlider(1, function(a)
        h = a
        commit()
    end)
    miniSlider(2, function(a)
        s = a
        commit()
    end)
    miniSlider(3, function(a)
        v = a
        commit()
    end)
    draw()

    function obj:Set(c, silent)
        h, s, v = c:ToHSV()
        draw()
        win:_flagSet(o.Flag, self.Value:ToHex())
        if not silent and o.Callback then
            task.spawn(o.Callback, self.Value)
        end
    end

    local open = false
    swatch.MouseButton1Click:Connect(function()
        open = not open
        item.h = open and (HEAD_H + 6 + 3 * (BAR_H + 2)) or HEAD_H
        if open then
            body.Visible = true
        end
        tween(row, { Size = UDim2.new(1, 0, 0, item.h) }, 0.25, QUINT)
        if not open then
            task.delay(0.27, function()
                if not open then
                    body.Visible = false
                end
            end)
        end
        self:_apply()
    end)

    if o.Flag and o.Callback then
        task.defer(o.Callback, obj.Value)
    end
    return obj
end

----------------------------------------------------------------
-- ButtonRow
----------------------------------------------------------------
function Panel:ButtonRow(list)
    local win = self.Window
    local row = self:_row(26)
    local n = #list
    local objs = {}
    local wOff = -6 * (n - 1) / n

    for i, o in ipairs(list) do
        local b = make("TextButton", {
            Position = UDim2.new((i - 1) / n, (i - 1) * (wOff + 6), 0, 0),
            Size = UDim2.new(1 / n, wOff, 1, 0),
            BorderSizePixel = 0,
            Font = Enum.Font.BuilderSansMedium,
            TextSize = 14,
            Text = o.Name or "Button",
            AutoButtonColor = false,
        }, row)
        win:_themed(b, "BackgroundColor3", "track")
        win:_themed(b, "TextColor3", o.Tone or "text")
        make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        pressable(b)
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundTransparency = 0.4 }, 0.12)
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundTransparency = 0 }, 0.12)
        end)
        b.MouseButton1Click:Connect(function()
            if o.Callback then
                task.spawn(o.Callback)
            end
        end)
        if o.Tooltip then
            win:_tooltip(b, o.Tooltip)
        end
        objs[i] = {
            Instance = b,
            SetText = function(_, t)
                b.Text = t
            end,
        }
    end
    return { Buttons = objs }
end

----------------------------------------------------------------
-- Group (collapsible), Search, Stat, Graph
----------------------------------------------------------------
local Group = setmetatable({}, { __index = Panel })
Group.__index = Group

function Group:_isCollapsed()
    return self._collapsed or (self._outer ~= nil and self._outer:_isCollapsed())
end

function Group:_refreshAll()
    for _, it in ipairs(self._items) do
        if it.group then
            it.collapsed = it.group:_isCollapsed()
            it.row.Visible = not (it.hidden or it.filtered or it.collapsed)
        end
    end
end

function Group:_row(h)
    local row, item = Panel._row(self, h)
    item.group = self
    item.collapsed = self:_isCollapsed()
    row.Visible = not (item.hidden or item.filtered or item.collapsed)
    self._parent:_apply()
    return row, item
end

function Group:_apply(instant)
    self._parent:_apply(instant)
end

function Group:SetOpen(open, instant)
    self._collapsed = not open
    tween(self._chev, { Rotation = open and 90 or 0 }, instant and 0 or 0.3, QUINT)
    if self._flagKey then
        self.Window:_flagSet(self._flagKey, open and true or false)
    end
    self:_refreshAll()
    self._parent:_apply(instant)
end

function Group:IsOpen()
    return not self._collapsed
end

function Panel:Group(o)
    if type(o) == "string" then
        o = { Name = o }
    end
    o = o or {}
    local win = self.Window
    local group = setmetatable({
        Window = win,
        Frame = self.Frame,
        Content = self.Content,
        _items = self._items,
        _parent = self,
        _outer = (getmetatable(self) == Group) and self or nil,
        _collapsed = false,
    }, Group)

    local open = o.Open ~= false
    if o.Persist and o.Name then
        group._flagKey = "_group:" .. o.Name
        open = win:_flagGet(group._flagKey, open)
    end
    group._collapsed = not open

    local head, hitem = self:_row(24)
    hitem.name = o.Name
    group._chev = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(16, 24),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 18,
        Text = "›",
        Rotation = open and 90 or 0,
    }, head)
    win:_themed(group._chev, "TextColor3", "sub")
    local title = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -18, 1, 0),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(o.Name or "Group"),
    }, head)
    win:_themed(title, "TextColor3", "text")
    local hit = make("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }, head)
    hit.MouseButton1Click:Connect(function()
        group:SetOpen(group._collapsed)
    end)
    if o.Tooltip then
        win:_tooltip(head, o.Tooltip)
    end
    return group
end

function Panel:Search(o)
    o = o or {}
    local win = self.Window
    local row = self:_row(26)
    local box = make("TextBox", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Font = Enum.Font.BuilderSans,
        TextSize = 13,
        Text = "",
        PlaceholderText = o.Placeholder or "Search…",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    win:_themed(box, "BackgroundColor3", "track")
    win:_themed(box, "TextColor3", "text")
    win:_themed(box, "PlaceholderColor3", "sub")
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)

    local function filter()
        local q = box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        for _, it in ipairs(self._items) do
            if it.row ~= row then
                local hit = true
                if q ~= "" then
                    hit = it.name ~= nil and tostring(it.name):lower():find(q, 1, true) ~= nil
                end
                it.filtered = not hit
                it.row.Visible = not (it.hidden or it.filtered or it.collapsed)
            end
        end
        self:_apply()
    end
    box:GetPropertyChangedSignal("Text"):Connect(filter)

    return {
        Instance = box,
        Clear = function()
            box.Text = ""
        end,
    }
end

function Panel:Stat(o)
    o = o or {}
    local win = self.Window
    local row = self:_row(22)
    rowLabel(win, row, o.Name or "Stat", 110)
    local v = make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(1, -114, 1, 0),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(o.Value or "–"),
    }, row)
    local e = win:_themed(v, "TextColor3", o.Tone or "text")
    return {
        Instance = v,
        Set = function(_, value, tone)
            v.Text = tostring(value)
            if tone then
                win:_setKey(e, tone)
            end
        end,
    }
end

function Panel:Graph(o)
    o = o or {}
    local win = self.Window
    local H, N = o.Height or 44, o.Points or 30
    local min, max = o.Min or 0, o.Max or 100
    local top = o.Name and 18 or 0

    local row = self:_row(H + top)
    if o.Name then
        local l = rowLabel(win, row, o.Name, 200)
        l.Size = UDim2.new(1, 0, 0, 16)
    end
    local area = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, top),
        Size = UDim2.new(1, 0, 0, H),
        ClipsDescendants = true,
    }, row)

    local bars, entries, values = {}, {}, {}
    for i = 1, N do
        local b = make("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new((i - 1) / N, 1, 1, 0),
            Size = UDim2.new(1 / N, -2, 0, 2),
            BorderSizePixel = 0,
        }, area)
        make("UICorner", { CornerRadius = UDim.new(0, 2) }, b)
        entries[i] = win:_themed(b, "BackgroundColor3", o.Tone or "accent")
        bars[i] = b
    end

    local function draw()
        for i = 1, N do
            local idx = #values - (N - i)
            local b = bars[i]
            if idx >= 1 then
                local a = max > min and (values[idx] - min) / (max - min) or 0
                b.Size = UDim2.new(1 / N, -2, math.clamp(a, 0.04, 1), 0)
                b.BackgroundTransparency = 0.2
            else
                b.Size = UDim2.new(1 / N, -2, 0.04, 0)
                b.BackgroundTransparency = 0.88
            end
        end
    end
    draw()

    local obj = {}
    function obj:Push(v)
        table.insert(values, v)
        if #values > N then
            table.remove(values, 1)
        end
        draw()
    end
    function obj:Clear()
        values = {}
        draw()
    end
    function obj:SetTone(key)
        for _, e in ipairs(entries) do
            win:_setKey(e, key)
        end
    end
    return obj
end

----------------------------------------------------------------
-- Common element methods: SetVisible / SetEnabled / Destroy / Tooltip
----------------------------------------------------------------
local ELEMENTS = {
    "Label", "Section", "Paragraph", "Separator", "Button", "ButtonRow", "Toggle",
    "Slider", "Choice", "Dropdown", "TextBox", "ColorPicker", "Keybind", "Bar", "List",
    "Search", "Stat", "Graph",
}
for _, name in ipairs(ELEMENTS) do
    local raw = Panel[name]
    Panel[name] = function(panel, o)
        local before = #panel._items
        local obj = raw(panel, o)
        if type(obj) ~= "table" then
            obj = {}
        end
        local item = panel._items[before + 1]
        if not item then
            return obj
        end
        local win = panel.Window
        obj.Row = item.row
        if type(o) == "table" then
            item.name = o.Name or o.Text
            if o.Flag and obj.Set then
                win._flagObjs[o.Flag] = { obj = obj, kind = name, opts = o }
            end
        elseif type(o) == "string" then
            item.name = o
        end

        function obj:SetVisible(v)
            item.hidden = not v
            item.row.Visible = not (item.hidden or item.filtered or item.collapsed)
            panel:_apply()
        end

        function obj:SetEnabled(e)
            if not item.shield then
                item.shield = make("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 0.4,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 50,
                    Visible = false,
                }, item.row)
                win:_themed(item.shield, "BackgroundColor3", "bg")
            end
            item.shield.Visible = not e
        end

        function obj:Destroy()
            for idx, it in ipairs(panel._items) do
                if it == item then
                    table.remove(panel._items, idx)
                    break
                end
            end
            item.row:Destroy()
            panel:_apply()
        end

        if name == "Keybind" and win._touchOnly then
            obj:SetVisible(false)
        end

        if type(o) == "table" and o.Tooltip then
            win:_tooltip(item.row, o.Tooltip)
        end
        return obj
    end
end

----------------------------------------------------------------
-- Window: width, aux gui, tooltips, toasts, prompt, watermark
----------------------------------------------------------------
function Window:SetWidth(w, instant)
    w = math.floor(w + 0.5)
    w = math.min(w, math.max(math.floor((viewport().X - 24) / self._scale.Scale), 200))
    if w == self.Width then
        return
    end
    self.Width = w
    tween(self.Root, { Size = UDim2.fromOffset(w, 0) }, instant and 0 or 0.25, QUINT)

    -- keep the window on screen after widening
    local vp = viewport()
    local x = math.clamp(self._rest.X.Offset, 0, math.max(vp.X - w * self._scale.Scale, 0))
    self._rest = UDim2.fromOffset(x, self._rest.Y.Offset)
    self.S.x = x
    if self._shown then
        tween(self.Root, { Position = self._rest }, instant and 0 or 0.25, QUINT)
    else
        self.Root.Position = self._rest
    end

    for _, fn in ipairs(self._onWidth) do
        pcall(fn)
    end
    self:_save()
end

function Window:_aux()
    if not self._auxGui then
        self._auxGui = make("ScreenGui", {
            Name = self.Name .. "_Aux",
            ResetOnSpawn = false,
            DisplayOrder = self.Gui.DisplayOrder + 1,
            IgnoreGuiInset = true,
        }, self.Gui.Parent)
        pcall(function()
            self._auxGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        end)
    end
    return self._auxGui
end

function Window:_tooltip(target, text)
    target.MouseEnter:Connect(function()
        self._tipToken = (self._tipToken or 0) + 1
        local mine = self._tipToken
        task.delay(0.4, function()
            if mine == self._tipToken and self.Alive then
                self:_showTip(text)
            end
        end)
    end)
    target.MouseLeave:Connect(function()
        self._tipToken = (self._tipToken or 0) + 1
        self:_hideTip()
    end)

    -- touch: press and hold to see the tip above your finger
    target.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        self._tipToken = (self._tipToken or 0) + 1
        local mine = self._tipToken
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        task.delay(0.5, function()
            if mine ~= self._tipToken or not self.Alive then
                return
            end
            self._tipFired = mine
            self:_showTip(text, pos)
            task.delay(2.5, function()
                if mine == self._tipToken then
                    self:_hideTip()
                end
            end)
        end)
    end)
    target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and self._tipFired ~= self._tipToken then
            self._tipToken = (self._tipToken or 0) + 1 -- released early: cancel
        end
    end)
end

function Window:_showTip(text, touchPos)
    if not self._tip then
        local f = make("Frame", {
            Name = "Tooltip",
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 300,
        }, self:_aux())
        self:_themed(f, "BackgroundColor3", "bg")
        make("UICorner", { CornerRadius = UDim.new(0, 7) }, f)
        local st = make("UIStroke", { Thickness = 1, Transparency = 0.85 }, f)
        self:_themed(st, "Color", "line")
        make("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, f)
        local l = make("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            Font = Enum.Font.BuilderSans,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "",
        }, f)
        make("UISizeConstraint", { MaxSize = Vector2.new(240, math.huge) }, l)
        self:_themed(l, "TextColor3", "text")
        self._tip, self._tipLabel = f, l
    end
    self._tipTouch = touchPos
    self._tip.AnchorPoint = touchPos and Vector2.new(0.5, 1) or Vector2.new(0, 0)
    self._tipLabel.Text = tostring(text)
    self._tip.Visible = true
    self:_moveTip()
end

function Window:_moveTip()
    if not self._tip or not self._tip.Visible then
        return
    end
    local vp, sz = viewport(), self._tip.AbsoluteSize
    if self._tipTouch then
        local inset = GuiService:GetGuiInset()
        local x = math.clamp(self._tipTouch.X, sz.X / 2 + 6, vp.X - sz.X / 2 - 6)
        local y = math.max(self._tipTouch.Y + inset.Y - 30, sz.Y + 6)
        self._tip.Position = UDim2.fromOffset(x, y)
    else
        local m = UserInputService:GetMouseLocation()
        self._tip.Position = UDim2.fromOffset(
            math.min(m.X + 14, vp.X - sz.X - 6),
            math.min(m.Y + 18, vp.Y - sz.Y - 6)
        )
    end
end

function Window:_hideTip()
    self._tipTouch = nil
    if self._tip then
        self._tip.Visible = false
    end
end

function Window:Notify(o)
    if type(o) == "string" then
        o = { Text = o }
    end
    o = o or {}
    if not self.Alive then
        return
    end
    local W = math.min(260, viewport().X - 36)
    local duration = o.Duration or 4

    if not self._toastHolder then
        self._toastHolder = make("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(W, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, self:_aux())
        make("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        }, self._toastHolder)
        self._toasts = {}
    end

    -- keep the stack tidy: at most 4 at once
    while #self._toasts >= 4 do
        local oldest = table.remove(self._toasts, 1)
        oldest()
    end

    self._toastN = (self._toastN or 0) + 1
    local wrap = make("Frame", {
        LayoutOrder = self._toastN,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self._toastHolder)

    local t = make("CanvasGroup", {
        Position = UDim2.fromOffset(W + 24, 0),
        Size = UDim2.fromOffset(W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Active = true,
    }, wrap)
    self:_themed(t, "BackgroundColor3", "bg")
    make("UICorner", { CornerRadius = UDim.new(0, 10) }, t)
    local st = make("UIStroke", { Thickness = 1, Transparency = 0.9 }, t)
    self:_themed(st, "Color", "line")

    local accent = make("Frame", {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BorderSizePixel = 0,
    }, t)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, accent)
    self:_themed(accent, "BackgroundColor3", o.Tone or "accent")

    -- thin countdown line along the bottom
    local line = make("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.45,
    }, t)
    self:_themed(line, "BackgroundColor3", o.Tone or "accent")

    local body = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, t)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 12),
    }, body)
    make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, body)

    if o.Title then
        local tl = make("TextLabel", {
            LayoutOrder = 1,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 14,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(o.Title),
        }, body)
        self:_themed(tl, "TextColor3", "text")
    end
    if o.Text then
        local xl = make("TextLabel", {
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.BuilderSans,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(o.Text),
        }, body)
        self:_themed(xl, "TextColor3", "sub")
    end

    local gone = false
    local function dismiss()
        if gone then
            return
        end
        gone = true
        local h = wrap.AbsoluteSize.Y
        wrap.AutomaticSize = Enum.AutomaticSize.None
        wrap.Size = UDim2.fromOffset(W, h)
        tween(t, { Position = UDim2.fromOffset(W + 24, 0), GroupTransparency = 1 }, 0.3, QUINT, Enum.EasingDirection.In)
        tween(wrap, { Size = UDim2.fromOffset(W, 0) }, 0.32, QUINT)
        task.delay(0.36, function()
            if wrap.Parent then
                wrap:Destroy()
            end
        end)
    end
    table.insert(self._toasts, dismiss)

    t.InputBegan:Connect(function(input)
        if isPress(input) then
            dismiss()
        end
    end)

    tween(t, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, 0.45, QUINT)
    if Lite.Animations then
        TweenService:Create(line, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    end
    task.delay(duration, dismiss)
end

function Window:Prompt(o)
    if type(o) == "string" then
        o = { Text = o }
    end
    o = o or {}
    if not self.Alive then
        return
    end

    local dim = make("TextButton", {
        Name = "Prompt",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 200,
    }, self:_aux())

    local dlg = make("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(o.Width or 300, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Active = true,
    }, dim)
    self:_themed(dlg, "BackgroundColor3", "bg")
    make("UICorner", { CornerRadius = UDim.new(0, 12) }, dlg)
    make("UISizeConstraint", { MaxSize = Vector2.new(math.max(viewport().X - 32, 200), math.huge) }, dlg)
    local pop = make("UIScale", { Scale = 0.9 }, dlg)
    local st = make("UIStroke", { Thickness = 1, Transparency = 0.88 }, dlg)
    self:_themed(st, "Color", "line")
    make("UIPadding", {
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
    }, dlg)
    make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, dlg)

    local function label(text, order, font, size, key)
        local l = make("TextLabel", {
            LayoutOrder = order,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = font,
            TextSize = size,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(text),
        }, dlg)
        self:_themed(l, "TextColor3", key)
    end
    if o.Title then
        label(o.Title, 1, Enum.Font.BuilderSansBold, 17, "text")
    end
    if o.Text then
        label(o.Text, 2, Enum.Font.BuilderSans, 14, "sub")
    end

    local BH = self._touchOnly and 38 or 30
    local btnRow = make("Frame", {
        LayoutOrder = 4,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, BH + 4),
    }, dlg)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, btnRow)

    local done = false
    local function finish(result)
        if done then
            return
        end
        done = true
        tween(dim, { BackgroundTransparency = 1 }, 0.22)
        tween(dlg, { GroupTransparency = 1 }, 0.18)
        tween(pop, { Scale = 0.94 }, 0.2, QUINT, Enum.EasingDirection.In)
        task.delay(0.25, function()
            dim:Destroy()
        end)
        if o.Callback then
            task.spawn(o.Callback, result)
        end
    end

    local function button(text, order, primary, result)
        local b = make("TextButton", {
            LayoutOrder = order,
            Size = UDim2.fromOffset(self._touchOnly and 104 or 92, BH),
            BorderSizePixel = 0,
            Font = Enum.Font.BuilderSansMedium,
            TextSize = 14,
            Text = text,
            AutoButtonColor = false,
        }, btnRow)
        make("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
        pressable(b)
        self:_themed(b, "BackgroundColor3", primary and (o.Tone or "accent") or "track")
        self:_themed(b, "TextColor3", primary and "bg" or "text")
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundTransparency = 0.25 }, 0.12)
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundTransparency = 0 }, 0.12)
        end)
        b.MouseButton1Click:Connect(function()
            finish(result)
        end)
    end
    if o.No ~= false then
        button(o.No or "Cancel", 1, false, false)
    end
    button(o.Yes or "OK", 2, true, true)

    tween(dim, { BackgroundTransparency = 0.5 }, 0.25)
    tween(dlg, { GroupTransparency = 0 }, 0.22)
    tween(pop, { Scale = 1 }, 0.42, Enum.EasingStyle.Back)
end

function Window:Watermark(o)
    o = o or {}
    local f = make("Frame", {
        Name = "Watermark",
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        AnchorPoint = o.AnchorPoint or Vector2.new(1, 0),
        Position = o.Position or UDim2.new(1, -18, 0, 44),
        BackgroundTransparency = 1 - self.S.opacity,
        BorderSizePixel = 0,
    }, self:_aux())
    self:_themed(f, "BackgroundColor3", "bg")
    table.insert(self._boxes, f)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
    local st = make("UIStroke", { Thickness = 1, Transparency = 0.9 }, f)
    self:_themed(st, "Color", "line")
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, f)
    local label = make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 13,
        Text = tostring(o.Text or self.Name),
    }, f)
    self:_themed(label, "TextColor3", "text")

    local acc, frames = 0, 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        frames += 1
        acc += dt
        if acc < 0.5 then
            return
        end
        local parts = { tostring(o.Text or self.Name) }
        if o.FPS ~= false then
            table.insert(parts, math.floor(frames / acc + 0.5) .. " fps")
        end
        if o.Ping ~= false then
            local ok, ping = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if ok and ping then
                table.insert(parts, math.floor(ping + 0.5) .. " ms")
            end
        end
        label.Text = table.concat(parts, "   ·   ")
        acc, frames = 0, 0
    end)
    table.insert(self._conns, conn)

    local obj = { Frame = f, Label = label }
    function obj:SetText(t)
        o.Text = t
    end
    function obj:SetVisible(v)
        f.Visible = v and true or false
    end
    function obj:Destroy()
        conn:Disconnect()
        f:Destroy()
    end
    return obj
end

function Window:_mobileButton()
    local b = make("TextButton", {
        Position = UDim2.new(0, 10, 0.5, -22),
        Size = UDim2.fromOffset(44, 44),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 15,
        Text = "UI",
        AutoButtonColor = false,
    }, self:_aux())
    self:_themed(b, "BackgroundColor3", "bg")
    self:_themed(b, "TextColor3", "text")
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
    local st = make("UIStroke", { Thickness = 1, Transparency = 0.85 }, b)
    self:_themed(st, "Color", "line")
    pressable(b, 0.9)

    -- tap = show / hide, drag = move it (it snaps to the nearest side)
    local drag
    b.InputBegan:Connect(function(input)
        if isPress(input) then
            drag = { sx = input.Position.X, sy = input.Position.Y, pos = b.Position, moved = false }
        end
    end)
    table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
        if not drag or not isMove(input) then
            return
        end
        local dx, dy = input.Position.X - drag.sx, input.Position.Y - drag.sy
        if not drag.moved and dx * dx + dy * dy > 36 then
            drag.moved = true
        end
        if drag.moved then
            b.Position = UDim2.new(drag.pos.X.Scale, drag.pos.X.Offset + dx, drag.pos.Y.Scale, drag.pos.Y.Offset + dy)
        end
    end))
    table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
        if not drag or not isPress(input) then
            return
        end
        local d = drag
        drag = nil
        if not d.moved then
            self:Toggle()
            return
        end
        local vp, ap, sz = viewport(), b.AbsolutePosition, b.AbsoluteSize
        local targetX = (ap.X + sz.X / 2 < vp.X / 2) and 10 or (vp.X - sz.X - 10)
        local targetY = math.clamp(ap.Y, 10, vp.Y - sz.Y - 10)
        tween(b, {
            Position = b.Position + UDim2.fromOffset(targetX - ap.X, targetY - ap.Y),
        }, 0.3, QUINT)
    end))
end

----------------------------------------------------------------
-- Accent override + config import/export/reset
----------------------------------------------------------------
function Window:SetAccent(color)
    if typeof(color) == "Color3" then
        self.S.accent = color:ToHex()
        self._accent = color
    else
        self.S.accent = ""
        self._accent = nil
    end
    self:_applyTheme(true)
    self:_save()
end

function Window:ExportConfig()
    return HttpService:JSONEncode(self.S)
end

local function copyValue(v)
    if type(v) == "table" then
        local c = {}
        for k, x in pairs(v) do
            c[k] = copyValue(x)
        end
        return c
    end
    return v
end

-- push a saved value into the live control that owns the flag
local function applyFlag(entry, value)
    local obj, kind = entry.obj, entry.kind
    if kind == "ColorPicker" then
        local ok, c = pcall(Color3.fromHex, tostring(value))
        if ok then
            obj:Set(c)
        end
    elseif kind == "Keybind" then
        obj:Set(keyOf(value, Enum.KeyCode.Unknown))
    elseif kind == "Slider" then
        obj:Set(tonumber(value) or obj.Value)
    else
        obj:Set(value)
    end
end

local function defaultFor(entry)
    local o, kind = entry.opts, entry.kind
    if kind == "Toggle" then
        return o.Default == true
    elseif kind == "Slider" then
        return o.Default or o.Min or 0
    elseif kind == "Choice" then
        return o.Default or (o.Options or {})[1]
    elseif kind == "Dropdown" then
        if o.Multi then
            return type(o.Default) == "table" and o.Default or {}
        end
        return o.Default or (o.Options or {})[1]
    elseif kind == "TextBox" then
        return o.Default or ""
    elseif kind == "ColorPicker" then
        return (typeof(o.Default) == "Color3" and o.Default or Color3.fromRGB(120, 200, 150)):ToHex()
    elseif kind == "Keybind" then
        return keyOf(o.Default, Enum.KeyCode.Unknown).Name
    end
end

function Window:_applyFlags()
    for flag, entry in pairs(self._flagObjs) do
        local v = self.S.flags[flag]
        if v ~= nil then
            pcall(applyFlag, entry, v)
        end
    end
end

function Window:ImportConfig(json)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, tostring(json))
    if not ok or type(data) ~= "table" then
        return false
    end
    if type(data.flags) == "table" then
        for k, v in pairs(data.flags) do
            if type(k) == "string" and k:sub(1, 1) ~= "_" then
                self.S.flags[k] = v
            end
        end
    end
    if type(data.theme) == "string" and Lite.Themes[data.theme] then
        self:SetTheme(data.theme)
    end
    if type(data.opacity) == "number" then
        self:SetOpacity(data.opacity)
    end
    if type(data.scale) == "number" then
        self:SetScale(data.scale)
    end
    if type(data.accent) == "string" then
        local okc, c = pcall(Color3.fromHex, data.accent)
        self:SetAccent(okc and c or nil)
    end
    self:_applyFlags()
    self:_save()
    return true
end

function Window:ResetConfig()
    for k in pairs(self.S.flags) do
        if k:sub(1, 1) ~= "_" then
            self.S.flags[k] = nil
        end
    end
    for _, entry in pairs(self._flagObjs) do
        local d = defaultFor(entry)
        if d ~= nil then
            pcall(applyFlag, entry, d)
        end
    end
    self:SetOpacity(0.96)
    self:SetScale(1)
    self:SetTheme("dark")
    self:SetAccent(nil)
    self:_save()
end

----------------------------------------------------------------
-- Profiles: named snapshots of every saved control + look
----------------------------------------------------------------
function Window:ListProfiles()
    local names = {}
    for k in pairs(self.S.profiles) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

function Window:SaveProfile(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return false
    end
    local flags = {}
    for k, v in pairs(self.S.flags) do
        if k:sub(1, 1) ~= "_" then
            flags[k] = copyValue(v)
        end
    end
    self.S.profiles[name] = {
        flags = flags,
        theme = self.S.theme,
        opacity = self.S.opacity,
        scale = self.S.scale,
        accent = self.S.accent,
    }
    self:_save()
    return true
end

function Window:LoadProfile(name)
    local p = self.S.profiles[name]
    if type(p) ~= "table" then
        return false
    end
    for k in pairs(self.S.flags) do
        if k:sub(1, 1) ~= "_" then
            self.S.flags[k] = nil
        end
    end
    for k, v in pairs(p.flags or {}) do
        self.S.flags[k] = copyValue(v)
    end
    if Lite.Themes[p.theme] then
        self:SetTheme(p.theme)
    end
    if type(p.opacity) == "number" then
        self:SetOpacity(p.opacity)
    end
    if type(p.scale) == "number" then
        self:SetScale(p.scale)
    end
    if type(p.accent) == "string" then
        local ok, c = pcall(Color3.fromHex, p.accent)
        self:SetAccent(ok and c or nil)
    end
    self:_applyFlags()
    self:_save()
    return true
end

function Window:DeleteProfile(name)
    if self.S.profiles[name] == nil then
        return false
    end
    self.S.profiles[name] = nil
    self:_save()
    return true
end

function Window:SetDraggable(on)
    self._noDrag = not on
end

function Window:OnVisibility(fn)
    table.insert(self._onVis, fn)
end

function Window:Unload()
    if self.Alive then
        self.Gui:Destroy()
    end
end

function Lite.UnloadAll()
    local copy = table.clone(Lite.Windows)
    for _, w in ipairs(copy) do
        w:Unload()
    end
end

----------------------------------------------------------------
-- Tabs: a segmented bar with a sliding highlight; each tab is a normal Panel.
-- The window widens so every tab name fits; past MaxWidth the bar scrolls.
----------------------------------------------------------------
function Window:Tabs(names, opts)
    opts = opts or {}
    local win = self
    self._tabCount = (self._tabCount or 0) + 1
    local flagKey = "_tab:" .. self._tabCount
    local n = #names
    local PAD, GAPX, EDGE = 24, 4, 4
    local BH = self._touchOnly and 30 or 26
    local BOX_H = BH + 8
    local maxW = opts.MaxWidth or 460

    -- measure each tab label and grow the window if needed
    local widths, total = {}, 0
    for i, name in ipairs(names) do
        local tw = TextService:GetTextSize(name, 14, Enum.Font.BuilderSansMedium, Vector2.new(1000, 100)).X
        widths[i] = math.ceil(tw) + PAD
        total += widths[i]
    end
    local needed = total + GAPX * (n - 1) + EDGE * 2
    self:SetWidth(math.min(math.max(self.Width, needed), maxW), not self._ready)

    local box = self:_box("Tabs", BOX_H)
    local scroller = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, box)

    -- the highlight that slides between tabs (sits behind the buttons)
    local pill = make("Frame", {
        Position = UDim2.fromOffset(EDGE, (BOX_H - BH) / 2),
        Size = UDim2.fromOffset(widths[1], BH),
        BorderSizePixel = 0,
        ZIndex = 1,
    }, scroller)
    make("UICorner", { CornerRadius = UDim.new(0, 7) }, pill)
    win:_themed(pill, "BackgroundColor3", "track")

    local rowF = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 2,
    }, scroller)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, GAPX),
    }, rowF)
    make("UIPadding", { PaddingLeft = UDim.new(0, EDGE), PaddingRight = UDim.new(0, EDGE) }, rowF)

    scroller.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local maxX = math.max(scroller.AbsoluteCanvasSize.X - scroller.AbsoluteSize.X, 0)
            scroller.CanvasPosition = Vector2.new(
                math.clamp(scroller.CanvasPosition.X - input.Position.Z * 48, 0, maxX),
                0
            )
        end
    end)

    local bar = { Panels = {}, Current = nil }
    local parts, idx, bx, bw = {}, {}, {}, {}

    for i, name in ipairs(names) do
        local b = make("TextButton", {
            LayoutOrder = i,
            Size = UDim2.fromOffset(widths[i], BH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Enum.Font.BuilderSansMedium,
            TextSize = 14,
            Text = name,
            AutoButtonColor = false,
        }, rowF)
        parts[name] = { btn = b, tx = win:_themed(b, "TextColor3", "sub") }
        idx[name] = i
        bar.Panels[name] = self:Panel({ Name = name, MaxHeight = opts.MaxHeight })

        b.MouseButton1Click:Connect(function()
            bar:Select(name)
        end)
        b.MouseEnter:Connect(function()
            if bar.Current ~= name then
                tween(b, { TextColor3 = win:_color("text") }, 0.12)
            end
        end)
        b.MouseLeave:Connect(function()
            if bar.Current ~= name then
                tween(b, { TextColor3 = win:_color("sub") }, 0.12)
            end
        end)
    end

    local function place(name, instant)
        local i = idx[name]
        if not (i and bx[i]) then
            return
        end
        tween(pill, {
            Position = UDim2.fromOffset(bx[i], (BOX_H - BH) / 2),
            Size = UDim2.fromOffset(bw[i], BH),
        }, instant and 0 or 0.38, QUINT)
    end

    -- spread leftover width evenly so the bar always fills the window
    local function layout()
        local inner = win.Width - EDGE * 2
        local extra = inner - GAPX * (n - 1) - total
        local share = extra > 0 and extra / n or 0
        local x = EDGE
        for i, name in ipairs(names) do
            local w = math.floor(widths[i] + share)
            parts[name].btn.Size = UDim2.fromOffset(w, BH)
            bx[i], bw[i] = x, w
            x += w + GAPX
        end
        if bar.Current then
            place(bar.Current, true)
        end
    end
    layout()
    table.insert(self._onWidth, layout)

    local function reveal(btn)
        local sc = win._scale.Scale
        local vw = scroller.AbsoluteSize.X / sc
        local cw = scroller.AbsoluteCanvasSize.X / sc
        if cw <= vw + 1 then
            return
        end
        local bpos = (btn.AbsolutePosition.X - scroller.AbsolutePosition.X) / sc + scroller.CanvasPosition.X
        local target = math.clamp(bpos - (vw - btn.AbsoluteSize.X / sc) / 2, 0, cw - vw)
        tween(scroller, { CanvasPosition = Vector2.new(target, 0) }, 0.3, QUINT)
    end

    function bar:Select(name, instant)
        if not self.Panels[name] then
            return
        end
        local prev = self.Current
        self.Current = name
        for _, nm in ipairs(names) do
            local sel = nm == name
            win:_setKey(parts[nm].tx, sel and "text" or "sub", instant)
            if sel then
                self.Panels[nm]:SetOpen(true, instant)
            elseif instant or nm == prev then
                -- the old tab shrinks and fades while the new one grows
                self.Panels[nm]:SetOpen(false, instant)
            end
        end
        place(name, instant)
        if not instant then
            reveal(parts[name].btn)
        end
        win:_flagSet(flagKey, name)
    end

    local start = win:_flagGet(flagKey, opts.Default or names[1])
    if not bar.Panels[start] then
        start = names[1]
    end
    bar:Select(start, true)
    return bar.Panels, bar
end

----------------------------------------------------------------
-- Ready-made settings panel (opacity, size, theme, hotkey, accent, config)
----------------------------------------------------------------
function Window:Settings(opts)
    opts = opts or {}
    local panel = opts.Panel or self:Panel({ Name = "Settings", Open = opts.Open })

    panel:Slider({
        Name = "Opacity",
        Min = 0.5,
        Max = 1,
        Step = 0.05,
        Default = self.S.opacity,
        Format = function(v)
            return math.floor(v * 100 + 0.5) .. "%"
        end,
        Callback = function(v)
            self:SetOpacity(v)
        end,
    })
    panel:Slider({
        Name = "Size",
        Min = 0.8,
        Max = 1.6,
        Step = 0.05,
        Default = self.S.scale,
        Format = function(v)
            return string.format("%.2fx", v)
        end,
        Callback = function(v)
            self:SetScale(v)
        end,
    })

    panel:Toggle({
        Name = "Animations",
        Default = self.S.anim,
        Tooltip = "Turn off for the snappiest feel on slower devices",
        Callback = function(v)
            self:SetAnimations(v)
        end,
    })

    local names = {}
    for k in pairs(Lite.Themes) do
        table.insert(names, k)
    end
    table.sort(names)
    panel:Choice({
        Name = "Theme",
        Options = names,
        Default = self.S.theme,
        Callback = function(v)
            self:SetTheme(v)
        end,
    })
    panel:Keybind({
        Name = "Hotkey",
        Default = self._key,
        Callback = function(k)
            self:SetKey(k)
        end,
    })

    local accent = panel:ColorPicker({
        Name = "Accent",
        Default = self:_color("accent"),
        Callback = function(c)
            self:SetAccent(c)
        end,
    })
    panel:Button({
        Name = "Reset accent",
        Callback = function()
            self:SetAccent(nil)
            accent:Set(self:_color("accent"), true)
        end,
    })

    panel:Separator()
    panel:ButtonRow({
        {
            Name = "Copy config",
            Callback = function()
                if type(setclipboard) == "function" then
                    setclipboard(self:ExportConfig())
                    self:Notify({ Title = "Config copied", Text = "Paste it into the Import box to restore it." })
                else
                    self:Notify({ Title = "Clipboard unavailable", Text = "This executor has no setclipboard.", Tone = "warn" })
                end
            end,
        },
        {
            Name = "Reset all",
            Tone = "danger",
            Callback = function()
                self:Prompt({
                    Title = "Reset all settings?",
                    Text = "Every saved control goes back to its default value.",
                    Yes = "Reset",
                    Tone = "danger",
                    Callback = function(ok)
                        if ok then
                            self:ResetConfig()
                            self:Notify({ Title = "Settings reset", Tone = "warn" })
                        end
                    end,
                })
            end,
        },
    })
    local imp
    imp = panel:TextBox({
        Name = "Import",
        Placeholder = "paste config + Enter",
        OnlyEnter = true,
        Callback = function(text)
            if text == "" then
                return
            end
            local ok = self:ImportConfig(text)
            self:Notify({
                Title = ok and "Config imported" or "Import failed",
                Text = ok and "Your controls were updated." or "That doesn't look like a valid config.",
                Tone = ok and "accent" or "danger",
            })
            imp:Set("", true)
        end,
    })
    return panel
end

----------------------------------------------------------------
-- Ready-made profiles panel (save / load / delete named setups)
----------------------------------------------------------------
function Window:Profiles(opts)
    opts = opts or {}
    local win = self
    local panel = opts.Panel or self:Panel({ Name = "Profiles", Open = opts.Open })

    local nameBox = panel:TextBox({ Name = "Profile", Placeholder = "name…" })
    local listLbl = panel:Paragraph("")

    local function refresh()
        local names = win:ListProfiles()
        listLbl:Set(#names == 0 and "No saved profiles yet." or ("Saved: " .. table.concat(names, ", ")))
    end
    local function current()
        return (nameBox.Instance.Text:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    panel:ButtonRow({
        {
            Name = "Save",
            Callback = function()
                local n = current()
                if win:SaveProfile(n) then
                    win:Notify({ Title = "Profile saved", Text = n })
                else
                    win:Notify({ Title = "Enter a profile name first", Tone = "warn" })
                end
                refresh()
            end,
        },
        {
            Name = "Load",
            Callback = function()
                local n = current()
                if win:LoadProfile(n) then
                    win:Notify({ Title = "Profile loaded", Text = n })
                else
                    win:Notify({ Title = "No profile called “" .. n .. "”", Tone = "warn" })
                end
            end,
        },
        {
            Name = "Delete",
            Tone = "danger",
            Callback = function()
                local n = current()
                if win:DeleteProfile(n) then
                    win:Notify({ Title = "Profile deleted", Text = n, Tone = "warn" })
                else
                    win:Notify({ Title = "No profile called “" .. n .. "”", Tone = "warn" })
                end
                refresh()
            end,
        },
    })
    refresh()
    return panel
end

return Lite
