--[[
    LiteUI example
    Loads the library from your GitHub repo, then builds a demo window.

    1. Upload LiteUI.lua to a GitHub repo (any branch, any folder).
    2. Open the file on GitHub, click "Raw", and copy that address.
    3. Paste it into LIB_URL below.

    Raw links look like:
        https://raw.githubusercontent.com/<user>/<repo>/<branch>/LiteUI.lua
    GitHub caches raw files for a few minutes, so after an update you may need to wait.
    To pin an exact version, use a commit hash instead of the branch name.
]]

local LIB_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/LiteUI.lua"

local ok, Lite = pcall(function()
    return loadstring(game:HttpGet(LIB_URL))()
end)
if not ok or type(Lite) ~= "table" then
    warn("[LiteUI] could not load the library from:", LIB_URL)
    warn("[LiteUI] " .. tostring(Lite))
    return
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Optional: add your own theme before creating the window.
-- It then shows up in Settings > Theme.
Lite.Themes.sunset = {
    bg = Color3.fromRGB(32, 20, 24),
    line = Color3.fromRGB(255, 220, 200),
    text = Color3.fromRGB(250, 236, 228),
    sub = Color3.fromRGB(160, 128, 120),
    accent = Color3.fromRGB(255, 140, 90),
    warn = Color3.fromRGB(255, 200, 100),
    danger = Color3.fromRGB(240, 100, 100),
    track = Color3.fromRGB(58, 38, 42),
}

local ui = Lite.new({
    Name = "LiteDemo",
    Key = Enum.KeyCode.RightShift, -- hide / show (phones get a draggable "UI" button instead)
    -- Animations = false,        -- uncomment to turn every animation off
    -- Scale = 1.2,               -- phones default to 1.2 automatically
})
ui:Watermark({ Text = "LiteUI" })

----------------------------------------------------------------
-- Header card + tabs (the window widens so every tab name fits)
----------------------------------------------------------------
local card = ui:Card({
    Title = "LiteUI",
    Subtitle = "Click the number to pin",
    Value = "0",
    Tone = "accent",
})

local tab = ui:Tabs({ "Main", "Visuals", "Utility", "Data", "Settings" }, { MaxHeight = 260 })

-- History panel, opened from a header button on the card
local history = ui:Panel({ Name = "History", Persist = true })
local list = history:List({ Max = 5 })
card:Attach(history, "▾", "▴")

----------------------------------------------------------------
-- Main tab: toggles, buttons, inputs
----------------------------------------------------------------
local main = tab.Main
local count = 0
local progress

main:Section("Actions")
main:Toggle({
    Name = "Auto pin",
    Flag = "autopin",
    Tooltip = "Pins the card so its value stops changing",
    Callback = function(on)
        card:SetPinned(on)
    end,
})
main:Button({
    Name = "Add entry",
    Callback = function()
        count += 1
        card:Set({ Value = count })
        progress:Set(count % 11)
        list:Push("Entry " .. count, count)
    end,
})
main:Separator()
main:Section("Inputs")
main:TextBox({
    Name = "Nickname",
    Placeholder = "type here…",
    Flag = "nick",
    Callback = function(text)
        card:Set({ Subtitle = text ~= "" and ("Hi, " .. text) or "Click the number to pin" })
    end,
})
main:TextBox({
    Name = "Amount",
    Numeric = true,
    Min = 0,
    Max = 100,
    Default = "10",
    Flag = "amount",
    Tooltip = "Numbers only, clamped to 0-100",
})
main:Dropdown({
    Name = "Mode",
    Options = { "Easy", "Normal", "Hard" },
    Default = "Normal",
    Flag = "mode",
    Callback = function(v)
        print("Mode:", v)
    end,
})
progress = main:Bar({ Name = "Progress", Min = 0, Max = 10 })

----------------------------------------------------------------
-- Visuals tab: colour picker, multi dropdown, typeable slider
----------------------------------------------------------------
local vis = tab.Visuals
vis:ColorPicker({
    Name = "Value color",
    Default = Color3.fromRGB(120, 200, 150),
    Flag = "valcol",
    Callback = function(c)
        card:SetTone(c)
    end,
})
vis:Dropdown({
    Name = "Features",
    Options = { "Names", "Boxes", "Health", "Distance" },
    Multi = true,
    Default = { "Names" },
    Flag = "features",
    Callback = function(picked)
        print("Features:", table.concat(picked, ", "))
    end,
})
-- click the number on the right of a slider to type an exact value
vis:Slider({ Name = "Intensity", Min = 0, Max = 100, Step = 5, Default = 50, Suffix = "%", Flag = "intensity" })
vis:Choice({ Name = "Style", Options = { "Flat", "Soft", "Sharp" }, Flag = "style" })

----------------------------------------------------------------
-- Utility tab: search, collapsible groups, key chips, hide / disable
----------------------------------------------------------------
local util = tab.Utility
util:Search({ Placeholder = "Search this tab…" })

local buttons = util:Group({ Name = "Buttons", Open = true })
buttons:ButtonRow({
    {
        Name = "Notify",
        Callback = function()
            ui:Notify({ Title = "Hello", Text = "Toasts fade out on their own. Click one to dismiss it." })
        end,
    },
    {
        Name = "Clear history",
        Tone = "danger",
        Callback = function()
            ui:Prompt({
                Title = "Clear history?",
                Text = "This removes every entry from the history list.",
                Yes = "Clear",
                Tone = "danger",
                Callback = function(yes)
                    if yes then
                        list:Clear()
                    end
                end,
            })
        end,
    },
})

local toggles = util:Group({ Name = "Toggles", Persist = true })
local extra
toggles:Toggle({
    Name = "Speed boost",
    Keybind = Enum.KeyCode.B,
    Flag = "boost",
    Tooltip = "Click the key chip to rebind. Backspace clears it.",
    Callback = function(on)
        print("Speed boost:", on)
    end,
})
toggles:Toggle({
    Name = "Show extra",
    Callback = function(on)
        extra:SetVisible(on)
    end,
})
toggles:Toggle({
    Name = "Lock extra",
    Tooltip = "Greys out the slider below",
    Callback = function(on)
        extra:SetEnabled(not on)
    end,
})
extra = toggles:Slider({ Name = "Extra", Min = 0, Max = 10, Step = 1, Default = 5 })
extra:SetVisible(false)

----------------------------------------------------------------
-- Data tab: live stats and a graph
----------------------------------------------------------------
local data = tab.Data
data:Section("Live")
local fpsStat = data:Stat({ Name = "FPS", Value = "–" })
local playersStat = data:Stat({ Name = "Players", Value = "–" })
local graph = data:Graph({ Name = "FPS history", Min = 0, Max = 120, Height = 48 })

local acc, frames = 0, 0
local conn = RunService.Heartbeat:Connect(function(dt)
    frames += 1
    acc += dt
    if acc >= 0.25 then
        local fps = math.floor(frames / acc + 0.5)
        fpsStat:Set(fps, fps < 30 and "danger" or fps < 55 and "warn" or "accent")
        playersStat:Set(#Players:GetPlayers())
        graph:Push(fps)
        acc, frames = 0, 0
    end
end)

data:Separator()
data:Section("About")
data:Label({ Text = "Player: " .. Players.LocalPlayer.Name })
data:Label({ Text = "LiteUI " .. Lite.Version })
data:Paragraph("Paragraphs wrap automatically and resize the panel to fit their text. Hover most rows for a tooltip.")

----------------------------------------------------------------
-- Settings tab: built-in settings + profiles
----------------------------------------------------------------
ui:Settings({ Panel = tab.Settings })
tab.Settings:Separator()
tab.Settings:Section("Profiles")
ui:Profiles({ Panel = tab.Settings })

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------
ui:OnVisibility(function(visible)
    print("LiteUI visible:", visible)
end)
ui:OnDestroy(function()
    conn:Disconnect()
    print("LiteUI demo closed")
end)

ui:Show()
ui:Notify({ Title = "LiteUI loaded", Text = "Press RightShift to hide or show.", Tone = "accent" })
