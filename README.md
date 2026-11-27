# 🎵 Pattufy

<p align="center">
  <img src="assets/app_icon.png" alt="Pattufy Logo" width="160" style="border-radius: 32px;" />
</p>

<p align="center">
  <b>Next-Generation Immersive Audio & Video Music Experience</b>
</p>

---

**Pattufy** is a sleek, feature-rich Flutter music player application designed to provide an immersive, modern audio and visual experience. Built with an Apple Music-inspired glassmorphic dark theme, it offers seamless playback, 1080p looping video canvases, Gemini AI music discovery, synchronized lyrics, secure private vaults, and cross-platform desktop/mobile support.

---

## ✨ Features

### 🎬 1080p Full-HD Video Canvas Mode
- **Spotify Canvas Experience**: Enjoy vertical, full-bleed 1080p looping video clips while streaming music.
- **Smart Chorus Extraction**: Automatically detects and caches high-definition video loops (~10 seconds) seamlessly synced to audio.
- **Flicker-Free Transitions**: Instant canvas restoration across player minimize and reopen navigation with zero transition flash or UI lag.
- **Flexible Playback**: Toggle between dynamic video canvas and high-resolution album art manually or let auto-reveal activate after 10 seconds.

### 🤖 Gemini AI Music Discovery
- **Natural Language Vibe Search**: Describe your mood, activity, or aesthetic (e.g., *"rainy night coding beats"* or *"energetic gym motivation"*) to get instant AI-curated playlists.
- **Semantic Song Matching**: Powered by Google Gemini AI to analyze catalog metadata, acoustic vibes, and musical themes.

### 🎧 High-Fidelity Audio Engine
- **Seamless Playback**: Built on `just_audio` and `audio_service` with gapless playback and system notification controls.
- **Lock-Screen & Background Controls**: Full OS-level media integration with live seekable progress, album art, and transport buttons.
- **Dynamic Sleep Timer**: Set timed auto-shutdown with custom presets (15m, 30m, 45m, 60m).

### 📜 Real-Time Synchronized Lyrics
- **Live Scrolling Lyrics**: Time-synced lyrics with active line highlighting and smooth auto-scrolling.
- **Interactive Sheet**: Tap anywhere to expand or dismiss lyrics without interrupting playback.

### 🚗 Distraction-Free Car Mode
- **Drive Safely**: Oversized tactile buttons, large font sizing, and high-contrast visuals designed for safe and easy in-car control.
- **Minimalist Controls**: Quick access to Play/Pause, Next/Previous, Shuffle, Repeat, and Favorites.

### 🔒 Cyber Vault & Private Media
- **Secure PIN & Stealth Mode**: Protect personal photos and audio collections behind a secure PIN-protected vault.
- **Encrypted Photo Viewer**: Private gallery viewer with interactive pinch-to-zoom, collection management, and stealth exit gestures.

### 🍎 Premium Glassmorphism UI/UX
- **Dynamic Backdrop Blur**: Multi-layer real-time Gaussian blurs with adaptive dark-mode palette styling.
- **Apple Music-Style Sheets**: Modern bottom sheets for queue management, song actions, playlist selection, and artist details.
- **Animated Audio Waves**: Responsive equalizer pulse bars indicating live playback state in the mini-player.
- **Desktop & Mobile Responsive**: Optimized for phones, tablets, and desktop workstations with collapsible sidebar navigation and full desktop player bar.

### 🎥 Music Video Integration
- **Watch Music Videos**: Instant one-tap video search to watch the full official music video directly within the app.
- **Smart Stream Extraction**: High-performance streaming powered by `youtube_explode_dart`.

### 📊 Stats & History Analytics
- **Listening Insights**: Track total listening time, favorite genres, top tracks, and daily listening trends.
- **Recent History**: Keep tabs on recently played songs and easily jump back into previous sessions.

### 🗂️ Playlists & Offline Library
- **Custom Playlists**: Create, reorder, rename, and manage custom playlists.
- **Offline Folders**: Direct device storage scanner to play local MP3, M4A, FLAC, and WAV audio offline.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.12.2` or later
- **Dart SDK**: `^3.0.0`
- **Supported Platforms**: Android, iOS, Windows, macOS, Linux, Web

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/arjuntopscore/muicfy.git
   cd muicfy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Gemini API (Optional for AI features)**
   - Obtain an API key from [Google AI Studio](https://aistudio.google.com/).
   - Add your key in `lib/gemini/gemini_config.dart` or via environment variables.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture & Tech Stack

| Layer | Technologies |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | `provider` for clean, decoupled reactive state handling |
| **Audio Playback** | `just_audio`, `audio_service`, `audio_session` |
| **Video & Canvas** | `video_player`, `youtube_explode_dart` |
| **AI Integration** | `google_generative_ai` (Gemini Flash & Pro) |
| **Local Storage** | `shared_preferences`, `sqflite`, `path_provider` |
| **UI Components** | Custom Apple Music glassmorphism, Cupertino & Material 3 design tokens |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/arjuntopscore/muicfy/issues).

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
