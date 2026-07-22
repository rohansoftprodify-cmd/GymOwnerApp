# Update Gym Name to "Akro Gym"

The user wants to update the application name and visible gym name to "Akro Gym". This involves updating the app label in Android and iOS configurations, as well as UI strings in the Flutter app.

## User Review Required

> [!NOTE]
> This change updates the display name of the app on the home screen (launcher) and within the app UI. It does not change the internal package name (`com.example.gym_owner_app`) or database schema.

## Proposed Changes

### Android Configuration

#### [MODIFY] [AndroidManifest.xml](file:///Users/akashsingh/Downloads/gym_owner_app/android/app/src/main/AndroidManifest.xml)
- Update `android:label` to "Akro Gym".

### iOS Configuration

#### [MODIFY] [Info.plist](file:///Users/akashsingh/Downloads/gym_owner_app/ios/Runner/Info.plist)
- Update `CFBundleName` and `CFBundleDisplayName` to "Akro Gym".

### Flutter App

#### [MODIFY] [app.dart](file:///Users/akashsingh/Downloads/gym_owner_app/lib/src/app.dart)
- Update `MaterialApp` title to "Akro Gym".

#### [MODIFY] [splash_page.dart](file:///Users/akashsingh/Downloads/gym_owner_app/lib/src/features/splash/splash_page.dart)
- Update the splash screen text to "AKRO GYM".

#### [MODIFY] [onboarding_page.dart](file:///Users/akashsingh/Downloads/gym_owner_app/lib/src/features/onboarding/onboarding_page.dart)
- Update the onboarding header text to "Akro Gym".

## Verification Plan

### Manual Verification
1.  Verify the app title in the task switcher (recents) shows "Akro Gym".
2.  Verify the splash screen shows "AKRO GYM".
3.  Verify the onboarding screen shows "Akro Gym".
4.  (Build required) Verify the launcher icon label on the device home screen.
