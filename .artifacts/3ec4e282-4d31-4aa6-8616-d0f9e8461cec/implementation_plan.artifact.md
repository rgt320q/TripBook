# Implementation Plan - Build & Environment Stability

This plan addresses the persistent Gradle build errors and environment variable conflicts that are preventing the application from running.

## Proposed Changes

### [Component] Gradle Build Configuration

#### [MODIFY] [build.gradle.kts](file:///D:/Repo/Flutter/Projects/TripBook/android/build.gradle.kts)
Remove the custom build directory override. This override is forcing Gradle tasks (from the C: drive Pub cache) to write into the D: drive, triggering the "different roots" security error in Gradle 8.x.

```kotlin
// I will remove the logic that sets rootProject.layout.buildDirectory to "../../build"
```

### [Component] Environment Variables (User Action Required)

#### [ACTION] Permanent Removal of `ANDROID_PREFS_ROOT`
The conflict between `ANDROID_PREFS_ROOT` and `ANDROID_USER_HOME` is a known blocker for Modern Android Gradle plugins.

1.  Open **PowerShell as Administrator**.
2.  Run the following command:
    ```powershell
    [Environment]::SetEnvironmentVariable("ANDROID_PREFS_ROOT", $null, "User"); [Environment]::SetEnvironmentVariable("ANDROID_PREFS_ROOT", $null, "Machine")
    ```
3.  **CRITICAL:** Restart your computer or at least log out and log back in to ensure all background processes (like the Gradle Daemon) see the change.

## Verification Plan

### Manual Verification
1.  Apply the Gradle configuration change.
2.  Perform the PowerShell action and restart.
3.  Run `flutter clean` and `flutter run`.
4.  Verify that the app launches on the device without "different roots" or "AndroidLocationsBuildService" errors.
