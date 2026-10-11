# Pulsar Hub — The Strongest Battlegrounds

Fluent UI (Night-Hub style) hub for **The Strongest Battlegrounds**.

## Structure

```
PulsarTSB/
├── main.lua      ← full hub (UI + logic)
├── loader.lua    ← one-line execute
└── README.md
```

Edit `main.lua` freely — tabs, toggles and sections are modular so you can restyle the UI for your GitHub repo.

## How to use

1. Join **The Strongest Battlegrounds**
2. Open your executor
3. Paste and run:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/main.lua"))()
```

Or paste the contents of `main.lua` directly.

**Toggle UI:** `Left Ctrl`

## Tabs

| Tab | Features |
|-----|----------|
| **Combat** | Auto Block, Auto Combo, Auto Attack, Auto Ultimate, Auto Dash, Kill Aura |
| **Farm** | Auto Farm, Auto Kill, Target Priority (Nearest / Lowest HP / Selected), player picker |
| **Visuals** | Player ESP (name, health, distance, box, tracers), Aimbot + FOV |
| **Movement** | Walk Speed, Jump Power, Infinite Jump, Fly, NoClip |
| **Misc** | Anti-AFK, Anti-Fling, Anti-Ragdoll, Auto Escape, FPS Boost, Fullbright, TP, Server Hop |
| **Settings** | SaveManager / InterfaceManager (theme, config save) |

## Notes

- Combat remotes vary by TSB update — M1 / Block / Ult / Dash use `VirtualInput` key simulation (F = block, G = ult, Q = dash).
- For tighter combat (techs, hitbox, desync) extend the Combat section with your own remote paths.
- Acrylic + Darker theme matches the Night Hub look from the reference screenshot.

## License

Use / edit freely in your repository.
