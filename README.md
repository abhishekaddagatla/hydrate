<p align="center">
  <img src="icon/water_1024.png" width="128" height="128" alt="Hydrate icon">
</p>

<h1 align="center">Hydrate</h1>

<p align="center">
  A lightweight macOS menu bar app that reminds you to drink water.<br>
  Persistent. Annoying (in a good way). Open source.
</p>

<p align="center">
  <a href="https://github.com/parampatel21/hydrate/releases/latest"><img src="https://img.shields.io/github/v/release/parampatel21/hydrate?style=flat-square" alt="Latest Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/parampatel21/hydrate?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square" alt="macOS 13+">
  <img src="https://img.shields.io/badge/swift-5.9%2B-orange?style=flat-square" alt="Swift 5.9+">
</p>

---

## What is Hydrate?

Hydrate lives in your menu bar and reminds you to drink water every 30 minutes. If you snooze, it gets increasingly persistent — halving the reminder interval each time until you give in and hydrate.

It also detects when you open your laptop after a break and immediately reminds you to have some water.

**No Dock icon. No bloat. Just water reminders.**

## Screenshots

<p align="center">
  <img src="screenshots/menubar.png" width="130" alt="Menu bar countdown">
  &nbsp;&nbsp;&nbsp;
  <img src="screenshots/dropdown.png" width="250" alt="Dropdown menu">
</p>

<p align="center">
  <img src="screenshots/reminder.png" width="250" alt="Reminder dialog">
  &nbsp;&nbsp;&nbsp;
  <img src="screenshots/preferences.png" width="250" alt="Preferences window">
</p>

## Features

- **Menu bar countdown** — always see how long until your next reminder
- **Escalating snooze** — reminders come back at 10 min, then 5, then 2.5, then 1.25...
- **Wake detection** — reminds you when you open your laptop after sleep
- **Two-button dialog** — "I Drank Water" to reset, or "Snooze" to delay
- **Preferences** — customize intervals, sound, and launch-at-login
- **Lightweight** — native Swift, ~15 MB memory, near-zero CPU
- **No Dock icon** — lives entirely in the menu bar
- **Open source** — MIT licensed, single-file Swift source

## Installation

### Download (recommended)

1. Go to [**Releases**](https://github.com/parampatel21/hydrate/releases/latest)
2. Download `Hydrate.zip`
3. Unzip and drag `Hydrate.app` to your **Applications** folder
4. Open it — you'll see the water droplet in your menu bar

> On first launch, macOS may show a security prompt. Go to **System Settings > Privacy & Security** and click **Open Anyway**.

### Build from source

Requires macOS 13+ and Xcode Command Line Tools.

```bash
git clone https://github.com/parampatel21/hydrate.git
cd hydrate
make build
make install   # copies to ~/Applications
make run       # or just open ~/Applications/Hydrate.app
```

## How It Works

1. **Timer starts** — 30 minutes on the clock (configurable)
2. **Reminder fires** — a dialog pops up with two buttons
3. **"I Drank Water"** — resets the timer back to 30 minutes
4. **"Snooze"** — next reminder in 10 minutes
5. **Snooze again** — 5 minutes, then 2.5, then 1.25... it keeps halving
6. **Ignore for 2 min** — auto-snoozes (escalates)
7. **Open laptop from sleep** — immediate reminder

The menu bar always shows a live countdown so you know when the next reminder is coming.

## Preferences

Click the menu bar icon and select **Preferences...** to configure:

| Setting | Default | Description |
|---------|---------|-------------|
| Reminder interval | 30 min | Time between reminders after drinking |
| First snooze | 10 min | How long the first snooze lasts |
| Minimum snooze floor | 15 sec | Shortest possible snooze interval |
| Sound | On | Play a beep when the reminder fires |
| Launch at login | Off | Start Hydrate automatically on boot |

## Uninstall

1. Click the menu bar icon and select **Quit Water Reminder**
2. Delete `Hydrate.app` from your Applications folder
3. Optionally remove preferences: `defaults delete com.parampatel.waterreminder`

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

[MIT](LICENSE) — do whatever you want with it.
