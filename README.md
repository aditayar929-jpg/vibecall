# VibeCall

A modern dating + random video calling mobile app with premium UI/UX.

## Features

- Random video calling with Agora/ZegoCloud
- Tinder-style swipe dating
- Real-time chat system
- Premium membership with coins
- Beautiful dark theme with neon gradients

## Tech Stack

- Flutter (latest)
- Firebase (Auth, Firestore, Storage, Messaging)
- Riverpod (state management)
- GoRouter (navigation)
- Agora SDK (video calling)

## Setup

1. **Install Flutter**: https://flutter.dev/docs/get-started/install
2. **Clone & install deps**:
   ```bash
   cd vibecall
   flutter pub get
   ```
3. **Firebase Setup**:
   - Create a Firebase project at https://console.firebase.google.com
   - Run `flutterfire configure` to generate `firebase_options.dart`
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
4. **Agora Setup**:
   - Create account at https://www.agora.io
   - Add your App ID to the video call screen
5. **Run**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App colors, strings
│   ├── di/             # Dependency injection
│   ├── router/         # GoRouter config
│   ├── theme/          # Dark theme
│   ├── utils/          # Validators, extensions
│   └── widgets/        # Main scaffold, bottom nav
├── features/
│   ├── auth/           # Splash, onboarding, login, OTP, signup, interests
│   ├── home/           # Home feed, stories, trending
│   ├── dating/         # Swipe cards, matching
│   ├── video_call/     # Matching, video call
│   ├── chat/           # Chat list, chat detail
│   ├── profile/        # Profile, edit profile
│   ├── wallet/         # Coins, rewards
│   ├── premium/        # Subscription plans
│   └── notifications/  # Notification center
├── shared/
│   ├── models/         # Data models
│   ├── services/       # Firebase service
│   └── widgets/        # Reusable widgets
└── firebase_options.dart
```

## Configuration Required

Replace placeholders in `firebase_options.dart` with your Firebase project credentials.

For video calling, add your Agora App ID in the video call screen.
