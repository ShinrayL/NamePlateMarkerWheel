# NamePlateMarkerWheel

<p align="center">
  <img src="logo/logo.png" alt="NamePlateMarkerWheel Logo" width="500">
</p>

English | [简体中文](README.md)

A World of Warcraft addon for quick raid marking - Double-click or Alt+click on nameplates to pop up a radial wheel for fast target marking.

![WoW Version](https://img.shields.io/badge/WoW-12.0%2B-blue)
![Version](https://img.shields.io/badge/version-1.2.0-green)

## Features

- 🎯 **Double-Click Summon** - Double-click any nameplate to summon the marking wheel
- ⌨️ **Alt+Click Summon** - Hold Alt and click on a nameplate as an alternative
- ⚔️ **Combat Quick Mark** - Set marks directly with modifier key + click combinations without summoning the wheel (usable in combat)
- 🔥 **8 Raid Marks** - Radially arranged 8 mark buttons (Star, Circle, Diamond, Triangle, Moon, Square, Cross, Skull)
- ❌ **Center Clear Button** - One-click removal of target marks
- ⌨️ **ESC to Close** - Press ESC or click outside to quickly close the wheel
- 🔄 **Mark Sync Highlight** - Wheel highlights the current mark on the target
- ⚙️ **Graphical Configuration** - `/npw config` opens the config panel with real-time preview
- 🎨 **Circular Wheel** - Supports circular/rectangular texture styles
- 🎭 **Texture Options** - Solid color, Blizzard style, tooltip, custom textures
- ✨ **Animation Effects** - Configurable open/close scale animations

## Installation

### Method 1: Download & Use (Recommended)

1. Download the latest `NamePlateMarkerWheel.zip` from [Releases](../../releases)
2. Extract and copy the `NamePlateMarkerWheel` folder to:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Restart the game or enable the addon at the character selection screen

### Method 2: Manual Installation

If you downloaded the source code, you only need the files from the `src` folder:

1. Create a `NamePlateMarkerWheel` folder in `Interface\AddOns\`
2. Copy all files from the `src` folder:
   ```
   Interface\AddOns\NamePlateMarkerWheel\
   ├── NamePlateMarkerWheel.toc
   ├── Core.lua
   ├── Utils.lua
   ├── Config.lua
   ├── Register.lua
   ├── Events.lua
   └── WheelUI.lua
   ```
3. Restart the game

## Usage

### Quick Marking

| Action | Effect |
|--------|--------|
| **Double-click nameplate** | Summon the marking wheel |
| **Alt + Left Click** | Summon the marking wheel (alternative method) |
| **Click mark icon** | Set the corresponding mark on target |
| **Click center button** | Clear target's mark |
| **ESC key** | Close the wheel |

### Combat Quick Mark (No Wheel Summoning)

In the config panel (`/npw config` → Combat Quick Mark), you can set independent key combinations for each mark:

| Key Combination | Default Binding |
|----------------|-----------------|
| **Alt + Left Click** | Star (1) |
| **Ctrl + Left Click** | Circle (2) |
| **Shift + Left Click** | Diamond (3) |
| **Alt + Right Click** | Triangle (4) |
| **Ctrl + Right Click** | Moon (5) |
| **Shift + Right Click** | Square (6) |
| **Alt + Ctrl + Left Click** | Cross (7) |
| **Alt + Shift + Left Click** | Skull (8) |
| **Alt + Middle Click** | Clear mark |

**Features:**
- ✅ **Usable in Combat** - Uses `SetOverrideBindingClick` technology with pre-created secure buttons
- ✅ **Customizable** - Freely set modifier keys and mouse buttons for each mark in the config panel
- ✅ **Instant Effect** - Changes apply immediately without UI reload
- ✅ **Toggle On/Off** - Can be enabled/disabled independently

**Modifier Options:** None, Alt, Ctrl, Shift, Alt+Ctrl, Alt+Shift, Ctrl+Shift, Alt+Ctrl+Shift

**Button Options:** Left Click, Right Click, Middle Click

### Command List

Type `/npw` or `/nameplatemarkerwheel` to see all commands:

```
/npw test         - Display test wheel at screen center
/npw tar          - Display wheel for current target
/npw config       - Open graphical configuration interface
/npw debug        - Toggle debug mode
/npw reset        - Reset configuration
/npw status       - View addon status
/npw forcereset   - Full reset (requires UI reload)
```

## Compatibility

- **Game Version**: World of Warcraft 12.0+ (The War Within)
- **Addon Conflicts**: Compatible with popular nameplate addons (Plater, Threat Plates, etc.)

## FAQ

**Q: Double-click doesn't work?**
A: Make sure the interval between two clicks is within 0.5 seconds, and you're clicking the same target.

**Q: Can it be used in combat?**
A: Yes, the addon uses secure button technology and works normally in combat.

**Q: How to close the wheel?**
A: Press ESC key, or click outside the wheel area.

**Q: Will Combat Quick Mark conflict with the wheel?**
A: No. Combat Quick Mark only works when the wheel is **not displayed**. If the wheel is open, clicks will operate the buttons on the wheel.

**Q: How to disable Combat Quick Mark?**
A: Type `/npw config` to open the config panel, uncheck "Enable Combat Quick Mark".

**Q: What if Combat Quick Mark conflicts with other addon keybindings?**
A: Select a different modifier key combination for the conflicting mark in the config panel. We recommend using less common combinations (like Alt+Ctrl+Left Click).

**Q: Do I need to reload after changing Combat Quick Mark settings?**
A: No, changes take effect immediately. However, if you modify settings during combat, bindings will update after combat ends.

## Changelog

### v1.2.0 (2026-03-11)

- ⚔️ **Added Combat Quick Mark** - Set marks directly with modifier key + click without summoning wheel
- ⚔️ Support for 8 modifier combinations (Alt, Ctrl, Shift and their combinations)
- ⚔️ Fully usable in combat (uses `SetOverrideBindingClick` secure binding)
- ⚔️ Graphical configuration interface for setting key combinations per mark
- ⚔️ Instant effect, no reload required after changes
- ⚔️ Can be enabled/disabled at any time without affecting wheel functionality

### v1.1.0 (2026-02-19)

- 🎨 Added circular wheel background (using mask technology)
- 🎨 Added border effects for enhanced visual outline
- 🎨 Support for 8 texture styles (circular/rectangular × solid/Blizzard/tooltip/custom)
- 🎨 Independent background opacity configuration
- 🎨 Unified center button style (consistent with other mark buttons)
- ⚡ Optimized config interface with real-time preview support

### v1.0.0 (2026-02-19)

- ✨ Initial release
- ✨ Support for double-click and Alt+click trigger methods
- ✨ Quick setting of 8 raid marks
- ✨ Mark sync highlight display
- ✨ Fully usable in combat
- ✨ Graphical configuration interface (`/npw config`)
- ✨ Configurable wheel appearance and behavior settings
- ✨ Open/close animation effects

## License

MIT License - Free to use, feel free to share

---

**Note**: This is an open-source World of Warcraft addon for educational and sharing purposes only.
