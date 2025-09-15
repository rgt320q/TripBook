import "package:firebase_auth/firebase_auth.dart";
import "package:tripbook/l10n/app_localizations.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:tripbook/models/location_group.dart";
import "package:tripbook/models/travel_location.dart";
import "package:tripbook/screens/map_screen.dart";
import "package:tripbook/services/firestore_service.dart";

class ManageLocationsScreen extends StatefulWidget {
  final String? initiallyExpandedLocationId;
  final bool isForSelection;
  const ManageLocationsScreen({
    super.key,
    this.initiallyExpandedLocationId,
    this.isForSelection = false,
  });

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

enum SortBy { nameAsc, nameDesc, dateNewest, dateOldest }

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<TravelLocation> _selectedLocations = [];
  SortBy _currentSortBy = SortBy.dateNewest;
  GlobalKey? _scrollKey;

  void _sortLocations(List<TravelLocation> locations) {
    switch (_currentSortBy) {
      case SortBy.nameAsc:
        locations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortBy.nameDesc:
        locations.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortBy.dateNewest:
        locations.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        break;
      case SortBy.dateOldest:
        locations.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
        break;
    }
  }

  void _scrollToSelected() {
    if (_scrollKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _scrollKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            alignment: 0.0, // Align to the top of the viewport
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageLocationsScreenTitle),
        actions: [
          if (widget.isForSelection)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_selectedLocations);
              },
            ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (SortBy result) {
              setState(() {
                _currentSortBy = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
              PopupMenuItem<SortBy>(
                value: SortBy.nameAsc,
                child: Text(l10n.sortByNameAsc),
              ),
              PopupMenuItem<SortBy>(
                value: SortBy.nameDesc,
                child: Text(l10n.sortByNameDesc),
              ),
              PopupMenuItem<SortBy>(
                value: SortBy.dateNewest,
                child: Text(l10n.sortByDateNewest),
              ),
              PopupMenuItem<SortBy>(
                value: SortBy.dateOldest,
                child: Text(l10n.sortByDateOldest),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TravelLocation>>(
        stream: _firestoreService.getLocations(),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!locationSnapshot.hasData || locationSnapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noSavedLocations));
          }
          if (locationSnapshot.hasError) {
            return Center(
              child: Text(l10n.error(locationSnapshot.error.toString())),
            );
          }

          final locations = locationSnapshot.data!;
          _sortLocations(locations);

          // Find the index of the item to scroll to
          final targetLocationIndex = widget.initiallyExpandedLocationId != null
              ? locations.indexWhere(
                  (loc) =>
                      loc.firestoreId == widget.initiallyExpandedLocationId,
                )
              : -1;

          if (targetLocationIndex != -1) {
            _scrollKey = GlobalKey();
            _scrollToSelected();
          }

          return StreamBuilder<List<LocationGroup>>(
            stream: _firestoreService.getGroups(),
            builder: (context, groupSnapshot) {
              final groups = groupSnapshot.data ?? [];
              groups.sort((a, b) => a.name.compareTo(b.name));
              final groupMap = {for (var g in groups) g.firestoreId: g.name};

              return ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final bool isTarget = index == targetLocationIndex;

                  Widget listItem = LocationListItem(
                    key: ValueKey(location.firestoreId ?? location.hashCode),
                    location: location,
                    groupName: groupMap[location.groupId] ?? l10n.groupNone,
                    allGroups: groups,
                    firestoreService: _firestoreService,
                    isInitiallyExpanded: isTarget,
                    isSelected: _selectedLocations.contains(location),
                    onSelected: widget.isForSelection
                        ? (location, selected) {
                            setState(() {
                              if (selected) {
                                _selectedLocations.add(location);
                              } else {
                                _selectedLocations.remove(location);
                              }
                            });
                          }
                        : null,
                  );

                  if (isTarget) {
                    return Container(key: _scrollKey, child: listItem);
                  }
                  return listItem;
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LocationListItem extends StatefulWidget {
  final TravelLocation location;
  final String groupName;
  final List<LocationGroup> allGroups;
  final FirestoreService firestoreService;
  final bool isInitiallyExpanded;
  final bool isSelected;
  final Function(TravelLocation, bool)? onSelected;

  const LocationListItem({
    super.key,
    required this.location,
    required this.groupName,
    required this.allGroups,
    required this.firestoreService,
    this.isInitiallyExpanded = false,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  State<LocationListItem> createState() => _LocationListItemState();
}

class _LocationListItemState extends State<LocationListItem> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _needsController;
  late TextEditingController _durationController;
  String? _selectedGroupId;

  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _descriptionController = TextEditingController(
      text: widget.location.description,
    );
    _notesController = TextEditingController(text: widget.location.notes);
    final needNames =
        widget.location.needsList
            ?.map((need) => need['name'] as String)
            .join(', ') ??
        '';
    _needsController = TextEditingController(text: needNames);
    _durationController = TextEditingController(
      text: widget.location.estimatedDuration?.toString(),
    );
    _selectedGroupId = widget.location.groupId;
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _needsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.location.firestoreId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationNameEmptyError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final invalidChars = RegExp(r'[<>]');
    if (invalidChars.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationNameInvalidCharsError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (invalidChars.hasMatch(description)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.descriptionInvalidCharsError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final notes = _notesController.text.trim();
    if (invalidChars.hasMatch(notes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notesInvalidCharsError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final newNames = _needsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final oldNeedsMap = {
      for (var need in (widget.location.needsList ?? []))
        if (need['name'] is String)
          (need['name'] as String): (need['checked'] as bool? ?? false),
    };

    final List<Map<String, dynamic>> needsList = [];
    for (var name in newNames) {
      needsList.add({'name': name, 'checked': oldNeedsMap[name] ?? false});
    }

    final updatedLocation = TravelLocation(
      firestoreId: widget.location.firestoreId,
      name: name,
      geoName: widget.location.geoName,
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      description: description,
      groupId: _selectedGroupId,
      notes: notes,
      needsList: needsList,
      estimatedDuration: int.tryParse(_durationController.text),
      createdAt: widget.location.createdAt, userId: '',
    );

    try {
      await widget.firestoreService.updateLocation(
        widget.location.firestoreId!,
        updatedLocation,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isExpanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        leading: widget.onSelected != null
            ? Checkbox(
                value: widget.isSelected,
                onChanged: (value) {
                  widget.onSelected!(widget.location, value!);
                },
              )
            : null,
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        title: Text(
          widget.location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(text: '${l10n.groupLabel}: ${widget.groupName}\n'),
              TextSpan(text: widget.location.geoName),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isExpanded
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteLocation(context),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, l10n.customLocationNameLabel),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, l10n.descriptionLabel),
                const SizedBox(height: 16),
                _buildTextField(_notesController, l10n.notesLabel),
                const SizedBox(height: 16),
                _buildTextField(_needsController, l10n.needsLabel),
                const SizedBox(height: 16),
                _buildTextField(
                  _durationController,
                  l10n.estimatedDurationLabel,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildGroupDropdown(),
                const SizedBox(height: 16),
                Text(
                  l10n.googleMapsNameLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.location.geoName),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      tooltip: l10n.showOnMap,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MapScreen(initialLocation: widget.location),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.orange),
                      tooltip: l10n.copyLocationInfo,
                      onPressed: () {
                        final lat = widget.location.latitude;
                        final lon = widget.location.longitude;
                        Clipboard.setData(ClipboardData(text: '$lat,$lon'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.locationCopiedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.green),
                      tooltip: l10n.saveChanges,
                      onPressed: _saveChanges,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: l10n.deleteLocation,
                      onPressed: () => _deleteLocation(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: inputType,
    );
  }

  Widget _buildGroupDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final allGroupIds = widget.allGroups.map((g) => g.firestoreId).toSet();
    allGroupIds.add(null);

    final String? validSelectedGroupId = allGroupIds.contains(_selectedGroupId)
        ? _selectedGroupId
        : null;

    return DropdownButtonFormField<String>(
      initialValue: validSelectedGroupId,
      decoration: InputDecoration(
        labelText: l10n.groupLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(l10n.groupNone)),
        ...widget.allGroups.map((group) {
          return DropdownMenuItem<String>(
            value: group.firestoreId,
            child: Text(group.name),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGroupId = value;
        });
      },
    );
  }

  Future<void> _deleteLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLocation),
        content: Text(l10n.deleteLocationConfirmation(widget.location.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmDelete == true && widget.location.firestoreId != null) {
      await widget.firestoreService.deleteLocation(
        widget.location.firestoreId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationDeletedSuccess),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
