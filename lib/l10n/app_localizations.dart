import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @selectGroupColor.
  ///
  /// In en, this message translates to:
  /// **'Select Group Color:'**
  String get selectGroupColor;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'By Name (A-Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'By Name (Z-A)'**
  String get sortByNameDesc;

  /// No description provided for @sortByDateNewest.
  ///
  /// In en, this message translates to:
  /// **'By Date (Newest)'**
  String get sortByDateNewest;

  /// No description provided for @sortByDateOldest.
  ///
  /// In en, this message translates to:
  /// **'By Date (Oldest)'**
  String get sortByDateOldest;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups created yet.'**
  String get noGroupsYet;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// Confirmation message for deleting a group
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the group \'{groupName}\'? All locations belonging to this group will also be deleted.'**
  String deleteGroupConfirmation(String groupName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @travelGroups.
  ///
  /// In en, this message translates to:
  /// **'TravelGroups'**
  String get travelGroups;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String error(String error);

  /// No description provided for @noLocationsInGroup.
  ///
  /// In en, this message translates to:
  /// **'No locations in this group yet.'**
  String get noLocationsInGroup;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsernameLabel;

  /// No description provided for @profileHomeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Location (Lat,Lng)'**
  String get profileHomeLocationLabel;

  /// No description provided for @profileLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageLabel;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileSaveSuccess;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get profileLoadError;

  /// No description provided for @profileUsernameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username.'**
  String get profileUsernameValidation;

  /// No description provided for @createRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRoute;

  /// No description provided for @savedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Saved Routes'**
  String get savedRoutes;

  /// No description provided for @reachedLocations.
  ///
  /// In en, this message translates to:
  /// **'Reached Locations'**
  String get reachedLocations;

  /// No description provided for @manageLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get manageLocations;

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @activeRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'Active Route Summary'**
  String get activeRouteSummary;

  /// No description provided for @clearRoute.
  ///
  /// In en, this message translates to:
  /// **'Clear Route'**
  String get clearRoute;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Book'**
  String get appTitle;

  /// No description provided for @createRouteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRouteDialogTitle;

  /// No description provided for @createRouteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'How would you like to create your route?'**
  String get createRouteDialogContent;

  /// No description provided for @fromGroup.
  ///
  /// In en, this message translates to:
  /// **'From Group'**
  String get fromGroup;

  /// No description provided for @manualSelection.
  ///
  /// In en, this message translates to:
  /// **'Manual Selection'**
  String get manualSelection;

  /// No description provided for @endPointDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get endPointDialogTitle;

  /// No description provided for @endPointDialogContent.
  ///
  /// In en, this message translates to:
  /// **'The starting point is set as the endpoint. You can select a different endpoint from the map if you wish.'**
  String get endPointDialogContent;

  /// No description provided for @selectFromMap.
  ///
  /// In en, this message translates to:
  /// **'Select from Map'**
  String get selectFromMap;

  /// No description provided for @homeLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Home location not set'**
  String get homeLocationNotSet;

  /// No description provided for @setHomeLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Home Location'**
  String get setHomeLocationTitle;

  /// No description provided for @setHomeLocationContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to set this location as your home?'**
  String get setHomeLocationContent;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @selectNewEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Please select a new endpoint from the map.'**
  String get selectNewEndpoint;

  /// No description provided for @minTwoLocationsError.
  ///
  /// In en, this message translates to:
  /// **'You must select at least 2 locations to create a route.'**
  String get minTwoLocationsError;

  /// No description provided for @locationsNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'The locations for this route could not be found or are insufficient.'**
  String get locationsNotFoundError;

  /// No description provided for @addLocationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Location'**
  String get addLocationDialogTitle;

  /// No description provided for @realLocationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Real Location Name (Cannot be changed)'**
  String get realLocationNameLabel;

  /// No description provided for @customLocationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Name'**
  String get customLocationNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Notes'**
  String get notesLabel;

  /// No description provided for @estimatedDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration (minutes)'**
  String get estimatedDurationLabel;

  /// No description provided for @needsLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs (comma-separated)'**
  String get needsLabel;

  /// No description provided for @selectGroupOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Group (Optional)'**
  String get selectGroupOptionalLabel;

  /// No description provided for @confirmEndpointDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Endpoint'**
  String get confirmEndpointDialogTitle;

  /// No description provided for @confirmEndpointDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Set \'{geoName}\' as the endpoint?'**
  String confirmEndpointDialogContent(String geoName);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// No description provided for @currentLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location. Please check location services.'**
  String get currentLocationError;

  /// No description provided for @drawRouteError.
  ///
  /// In en, this message translates to:
  /// **'Could not draw route. Check your API key or try again later.'**
  String get drawRouteError;

  /// No description provided for @saveRouteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Route'**
  String get saveRouteDialogTitle;

  /// No description provided for @routeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter route name'**
  String get routeNameHint;

  /// No description provided for @routeExistsError.
  ///
  /// In en, this message translates to:
  /// **'A route named \'{routeName}\' already exists. Overwrite?'**
  String routeExistsError(String routeName);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @routeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route saved as \'{routeName}\''**
  String routeSavedSuccess(String routeName);

  /// No description provided for @routeCompletionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Completed'**
  String get routeCompletionDialogTitle;

  /// No description provided for @plannedDistance.
  ///
  /// In en, this message translates to:
  /// **'Planned Distance'**
  String get plannedDistance;

  /// No description provided for @actualDistance.
  ///
  /// In en, this message translates to:
  /// **'Actual Distance'**
  String get actualDistance;

  /// No description provided for @plannedTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Planned Total Duration'**
  String get plannedTotalDuration;

  /// No description provided for @actualDuration.
  ///
  /// In en, this message translates to:
  /// **'Actual Duration'**
  String get actualDuration;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @routeSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Summary'**
  String get routeSummaryTitle;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNavigation;

  /// No description provided for @estimatedTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Travel Time'**
  String get estimatedTravelTime;

  /// No description provided for @totalTimeAtStops.
  ///
  /// In en, this message translates to:
  /// **'Total Time at Stops'**
  String get totalTimeAtStops;

  /// No description provided for @totalTripTime.
  ///
  /// In en, this message translates to:
  /// **'Total Trip Time'**
  String get totalTripTime;

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get totalDistance;

  /// No description provided for @needsForTrip.
  ///
  /// In en, this message translates to:
  /// **'Your needs for this trip:'**
  String get needsForTrip;

  /// No description provided for @notesForTrip.
  ///
  /// In en, this message translates to:
  /// **'Your private notes for this trip:'**
  String get notesForTrip;

  /// No description provided for @launchMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Google Maps.'**
  String get launchMapsError;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @mapTypeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get mapTypeTooltip;

  /// No description provided for @resetBearingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset Bearing'**
  String get resetBearingTooltip;

  /// No description provided for @myLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go to my location'**
  String get myLocationTooltip;

  /// No description provided for @manageLocationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get manageLocationsScreenTitle;

  /// No description provided for @noSavedLocations.
  ///
  /// In en, this message translates to:
  /// **'No saved locations found.'**
  String get noSavedLocations;

  /// No description provided for @groupNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get groupNone;

  /// No description provided for @locationUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location updated!'**
  String get locationUpdatedSuccess;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on Map'**
  String get showOnMap;

  /// No description provided for @copyLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy Location Info'**
  String get copyLocationInfo;

  /// No description provided for @locationCopiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location info copied!'**
  String get locationCopiedSuccess;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @deleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Delete Location'**
  String get deleteLocation;

  /// No description provided for @deleteLocationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the location \'{locationName}\'?'**
  String deleteLocationConfirmation(String locationName);

  /// No description provided for @locationDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location deleted.'**
  String get locationDeletedSuccess;

  /// No description provided for @googleMapsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Maps Name:'**
  String get googleMapsNameLabel;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmationContent;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'Home Location'**
  String get homeLocation;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @selectHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Home Location'**
  String get selectHomeLocation;

  /// No description provided for @endLocation.
  ///
  /// In en, this message translates to:
  /// **'End Location'**
  String get endLocation;

  /// No description provided for @homeLocationAuto.
  ///
  /// In en, this message translates to:
  /// **'Home Location (Auto)'**
  String get homeLocationAuto;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @notificationSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout Notification Sound'**
  String get notificationSoundLabel;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefault;

  /// No description provided for @soundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get soundChime;

  /// No description provided for @soundAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get soundAlert;

  /// No description provided for @soundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get soundNone;

  /// No description provided for @backgroundLocationNotificationText.
  ///
  /// In en, this message translates to:
  /// **'TripBook is tracking your location in the background.'**
  String get backgroundLocationNotificationText;

  /// No description provided for @backgroundLocationNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'TripBook Route Tracking'**
  String get backgroundLocationNotificationTitle;

  /// No description provided for @routeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Route completed!'**
  String get routeCompleted;

  /// No description provided for @nearbyLocationNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'You are near: {locationName}'**
  String nearbyLocationNotificationTitle(String locationName);

  /// No description provided for @nearbyLocationNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Click to search for this location on Google!'**
  String get nearbyLocationNotificationBody;

  /// No description provided for @timeExpiredNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timeExpiredNotificationTitle;

  /// No description provided for @timeExpiredNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your planned time at {locationName} has expired.'**
  String timeExpiredNotificationBody(String locationName);

  /// No description provided for @minOneLocationError.
  ///
  /// In en, this message translates to:
  /// **'You must select at least one location for the route.'**
  String get minOneLocationError;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

  /// No description provided for @selectEndpointTitle.
  ///
  /// In en, this message translates to:
  /// **'Select End Point'**
  String get selectEndpointTitle;

  /// No description provided for @currentEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Current End Point'**
  String get currentEndpoint;

  /// No description provided for @communityRoutes.
  ///
  /// In en, this message translates to:
  /// **'Community Routes'**
  String get communityRoutes;

  /// No description provided for @locationsNotFoundOrInsufficient.
  ///
  /// In en, this message translates to:
  /// **'The locations for this route could not be found or are insufficient.'**
  String get locationsNotFoundOrInsufficient;

  /// No description provided for @selectedEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Selected End Point'**
  String get selectedEndpoint;

  /// No description provided for @routeStart.
  ///
  /// In en, this message translates to:
  /// **'Route start'**
  String get routeStart;

  /// No description provided for @endPoint.
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get endPoint;

  /// No description provided for @routeEnd.
  ///
  /// In en, this message translates to:
  /// **'Route end'**
  String get routeEnd;

  /// No description provided for @routeExistsWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning: Route Already Exists'**
  String get routeExistsWarningTitle;

  /// No description provided for @routeExistsWarningContent.
  ///
  /// In en, this message translates to:
  /// **'You have already downloaded this route. Do you want to overwrite the existing version?'**
  String get routeExistsWarningContent;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @downloadRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Route'**
  String get downloadRouteTitle;

  /// No description provided for @downloadRouteContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save the route \'{routeName}\' and all its locations to your own routes?'**
  String downloadRouteContent(String routeName);

  /// No description provided for @downloadAndView.
  ///
  /// In en, this message translates to:
  /// **'Download and View'**
  String get downloadAndView;

  /// No description provided for @routeUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route \'{routeName}\' was updated successfully!'**
  String routeUpdateSuccess(String routeName);

  /// No description provided for @routeDownloadError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while downloading the route: {error}'**
  String routeDownloadError(String error);

  /// No description provided for @routeDetailsPlannedDistance.
  ///
  /// In en, this message translates to:
  /// **'Planned Distance: {distance}'**
  String routeDetailsPlannedDistance(String distance);

  /// No description provided for @routeDetailsActualDistance.
  ///
  /// In en, this message translates to:
  /// **'Actual Distance: {distance}'**
  String routeDetailsActualDistance(String distance);

  /// No description provided for @routeDetailsPlannedTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Travel Time: {time}'**
  String routeDetailsPlannedTravelTime(String time);

  /// No description provided for @routeDetailsPlannedStopTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Stop Time: {time}'**
  String routeDetailsPlannedStopTime(String time);

  /// No description provided for @routeDetailsPlannedTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Total Time: {time}'**
  String routeDetailsPlannedTotalTime(String time);

  /// No description provided for @routeDetailsActualTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Actual Total Time: {time}'**
  String routeDetailsActualTotalTime(String time);

  /// No description provided for @needsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs List:'**
  String get needsListTitle;

  /// No description provided for @privateNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Notes:'**
  String get privateNotesTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noLocationsInThisRoute.
  ///
  /// In en, this message translates to:
  /// **'No locations found in this route.'**
  String get noLocationsInThisRoute;

  /// No description provided for @showDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Show Downloaded'**
  String get showDownloaded;

  /// No description provided for @hideDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Hide Downloaded'**
  String get hideDownloaded;

  /// No description provided for @noSharedRoutes.
  ///
  /// In en, this message translates to:
  /// **'No shared routes yet.'**
  String get noSharedRoutes;

  /// No description provided for @allRoutesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'All routes are downloaded and hidden.'**
  String get allRoutesDownloaded;

  /// No description provided for @routeDistanceAndDuration.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} | Duration: {duration}'**
  String routeDistanceAndDuration(String distance, String duration);

  /// No description provided for @sharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by: {author}'**
  String sharedBy(String author);

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} votes)'**
  String rating(String rating, int count);

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String comments(int count);

  /// No description provided for @downloadingRoute.
  ///
  /// In en, this message translates to:
  /// **'Downloading route...'**
  String get downloadingRoute;

  /// No description provided for @saveRoute.
  ///
  /// In en, this message translates to:
  /// **'Save Route'**
  String get saveRoute;

  /// No description provided for @saveRouteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to add the \'{routeName}\' route to your saved routes?'**
  String saveRouteConfirmation(String routeName);

  /// No description provided for @routeSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'\'{routeName}\' route saved successfully!'**
  String routeSavedSuccessfully(String routeName);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @totalBreakTime.
  ///
  /// In en, this message translates to:
  /// **'Total Break Time'**
  String get totalBreakTime;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @drawRoute.
  ///
  /// In en, this message translates to:
  /// **'Draw Route'**
  String get drawRoute;

  /// No description provided for @routeNeeds.
  ///
  /// In en, this message translates to:
  /// **'Route Needs'**
  String get routeNeeds;

  /// No description provided for @routeNotes.
  ///
  /// In en, this message translates to:
  /// **'Route Notes'**
  String get routeNotes;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @commentsLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Comments can\'t be loaded.'**
  String get commentsLoadingError;

  /// No description provided for @commentsLoadingErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading comments: {error}'**
  String commentsLoadingErrorDescription(String error);

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'votes'**
  String get votes;

  /// No description provided for @plannedTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Travel Time'**
  String get plannedTravelTime;

  /// No description provided for @plannedBreakTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Break Time'**
  String get plannedBreakTime;

  /// No description provided for @plannedTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Total Time'**
  String get plannedTotalTime;

  /// No description provided for @actualTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Actual Total Time'**
  String get actualTotalTime;

  /// No description provided for @needsList.
  ///
  /// In en, this message translates to:
  /// **'Needs List'**
  String get needsList;

  /// No description provided for @privateNotes.
  ///
  /// In en, this message translates to:
  /// **'Private Notes'**
  String get privateNotes;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @noLocationsInRoute.
  ///
  /// In en, this message translates to:
  /// **'No locations in this route.'**
  String get noLocationsInRoute;

  /// No description provided for @privateNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Notes'**
  String get privateNotesLabel;

  /// No description provided for @estimatedStayTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Stay Time (minutes)'**
  String get estimatedStayTimeLabel;

  /// No description provided for @enterValidNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get enterValidNumberError;

  /// No description provided for @needsListLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs List'**
  String get needsListLabel;

  /// No description provided for @addNewNeedHint.
  ///
  /// In en, this message translates to:
  /// **'Add new need'**
  String get addNewNeedHint;

  /// No description provided for @sortAndEdit.
  ///
  /// In en, this message translates to:
  /// **'Sort and Edit'**
  String get sortAndEdit;

  /// No description provided for @endLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'End Location'**
  String get endLocationLabel;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Lon'**
  String get longitude;

  /// No description provided for @reachedLocationsLog.
  ///
  /// In en, this message translates to:
  /// **'Reached Locations Log'**
  String get reachedLocationsLog;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// No description provided for @allLogsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All logs marked as read.'**
  String get allLogsMarkedAsRead;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @unselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect All'**
  String get unselectAll;

  /// No description provided for @allLogsMarkedAsUnread.
  ///
  /// In en, this message translates to:
  /// **'All logs marked as unread.'**
  String get allLogsMarkedAsUnread;

  /// No description provided for @deleteRead.
  ///
  /// In en, this message translates to:
  /// **'Delete Read'**
  String get deleteRead;

  /// No description provided for @readLogsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All read logs have been deleted.'**
  String get readLogsDeleted;

  /// No description provided for @sortByDateNew.
  ///
  /// In en, this message translates to:
  /// **'By Date (Newest)'**
  String get sortByDateNew;

  /// No description provided for @sortByDateOld.
  ///
  /// In en, this message translates to:
  /// **'By Date (Oldest)'**
  String get sortByDateOld;

  /// No description provided for @noReachedLocations.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t reached any locations yet.\nThey will be added here as you approach them on a route.'**
  String get noReachedLocations;

  /// No description provided for @reachedAt.
  ///
  /// In en, this message translates to:
  /// **'Reached At'**
  String get reachedAt;

  /// No description provided for @moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get moreInfo;

  /// No description provided for @stopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing'**
  String get stopSharing;

  /// No description provided for @shareRoute.
  ///
  /// In en, this message translates to:
  /// **'Share Route'**
  String get shareRoute;

  /// No description provided for @stopSharingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'When sharing is removed, all related information about the route (ratings, comments, etc.) will be deleted. Are you sure you want to stop sharing the route \'{routeName}\' with the community?'**
  String stopSharingConfirmation(String routeName);

  /// No description provided for @shareRouteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to share the route \'{routeName}\' with other users? The route will appear on the community screen.'**
  String shareRouteConfirmation(String routeName);

  /// No description provided for @routeNoLongerShared.
  ///
  /// In en, this message translates to:
  /// **'\'{routeName}\' route is no longer shared.'**
  String routeNoLongerShared(Object routeName);

  /// No description provided for @routeSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'\'{routeName}\' route shared successfully!'**
  String routeSharedSuccessfully(String routeName);

  /// No description provided for @deleteRoute.
  ///
  /// In en, this message translates to:
  /// **'Delete Route'**
  String get deleteRoute;

  /// No description provided for @deleteRouteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the route named \'{routeName}\'?'**
  String deleteRouteConfirmation(String routeName);

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @routeDeleted.
  ///
  /// In en, this message translates to:
  /// **'\'{routeName}\' route has been deleted.'**
  String routeDeleted(String routeName);

  /// No description provided for @noSavedRoutes.
  ///
  /// In en, this message translates to:
  /// **'No saved routes found.'**
  String get noSavedRoutes;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get languageCode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get enterValidEmail;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long.'**
  String get passwordMinLengthError;

  /// No description provided for @routeAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This route is already saved.'**
  String get routeAlreadySaved;

  /// No description provided for @downloadedFromCommunity.
  ///
  /// In en, this message translates to:
  /// **'(Downloaded from community)'**
  String get downloadedFromCommunity;

  /// No description provided for @deleteRouteConfirmationWithLocations.
  ///
  /// In en, this message translates to:
  /// **'This route was downloaded from the community. Do you want to delete the associated locations as well?'**
  String get deleteRouteConfirmationWithLocations;

  /// No description provided for @locationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsLabel;

  /// No description provided for @deleteRouteAndLocations.
  ///
  /// In en, this message translates to:
  /// **'Delete Route and Locations'**
  String get deleteRouteAndLocations;

  /// No description provided for @passwordComplexityError.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one letter and one number.'**
  String get passwordComplexityError;

  /// No description provided for @passwordWhitespaceError.
  ///
  /// In en, this message translates to:
  /// **'Password cannot contain spaces.'**
  String get passwordWhitespaceError;

  /// No description provided for @invalidCommentError.
  ///
  /// In en, this message translates to:
  /// **'Comment contains invalid characters.'**
  String get invalidCommentError;

  /// No description provided for @invalidGroupNameError.
  ///
  /// In en, this message translates to:
  /// **'Group name contains invalid characters.'**
  String get invalidGroupNameError;

  /// No description provided for @locationNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Location name cannot be empty.'**
  String get locationNameEmptyError;

  /// No description provided for @locationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get locationNameLabel;

  /// No description provided for @estimatedDurationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get estimatedDurationHint;

  /// No description provided for @selectGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Select a group (Optional)'**
  String get selectGroupHint;

  /// No description provided for @addNeedHint.
  ///
  /// In en, this message translates to:
  /// **'Add a need'**
  String get addNeedHint;

  /// No description provided for @locationNameInvalidCharsError.
  ///
  /// In en, this message translates to:
  /// **'Location name contains invalid characters.'**
  String get locationNameInvalidCharsError;

  /// No description provided for @descriptionInvalidCharsError.
  ///
  /// In en, this message translates to:
  /// **'Description contains invalid characters.'**
  String get descriptionInvalidCharsError;

  /// No description provided for @notesInvalidCharsError.
  ///
  /// In en, this message translates to:
  /// **'Notes contain invalid characters.'**
  String get notesInvalidCharsError;

  /// No description provided for @routeNameInvalidCharsError.
  ///
  /// In en, this message translates to:
  /// **'Route name contains invalid characters.'**
  String get routeNameInvalidCharsError;

  /// No description provided for @usernameInvalidCharsError.
  ///
  /// In en, this message translates to:
  /// **'Username contains invalid characters.'**
  String get usernameInvalidCharsError;

  /// No description provided for @mySharedRoute.
  ///
  /// In en, this message translates to:
  /// **'This is a route I shared'**
  String get mySharedRoute;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @needsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Water, Snacks, Tickets'**
  String get needsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
