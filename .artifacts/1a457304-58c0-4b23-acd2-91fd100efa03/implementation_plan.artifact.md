# Implementation Plan - Fix Gesture Bleed-through on Web

The goal is to prevent interactions (scrolling, dragging, zooming) on the Route Summary and other modals from affecting the underlying Google Map on the web platform.

## User Review Required

> [!IMPORTANT]
> I will implement a "Modal State" management system. When a modal or bottom sheet is open, we will programmatically disable gestures on the `GoogleMap` widget. This is a robust, dependency-free way to ensure that mouse events (scroll wheel, drag) are handled exclusively by the foreground UI.

## Proposed Changes

### 1. Map Screen State Management
#### [MODIFY] [map_screen.dart](file:///C:/Users/cetin/Projects/TripBook/lib/screens/map_screen.dart)
- Add a new state variable: `bool _isAnyModalOpen = false;`.
- Update `GoogleMap` widget parameters to use this state:
    - `scrollGesturesEnabled: !_isAnyModalOpen`
    - `zoomGesturesEnabled: !_isAnyModalOpen`
    - `rotateGesturesEnabled: !_isAnyModalOpen`
    - `tiltGesturesEnabled: !_isAnyModalOpen`
- Wrap `showModalBottomSheet` and `showDialog` calls (where appropriate) with `setState(() => _isAnyModalOpen = true)` and reset it in `.whenComplete()`.

### 2. Route Summary Interaction
- Apply the modal state logic to `_showRouteSummary`.
- Apply the same logic to `_showRouteCreationDialog` and other interactive overlays on the map.

### 3. Pointer Interceptor (Optional Backup)
- If the gesture disabling is not sufficient for certain browser edge cases, I will consider adding the `pointer_interceptor` package, but the gesture-disabling approach is preferred as it requires no new dependencies.

## Verification Plan

### Manual Verification
- Open the Route Summary on Web.
- Use the mouse wheel over the summary; verify the summary scrolls and the map does **not** zoom.
- Click and drag the summary content; verify the summary scrolls and the map does **not** pan.
- Close the summary and verify map interactions are restored.
