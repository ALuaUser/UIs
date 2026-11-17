--[[
    LiteUI  v1.0.0
    A flat, minimal UI library for Roblox (cards, collapsible panels, settings).

    ── Quick start ──────────────────────────────────────────────
    local Lite = loadstring(readfile("LiteUI.lua"))()   -- or require(moduleScript)

    local ui   = Lite.new({ Name = "MyHUD", Key = Enum.KeyCode.RightShift })
    local card = ui:Card({ Title = "Hello", Subtitle = "World", Value = "42" })
    local pane = ui:Panel({ Name = "Options" })
    pane:Toggle({ Name = "Enabled", Flag = "enabled", Default = true, Callback = print })
    local settings = ui:Settings()
    card:Attach(pane, "▾", "▴")
    card:Attach(settings, "···", "···")
    ui:Show()

    ── API ──────────────────────────────────────────────────────
    Lite.new(opts)  opts: Name, Width(264), Key, Theme("dark"), Opacity(.96), Scale(1),
                          X, Y, Parent, DisplayOrder, Save(true), SaveFile
    Lite.Themes     table of palettes; add your own before calling Lite.new

    Window:  :Card(opts)  :Panel(opts)  :Settings(opts)
             :Show() :Hide() :Toggle() :Destroy()
             :SetTheme(n) :SetOpacity(v) :SetScale(v) :SetKey(keyCode)
             :OnDestroy(fn)    .Flags (saved values)   .Alive

    Card:    :Set{Title,Subtitle,Value,Tone}  :SetTone(key)  :Minimize(bool)
             :SetPinned(bool) :IsPinned() :AddButton(text, fn) :Attach(panel, closed, open)
             opts: Title, Subtitle, Value, Closable, Minimizable, Pinnable, OnPin, Draggable

    Panel:   :SetOpen(bool) :IsOpen()
             :Label{Text,Tone}   :Separator()   :Button{Name,Callback}
             :Toggle{Name,Default,Flag,Callback}
             :Slider{Name,Min,Max,Step,Default,Flag,Format,Suffix,Callback}
             :Choice{Name,Options,Default,Flag,Callback}
             :Keybind{Name,Default,Flag,Callback,Press}
             :List{Max,Empty}  ->  :Push(name, value)  :Clear()
             opts: Name, Open, Persist

    Elements with a Flag are saved/restored, and their Callback is called once
    on load with the restored value.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Lite = { Version = "1.0.0" }

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
    if t == 0 then
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

    self.Name = opts.Name or "LiteUI"
    self.Width = opts.Width or 264
    self.Alive = true
    self._conns, self._registry, self._boxes, self._binds = {}, {}, {}, {}
    self._onDestroy = {}
    self._order = 0
    self._shown = false
    self._ready = false
    self._saveToken = 0
    self._saveOn = opts.Save ~= false
    self._file = opts.SaveFile or ("LiteUI_" .. self.Name .. ".json")
    self._attr = "LiteUI_" .. self.Name
    self._touchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local keyDefault = keyOf(opts.Key, Enum.KeyCode.RightShift)
    self.S = self:_load({
        x = opts.X or 18,
        y = opts.Y or 120,
        opacity = opts.Opacity or 0.96,
        scale = opts.Scale or 1,
        theme = opts.Theme or "dark",
        key = keyDefault.Name,
        flags = {},
    })
    self.Flags = self.S.flags
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
        for _, c in ipairs(self._conns) do
            c:Disconnect()
        end
        for _, fn in ipairs(self._onDestroy) do
            pcall(fn)
        end
    end)

    self:_installInput()
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
        if self._slider then
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
    self.Root.Position = self._rest + UDim2.fromOffset(0, -8)
    tween(self.Root, { GroupTransparency = 0, Position = self._rest }, 0.3)
end

function Window:Hide(onDone)
    if not self.Alive then
        return
    end
    self._shown = false
    tween(self.Root, {
        GroupTransparency = 1,
        Position = self._rest + UDim2.fromOffset(0, 8),
    }, 0.22, QUINT)
    task.delay(0.22, function()
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
    self:_save()
end

function Window:SetKey(key)
    self._key = keyOf(key, Enum.KeyCode.Unknown)
    self.S.key = self._key.Name
    self:_save()
end

function Window:_box(name, height)
    self._order += 1
    local f = make("Frame", {
        Name = name,
        Size = UDim2.fromOffset(self.Width, height),
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
        Size = UDim2.fromOffset(W - 122, 20),
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
        Size = UDim2.fromOffset(W - 122, 18),
        Font = Enum.Font.BuilderSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(opts.Subtitle or ""),
    }, f)
    self:_themed(card.SubLabel, "TextColor3", "sub")

    card.Divider = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, W - 94, 0.5, 0),
        Size = UDim2.fromOffset(1, 40),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, f)
    self:_themed(card.Divider, "BackgroundColor3", "line")

    card.ValueLabel = make("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(W - 86, 0),
        Size = UDim2.fromOffset(76, FULL_H),
        Font = Enum.Font.BuilderSansExtraBold,
        TextSize = 34,
        Text = tostring(opts.Value or "–"),
        AutoButtonColor = false,
    }, f)
    card._toneEntry = self:_themed(card.ValueLabel, "TextColor3", opts.Tone or "sub")

    card.PinLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(W - 86, FULL_H - 19),
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
    local b = make("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -22 - slot * 20, 0, 3),
        Size = UDim2.fromOffset(18, 18),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 16,
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
                tween(self.ValueLabel, { TextTransparency = 0 }, 0.25)
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
    tween(self.Frame, { Size = UDim2.fromOffset(self._width, m and self._miniH or self._full) }, d, QUINT)
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

    local f = self:_box(opts.Name or "Panel", 0)
    f.Visible = false
    make("UIListLayout", {
        Padding = UDim.new(0, GAP),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, f)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    }, f)
    panel.Frame = f

    local open = opts.Open == true
    if opts.Persist and opts.Name then
        panel._flagKey = "_open:" .. opts.Name
        open = self:_flagGet(panel._flagKey, open)
    end
    panel._open = open
    if open then
        f.Visible = true
    end
    return panel
end

function Panel:_height()
    local n = #self._items
    if n == 0 then
        return 16
    end
    local h = 16 + GAP * (n - 1)
    for _, it in ipairs(self._items) do
        h += it.h
    end
    return h
end

function Panel:_apply(instant)
    local f = self.Frame
    local W = self.Window.Width
    instant = instant or not self.Window._ready
    local d = instant and 0 or 0.3

    if self._open then
        f.Visible = true
        tween(f, { Size = UDim2.fromOffset(W, self:_height()) }, d, QUINT)
    else
        if not f.Visible then
            return
        end
        tween(f, { Size = UDim2.fromOffset(W, 0) }, d, QUINT)
        if instant then
            f.Visible = false
        else
            task.delay(d + 0.02, function()
                if not self._open then
                    f.Visible = false
                end
            end)
        end
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
    }, self.Frame)
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
    win:_themed(b, "TextColor3", "text")
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
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
    rowLabel(win, row, o.Name or "Toggle", 150)

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
        tween(knob, { Position = UDim2.new(0, v and 18 or 2, 0.5, 0) }, 0.15)
        win:_flagSet(o.Flag, v)
        if not silent and o.Callback then
            task.spawn(o.Callback, v)
        end
    end
    click.MouseButton1Click:Connect(function()
        obj:Set(not obj.Value)
    end)

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

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
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
            if k ~= Enum.KeyCode.Escape and k ~= Enum.KeyCode.Unknown then
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
-- Ready-made settings panel (opacity, size, theme, hotkey)
----------------------------------------------------------------
function Window:Settings(opts)
    opts = opts or {}
    local panel = self:Panel({ Name = "Settings", Open = opts.Open })

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
        Max = 1.3,
        Step = 0.05,
        Default = self.S.scale,
        Format = function(v)
            return string.format("%.2fx", v)
        end,
        Callback = function(v)
            self:SetScale(v)
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
    return panel
end

return Lite
