import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/utils/brand_colors.dart';
import 'package:tripbook/widgets/duration_selector.dart';
import 'package:tripbook/widgets/multi_group_selector.dart';

class ManageLocationsScreen extends StatefulWidget {
  final String? initiallyExpandedLocationId;
  final bool isForSelection;
  final bool isReadOnly;
  const ManageLocationsScreen({
    super.key,
    this.initiallyExpandedLocationId,
    this.isForSelection = false,
    this.isReadOnly = false,
  });

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

enum SortBy { nameAsc, nameDesc, dateNewest, dateOldest }

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<TravelLocation>> _locationsStream;
  late final Stream<List<LocationGroup>> _groupsStream;
  final List<TravelLocation> _selectedLocations = [];
  SortBy _currentSortBy = SortBy.dateNewest;
  GlobalKey? _scrollKey;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  void _scrollToSelected(int targetIndex) {
    if (_scrollKey == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTargetIntoView(targetIndex, retries: 5);
    });
  }

  Future<void> _scrollTargetIntoView(
    int targetIndex, {
    required int retries,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final ctx = _scrollKey?.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          alignment: 0.0,
          curve: Curves.easeInOut,
        );
        return;
      }
      if (_scrollController.hasClients && attempt == 0) {
        await _scrollController.animateTo(
          (targetIndex * 100).toDouble(),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String _getSortLabel(AppLocalizations l10n) {
    switch (_currentSortBy) {
      case SortBy.nameAsc:
        return 'A-Z';
      case SortBy.nameDesc:
        return 'Z-A';
      case SortBy.dateNewest:
        return l10n.newLabel;
      case SortBy.dateOldest:
        return l10n.oldLabel;
    }
  }

  @override
  void initState() {
    super.initState();
    _locationsStream = _firestoreService.getLocations();
    _groupsStream = _firestoreService.getGroups();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelected(TravelLocation location, bool selected) {
    final double? offset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() {
      if (selected) {
        _selectedLocations.add(location);
      } else {
        _selectedLocations.remove(location);
      }
    });
    if (offset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    }
  }

  Widget _buildSearchField(AppLocalizations l10n, ColorScheme colorScheme) {
    final hasQuery = _searchQuery.isNotEmpty;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasQuery
              ? Theme.of(context).primaryColor
              : colorScheme.outlineVariant,
        ),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchLocationsHint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: l10n.clearSearch,
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(AppLocalizations l10n, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSearchResults,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.manageLocationsScreenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isForSelection)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop(_selectedLocations);
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<SortBy>(
                icon: const Icon(Icons.sort, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (SortBy result) {
                  setState(() {
                    _currentSortBy = result;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                  PopupMenuItem<SortBy>(
                    value: SortBy.nameAsc,
                    child: Row(
                      children: [
                        const Icon(Icons.sort_by_alpha, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.sortByNameAsc),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortBy>(
                    value: SortBy.nameDesc,
                    child: Row(
                      children: [
                        const Icon(Icons.sort_by_alpha, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.sortByNameDesc),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortBy>(
                    value: SortBy.dateNewest,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.sortByDateNewest),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortBy>(
                    value: SortBy.dateOldest,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.sortByDateOldest),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TravelLocation>>(
        stream: _locationsStream,
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!locationSnapshot.hasData || locationSnapshot.data!.isEmpty) {
            return Container(
              margin: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.location_off,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noSavedLocations,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.addLocationsFromMapHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (locationSnapshot.hasError) {
            return Container(
              margin: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.errorOccurred(""),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.error(locationSnapshot.error.toString()),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
            _scrollToSelected(targetLocationIndex);
          }

          return StreamBuilder<List<LocationGroup>>(
            stream: _groupsStream,
            builder: (context, groupSnapshot) {
              final groups = groupSnapshot.data ?? [];
              groups.sort((a, b) => a.name.compareTo(b.name));
              final groupMap = {for (var g in groups) g.firestoreId: g.name};

              final query = _searchQuery.trim().toLowerCase();
              final filteredLocations = query.isEmpty
                  ? locations
                  : locations.where((loc) {
                      bool matches(String? value) =>
                          value != null && value.toLowerCase().contains(query);
                      final groupMatch = loc.groupIds.any(
                        (gid) => matches(groupMap[gid]),
                      );
                      return matches(loc.name) ||
                          matches(loc.geoName) ||
                          groupMatch;
                    }).toList();

              final filteredTargetIndex =
                  widget.initiallyExpandedLocationId != null
                  ? filteredLocations.indexWhere(
                      (loc) =>
                          loc.firestoreId == widget.initiallyExpandedLocationId,
                    )
                  : -1;

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats header
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.blue[900]!, Colors.blue[800]!]
                              : [
                                  colorScheme.primaryContainer,
                                  Colors.blue[100]!,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${locations.length} ${l10n.locationsLabel}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  l10n.savedLocationsHeader,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.blue[200]
                                        : colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getSortLabel(l10n),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    _buildSearchField(l10n, colorScheme),
                    const SizedBox(height: 12),

                    if (query.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${filteredLocations.length} ${l10n.locationsLabel}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],

                    // Locations list
                    Expanded(
                      child: filteredLocations.isEmpty
                          ? _buildNoSearchResults(l10n, colorScheme)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: filteredLocations.length,
                              itemBuilder: (context, index) {
                                final location = filteredLocations[index];
                                final bool isTarget =
                                    index == filteredTargetIndex;

                                Widget listItem = LocationListItem(
                                  key: ValueKey(
                                    location.firestoreId ?? location.hashCode,
                                  ),
                                  location: location,
                                  groupNames: location.groupIds
                                      .map(
                                        (id) => groupMap[id] ?? l10n.groupNone,
                                      )
                                      .toList(),
                                  allGroups: groups,
                                  firestoreService: _firestoreService,
                                  isInitiallyExpanded: isTarget,
                                  isSelected: _selectedLocations.contains(
                                    location,
                                  ),
                                  isReadOnly: widget.isReadOnly,
                                  onSelected: widget.isForSelection
                                      ? (location, selected) {
                                          _toggleSelected(location, selected);
                                        }
                                      : null,
                                );

                                return Container(
                                  key: isTarget ? _scrollKey : null,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: listItem,
                                );
                              },
                            ),
                    ),
                  ],
                ),
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
  final List<String> groupNames;
  final List<LocationGroup> allGroups;
  final FirestoreService firestoreService;
  final bool isInitiallyExpanded;
  final bool isSelected;
  final bool isReadOnly;
  final Function(TravelLocation, bool)? onSelected;

  const LocationListItem({
    super.key,
    required this.location,
    required this.groupNames,
    required this.allGroups,
    required this.firestoreService,
    this.isInitiallyExpanded = false,
    this.isSelected = false,
    this.isReadOnly = false,
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
  int? _selectedDuration;
  List<String> _selectedGroupIds = [];

  late bool _isExpanded;

  final List<Color> _groupColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  Future<LocationGroup?> _showAddNewGroupDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final groupNameController = TextEditingController();
    Color selectedColor = _groupColors.first;
    final formKey = GlobalKey<FormState>();

    return await showDialog<LocationGroup>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add,
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                l10n.newGroup,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Group name input
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: TextFormField(
                            controller: groupNameController,
                            decoration: InputDecoration(
                              labelText: l10n.groupName,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              labelStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.locationNameEmptyError;
                              }
                              final invalidChars = RegExp(r'[<>]');
                              if (invalidChars.hasMatch(value)) {
                                return l10n.invalidGroupNameError;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Color selection
                        Text(
                          l10n.selectGroupColor,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            children: _groupColors.map((color) {
                              final isSelected = selectedColor == color;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                        ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancel,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      brandButtonBlue(
                                        Theme.of(context).brightness,
                                      ),
                                      brandGradientEndBlue(
                                        Theme.of(context).brightness,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      final newGroup = LocationGroup(
                                        name: groupNameController.text.trim(),
                                        // ignore: deprecated_member_use
                                        color: selectedColor.value,
                                        createdAt: DateTime.now(),
                                        userId: FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid,
                                      );
                                      final docRef = await widget
                                          .firestoreService
                                          .addGroup(newGroup);
                                      final createdGroup = LocationGroup(
                                        firestoreId: docRef.id,
                                        name: newGroup.name,
                                        color: newGroup.color,
                                        createdAt: newGroup.createdAt,
                                        userId: newGroup.userId,
                                      );
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(createdGroup);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.save,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
    _selectedDuration = widget.location.estimatedDuration;
    _selectedGroupIds = List.from(widget.location.groupIds);
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _needsController.dispose();
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
      groupIds: _selectedGroupIds,
      notes: notes,
      needsList: needsList,
      estimatedDuration: _selectedDuration,
      createdAt: widget.location.createdAt,
      userId: widget.location.userId,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group color for the location
    final groupColor =
        widget.allGroups
            .where((g) => widget.location.groupIds.contains(g.firestoreId))
            .map((g) => Color(g.color!))
            .firstOrNull ??
        Colors.grey[400]!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isExpanded ? theme.primaryColor : colorScheme.outlineVariant,
          width: _isExpanded ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            leading: widget.onSelected != null
                ? Container(
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? theme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isSelected
                            ? theme.primaryColor
                            : colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: Checkbox(
                      value: widget.isSelected,
                      activeColor: Colors.transparent,
                      checkColor: Colors.white,
                      side: BorderSide.none,
                      onChanged: (value) {
                        widget.onSelected!(widget.location, value!);
                      },
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: groupColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on, color: groupColor, size: 24),
                  ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            title: Text(
              widget.location.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.location.groupIds.map((gid) {
                    final group = widget.allGroups.firstWhere(
                      (g) => g.firestoreId == gid,
                      orElse: () =>
                          LocationGroup(name: l10n.groupNone, userId: ''),
                    );
                    final color = group.color != null
                        ? Color(group.color!)
                        : Colors.grey[400]!;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color.computeLuminance() > 0.5
                              ? Colors.grey[800]
                              : color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location.geoName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.location.estimatedDuration != null &&
                    widget.location.estimatedDuration! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.location.estimatedDuration} ${l10n.minutes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: _isExpanded
                ? null
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isReadOnly
                          ? colorScheme.surfaceContainerHighest
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: widget.isReadOnly
                          ? colorScheme.onSurfaceVariant
                          : Colors.red[600],
                      size: 20,
                    ),
                  ),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      _nameController,
                      l10n.customLocationNameLabel,
                      readOnly: widget.isReadOnly,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _descriptionController,
                      l10n.descriptionLabel,
                      readOnly: widget.isReadOnly,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _notesController,
                      l10n.notesLabel,
                      readOnly: widget.isReadOnly,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _needsController,
                      l10n.needsLabel,
                      hint: l10n.needsHint,
                      readOnly: widget.isReadOnly,
                    ),
                    const SizedBox(height: 16),
                    DurationSelector(
                      initialDurationMinutes: _selectedDuration,
                      readOnly: widget.isReadOnly,
                      onChanged: (value) => _selectedDuration = value,
                    ),
                    const SizedBox(height: 16),
                    _buildGroupsSelection(),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  brandButtonBlue(Theme.of(context).brightness),
                                  brandGradientEndBlue(
                                    Theme.of(context).brightness,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map, size: 20),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.showOnMap),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.isReadOnly
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapScreen(
                                            initialLocation: widget.location,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.copy, size: 20),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.copyLocationInfo),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.surface,
                                foregroundColor: colorScheme.onSurface,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.isReadOnly
                                  ? null
                                  : () {
                                      final lat = widget.location.latitude;
                                      final lon = widget.location.longitude;
                                      Clipboard.setData(
                                        ClipboardData(text: '$lat,$lon'),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.locationCopiedSuccess,
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[600]!,
                                  Colors.green[800]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save, size: 20),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.saveChanges),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.isReadOnly
                                  ? null
                                  : _saveChanges,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red[600]!, Colors.red[800]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete, size: 20),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.deleteLocation),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.isReadOnly
                                  ? null
                                  : () => _deleteLocation(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
    String? hint,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          suffixIcon: readOnly
              ? Icon(Icons.lock, color: colorScheme.onSurfaceVariant, size: 20)
              : null,
        ),
        keyboardType: inputType,
        style: TextStyle(
          color: readOnly
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGroupsSelection() {
    return MultiGroupSelector(
      selectedGroupIds: _selectedGroupIds,
      allGroups: widget.allGroups,
      readOnly: widget.isReadOnly,
      onChanged: (ids) {
        setState(() {
          _selectedGroupIds = ids;
        });
      },
      onAddNewGroup: () async {
        final newGroup = await _showAddNewGroupDialog(context);
        if (newGroup != null) {
          setState(() {
            if (!widget.allGroups.any(
              (g) => g.firestoreId == newGroup.firestoreId,
            )) {
              widget.allGroups.add(newGroup);
            }
          });
        }
        return newGroup;
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
      try {
        await widget.firestoreService.deleteLocation(
          widget.location.firestoreId!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationDeletedSuccess),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.error(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
