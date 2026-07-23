# Implementation Plan - Comprehensive Localization Fix

This plan covers identified hardcoded Turkish strings across various screens to ensure full support for English and other future languages.

## Proposed Changes

### [Component] Localization Files

#### [MODIFY] [app_en.arb](file:///D:/Repo/Flutter/Projects/TripBook/lib/l10n/app_en.arb)
Add the following keys:
- `routeOrder`: "Route Order"
- `numLocationsDragToOrder`: "{count} locations • Drag to reorder"
- `edit`: "Edit"
- `confirmRouteWithCount`: "Confirm Route ({count} Locations)"
- `selectAvatarTitle`: "Select Avatar"
- `selectButton`: "Select"
- `selectAvatarLabel`: "Select Avatar"
- `selectAvatarDescription`: "Select one of the avatars below"
- `aboutLabel`: "About:"
- `genderLabel`: "Gender:"
- `birthDateLabel`: "Birth Date:"
- `privacyNotShared`: "This user has chosen not to share profile information."
- `saved`: "Saved"
- `authorProfileTooltip`: "Author's profile information"
- `newRoutes`: "New routes"
- `allRoutes`: "All routes"
- `filtered`: "Filtered"
- `all`: "All"
- `downloaded`: "Downloaded"
- `newLabel`: "New"
- `oldLabel`: "Old"
- `addLocationsFromMapHint`: "You can add locations via the map"
- `savedLocationsHeader`: "Your saved locations"
- `thisIsYourProfile`: "This is your profile"
- `privacyNotice`: "Other users can only see information you set as public."
- `publicProfileInfo`: "Public profile information of this user."
- `privacyPreferencesNotice`: "Profile information is displayed based on user privacy preferences."
- `minutes`: "minutes"
- `hours`: "hours"
- `connectionLost`: "Connection lost. Using offline data."
- `groupsSyncFailed`: "Groups sync failed. Some features may be limited."
- `profileSyncFailed`: "Profile sync failed. Home location may not be available."
- `failedToSaveRoute`: "Failed to save route. Please try again."

#### [MODIFY] [app_tr.arb](file:///D:/Repo/Flutter/Projects/TripBook/lib/l10n/app_tr.arb)
Add the corresponding Turkish translations for all the keys above.

### [Component] UI Screens

#### [MODIFY] [location_selection_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/location_selection_screen.dart)
- Replace "Rota Sırası", "Düzenle", etc., with localized strings.

#### [MODIFY] [avatar_selection_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/avatar_selection_screen.dart)
- Localize title and button labels.

#### [MODIFY] [community_route_detail_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/community_route_detail_screen.dart)
- Localize labels like "Hakkında", "Cinsiyet", etc.

#### [MODIFY] [community_routes_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/community_routes_screen.dart)
- Localize filter labels and route counts.

#### [MODIFY] [manage_locations_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/manage_locations_screen.dart)
- Localize "Yeni"/"Eski" labels and hints.

#### [MODIFY] [map_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/map_screen.dart)
- Localize dynamic duration strings ("saat", "dakika") and snackbar messages.

### [Component] Widgets

#### [MODIFY] [user_profile_card.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/widgets/user_profile_card.dart)
- Localize privacy notices and profile descriptions.

## Verification Plan

### Manual Verification
1.  Switch the app language to **English**.
2.  Navigate to "Create Route > From Group" and select a group. Verify the "Route Order" screen is entirely in English.
3.  Check the "Community Routes" screen and verify filters and counts are in English.
4.  Check "User Profile" (your own and others) to verify privacy notices are in English.
5.  Check "Avatar Selection" to verify labels are in English.
6.  Switch to **Turkish** and repeat to ensure no regressions.
