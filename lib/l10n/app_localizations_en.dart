// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get selectGroupColor => 'Select Group Color:';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get sortByNameAsc => 'By Name (A-Z)';

  @override
  String get sortByNameDesc => 'By Name (Z-A)';

  @override
  String get sortByDateNewest => 'By Date (Newest)';

  @override
  String get sortByDateOldest => 'By Date (Oldest)';

  @override
  String get noGroupsYet => 'No groups created yet.';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String deleteGroupConfirmation(String groupName) {
    return 'Are you sure you want to delete the group \'$groupName\'? All locations belonging to this group will also be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get groups => 'Groups';

  @override
  String get groupName => 'Group Name';

  @override
  String get newGroup => 'New Group';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get selectGroup => 'Select Group';

  @override
  String get travelGroups => 'TravelGroups';

  @override
  String error(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get noLocationsInGroup => 'No locations in this group yet.';

  @override
  String get profileScreenTitle => 'User Profile';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileHomeLocationLabel => 'Home Location (Lat,Lng)';

  @override
  String get profileLanguageLabel => 'Language';

  @override
  String get profileSaveSuccess => 'Profile updated!';

  @override
  String get profileLoadError => 'Could not load profile.';

  @override
  String get profileUsernameValidation => 'Please enter a username.';

  @override
  String get createRoute => 'Create Route';

  @override
  String get savedRoutes => 'Saved Routes';

  @override
  String get reachedLocations => 'Reached Locations';

  @override
  String get manageLocations => 'Manage Locations';

  @override
  String get manageGroups => 'Manage Groups';

  @override
  String get logout => 'Logout';

  @override
  String get activeRouteSummary => 'Active Route Summary';

  @override
  String get clearRoute => 'Clear Route';

  @override
  String get appTitle => 'Trip Book';

  @override
  String get createRouteDialogTitle => 'Create Route';

  @override
  String get createRouteDialogContent =>
      'How would you like to create your route?';

  @override
  String get fromGroup => 'From Group';

  @override
  String get manualSelection => 'Manual Selection';

  @override
  String get endPointDialogTitle => 'Endpoint';

  @override
  String get endPointDialogContent =>
      'The starting point is set as the endpoint. You can select a different endpoint from the map if you wish.';

  @override
  String get selectFromMap => 'Select from Map';

  @override
  String get homeLocationNotSet => 'Home location not set';

  @override
  String get setHomeLocationTitle => 'Set Home Location';

  @override
  String get setHomeLocationContent =>
      'Do you want to set this location as your home?';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get continueButton => 'Continue';

  @override
  String get selectNewEndpoint => 'Please select a new endpoint from the map.';

  @override
  String get minTwoLocationsError =>
      'You must select at least 2 locations to create a route.';

  @override
  String get locationsNotFoundError =>
      'The locations for this route could not be found or are insufficient.';

  @override
  String get addLocationDialogTitle => 'Add New Location';

  @override
  String get realLocationNameLabel => 'Real Location Name (Cannot be changed)';

  @override
  String get customLocationNameLabel => 'Custom Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notesLabel => 'Private Notes';

  @override
  String get estimatedDurationLabel => 'Estimated Stay Time';

  @override
  String get needsLabel => 'Needs (comma-separated)';

  @override
  String get selectGroupOptionalLabel => 'Select Group (Optional)';

  @override
  String get confirmEndpointDialogTitle => 'Confirm Endpoint';

  @override
  String confirmEndpointDialogContent(String geoName) {
    return 'Set \'$geoName\' as the endpoint?';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get drawRouteError =>
      'Could not draw route. Check your API key or try again later.';

  @override
  String get currentLocationError =>
      'Could not get current location. Please check location services.';

  @override
  String get saveRouteDialogTitle => 'Save Route';

  @override
  String get routeNameHint => 'Enter route name';

  @override
  String routeExistsError(String routeName) {
    return 'A route named \'$routeName\' already exists. Overwrite?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String routeSavedSuccess(String routeName) {
    return 'Route saved as \'$routeName\'';
  }

  @override
  String get routeCompletionDialogTitle => 'Route Completed';

  @override
  String get plannedDistance => 'Planned Distance';

  @override
  String get actualDistance => 'Actual Distance';

  @override
  String get plannedTotalDuration => 'Planned Total Duration';

  @override
  String get actualDuration => 'Actual Duration';

  @override
  String get exit => 'Exit';

  @override
  String get routeSummaryTitle => 'Route Summary';

  @override
  String get startNavigation => 'Start';

  @override
  String get estimatedTravelTime => 'Estimated Travel Time';

  @override
  String get totalTimeAtStops => 'Total Time at Stops';

  @override
  String get totalTripTime => 'Total Trip Time';

  @override
  String get totalDistance => 'Total Distance';

  @override
  String get needsForTrip => 'Your needs for this trip:';

  @override
  String get notesForTrip => 'Your private notes for this trip:';

  @override
  String get consolidate => 'Consolidate';

  @override
  String get expand => 'Expand';

  @override
  String get launchMapsError => 'Could not launch Google Maps.';

  @override
  String get searchHint => 'Search...';

  @override
  String get mapTypeTooltip => 'Map Type';

  @override
  String get mapTypeNormal => 'Standard';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeTerrain => 'Terrain';

  @override
  String get mapTypeHybrid => 'Hybrid';

  @override
  String get zoomInTooltip => 'Zoom In';

  @override
  String get zoomOutTooltip => 'Zoom Out';

  @override
  String get resetBearingTooltip => 'Reset Bearing';

  @override
  String get myLocationTooltip => 'Go to my location';

  @override
  String get manageLocationsScreenTitle => 'Manage Locations';

  @override
  String get noSavedLocations => 'No saved locations found.';

  @override
  String get groupNone => 'None';

  @override
  String get locationUpdatedSuccess => 'Location updated!';

  @override
  String get groupLabel => 'Group';

  @override
  String get showOnMap => 'Show on Map';

  @override
  String get copyLocationInfo => 'Copy Location Info';

  @override
  String get locationCopiedSuccess => 'Location info copied!';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get deleteLocation => 'Delete Location';

  @override
  String deleteLocationConfirmation(String locationName) {
    return 'Are you sure you want to delete the location \'$locationName\'?';
  }

  @override
  String get locationDeletedSuccess => 'Location deleted.';

  @override
  String get googleMapsNameLabel => 'Google Maps Name:';

  @override
  String get logoutConfirmationTitle => 'Logout';

  @override
  String get logoutConfirmationContent => 'Are you sure you want to logout?';

  @override
  String get homeLocation => 'Home Location';

  @override
  String get notSet => 'Not Set';

  @override
  String get selectHomeLocation => 'Select Home Location';

  @override
  String get endLocation => 'End Location';

  @override
  String get homeLocationAuto => 'Home Location (Auto)';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get notificationSoundLabel => 'Timeout Notification Sound';

  @override
  String get soundDefault => 'Default';

  @override
  String get soundChime => 'Chime';

  @override
  String get soundAlert => 'Alert';

  @override
  String get soundNone => 'None';

  @override
  String get backgroundLocationNotificationText =>
      'TripBook is tracking your location in the background.';

  @override
  String get backgroundLocationNotificationTitle => 'TripBook Route Tracking';

  @override
  String get routeCompleted => 'Route completed!';

  @override
  String nearbyLocationNotificationTitle(String locationName) {
    return 'You are near: $locationName';
  }

  @override
  String get nearbyLocationNotificationBody =>
      'Click to search for this location on Google!';

  @override
  String get timeExpiredNotificationTitle => 'Time\'s Up!';

  @override
  String timeExpiredNotificationBody(String locationName) {
    return 'Your planned time at $locationName has expired.';
  }

  @override
  String get minOneLocationError =>
      'You must select at least one location for the route.';

  @override
  String get notAvailable => 'N/A';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get selectEndpointTitle => 'Select End Point';

  @override
  String get currentEndpoint => 'Current End Point';

  @override
  String get communityRoutes => 'Community Routes';

  @override
  String get locationsNotFoundOrInsufficient =>
      'The locations for this route could not be found or are insufficient.';

  @override
  String get selectedEndpoint => 'Selected End Point';

  @override
  String get routeStart => 'Route start';

  @override
  String get endPoint => 'End Point';

  @override
  String get routeEnd => 'Route end';

  @override
  String get routeExistsWarningTitle => 'Warning: Route Already Exists';

  @override
  String get routeExistsWarningContent =>
      'You have already downloaded this route. Do you want to overwrite the existing version?';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get downloadRouteTitle => 'Download Route';

  @override
  String downloadRouteContent(String routeName) {
    return 'Do you want to save the route \'$routeName\' and all its locations to your own routes?';
  }

  @override
  String get downloadAndView => 'Download and View';

  @override
  String routeUpdateSuccess(String routeName) {
    return 'Route \'$routeName\' was updated successfully!';
  }

  @override
  String routeDownloadError(String error) {
    return 'An error occurred while downloading the route: $error';
  }

  @override
  String routeDetailsPlannedDistance(String distance) {
    return 'Planned Distance: $distance';
  }

  @override
  String routeDetailsActualDistance(String distance) {
    return 'Actual Distance: $distance';
  }

  @override
  String routeDetailsPlannedTravelTime(String time) {
    return 'Planned Travel Time: $time';
  }

  @override
  String routeDetailsPlannedStopTime(String time) {
    return 'Planned Stop Time: $time';
  }

  @override
  String routeDetailsPlannedTotalTime(String time) {
    return 'Planned Total Time: $time';
  }

  @override
  String routeDetailsActualTotalTime(String time) {
    return 'Actual Total Time: $time';
  }

  @override
  String get needsListTitle => 'Needs List:';

  @override
  String get privateNotesTitle => 'Private Notes:';

  @override
  String get close => 'Close';

  @override
  String get noLocationsInThisRoute => 'No locations found in this route.';

  @override
  String get showDownloaded => 'Show Downloaded';

  @override
  String get hideDownloaded => 'Hide Downloaded';

  @override
  String get noSharedRoutes => 'No shared routes yet.';

  @override
  String get allRoutesDownloaded => 'All routes are downloaded and hidden.';

  @override
  String routeDistanceAndDuration(String distance, String duration) {
    return 'Distance: $distance | Duration: $duration';
  }

  @override
  String sharedBy(String author) {
    return 'Shared by: $author';
  }

  @override
  String rating(String rating, int count) {
    return '$rating ($count votes)';
  }

  @override
  String comments(int count) {
    return '$count comments';
  }

  @override
  String get downloadingRoute => 'Downloading route...';

  @override
  String get saveRoute => 'Save Route';

  @override
  String saveRouteConfirmation(String routeName) {
    return 'Are you sure you want to add the \'$routeName\' route to your saved routes?';
  }

  @override
  String routeSavedSuccessfully(String routeName) {
    return '\'$routeName\' route saved successfully!';
  }

  @override
  String get unknownUser => 'Unknown';

  @override
  String get distance => 'Distance';

  @override
  String get duration => 'Duration';

  @override
  String get totalBreakTime => 'Total Break Time';

  @override
  String get rate => 'Rate';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get drawRoute => 'Draw Route';

  @override
  String get routeNeeds => 'Route Needs';

  @override
  String get routeNotes => 'Route Notes';

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get commentsLoadingError => 'Comments can\'t be loaded.';

  @override
  String commentsLoadingErrorDescription(String error) {
    return 'An error occurred while loading comments: $error';
  }

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get votes => 'votes';

  @override
  String get plannedTravelTime => 'Planned Travel Time';

  @override
  String get plannedBreakTime => 'Planned Break Time';

  @override
  String get plannedTotalTime => 'Planned Total Time';

  @override
  String get actualTotalTime => 'Actual Total Time';

  @override
  String get needsList => 'Needs List';

  @override
  String get privateNotes => 'Private Notes';

  @override
  String get start => 'Start';

  @override
  String get noLocationsInRoute => 'No locations in this route.';

  @override
  String get privateNotesLabel => 'Private Notes';

  @override
  String get estimatedStayTimeLabel => 'Estimated Stay Time (minutes)';

  @override
  String get enterValidNumberError => 'Please enter a valid number.';

  @override
  String get needsListLabel => 'Needs List';

  @override
  String get addNewNeedHint => 'Add new need';

  @override
  String get sortAndEdit => 'Sort and Edit';

  @override
  String get endLocationLabel => 'End Location';

  @override
  String get change => 'Change';

  @override
  String get latitude => 'Lat';

  @override
  String get longitude => 'Lon';

  @override
  String get reachedLocationsLog => 'Reached Locations Log';

  @override
  String get markAllAsRead => 'Mark All as Read';

  @override
  String get allLogsMarkedAsRead => 'All logs marked as read.';

  @override
  String get selectAll => 'Select All';

  @override
  String get unselectAll => 'Unselect All';

  @override
  String get allLogsMarkedAsUnread => 'All logs marked as unread.';

  @override
  String get deleteRead => 'Delete Read';

  @override
  String get readLogsDeleted => 'All read logs have been deleted.';

  @override
  String get sortByDateNew => 'By Date (Newest)';

  @override
  String get sortByDateOld => 'By Date (Oldest)';

  @override
  String get noReachedLocations =>
      'You haven\'t reached any locations yet.\nThey will be added here as you approach them on a route.';

  @override
  String get reachedAt => 'Reached At';

  @override
  String get moreInfo => 'More Info';

  @override
  String get stopSharing => 'Stop Sharing';

  @override
  String get shareRoute => 'Share Route';

  @override
  String stopSharingConfirmation(String routeName) {
    return 'When sharing is removed, all related information about the route (ratings, comments, etc.) will be deleted. Are you sure you want to stop sharing the route \'$routeName\' with the community?';
  }

  @override
  String shareRouteConfirmation(String routeName) {
    return 'Are you sure you want to share the route \'$routeName\' with other users? The route will appear on the community screen.';
  }

  @override
  String routeNoLongerShared(Object routeName) {
    return '\'$routeName\' route is no longer shared.';
  }

  @override
  String routeSharedSuccessfully(String routeName) {
    return '\'$routeName\' route shared successfully!';
  }

  @override
  String get deleteRoute => 'Delete Route';

  @override
  String deleteRouteConfirmation(String routeName) {
    return 'Are you sure you want to delete the route named \'$routeName\'?';
  }

  @override
  String get deleteLabel => 'Delete';

  @override
  String routeDeleted(String routeName) {
    return '\'$routeName\' route has been deleted.';
  }

  @override
  String get noSavedRoutes => 'No saved routes found.';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get distanceLabel => 'Distance';

  @override
  String get durationLabel => 'Duration';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageCode => 'en';

  @override
  String get language => 'Language';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get passwordMinLengthError =>
      'Password must be at least 8 characters long.';

  @override
  String get routeAlreadySaved => 'This route is already saved.';

  @override
  String get downloadedFromCommunity => '(Downloaded from community)';

  @override
  String get deleteRouteConfirmationWithLocations =>
      'This route was downloaded from the community. Do you want to delete the associated locations as well?';

  @override
  String get locationsLabel => 'Locations';

  @override
  String get deleteRouteAndLocations => 'Delete Route and Locations';

  @override
  String get passwordComplexityError =>
      'Password must contain at least one letter and one number.';

  @override
  String get passwordWhitespaceError => 'Password cannot contain spaces.';

  @override
  String get invalidCommentError => 'Comment contains invalid characters.';

  @override
  String get apiKeyWarning =>
      'Google Maps could not be loaded. The API key for the web is missing or invalid. Please check the .env file and your Google Cloud project configuration.';

  @override
  String get notificationsBlockedMessage =>
      'Notifications are blocked by your browser. Click the tune icon next to the address bar and allow notifications to receive travel alerts.';

  @override
  String get invalidGroupNameError =>
      'Group name cannot contain < or > characters.';

  @override
  String get locationNameEmptyError => 'Location name cannot be empty.';

  @override
  String get locationNameLabel => 'Location Name';

  @override
  String get estimatedDurationHint => 'e.g. 30';

  @override
  String get selectGroupHint => 'Select a group (Optional)';

  @override
  String get addNeedHint => 'Add a need';

  @override
  String get locationNameInvalidCharsError =>
      'Location name contains invalid characters.';

  @override
  String get descriptionInvalidCharsError =>
      'Description contains invalid characters.';

  @override
  String get notesInvalidCharsError => 'Notes contain invalid characters.';

  @override
  String get routeNameInvalidCharsError =>
      'Route name contains invalid characters.';

  @override
  String get usernameInvalidCharsError =>
      'Username contains invalid characters.';

  @override
  String get mySharedRoute => 'This is a route I shared';

  @override
  String get add => 'Add';

  @override
  String get needsHint => 'e.g. Water, Snacks, Tickets';

  @override
  String get addNewGroup => 'Add New Group...';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetEmailSent => 'Password reset email sent!';

  @override
  String get enterEmailToResetPassword =>
      'Enter your email to reset your password';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get processing => 'Processing your request...';

  @override
  String get routeOrder => 'Route Order';

  @override
  String numLocationsDragToOrder(int count) {
    return '$count locations • Drag to reorder';
  }

  @override
  String get edit => 'Edit';

  @override
  String confirmRouteWithCount(int count) {
    return 'Confirm Route ($count Locations)';
  }

  @override
  String get selectAvatarTitle => 'Select Avatar';

  @override
  String get selectButton => 'Select';

  @override
  String get selectAvatarLabel => 'Select Avatar';

  @override
  String get selectAvatarDescription => 'Select one of the avatars below';

  @override
  String get aboutLabel => 'About:';

  @override
  String get genderLabel => 'Gender:';

  @override
  String get birthDateLabel => 'Birth Date:';

  @override
  String get privacyNotShared =>
      'This user has chosen not to share profile information.';

  @override
  String get saved => 'Saved';

  @override
  String get authorProfileTooltip => 'Author\'s profile information';

  @override
  String get newRoutes => 'New routes';

  @override
  String get allRoutes => 'All routes';

  @override
  String get filtered => 'Filtered';

  @override
  String get all => 'All';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get newLabel => 'New';

  @override
  String get oldLabel => 'Old';

  @override
  String get addLocationsFromMapHint => 'You can add locations via the map';

  @override
  String get savedLocationsHeader => 'Your saved locations';

  @override
  String get thisIsYourProfile => 'This is your profile';

  @override
  String get privacyNotice =>
      'Other users can only see information you set as public.';

  @override
  String get publicProfileInfo => 'Public profile information of this user.';

  @override
  String get privacyPreferencesNotice =>
      'Profile information is displayed based on user privacy preferences.';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'hours';

  @override
  String get connectionLost => 'Connection lost. Using offline data.';

  @override
  String get groupsSyncFailed =>
      'Groups sync failed. Some features may be limited.';

  @override
  String get profileSyncFailed =>
      'Profile sync failed. Home location may not be available.';

  @override
  String get failedToSaveRoute => 'Failed to save route. Please try again.';

  @override
  String get networkError =>
      'Network error. Please check your internet connection.';

  @override
  String get quotaLimitError =>
      'Service limit reached. Please try again later.';

  @override
  String get invalidLocationError =>
      'Invalid location. Please check your waypoints.';

  @override
  String get routeDetails => 'Route Details';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get passwordChangeError => 'Error changing password';

  @override
  String get wrongCurrentPassword => 'Current password is wrong';

  @override
  String get selectBirthDate => 'Select Birth Date';

  @override
  String get avatarUpdated => 'Avatar updated successfully';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get nicknameLabel => 'Nickname / Username';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get gender => 'Gender';

  @override
  String get aboutMe => 'About Me';

  @override
  String get security => 'Security';

  @override
  String get visibleToPublic => 'Visible to public';

  @override
  String get visibleToOnlyYou => 'Only visible to you';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get select => 'Select';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get introduceYourself => 'Introduce yourself';

  @override
  String get writeBioHint => 'Write a short bio...';

  @override
  String get settings => 'Settings';

  @override
  String get custom => 'Custom';

  @override
  String get durationUnitMinutes => 'Minutes';

  @override
  String get durationUnitHours => 'Hours';

  @override
  String get addGroups => 'Add to Groups';

  @override
  String get selectGroups => 'Select Groups';

  @override
  String get noInternetAtStartup =>
      'No internet connection detected. Some features may be limited.';

  @override
  String get noInternetForOperation =>
      'This operation requires an internet connection. Please check your network.';

  @override
  String get connectionRestored => 'Internet connection restored.';

  @override
  String hybridRouteTitle(String mode) {
    return 'Hybrid Route ($mode + As the Crow Flies)';
  }

  @override
  String get noRoadAccessWarning => 'No Road Access to Some Points';

  @override
  String get approximateDurationWarning =>
      'Approximate duration calculated due to unreachable routes.';

  @override
  String get stageCompletedTitle => 'Stage Completed';

  @override
  String stageCompletedMessage(String location) {
    return 'You have reached $location. The next part is marked as unreachable by vehicle (sea crossing etc.). You can restart navigation for the next land point when you complete the crossing.';
  }

  @override
  String get nextStageReadyTitle => 'Next Stage Ready';

  @override
  String get nextStageReadyMessage =>
      'Sea crossing/buffer zone completed. Would you like to start Google Maps navigation for the next land route?';

  @override
  String get navigationNotAvailableTitle => 'Mid-Transit';

  @override
  String get navigationNotAvailableMessage =>
      'Google Maps navigation is not available for this stage (as the crow flies). Please try again when you reach the next land point.';

  @override
  String get modeDriving => 'Driving';

  @override
  String get modeWalking => 'Walking';

  @override
  String get later => 'Later';

  @override
  String get reachedCheckpoint => 'Reached Checkpoint';

  @override
  String reachedCheckpointMessage(String location) {
    return 'You have reached $location. Beyond this is a non-road segment (sea crossing, etc.).';
  }

  @override
  String get startLabel => 'Start';

  @override
  String get ok => 'OK';
}
