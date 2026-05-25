# VibeCall - Play Store AAB Build Guide

## Step 1: Setup Environment

```bash
# Install Flutter (if not installed)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor

# Install Java 17 (needed for Android build)
pkg install openjdk-17
export JAVA_HOME=$PREFIX/opt/openjdk-17
```

## Step 2: Configure Firebase

```bash
# Install Firebase CLI
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

# Configure Firebase (select your project)
cd ~/vibecall
flutterfire configure
```

This will auto-update `lib/firebase_options.dart` with your real credentials.

## Step 3: Configure Agora (Video Calling)

Edit `lib/features/video_call/presentation/screens/video_call_screen.dart`:
- Add your Agora App ID
- Add your Agora Token (or use token server)

Sign up at: https://www.agora.io/en/

## Step 4: Create Signing Key

```bash
cd ~/vibecall/android/app

keytool -genkey -v \
  -keystore ~/vibecall/android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass vibecall123 \
  -keypass vibecall123 \
  -dname "CN=VibeCall, OU=Development, O=VibeCall, L=Mumbai, ST=Maharashtra, C=IN"
```

## Step 5: Update key.properties

Edit `android/key.properties`:
```
storePassword=vibecall123
keyPassword=vibecall123
keyAlias=upload
storeFile=upload-keystore.jks
```

## Step 6: Update Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # increment for each release
```

## Step 7: Generate App Icons

```bash
cd ~/vibecall
# Place a 1024x1024 PNG at assets/images/app_icon.png first
flutter pub run flutter_launcher_icons
```

## Step 8: Build AAB

```bash
cd ~/vibecall
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

## Step 9: Find Your AAB

```bash
ls -la build/app/outputs/bundle/release/
# Output: app-release.aab
```

## Step 10: Upload to Play Store

1. Go to: https://play.google.com/console
2. Create developer account (\$25 one-time fee)
3. Create new app
4. Upload `app-release.aab` in Release > Production
5. Fill store listing:
   - App name: VibeCall
   - Short description: Connect. Vibe. Match.
   - Full description: (see below)
   - Screenshots (min 2, phone + tablet)
   - Feature graphic (1024x500)
   - App icon (512x512)
6. Set content rating (IARC questionnaire)
7. Set pricing (Free)
8. Submit for review

## Store Listing Copy

**Short Description:**
Meet new people, video call strangers, find your match. VibeCall - Connect. Vibe. Match.

**Full Description:**
VibeCall is the ultimate social app that combines random video calling with modern dating. Meet amazing people from around the world through live video calls or find your perfect match with our smart swipe-based dating system.

Features:
- Random Video Calls - Connect instantly with people worldwide
- Smart Dating - Swipe right on profiles you like
- Real-time Chat - Message your matches instantly
- Beauty Filters - Look your best on every call
- Premium Membership - Unlock unlimited calls, swipes, and more
- Safe & Secure - Report, block, and stay protected

Download VibeCall now and start connecting!

**Category:** Social
**Content Rating:** Mature 17+
**Contains Ads:** Yes (optional)
**In-App Products:** Yes (coins, premium)

## Troubleshooting

### Build fails with signing error
- Check `key.properties` file path
- Verify keystore password matches

### Build fails with Firebase error
- Run `flutterfire configure` again
- Check `firebase_options.dart` has real values

### Build fails with memory error
```bash
# Increase Gradle memory
echo "org.gradle.jvmargs=-Xmx4g" >> android/gradle.properties
```

### Slow build
```bash
# Enable Gradle daemon
echo "org.gradle.daemon=true" >> android/gradle.properties
```
