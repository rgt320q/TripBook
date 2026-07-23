# Walkthrough - Group Location Sorting & Ordering

I have implemented the ability to manually sort locations within a group and ensured that this order is respected when creating a route.

## Changes Made

### 1. Data Model Update
- Updated `LocationGroup` in [location_group.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/models/location_group.dart) to include a `locationIds` list. This list persists the manual order of locations within each group.

### 2. Service Logic Improvements
- Updated `FirestoreService` in [firestore_service.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/services/firestore_service.dart):
    - **Add/Delete/Update:** Automatically keeps the group's `locationIds` list in sync when locations are added, deleted, or moved between groups.
    - **Fetching:** `getLocationsForGroup` now returns locations sorted by the manual order (if set) or by creation date (as a fallback).
    - **New Method:** Added `updateGroupLocationOrder` to save manual reordering changes.

### 3. UI: Manual Reordering in Groups
- Refactored `GroupDetailScreen` in [group_detail_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/group_detail_screen.dart):
    - Replaced the static list with a `ReorderableListView`.
    - Users can now drag and drop locations to set their preferred order within a group.
    - Changes are automatically saved to Firebase.

### 4. Rota Creation Logic
- Updated `MapScreen` in [map_screen.dart](file:///D:/Repo/Flutter/Projects/TripBook/lib/screens/map_screen.dart):
    - When selecting "From Group", the app now respects the group's internal order (manual or chronological) instead of forcing a distance-based optimization.
    - This ensures that the "Sort and Edit" screen opens with the exact order you defined in the group.

## How to Test
1.  **Manual Sorting:**
    - Go to **Groups** and select a group.
    - Use the handle on the right to drag locations into a new order.
2.  **Route Creation:**
    - Go back to the **Map**, tap "Create Route", and select **"From Group"**.
    - Choose the group you just sorted.
    - Notice that the next screen ("Sort and Edit") displays the locations in the exact order you set in the group.
3.  **Persistence:**
    - Restart the app and verify that your manual group order is still preserved.
