<div align="center">

<picture>
  <img src="assets/readme_banner.svg" alt="Pattufy — your sound, your world" width="100%">
</picture>

# 🎵 Pattufy

**A premium cross-platform music experience built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Android%20%7C%20iOS%20%7C%20Desktop-22C55E?style=for-the-badge)](#supported-platforms)
[![AI](https://img.shields.io/badge/Powered%20by-Gemini-8E75FF?style=for-the-badge&logo=googlegemini&logoColor=white)](https://ai.google.dev/)

[![Stars](https://img.shields.io/github/stars/arjuntopscore/muicfy?style=social)](https://github.com/arjuntopscore/muicfy/stargazers)
[![Issues](https://img.shields.io/github/issues/arjuntopscore/muicfy)](https://github.com/arjuntopscore/muicfy/issues)

</div>

<br>

Pattufy turns every listening session into an immersive experience — with high-fidelity playback, full-screen video canvases, AI-curated discovery, synchronized lyrics, private media, and a polished glassmorphic interface.

<div align="center">

## ✨ The Experience

| | | |
|:---:|:---:|:---:|
| **🎬 Video Canvas**<br>Full-screen looping music visuals | **🤖 Gemini AI**<br>Natural-language vibe discovery | **🎧 Spatial Listening**<br>Gapless audio and background controls |
| **📜 Live Lyrics**<br>Synced, scrolling, interactive | **🚗 Car Mode**<br>Large controls for safe driving | **🔒 Private Vault**<br>PIN-protected personal media |
| **🍎 Glassmorphic UI**<br>Fluid Apple Music-inspired design | **📊 Listening Stats**<br>History, trends, and favorites | **🎥 Music Videos**<br>One-tap YouTube integration |

</div>

<br>

<details>
<summary><strong>Explore every feature</strong></summary>

### 🎬 Immersive video canvas
- 1080p looping vertical music visuals
- Smart 10-second chorus loops with flicker-free transitions
- Switch instantly between canvas mode and high-resolution artwork

### 🤖 AI-powered music discovery
- Describe a mood, scene, or activity in natural language
- Gemini matches your vibe against the music catalog
- Discover curated playlists and semantically related songs

### 🎧 Premium playback
- Gapless playback powered by `just_audio`
- Lock-screen, notification, and background transport controls
- Sleep timer presets for 15, 30, 45, and 60 minutes

### 📜 Lyrics, safety, and privacy
- Real-time synchronized lyrics with active-line highlighting
- Oversized, high-contrast controls in car mode
- PIN-protected vault for private audio and photos

### 🗂️ Your library
- Custom playlists with reorder and rename support
- Offline folders for MP3, M4A, FLAC, and WAV files
- Recent history and detailed listening analytics

</details>

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK as declared in `pubspec.yaml`
- A device or emulator for your target platform

### Supported platforms

| Platform | Status |
|:---:|:---:|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | ✅ |

### Installation

```bash
# Clone the repository
git clone https://github.com/arjuntopscore/muicfy.git
cd muicfy

# Get dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Configure Gemini AI

Gemini is optional. Supply a key with a compile-time dart-define:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key
```

For a Windows build, PowerShell supports the same format:

```powershell
flutter run --dart-define=GEMINI_API_KEY=$env:GEMINI_API_KEY
```

The app can also save a custom key through its in-app Gemini settings.

---

## 🏗️ Tech Stack

| Area | Technology |
|---|---|
| UI framework | Flutter and Dart |
| State management | `provider` |
| Audio | `just_audio`, `audio_service`, `audio_session` |
| Video | `video_player`, `youtube_explode_dart`, `youtube_player_flutter` |
| AI | `google_generative_ai` |
| Storage | `shared_preferences`, `path_provider`, platform file APIs |
| Visuals | Flutter glassmorphism, Material 3, and Cupertino components |

---

## 🧭 Project Structure

```text
lib/
├── gemini/          # Gemini configuration, services, and models
├── ui/              # Screens, players, sheets, library, and widgets
├── music_provider.dart
├── custom_audio_handler.dart
└── main.dart
assets/
└── app_icon.png
```

---

## 🤝 Contributing

Issues and pull requests are welcome.

1. Fork the repository
2. Create a focused feature branch
3. Commit your changes
4. Open a pull request

Found a bug or have an idea? Visit the [issue tracker](https://github.com/arjuntopscore/muicfy/issues).

<div align="center">

### Enjoying Pattufy?

**Give the repository a ⭐ — it helps the project grow!**

</div>
