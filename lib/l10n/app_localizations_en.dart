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
  String get customLocationNameLabel => 'Custom Location Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notesLabel => 'Private Notes';

  @override
  String get estimatedDurationLabel => 'Estimated Duration (minutes)';

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
  String get currentLocationError =>
      'Could not get current location. Please check location services.';

  @override
  String get drawRouteError =>
      'Could not draw route. Check your API key or try again later.';

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
    return 'Route saved as \"$routeName\"';
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
  String get launchMapsError => 'Could not launch Google Maps.';

  @override
  String get searchHint => 'Search...';

  @override
  String get mapTypeTooltip => 'Map Type';

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
}
