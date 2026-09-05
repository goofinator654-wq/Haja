# Haja UI

A premium, clean, **mobile + PC ready** UI library for Roblox. Single file, zero dependencies, built to outshine Rayfield.

## Files

| File | Purpose |
|---|---|
| `haja.lua` | The full library source |
| `haja-ui-script.txt` | Same script as a `.txt` — copy/paste straight into your executor |
| `demo.lua` | **Self-contained demo** — library + demo app in one file, zero links needed |
| `haja-ui-demo.txt` | Same demo as a `.txt` — paste & run, it just works |
| `example.lua` | Minimal example showing how to load the library via `loadstring` |

## Demo (paste & run)

`haja-ui-demo.txt` embeds the entire library **and** a demo UI with every element — toggles, sliders, dropdowns, keybinds, color picker, textboxes, notifications. Paste it into an executor and it opens instantly; no `game:HttpGet` or external links required. Callbacks just print/toast, so it's safe to use as a UI showcase or a starting template for your own script.

## Quick Start

```lua
local Haja = loadstring(game:HttpGet("https://raw.githubusercontent.com/goofinator654-wq/Haja/main/haja.lua"))()

local Window = Haja:CreateWindow({
    Title      = "Haja Hub",
    SubTitle   = "v1.0 · Premium",
    Theme      = "Midnight",   -- Midnight | Obsidian | Aurora
    SaveCfgKey = "my_config",  -- optional: persists toggles/sliders/etc
})

local Tab = Window:CreateTab("Main", "rbxassetid://3926307971")

Tab:CreateToggle({ Name = "Kill Aura", Flag = "killaura", Callback = print })
Tab:CreateSlider({ Name = "Speed", Min = 16, Max = 300, Default = 16, Suffix = "st/s", Callback = print })
Tab:CreateButton({ Name = "Rejoin", Callback = function() end })
Tab:CreateDropdown({ Name = "Mode", Options = {"A","B"}, Default = "A", Callback = print })
Tab:CreateKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.RightControl, Callback = function() Window:Toggle() end })
Tab:CreateTextbox({ Name = "Note", Placeholder = "...", Callback = print })
Tab:CreateColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(124,92,255), Callback = print })
Tab:CreateSection("Info")
Tab:CreateParagraph({ Title = "About", Content = "Text here." })
Tab:CreateLabel({ Text = "Plain label." })

Haja:Notify({ Title = "Loaded", Content = "Welcome to Haja UI.", Duration = 5 })
```

## Elements

`CreateToggle` · `CreateSlider` · `CreateButton` · `CreateDropdown` · `CreateKeybind` · `CreateTextbox` · `CreateColorPicker` · `CreateParagraph` · `CreateLabel` · `CreateSection`

Every element that accepts a `Flag` persists its value between sessions when `SaveCfgKey` is set on the window.

## Mobile + PC

- **PC:** draggable title bar, corner resize handle, mouse hover states, text labels next to tab icons.
- **Mobile:** auto-compacted layout sized to the viewport, touch-friendly hitboxes on sliders/dropdowns/toggles, icon-only tabs, touch dragging.
- Detection is automatic (`Haja.IsMobile()` exposes it if you want to branch logic).

## Themes

Set `Theme = "Midnight" | "Obsidian" | "Aurora"` in `CreateWindow`. Each theme defines accent, background, element, stroke, and text colors.

## API Notes

- `Window:Toggle(state?)` — show/hide the window (toggles if no arg).
- `Window:SetTitle(text)` — update the title.
- `Haja:Notify{...}` — toast notification.
- `Haja.SaveConfig(key?)` — manually force a config save.
- Toggle/slider/dropdown APIs return handles with `:Set(...)` (and `:Get()` on sliders/colorpickers).
- The search box filters the current tab's elements by name; switching tabs clears the filter.
