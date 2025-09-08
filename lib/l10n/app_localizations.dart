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
  /// **'Custom Location Name'**
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
