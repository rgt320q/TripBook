# Implementation Plan - Project Stabilization and Build Fix

This plan addresses several critical build and configuration issues in the TripBook project, ranging from environment conflicts to dependency mismatches.

## User Review Required

> [!IMPORTANT]
> **Environment Variables Cleanup:** You MUST delete the following environment variables from your system to prevent persistent Gradle service failures:
> - `ANDROID_PREFS_ROOT`
> - `ANDROID_USER_HOME`
>
> These variables often point to conflicting paths (e.g., including `.android` in the root) which causes `AndroidLocationsBuildService` to fail.

## Proposed Changes

### [Component] Android Build Configuration

#### [MODIFY] [local.properties](file:///C:/Users/cetin/Projects/TripBook/android/local.properties)
- Correct the `flutter.sdk` path to `C:\flutter` to match your current system setup and avoid cross-drive path issues.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/cetin/Projects/TripBook/android/settings.gradle.kts)
- Upgrade **Android Gradle Plugin (AGP)** to `8.9.1` to support modern dependencies.
- Upgrade **Kotlin** to `2.2.0` (a stable version that resolves internal compiler errors found in 2.1.0).

#### [MODIFY] [build.gradle.kts (App)](file:///C:/Users/cetin/Projects/TripBook/android/app/build.gradle.kts)
- Apply `id("org.jetbrains.kotlin.android")` plugin explicitly.
- Upgrade `compileSdk` and `targetSdk` to `36` as required by the latest Flutter plugins.
- Upgrade `minSdk` to `24` as required by `geocoding_android`.
- Update `compileOptions` and `kotlinOptions` to use **Java 17** for better compatibility with modern Android tools.

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/cetin/Projects/TripBook/android/gradle/wrapper/gradle-wrapper.properties)
- Upgrade **Gradle** to `8.11.1` (required by AGP 8.9.1).

#### [MODIFY] [gradle.properties](file:///C:/Users/cetin/Projects/TripBook/android/gradle.properties)
- Set `org.gradle.java.home` to use Android Studio's bundled **JDK 21** to avoid "Unsupported class file major version 68" (Java 24) errors.

## Verification Plan

### Automated Tests
- Run `./gradlew assembleDebug` in the `android` folder.
- Run `flutter build apk --debug`.

### Manual Verification
1. Open the project in Android Studio.
2. Ensure Gradle syncs without errors.
3. Run the app on an emulator or physical device.
