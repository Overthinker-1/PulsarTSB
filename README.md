# Pulsar Hub — The Strongest Battlegrounds

Fluent UI **hosted on this repo** so you control the UI 100%.

## Structure

```
PulsarTSB/
├── main.lua                 ← hub logic + tabs
├── loader.lua               ← one-line execute
├── Fluent/
│   ├── main.lua             ← Fluent UI library (YOURS — edit freely)
│   └── Addons/
│       ├── SaveManager.lua
│       └── InterfaceManager.lua
└── README.md
```

## How to use

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Overthinker-1/PulsarTSB/main/main.lua"))()
```

**Toggle UI:** Left Ctrl

## Edit the UI

- Themes / window size / acrylic → top of `main.lua` (`CreateWindow`)
- Tabs, toggles, labels → sections inside `main.lua`
- Fluent core look → edit `Fluent/main.lua` (your copy)

## Upload order on GitHub

1. Create folders `Fluent` and `Fluent/Addons`
2. Upload all files keeping the same paths
3. Wait ~30s for raw CDN, then execute
