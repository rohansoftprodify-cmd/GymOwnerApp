# Update Summary: Akro Gym Name & Release Build Fixes

I have completed the request to rename the app to **Akro Gym** and applied fixes to resolve the "stuck on splash screen" issue in release builds.

## Changes Made

### 1. App Renaming (Akro Gym)
- **Android**: Updated `AndroidManifest.xml` label to "Akro Gym".
- **iOS**: Updated `Info.plist` display name and bundle name to "Akro Gym".
- **Flutter UI**:
    - Updated `MaterialApp` title.
    - Updated text on `SplashPage` to "AKRO GYM".
    - Updated text on `OnboardingPage` to "Akro Gym".

### 2. Release Build Fixes
- **ProGuard/R8 Configuration**:
    - Created `android/app/proguard-rules.pro` with rules to preserve Flutter and Supabase classes.
    - Enabled minification and linked ProGuard rules in `android/app/build.gradle.kts`.
- **Initialization Stability**:
    - Updated `lib/main.dart` to include a 10-second timeout for Supabase initialization.
    - Added error handling to ensure the app shows an error screen instead of hanging if initialization fails.

## Verification & Next Steps

> [!IMPORTANT]
> To verify these changes and create a working release build, you **must** use the command line with the required environment variables:
>
> ```bash
> flutter build apk --release \
>   --dart-define=SUPABASE_URL="https://sczikgmltxcufkcquxmt.supabase.co" \
>   --dart-define=SUPABASE_ANON_KEY="YOUR_ANON_KEY"
> ```

> [!TIP]
> If you still see the old "gym_owner_app" name in some places (like folder names or build artifacts), run `flutter clean` before rebuilding.
