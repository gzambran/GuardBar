# GuardBar

A native macOS menu bar application for managing [AdGuard Home](https://adguard.com/en/adguard-home/overview.html).

## 🚀 Status

GuardBar is currently in active development and testing.

**Coming soon to the Mac App Store!**

Want to try it early? You can build from source (see instructions below).

## ✨ Features

- **Quick Access** - Manage AdGuard Home directly from your menu bar
- **One-Click Toggle** - Enable or disable ad blocking instantly
- **Smart Timers** - Temporarily disable protection with customizable presets (30s, 1m, 5m, 30m, 1h, 2h)
- **Real-Time Status** - Color-coded menu bar icons show protection status at a glance
- **Background Monitoring** - Automatic status updates via configurable polling
- **Start at Login** - Launches automatically with macOS
- **Native Experience** - Built with SwiftUI for a smooth, modern macOS feel

## 📋 Requirements

- macOS 14.0 (Sonoma) or later
- AdGuard Home instance (running on your network)
- AdGuard Home credentials (username and password)

## 🛠️ Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 or later

### Build Instructions

1. Clone the repository:
```bash
git clone https://github.com/gzambran/GuardBar.git
cd GuardBar
```

2. Open the project in Xcode:
```bash
open GuardBar.xcodeproj
```

3. Build and run:
   - Select the GuardBar scheme
   - Press `Cmd+R` to build and run

### First Launch Setup

1. Click the GuardBar icon in your menu bar
2. Open Settings (Cmd+,)
3. Enter your AdGuard Home connection details:
   - Host/IP address
   - Port (default: 80)
   - Username
   - Password
4. Click "Test Connection" to verify

## 🎯 Usage

### Toggle Protection

- **Enable/Disable**: Click the menu bar icon and select "Enable Ad Blocking" or "Disable for → Permanently"
- **Temporary Disable**: Choose a preset time (30 seconds to 2 hours) for automatic re-enable

### Menu Bar Icons

- 🟢 **Green Shield**: Protection is ON
- 🔴 **Red Shield**: Protection is OFF
- 🟠 **Orange Clock**: Timer active (will re-enable automatically)
- ⚪ **Gray Shield**: Loading or connection error

### Settings

Access settings via:
- Menu bar icon → Settings
- Keyboard shortcut: `Cmd+,`

Configure:
- AdGuard Home connection
- Background polling interval
- Timer presets
- Start at login

## 🏗️ Architecture

GuardBar is built with modern Swift best practices:

- **SwiftUI** for the user interface
- **MVVM architecture** with proper separation of concerns
- **Combine framework** for reactive programming
- **ServiceManagement** for login item management
- **Keychain** for secure password storage
- **Feature-based code organization** for maintainability

## 💰 Support Development

GuardBar is open source (MIT License). While you can build it yourself, purchasing from the Mac App Store supports development and provides:

- ✅ Easy installation and automatic updates
- ✅ Priority support
- ✅ Supports future development

**[Coming to Mac App Store Soon]**

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [PiBar](https://github.com/amiantos/pibar)
- Built for the [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) community

## 📧 Contact

- GitHub: [@gzambran](https://github.com/gzambran)
- Issues: [GitHub Issues](https://github.com/gzambran/GuardBar/issues)

---

**Note**: GuardBar is not affiliated with or endorsed by AdGuard.