-- LiteUI demo: shows a card, a history list, extra controls and settings.
-- Load the library however you like:
local Lite = loadstring(readfile("LiteUI.lua"))()
-- local Lite = require(path.to.LiteUI)   -- if it's a ModuleScript

-- Optional: add your own theme before creating the window
Lite.Themes.ocean = {
    bg = Color3.fromRGB(14, 22, 34),
    line = Color3.fromRGB(180, 215, 255),
    text = Color3.fromRGB(226, 238, 252),
    sub = Color3.fromRGB(110, 140, 175),
    accent = Color3.fromRGB(90, 190, 230),
    warn = Color3.fromRGB(232, 184, 108),
    danger = Color3.fromRGB(232, 110, 110),
    track = Color3.fromRGB(32, 48, 68),
}

local ui = Lite.new({
    Name = "LiteDemo",
    Key = Enum.KeyCode.RightShift,
})

-- Main card -------------------------------------------------------
local card = ui:Card({
    Title = "LiteUI demo",
    Subtitle = "Click the number to pin",
    Value = "0",
    Tone = "accent",
    OnPin = function(pinned)
        print("pinned:", pinned)
    end,
})

-- History panel (a list element) ---------------------------------
local history = ui:Panel({ Name = "History", Persist = true })
local list = history:List({ Max = 5, Empty = "Nothing yet" })

-- Settings panel (built in) + our own controls added to it -------
local settings = ui:Settings()
settings:Separator()
settings:Toggle({
    Name = "Warn tone",
    Flag = "warnTone",
    Default = false,
    Callback = function(on)
        card:SetTone(on and "warn" or "accent")
    end,
})
settings:Slider({
    Name = "Step",
    Flag = "step",
    Min = 1,
    Max = 10,
    Step = 1,
    Default = 1,
})
settings:Button({
    Name = "Add entry",
    Callback = function()
        local n = tonumber(card.ValueLabel.Text) or 0
        n += ui.Flags.step or 1
        card:Set({ Value = n, Subtitle = "Count updated" })
        list:Push("Entry " .. n, n)
    end,
})
settings:Button({
    Name = "Clear history",
    Callback = function()
        list:Clear()
    end,
})

-- Header buttons that toggle panels ------------------------------
card:Attach(history, "▾", "▴")
card:Attach(settings, "···", "···")

ui:OnDestroy(function()
    print("LiteUI demo closed")
end)

ui:Show()
