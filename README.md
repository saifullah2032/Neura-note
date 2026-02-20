# NeuraNote AI 🌊

An AI-powered note-taking app that summarizes images and voice recordings with a premium "Ocean Theme" UI.

## Features

- **AI Summarization**: Summarize images and voice recordings using Groq (Whisper) and Hugging Face APIs
- **Smart Reminders**: Location-based and calendar-integrated reminders
- **Ocean Theme UI**: Premium glassmorphism design with butter-smooth animations
- **Token System**: Usage-based token economy for AI services

## Tech Stack

- **Frontend**: Flutter 3.x with Material Design 3
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI Services**: Groq Whisper, Hugging Face
- **Animations**: Rive for interactive animations

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Firebase project configured
- API keys (Groq, Hugging Face, Cloudinary)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure environment variables:
   - Copy `.env` file (contains API keys for testing)
   - For production, set environment variables via `--dart-define`

4. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables

Create a `.env` file with the following:

```env
# API Keys
GROQ_API_KEY=your_groq_api_key
HUGGINGFACE_API_KEY=your_huggingface_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_key

# Cloudinary (optional)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## Ocean Theme 🎨

The app features a premium "Ocean Theme" with:

- **Typography**: Syne (headlines) + DM Sans (body)
- **Colors**: Deep Teal (#006064), Coral Teal (#4DB6AC), Sky Blue (#E1F5FE)
- **Glassmorphism**: Frosted glass effects on cards and navigation
- **Animations**: 
  - Custom `Curves.easeOutQuart` transitions
  - Staggered slide-and-fade for lists
  - Hero animations between screens
  - Rive-powered wave backgrounds

## Project Structure

```
lib/
├── core/
│   ├── constants.dart      # App constants & API config
│   ├── env_config.dart     # Environment configuration
│   ├── routes.dart         # GoRouter configuration
│   └── themes.dart         # Ocean Theme
├── model/                  # Data models
├── providers/              # State management
├── repo/                   # Data repositories
├── screens/
│   ├── home/               # Home screen with summaries
│   ├── login/              # Authentication
│   ├── profile/            # User profile & tokens
│   ├── reminders/          # Reminder management
│   ├── summarize/          # AI summarization
│   └── widgets/            # Shared widgets
│       └── ocean_ui_components.dart  # Ocean Theme components
└── services/               # AI & backend services
```

## API Services

### Groq Whisper
- Speech-to-text for voice recordings
- Model: `whisper-large-v3`

### Hugging Face
- Image captioning: `Salesforce/blip-image-captioning-base`
- Text summarization: `facebook/bart-large-cnn`

## License

MIT License
